import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/doctors/presentation/doctor_detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/care_empty_state.dart';

abstract final class AppRouteNames {
  static const String home = 'home';
  static const String doctorDetail = 'doctor-detail';
}

abstract final class AppRoutePaths {
  static const String home = '/';
  static const String doctorDetail = '/doctor/:id';
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
  ],
);
