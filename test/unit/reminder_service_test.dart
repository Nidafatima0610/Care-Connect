import 'package:flutter_test/flutter_test.dart';

import 'package:care_connect/features/appointments/data/notification_service.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';

void main() {
  group('NotificationService & Local Reminders Unit Tests', () {
    late LocalNotificationServiceImpl notifService;

    setUp(() async {
      notifService = LocalNotificationServiceImpl.instance;
      await notifService.initialize();
      await notifService.cancelAllReminders();
    });

    test(
      'Notification service initializes and requests permissions safely',
      () async {
        expect(notifService.isInitialized, isTrue);
        final granted = await notifService.requestPermissions();
        expect(granted, isTrue);
      },
    );

    test(
      'stableNotificationId returns consistent positive 31-bit integers',
      () {
        final id1 = notifService.stableNotificationId('APT-849201');
        final id2 = notifService.stableNotificationId('APT-849201');
        final idOther = notifService.stableNotificationId('APT-999999');

        expect(id1, id2);
        expect(id1, isNonNegative);
        expect(id1, lessThan(1000000));
        expect(id1, isNot(idOther));
      },
    );

    test(
      'scheduleAppointmentReminder schedules reminder 30 min before visit',
      () async {
        final now = DateTime.now();
        final visitTime = now.add(const Duration(days: 2, hours: 3));
        final apt = Appointment(
          id: 'APT-NOTIF-001',
          doctorId: 'doc_marcus_vance',
          doctorName: 'Dr. Marcus Vance',
          patientId: 'pat_maya_01',
          patientName: 'Maya Sterling',
          patientPhone: '+1 555-0194',
          scheduledDateTime: visitTime,
          timeSlot: '02:00 PM',
          status: AppointmentStatus.confirmed,
          fee: 140.0,
          clinicAddress: 'East Pavilion, Suite 410',
          createdAt: now,
        );

        final scheduled = await notifService.scheduleAppointmentReminder(
          appointment: apt,
          minutesBefore: 30,
        );

        expect(scheduled, isTrue);
        expect(
          notifService.scheduledReminders.containsKey('APT-NOTIF-001'),
          isTrue,
        );

        final scheduledTarget =
            notifService.scheduledReminders['APT-NOTIF-001'];
        expect(scheduledTarget, isNotNull);
        final diff = visitTime.difference(scheduledTarget!);
        expect(diff.inMinutes, 30);
      },
    );

    test('scheduleAppointmentReminder rejects past appointments', () async {
      final now = DateTime.now();
      final pastApt = Appointment(
        id: 'APT-PAST-002',
        doctorId: 'doc_marcus_vance',
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1 555-0194',
        scheduledDateTime: now.subtract(const Duration(days: 1)),
        timeSlot: '10:00 AM',
        status: AppointmentStatus.completed,
        fee: 140.0,
        clinicAddress: 'East Pavilion, Suite 410',
        createdAt: now.subtract(const Duration(days: 2)),
      );

      final result = await notifService.scheduleAppointmentReminder(
        appointment: pastApt,
      );

      expect(result, isFalse);
      expect(
        notifService.scheduledReminders.containsKey('APT-PAST-002'),
        isFalse,
      );
    });

    test(
      'scheduleAppointmentReminder rejects cancelled appointments',
      () async {
        final now = DateTime.now();
        final cancelledApt = Appointment(
          id: 'APT-CANCELLED-003',
          doctorId: 'doc_marcus_vance',
          patientId: 'pat_maya_01',
          patientName: 'Maya Sterling',
          patientPhone: '+1 555-0194',
          scheduledDateTime: now.add(const Duration(days: 2)),
          timeSlot: '10:00 AM',
          status: AppointmentStatus.cancelled,
          fee: 140.0,
          clinicAddress: 'East Pavilion, Suite 410',
          createdAt: now,
        );

        final result = await notifService.scheduleAppointmentReminder(
          appointment: cancelledApt,
        );

        expect(result, isFalse);
        expect(
          notifService.scheduledReminders.containsKey('APT-CANCELLED-003'),
          isFalse,
        );
      },
    );

    test('cancelAppointmentReminder removes reminder successfully', () async {
      final now = DateTime.now();
      final apt = Appointment(
        id: 'APT-REMOVE-004',
        doctorId: 'doc_marcus_vance',
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1 555-0194',
        scheduledDateTime: now.add(const Duration(days: 3)),
        timeSlot: '11:00 AM',
        status: AppointmentStatus.confirmed,
        fee: 140.0,
        clinicAddress: 'East Pavilion, Suite 410',
        createdAt: now,
      );

      await notifService.scheduleAppointmentReminder(appointment: apt);
      expect(
        notifService.scheduledReminders.containsKey('APT-REMOVE-004'),
        isTrue,
      );

      await notifService.cancelAppointmentReminder('APT-REMOVE-004');
      expect(
        notifService.scheduledReminders.containsKey('APT-REMOVE-004'),
        isFalse,
      );
    });

    test(
      'showDemoNotification executes and logs demo delivery successfully',
      () async {
        final result = await notifService.showDemoNotification(
          title: 'Demo Test Title',
          body: 'Demo Test Reminder Body',
        );

        expect(result, isTrue);
        expect(notifService.scheduledReminders.containsKey('demo'), isTrue);
      },
    );
  });
}
