import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:care_connect/core/router/app_router.dart';
import 'package:care_connect/core/theme/app_theme.dart';
import 'package:care_connect/features/appointments/data/appointment_repository_impl.dart';
import 'package:care_connect/features/appointments/domain/appointment_repository.dart';
import 'package:care_connect/features/appointments/presentation/booking_screen.dart';
import 'package:care_connect/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:care_connect/features/doctors/data/doctor_repository.dart';
import 'package:care_connect/features/doctors/presentation/controllers/doctor_providers.dart';
import 'package:care_connect/features/doctors/presentation/doctor_detail_screen.dart';

void main() {
  late AppointmentRepository mockAppointmentRepo;
  late DoctorRepository mockDoctorRepo;

  setUp(() {
    mockAppointmentRepo = AppointmentRepositoryImpl(
      simulatedLatency: Duration.zero,
      clockTime: DateTime(2026, 11, 18, 10, 0),
    );
    mockDoctorRepo = DoctorRepositoryImpl(latency: Duration.zero);
  });

  testWidgets(
    'Tapping Book Appointment on DoctorDetailScreen navigates to BookingScreen via GoRouter',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/doctor/doc_alistair_vance',
        routes: [
          GoRoute(
            name: AppRouteNames.doctorDetail,
            path: '/doctor/:id',
            builder: (context, state) =>
                DoctorDetailScreen(doctorId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
            name: AppRouteNames.booking,
            path: '/doctor/:id/book',
            builder: (context, state) =>
                BookingScreen(doctorId: state.pathParameters['id'] ?? ''),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appointmentRepositoryProvider.overrideWithValue(
              mockAppointmentRepo,
            ),
            doctorRepositoryProvider.overrideWithValue(mockDoctorRepo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. Alistair Vance'), findsWidgets);
      expect(find.text('Book Appointment'), findsOneWidget);

      await tester.tap(find.text('Book Appointment'));
      await tester.pumpAndSettle();

      // Should now be on the Booking Screen
      expect(find.text('Select Appointment Date'), findsOneWidget);
      expect(find.text('Available Time Slots'), findsOneWidget);
      expect(find.text('Confirm Booking'), findsOneWidget);
    },
  );
}
