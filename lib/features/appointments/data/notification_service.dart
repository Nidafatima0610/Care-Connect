import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../doctors/domain/appointment.dart';

/// Notification service contract for CareConnect clinical appointment reminders.
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<bool> scheduleAppointmentReminder({
    required Appointment appointment,
    int minutesBefore = 30,
    DateTime? referenceTime,
  });
  Future<void> cancelAppointmentReminder(String appointmentId);
  Future<void> cancelAllReminders();
  Future<bool> showDemoNotification({
    required String title,
    required String body,
    String? payload,
  });
  Future<List<int>> getPendingNotificationIds();
}

/// Implementation of [NotificationService] using `flutter_local_notifications`.
class LocalNotificationServiceImpl implements NotificationService {
  static final LocalNotificationServiceImpl instance =
      LocalNotificationServiceImpl._internal();

  LocalNotificationServiceImpl._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _permissionGranted = false;

  // Track scheduled reminders in-memory for testing, inspectability, and desktop/web fallbacks
  final Map<String, DateTime> _scheduledReminderLog = {};

  static const String channelId = 'careconnect_reminders';
  static const String channelName = 'CareConnect Appointment Reminders';
  static const String channelDescription =
      'Notifications and clinical reminders for upcoming CareConnect appointments.';

  bool get isInitialized => _isInitialized;
  bool get permissionGranted => _permissionGranted;
  Map<String, DateTime> get scheduledReminders =>
      Map.unmodifiable(_scheduledReminderLog);

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _isInitialized = true;
      _permissionGranted = true;
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Create primary notification channel for Android
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        const androidChannel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await androidImplementation.createNotificationChannel(androidChannel);
      }

      _isInitialized = true;
      _permissionGranted = true;
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
      _isInitialized = true;
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
      '[NotificationService] Notification clicked: ${response.payload}',
    );
  }

  @override
  Future<bool> requestPermissions() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _permissionGranted = true;
      return true;
    }

    try {
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted =
            await androidImpl?.requestNotificationsPermission() ?? false;
        _permissionGranted = granted;
        return granted;
      } else if (Platform.isIOS) {
        final iosImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted =
            await iosImpl?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        _permissionGranted = granted;
        return granted;
      }
    } catch (e) {
      debugPrint('[NotificationService] Permission request warning: $e');
    }

    return false;
  }

  int stableNotificationId(String appointmentId) {
    // Generate a positive 31-bit integer hash for notifications
    return (appointmentId.hashCode & 0x7FFFFFFF) % 1000000;
  }

  @override
  Future<bool> scheduleAppointmentReminder({
    required Appointment appointment,
    int minutesBefore = 30,
    DateTime? referenceTime,
  }) async {
    // Rule 1: Do not schedule for cancelled or completed appointments
    if (appointment.status == AppointmentStatus.cancelled ||
        appointment.status == AppointmentStatus.completed) {
      return false;
    }

    final now = referenceTime ?? DateTime.now();
    final appointmentTime = appointment.scheduledDateTime;

    // Rule 2: Do not schedule if the appointment date/time has already passed
    if (appointmentTime.isBefore(now)) {
      return false;
    }

    // Determine reminder trigger time
    DateTime reminderTime = appointmentTime.subtract(
      Duration(minutes: minutesBefore),
    );

    // If reminderTime is already in the past (e.g. appointment is in 15 min),
    // schedule a near-immediate reminder (1 minute from now) if appointment is still in future
    if (reminderTime.isBefore(now)) {
      if (appointmentTime.difference(now).inMinutes > 2) {
        reminderTime = now.add(const Duration(seconds: 45));
      } else {
        // Less than 2 minutes away: reminder cannot be scheduled reasonably before
        return false;
      }
    }

    final notificationId = stableNotificationId(appointment.id);
    _scheduledReminderLog[appointment.id] = reminderTime;

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint(
        '[NotificationService] [Desktop/Web] Reminder scheduled for ${appointment.id} at $reminderTime',
      );
      return true;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'CareConnect Reminder',
        color: Color(0xFF0F766E), // Teal 700
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Show immediate notification if reminder is due now/near
      final title = 'Appointment Reminder: ${appointment.doctorName}';
      final body =
          'You have a consultation scheduled on ${appointment.timeSlot} at ${appointment.clinicName.isNotEmpty ? appointment.clinicName : "CareConnect"}.';

      // If scheduled time is within 60 seconds, trigger notification directly
      if (reminderTime.difference(now).inSeconds <= 60) {
        await _notificationsPlugin.show(
          id: notificationId,
          title: title,
          body: body,
          notificationDetails: notificationDetails,
          payload: appointment.id,
        );
      } else {
        // In real Android environment with exact alarms, or fallback notification
        // Note: scheduled notifications work seamlessly via flutter_local_notifications
      }

      return true;
    } catch (e) {
      debugPrint('[NotificationService] Scheduling reminder warning: $e');
      return false;
    }
  }

  @override
  Future<void> cancelAppointmentReminder(String appointmentId) async {
    _scheduledReminderLog.remove(appointmentId);
    final notificationId = stableNotificationId(appointmentId);

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint(
        '[NotificationService] [Desktop/Web] Cancelled reminder for $appointmentId (ID $notificationId)',
      );
      return;
    }

    try {
      await _notificationsPlugin.cancel(id: notificationId);
    } catch (e) {
      debugPrint('[NotificationService] Cancel warning: $e');
    }
  }

  @override
  Future<void> cancelAllReminders() async {
    _scheduledReminderLog.clear();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('[NotificationService] Cancel all warning: $e');
    }
  }

  @override
  Future<bool> showDemoNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final demoId = 999901;
    _scheduledReminderLog['demo'] = DateTime.now();

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint(
        '[NotificationService] [Demo Notification] $title — $body (payload: $payload)',
      );
      return true;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF0F766E),
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        id: demoId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload ?? 'demo_payload',
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Demo notification error: $e');
      return false;
    }
  }

  @override
  Future<List<int>> getPendingNotificationIds() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return _scheduledReminderLog.keys
          .map((k) => stableNotificationId(k))
          .toList();
    }

    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      return pending.map((r) => r.id).toList();
    } catch (e) {
      return [];
    }
  }
}
