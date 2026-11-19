import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:care_connect/core/router/app_router.dart';
import 'package:care_connect/core/theme/app_theme.dart';
import 'package:care_connect/features/appointments/data/appointment_database.dart';
import 'package:care_connect/features/appointments/data/appointment_repository_impl.dart';
import 'package:care_connect/features/appointments/data/notification_service.dart';
import 'package:care_connect/features/appointments/domain/appointment_repository.dart';
import 'package:care_connect/features/appointments/presentation/appointment_history_screen.dart';
import 'package:care_connect/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:care_connect/features/appointments/presentation/reschedule_screen.dart';
import 'package:care_connect/features/doctors/data/doctor_repository.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';
import 'package:care_connect/features/doctors/presentation/controllers/doctor_providers.dart';
import 'package:care_connect/features/patient/data/patient_repository.dart';
import 'package:care_connect/features/patient/presentation/controllers/patient_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Appointment Management UI & Flow Widget Tests', () {
    late AppointmentDatabase db;
    late AppointmentRepository repository;
    final fixedClock = DateTime(2026, 11, 18, 10, 0);

    setUp(() async {
      db = AppointmentDatabase.instance;
      await db.init(inMemory: true);
      await db.clearAll();
      await db.seedInitialDataIfEmpty(now: fixedClock);

      repository = AppointmentRepositoryImpl(
        simulatedLatency: Duration.zero,
        clockTime: fixedClock,
        database: db,
        notificationService: LocalNotificationServiceImpl.instance,
      );
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestApp({String initialLocation = '/appointments'}) {
      final router = GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: '/appointments',
            name: AppRouteNames.appointments,
            builder: (context, state) => const AppointmentHistoryScreen(),
          ),
          GoRoute(
            path: '/appointments/:id/reschedule',
            name: AppRouteNames.reschedule,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final extra = state.extra is Appointment
                  ? state.extra as Appointment
                  : null;
              return RescheduleScreen(
                appointmentId: id,
                initialAppointment: extra,
              );
            },
          ),
          GoRoute(
            path: '/',
            name: AppRouteNames.home,
            builder: (context, state) =>
                const Scaffold(body: Text('Home Screen')),
          ),
          GoRoute(
            path: '/doctor/:id',
            name: AppRouteNames.doctorDetail,
            builder: (context, state) =>
                const Scaffold(body: Text('Doctor Detail Screen')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          appointmentDatabaseProvider.overrideWithValue(db),
          appointmentRepositoryProvider.overrideWithValue(repository),
          doctorRepositoryProvider.overrideWithValue(
            DoctorRepositoryImpl(latency: Duration.zero),
          ),
          patientRepositoryProvider.overrideWithValue(
            LocalPatientRepository(latency: Duration.zero),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
    }

    testWidgets(
      'AppointmentHistoryScreen loads persisted appointments from database',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestApp());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        // Should show 'My Appointments' header
        expect(find.text('My Appointments'), findsOneWidget);

        // Should find seeded confirmed upcoming appointment APT-849201
        expect(find.text('#APT-849201'), findsOneWidget);
        expect(find.text('Dr. Marcus Vance'), findsOneWidget);
        expect(find.text('Confirmed'), findsOneWidget);

        // Should show management action buttons
        expect(find.text('Cancel Visit'), findsOneWidget);
        expect(find.text('Reschedule'), findsOneWidget);

        // Should show reminder scheduled indicator
        expect(
          find.text('Reminder scheduled (30m before visit)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Tapping Cancel opens CancellationDialog with appointment details',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestApp());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        final cancelBtn = find.text('Cancel Visit');
        expect(cancelBtn, findsOneWidget);

        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Dialog title and details
        expect(find.text('Cancel Appointment?'), findsOneWidget);
        expect(find.text('Booking ID: #APT-849201'), findsOneWidget);
        expect(find.text('Dr. Marcus Vance'), findsWidgets);
        expect(find.text('Keep Visit'), findsOneWidget);

        // Dismiss dialog with Keep Visit
        await tester.tap(find.text('Keep Visit'));
        await tester.pumpAndSettle();

        // Appointment should still be confirmed
        expect(find.text('Confirmed'), findsOneWidget);
      },
    );

    testWidgets(
      'Confirming cancellation updates appointment status to Cancelled',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestApp());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel Visit'));
        await tester.pumpAndSettle();

        // Tap confirm cancel
        final dialogCancelBtn = find.widgetWithText(
          ElevatedButton,
          'Cancel Visit',
        );
        await tester.tap(dialogCancelBtn);
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 150));
        });
        await tester.pump();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 150));
        });
        await tester.pumpAndSettle();

        // Upcoming count should now be 0
        expect(find.text('No Upcoming Appointments'), findsOneWidget);

        // Switch to Past tab to verify cancelled record
        await tester.tap(find.text('Past'));
        await tester.pumpAndSettle();

        expect(find.text('#APT-849201'), findsOneWidget);
        expect(find.text('Cancelled'), findsOneWidget);
        expect(
          find.text('Appointment cancelled. Reserved time slot released.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Offline toggle button displays persistent offline storage banner',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestApp());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        // Offline banner should initially not be visible
        expect(find.text('Offline Storage Active'), findsNothing);

        // Tap offline toggle icon in app bar
        final offlineIcon = find.byIcon(Icons.cloud_done_rounded);
        expect(offlineIcon, findsOneWidget);
        await tester.tap(offlineIcon);
        await tester.pumpAndSettle();

        // Offline banner should now be visible
        expect(find.text('Offline Storage Active'), findsOneWidget);
        expect(
          find.text(
            'Appointments & history loaded directly from local SQLite database.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'RescheduleScreen renders and allows date and time slot selection',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createTestApp(initialLocation: '/appointments/APT-849201/reschedule'),
        );
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();

        // Reschedule screen header
        expect(find.text('Reschedule Appointment'), findsOneWidget);
        expect(find.text('CURRENT BOOKING'), findsOneWidget);
        expect(find.text('Dr. Marcus Vance'), findsWidgets);

        // Date selector section
        expect(find.text('Select New Date'), findsOneWidget);

        // Slot grid section
        expect(find.text('Select New Time Slot'), findsOneWidget);

        // Action button
        expect(find.text('Confirm Reschedule'), findsOneWidget);
      },
    );
  });
}
