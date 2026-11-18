import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:care_connect/core/router/app_router.dart';
import 'package:care_connect/core/theme/app_theme.dart';
import 'package:care_connect/features/appointments/data/appointment_repository_impl.dart';
import 'package:care_connect/features/appointments/domain/appointment_repository.dart';
import 'package:care_connect/features/appointments/presentation/booking_confirmation_screen.dart';
import 'package:care_connect/features/appointments/presentation/booking_screen.dart';
import 'package:care_connect/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:care_connect/features/doctors/data/doctor_repository.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';
import 'package:care_connect/features/doctors/presentation/controllers/doctor_providers.dart';
import 'package:care_connect/features/patient/data/patient_repository.dart';
import 'package:care_connect/features/patient/presentation/controllers/patient_provider.dart';

void main() {
  late AppointmentRepository mockAppointmentRepo;
  late DoctorRepository mockDoctorRepo;
  final fixedClock = DateTime(2026, 11, 18, 9, 0);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAppointmentRepo = AppointmentRepositoryImpl(
      simulatedLatency: Duration.zero,
      clockTime: fixedClock,
    );
    mockDoctorRepo = DoctorRepositoryImpl(latency: Duration.zero);
  });

  Widget createBookingWidget({
    String doctorId = 'doc_alistair_vance',
    Appointment? createdAppointment,
  }) {
    final router = GoRouter(
      initialLocation: '/book',
      routes: [
        GoRoute(
          path: '/book',
          name: AppRouteNames.booking,
          builder: (context, state) => BookingScreen(doctorId: doctorId),
        ),
        GoRoute(
          path: '/booking/confirmation',
          name: AppRouteNames.bookingConfirmation,
          builder: (context, state) {
            final apt = state.extra as Appointment? ?? createdAppointment!;
            return BookingConfirmationScreen(appointment: apt);
          },
        ),
        GoRoute(
          path: '/appointments',
          name: AppRouteNames.appointments,
          builder: (context, state) =>
              const Scaffold(body: Text('Appointments Screen')),
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
        appointmentRepositoryProvider.overrideWithValue(mockAppointmentRepo),
        doctorRepositoryProvider.overrideWithValue(mockDoctorRepo),
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

  group('BookingScreen Widget Tests', () {
    testWidgets(
      'Renders doctor summary, date selector, and time slot sections',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createBookingWidget());
        await tester.pumpAndSettle();

        // Header title
        expect(find.text('Schedule Appointment'), findsOneWidget);

        // Doctor summary card
        expect(find.text('Dr. Alistair Vance'), findsWidgets);
        expect(find.text('Cardiology • MD, FACC'), findsOneWidget);
        expect(find.text('\$140 / visit'), findsOneWidget);

        // Date selector section
        expect(find.text('Select Appointment Date'), findsOneWidget);

        // Time slots section
        expect(find.text('Available Time Slots'), findsOneWidget);

        // Consultation modality section
        expect(find.text('Consultation Modality'), findsOneWidget);
        expect(find.text('In-Person Visit'), findsWidgets);
        expect(find.text('Video Visit'), findsOneWidget);

        // Bottom bar
        expect(find.text('Confirm Booking'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Confirm Booking without selecting slot shows validation banner',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createBookingWidget());
        await tester.pumpAndSettle();

        // Tap confirm button without selecting slot
        final confirmBtn = find.text('Confirm Booking');
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Banner should appear
        expect(
          find.text('Please select an appointment time slot.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Selecting a future date and available slot updates booking review',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createBookingWidget());
        await tester.pumpAndSettle();

        // Tap tomorrow's date chip (18)
        final tomorrowChip = find.text('18');
        expect(tomorrowChip, findsOneWidget);
        await tester.tap(tomorrowChip);
        await tester.pumpAndSettle();

        // Find an available morning slot (10:00 AM)
        final slotFinder = find.text('10:00 AM');
        expect(slotFinder, findsOneWidget);

        await tester.tap(slotFinder);
        await tester.pumpAndSettle();

        // Review Booking card should appear with the selected time
        expect(find.text('Booking Review'), findsOneWidget);
        expect(find.text('10:00 AM'), findsWidgets);
      },
    );

    testWidgets(
      'Selecting date, slot, and confirming navigates to confirmation screen',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createBookingWidget());
        await tester.pumpAndSettle();

        // Tap tomorrow's date chip (18)
        final tomorrowChip = find.text('18');
        await tester.tap(tomorrowChip);
        await tester.pumpAndSettle();

        // Select available slot
        final slotFinder = find.text('10:00 AM');
        await tester.tap(slotFinder);
        await tester.pumpAndSettle();

        // Tap confirm
        final confirmBtn = find.text('Confirm Booking');
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Confirmation screen is shown
        expect(find.text('Appointment Confirmed!'), findsOneWidget);
        expect(find.text('BOOKING REFERENCE'), findsOneWidget);
        expect(find.text('Dr. Alistair Vance'), findsWidgets);
        expect(find.text('View in Appointment History'), findsOneWidget);
        expect(find.text('Return to Home'), findsOneWidget);
      },
    );
  });

  group('BookingConfirmationScreen Widget Tests', () {
    testWidgets('Renders all receipt details and action buttons', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testAppointment = Appointment(
        id: 'APT-1008',
        doctorId: 'doc_alistair_vance',
        doctorName: 'Dr. Alistair Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
        patientId: 'pat_sarah_jenkins_001',
        patientName: 'Sarah Jenkins',
        patientPhone: '+1 (555) 234-5678',
        scheduledDateTime: DateTime(2026, 11, 20, 10, 30),
        timeSlot: '10:30 AM',
        status: AppointmentStatus.confirmed,
        modality: AppointmentModality.inPerson,
        fee: 140.0,
        createdAt: DateTime(2026, 11, 17),
      );

      final router = GoRouter(
        initialLocation: '/confirm',
        routes: [
          GoRoute(
            path: '/confirm',
            builder: (context, state) =>
                BookingConfirmationScreen(appointment: testAppointment),
          ),
          GoRoute(
            path: '/appointments',
            name: AppRouteNames.appointments,
            builder: (context, state) =>
                const Scaffold(body: Text('Appointments Screen')),
          ),
          GoRoute(
            path: '/',
            name: AppRouteNames.home,
            builder: (context, state) =>
                const Scaffold(body: Text('Home Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Appointment Confirmed!'), findsOneWidget);
      expect(find.text('#APT-1008'), findsOneWidget);
      expect(find.text('Dr. Alistair Vance'), findsOneWidget);
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('\$140.00'), findsOneWidget);
      expect(find.text('In-Person Visit'), findsOneWidget);

      // Buttons
      expect(find.text('View in Appointment History'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);

      // Test tapping View in Appointment History
      await tester.tap(find.text('View in Appointment History'));
      await tester.pumpAndSettle();
      expect(find.text('Appointments Screen'), findsOneWidget);
    });
  });
}
