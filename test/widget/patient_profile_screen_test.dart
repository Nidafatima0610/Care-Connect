import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:care_connect/features/patient/data/patient_repository.dart';
import 'package:care_connect/features/patient/domain/patient.dart';
import 'package:care_connect/features/patient/presentation/controllers/patient_provider.dart';
import 'package:care_connect/features/patient/presentation/patient_profile_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableProfileScreen({Patient? initialPatient}) {
    return ProviderScope(
      overrides: [
        patientRepositoryProvider.overrideWithValue(
          LocalPatientRepository(latency: Duration.zero),
        ),
      ],
      child: const MaterialApp(home: PatientProfileScreen()),
    );
  }

  group('PatientProfileScreen Widget Tests', () {
    testWidgets('Renders all demographic and clinical identity elements', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      // Check header details
      expect(find.text('Patient Profile'), findsOneWidget);
      expect(find.text('Maya Sterling'), findsOneWidget);
      expect(find.text('MS'), findsOneWidget);
      expect(find.text('Verified Patient Account'), findsOneWidget);
      expect(find.text('Medical Record ID: #PAT-84920'), findsOneWidget);

      // Check Demo Notice
      expect(find.text('Local Demo Identity'), findsOneWidget);

      // Check contact information
      expect(find.text('Contact Information'), findsOneWidget);
      expect(find.text('maya.sterling@careconnect.health'), findsOneWidget);
      expect(find.text('+1 (617) 555-0194'), findsOneWidget);
      expect(find.text('A+'), findsOneWidget);

      // Check clinical details
      expect(find.text('Clinical & Emergency'), findsOneWidget);
      expect(
        find.text('CareConnect Metropolitan Health Center'),
        findsOneWidget,
      );
      expect(find.text('David Sterling'), findsOneWidget);

      // Check action buttons
      expect(find.text('Edit Profile Details'), findsOneWidget);
      expect(find.text('Reset to Demo Default'), findsOneWidget);
    });

    testWidgets(
      'Tapping Reset button opens confirmation dialog and can cancel',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestableProfileScreen());
        await tester.pumpAndSettle();

        // Tap Reset button
        await tester.ensureVisible(find.text('Reset to Demo Default'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reset to Demo Default'));
        await tester.pumpAndSettle();

        expect(find.text('Reset Demo Profile?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Reset Demo Profile?'), findsNothing);
        expect(find.text('Maya Sterling'), findsOneWidget);
      },
    );
  });
}
