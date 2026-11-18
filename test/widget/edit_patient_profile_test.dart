import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:care_connect/features/patient/data/patient_repository.dart';
import 'package:care_connect/features/patient/presentation/controllers/patient_provider.dart';
import 'package:care_connect/features/patient/presentation/edit_patient_profile_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableEditScreen() {
    return ProviderScope(
      overrides: [
        patientRepositoryProvider.overrideWithValue(
          LocalPatientRepository(latency: Duration.zero),
        ),
      ],
      child: const MaterialApp(home: EditPatientProfileScreen()),
    );
  }

  group('EditPatientProfileScreen Widget Tests', () {
    testWidgets('Renders pre-populated inputs for patient demographics', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableEditScreen());
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Personal Demographics'), findsOneWidget);
      expect(find.byKey(const Key('edit_patient_name_field')), findsOneWidget);
      expect(find.byKey(const Key('edit_patient_email_field')), findsOneWidget);
      expect(find.byKey(const Key('edit_patient_phone_field')), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Validates required fields on empty or invalid inputs', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableEditScreen());
      await tester.pumpAndSettle();

      // Clear full name
      final nameFinder = find.byKey(const Key('edit_patient_name_field'));
      await tester.enterText(nameFinder, '');

      // Clear email and enter invalid format
      final emailFinder = find.byKey(const Key('edit_patient_email_field'));
      await tester.enterText(emailFinder, 'invalid-email-address');

      // Clear phone and enter short phone
      final phoneFinder = find.byKey(const Key('edit_patient_phone_field'));
      await tester.enterText(phoneFinder, '123');

      // Tap Save Changes
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Assert error messages
      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(
        find.text('Please enter a valid phone number (min 7 digits)'),
        findsOneWidget,
      );
    });

    testWidgets('Saves valid modifications successfully', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableEditScreen());
      await tester.pumpAndSettle();

      // Update name to Dr. Clara Barton
      final nameFinder = find.byKey(const Key('edit_patient_name_field'));
      await tester.enterText(nameFinder, 'Dr. Clara Barton');

      // Tap Save Changes
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // No validation errors should be displayed
      expect(find.text('Please enter your full name'), findsNothing);
      expect(find.text('Please enter a valid email address'), findsNothing);
    });
  });
}
