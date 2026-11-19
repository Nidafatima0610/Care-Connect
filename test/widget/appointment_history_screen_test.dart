import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:care_connect/core/router/app_router.dart';
import 'package:care_connect/core/theme/app_theme.dart';
import 'package:care_connect/features/appointments/data/appointment_repository_impl.dart';
import 'package:care_connect/features/appointments/domain/appointment_repository.dart';
import 'package:care_connect/features/appointments/presentation/appointment_history_screen.dart';
import 'package:care_connect/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';

import 'package:care_connect/features/appointments/domain/appointment_draft.dart';
import 'package:care_connect/features/appointments/domain/time_slot.dart';
import 'package:care_connect/features/patient/data/patient_repository.dart';
import 'package:care_connect/features/patient/presentation/controllers/patient_provider.dart';

class EmptyAppointmentRepository implements AppointmentRepository {
  @override
  Future<void> init() async {}

  @override
  Future<List<TimeSlot>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
    String? excludeAppointmentId,
  }) async => [];

  @override
  Future<Appointment> createBooking(AppointmentDraft draft) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Appointment>> getPatientAppointments({
    required String patientId,
  }) async => [];

  @override
  Future<Appointment?> getAppointmentById(String id) async => null;

  @override
  Future<Appointment> cancelAppointment({
    required String appointmentId,
    String? cancellationReason,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTimeSlot,
  }) async {
    throw UnimplementedError();
  }

  @override
  void reset() {}

  @override
  void simulatePreExistingBooking({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
  }) {}
}

void main() {
  late AppointmentRepository seededRepo;
  final fixedClock = DateTime(2026, 11, 18, 10, 0);

  setUp(() async {
    seededRepo = AppointmentRepositoryImpl(
      simulatedLatency: Duration.zero,
      clockTime: fixedClock,
    );
    await seededRepo.init();
  });

  Widget createHistoryWidget({AppointmentRepository? repo}) {
    final router = GoRouter(
      initialLocation: '/appointments',
      routes: [
        GoRoute(
          path: '/appointments',
          builder: (context, state) => const AppointmentHistoryScreen(),
        ),
        GoRoute(
          path: '/doctor/:id',
          builder: (context, state) => Scaffold(
            body: Text('Doctor Detail: ${state.pathParameters['id']}'),
          ),
        ),
        GoRoute(
          path: '/',
          name: AppRouteNames.home,
          builder: (context, state) =>
              const Scaffold(body: Text('Home Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        appointmentRepositoryProvider.overrideWithValue(repo ?? seededRepo),
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

  group('AppointmentHistoryScreen Widget Tests', () {
    testWidgets('Renders Upcoming and Past tabs with count badges', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createHistoryWidget());
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('My Appointments'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);

      // Verify seeded upcoming appointments are rendered
      expect(find.text('Dr. Marcus Vance'), findsOneWidget);
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('#APT-849201'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
    });

    testWidgets(
      'Switching to Past tab renders completed and past appointments',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 950));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createHistoryWidget());
        await tester.pump();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 150));
        });
        await tester.pump();
        await tester.pumpAndSettle();

        // Tap Past tab
        await tester.tap(find.text('Past'));
        await tester.pumpAndSettle();

        // Verify seeded past appointments
        expect(find.text('Dr. Elena Rostova'), findsOneWidget);
        expect(find.text('Dermatology'), findsOneWidget);
        expect(find.text('#APT-849105'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      },
    );

    testWidgets('Renders empty state when no appointments exist', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createHistoryWidget(repo: EmptyAppointmentRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Upcoming Appointments'), findsOneWidget);
      expect(
        find.text(
          'You have no appointments scheduled at this time. Book a consultation with a certified CareConnect specialist.',
        ),
        findsOneWidget,
      );
      expect(find.text('Book an Appointment'), findsOneWidget);

      // Tap CTA to navigate home
      await tester.tap(find.text('Book an Appointment'));
      await tester.pumpAndSettle();
      expect(find.text('Home Screen'), findsOneWidget);
    });
  });
}
