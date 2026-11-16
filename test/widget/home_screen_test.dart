import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/features/doctors/data/doctor_repository.dart';
import 'package:care_connect/features/doctors/presentation/controllers/doctor_providers.dart';
import 'package:care_connect/features/home/presentation/home_screen.dart';
import 'package:care_connect/core/theme/app_theme.dart';

void main() {
  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        doctorRepositoryProvider.overrideWithValue(
          DoctorRepositoryImpl(latency: Duration.zero),
        ),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
    );
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('Renders header, branding, greeting, and search bar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Check Patient Greeting & Header
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('CareConnect Health Center'), findsOneWidget);

      // Check Hero Promotion Banner
      expect(find.text('Need Immediate or Scheduled Care?'), findsOneWidget);
      expect(find.text('Explore Providers'), findsOneWidget);

      // Check Search Bar
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText ==
                  'Search doctor, specialty, or clinic...',
        ),
        findsOneWidget,
      );

      // Check Medical Specialties Section
      expect(find.text('Medical Specialties'), findsOneWidget);
      expect(find.text('All Specialists'), findsOneWidget);
      expect(find.text('Cardiology'), findsWidgets);
    });

    testWidgets('Filters doctor list when searching in the search bar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Initially multiple doctors are visible
      expect(find.text('Dr. Alistair Vance'), findsWidgets);

      // Enter search term
      await tester.enterText(find.byType(TextField), 'Elena');
      await tester.pumpAndSettle();

      // Dr. Elena Rostova is visible, Dr. Alistair Vance is filtered out
      expect(find.text('Dr. Elena Rostova'), findsOneWidget);
      expect(find.text('Dr. Alistair Vance'), findsNothing);

      // Clear search
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      // Back to normal
      expect(find.text('Dr. Alistair Vance'), findsWidgets);
    });

    testWidgets(
      'Shows empty state with reset button when no doctor matches query',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        // Enter non-matching query
        await tester.enterText(
          find.byType(TextField),
          'NonExistentDoctorQuery123',
        );
        await tester.pumpAndSettle();

        expect(find.text('No Specialists Found'), findsOneWidget);
        expect(find.text('Reset Filters'), findsOneWidget);

        // Scroll to Reset Filters button if necessary and tap
        await tester.ensureVisible(find.text('Reset Filters'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reset Filters'));
        await tester.pumpAndSettle();

        expect(find.text('Dr. Alistair Vance'), findsWidgets);
      },
    );

    testWidgets('Tapping notification bell opens notification bottom sheet', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Clinic Notices'));
      await tester.pumpAndSettle();

      expect(find.text('Clinic Notices & Updates'), findsOneWidget);
      expect(find.text('Annual Cardiovascular Health Check'), findsOneWidget);
    });
  });
}
