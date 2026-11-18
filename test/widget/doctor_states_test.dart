import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:care_connect/core/widgets/care_doctor_card_skeleton.dart';
import 'package:care_connect/core/widgets/care_empty_state.dart';
import 'package:care_connect/core/widgets/care_error_view.dart';
import 'package:care_connect/features/doctors/data/doctor_repository.dart';
import 'package:care_connect/features/doctors/presentation/controllers/doctor_providers.dart';
import 'package:care_connect/features/home/presentation/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableHomeScreen({DoctorRepository? repository}) {
    return ProviderScope(
      overrides: [
        if (repository != null)
          doctorRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  group('Doctor Asynchronous States Widget Tests', () {
    testWidgets(
      'Renders skeleton placeholders when doctor directory is loading',
      (tester) async {
        // Use large surface size so sliver list is within viewport
        await tester.binding.setSurfaceSize(const Size(420, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final slowRepo = DoctorRepositoryImpl(
          latency: const Duration(milliseconds: 500),
        );

        await tester.pumpWidget(buildTestableHomeScreen(repository: slowRepo));
        // Pump initial frame during simulated network latency
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(CareDoctorCardSkeleton), findsWidgets);

        // Drain pending simulated network timer to complete cleanly
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Renders error view when directory service fails and retries on action',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final failingRepo = DoctorRepositoryImpl(
          latency: Duration.zero,
          simulateError: true,
        );

        await tester.pumpWidget(
          buildTestableHomeScreen(repository: failingRepo),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CareErrorView), findsOneWidget);
        expect(find.text('Unable to Load Directory'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);

        // Disable simulated error so retry succeeds
        failingRepo.setSimulateError(false);

        // Tap Try Again
        await tester.tap(find.text('Try Again'));
        await tester.pumpAndSettle();

        expect(find.byType(CareErrorView), findsNothing);
        expect(find.text('Dr. Alistair Vance'), findsWidgets);
      },
    );

    testWidgets(
      'Renders empty state when search query matches no specialist and resets',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final instantRepo = DoctorRepositoryImpl(latency: Duration.zero);

        await tester.pumpWidget(
          buildTestableHomeScreen(repository: instantRepo),
        );
        await tester.pumpAndSettle();

        // Enter search term that has no matches
        await tester.enterText(
          find.byType(TextField),
          'ZeroMatchSpecialistXYZ',
        );
        await tester.pumpAndSettle();

        expect(find.byType(CareEmptyState), findsOneWidget);
        expect(find.text('No Specialists Found'), findsOneWidget);
        expect(find.text('Reset Filters'), findsOneWidget);

        // Tap Reset Filters
        await tester.tap(find.text('Reset Filters'));
        await tester.pumpAndSettle();

        expect(find.byType(CareEmptyState), findsNothing);
        expect(find.text('Dr. Alistair Vance'), findsWidgets);
      },
    );
  });
}
