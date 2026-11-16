import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/core/router/app_router.dart';
import 'package:care_connect/core/theme/app_theme.dart';
import 'package:care_connect/features/doctors/data/doctor_repository.dart';
import 'package:care_connect/features/doctors/presentation/controllers/doctor_providers.dart';
import 'package:care_connect/features/doctors/presentation/doctor_detail_screen.dart';
import 'package:care_connect/features/home/presentation/home_screen.dart';

void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [
        doctorRepositoryProvider.overrideWithValue(
          DoctorRepositoryImpl(latency: Duration.zero),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }

  group('Navigation Flow Tests', () {
    testWidgets('Navigates from HomeScreen to DoctorDetailScreen and back', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Reset location
      appRouter.go(AppRoutePaths.home);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Verify on HomeScreen
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Dr. Alistair Vance'), findsWidgets);

      // Find first "View Profile" button and tap it
      final viewDetailsButton = find.text('View Profile').first;
      await tester.ensureVisible(viewDetailsButton);
      await tester.pumpAndSettle();
      await tester.tap(viewDetailsButton);
      await tester.pumpAndSettle();

      // Verify on DoctorDetailScreen
      expect(find.text('About Specialist'), findsOneWidget);
      expect(find.text('Weekly Availability'), findsOneWidget);
      expect(find.text('Education & Credentials'), findsOneWidget);

      // Tap back button
      final backButton = find.byTooltip('Back to Discovery');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify returned to HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(DoctorDetailScreen), findsNothing);
    });
  });
}
