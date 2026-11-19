import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/appointment_history_screen.dart';
import '../../features/appointments/presentation/booking_confirmation_screen.dart';
import '../../features/appointments/presentation/booking_screen.dart';
import '../../features/appointments/presentation/reschedule_screen.dart';
import '../../features/doctors/domain/appointment.dart';
import '../../features/doctors/presentation/doctor_detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/patient/presentation/edit_patient_profile_screen.dart';
import '../../features/patient/presentation/patient_profile_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/care_empty_state.dart';

abstract final class AppRouteNames {
  static const String home = 'home';
  static const String doctorDetail = 'doctor-detail';
  static const String profile = 'profile';
  static const String editProfile = 'edit-profile';
  static const String booking = 'booking';
  static const String bookingConfirmation = 'booking-confirmation';
  static const String appointments = 'appointments';
  static const String reschedule = 'reschedule';
}

abstract final class AppRoutePaths {
  static const String home = '/';
  static const String doctorDetail = '/doctor/:id';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String booking = '/doctor/:id/book';
  static const String bookingConfirmation = '/booking/confirmation';
  static const String appointments = '/appointments';
  static const String reschedule = '/appointments/:id/reschedule';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutePaths.home,
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: AppColors.ivory,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CareEmptyState(
            icon: Icons.alt_route_rounded,
            title: 'Page Not Found',
            message:
                'The destination "${state.uri.toString()}" could not be located in CareConnect.',
            actionLabel: 'Return Home',
            onAction: () => context.goNamed(AppRouteNames.home),
          ),
        ),
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: AppRoutePaths.home,
      name: AppRouteNames.home,
      pageBuilder: (context, state) =>
          const MaterialPage(key: ValueKey('home_screen'), child: HomeScreen()),
    ),
    GoRoute(
      path: AppRoutePaths.doctorDetail,
      name: AppRouteNames.doctorDetail,
      pageBuilder: (context, state) {
        final doctorId = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          key: ValueKey('doctor_detail_$doctorId'),
          child: DoctorDetailScreen(doctorId: doctorId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(begin: begin, end: end).animate(curve),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.profile,
      name: AppRouteNames.profile,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: const ValueKey('patient_profile_screen'),
        child: const PatientProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(curve),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutePaths.editProfile,
      name: AppRouteNames.editProfile,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: const ValueKey('edit_patient_profile_screen'),
        child: const EditPatientProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(curve),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutePaths.booking,
      name: AppRouteNames.booking,
      pageBuilder: (context, state) {
        final doctorId = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          key: ValueKey('booking_screen_$doctorId'),
          child: BookingScreen(doctorId: doctorId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(begin: begin, end: end).animate(curve),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.bookingConfirmation,
      name: AppRouteNames.bookingConfirmation,
      pageBuilder: (context, state) {
        final appointment = state.extra is Appointment
            ? state.extra as Appointment
            : null;
        final appointmentId =
            state.uri.queryParameters['id'] ??
            Uri.base.queryParameters['id'] ??
            (appointment == null ? 'APT-849201' : null);
        return CustomTransitionPage(
          key: const ValueKey('booking_confirmation_screen'),
          child: BookingConfirmationScreen(
            appointment: appointment,
            appointmentId: appointmentId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(begin: begin, end: end).animate(curve),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.appointments,
      name: AppRouteNames.appointments,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: const ValueKey('appointment_history_screen'),
        child: const AppointmentHistoryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(curve),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutePaths.reschedule,
      name: AppRouteNames.reschedule,
      pageBuilder: (context, state) {
        final appointmentId = state.pathParameters['id'] ?? '';
        final appointment = state.extra is Appointment
            ? state.extra as Appointment
            : null;
        return CustomTransitionPage(
          key: ValueKey('reschedule_screen_$appointmentId'),
          child: RescheduleScreen(
            appointmentId: appointmentId,
            initialAppointment: appointment,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(begin: begin, end: end).animate(curve),
              child: child,
            );
          },
        );
      },
    ),
  ],
);
