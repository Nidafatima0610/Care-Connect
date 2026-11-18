import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/features/patient/domain/patient.dart';

void main() {
  group('Patient Model Unit Tests', () {
    test('defaultDemoPatient creates valid default fictional patient', () {
      final patient = Patient.defaultDemoPatient();

      expect(patient.id, 'pat-84920');
      expect(patient.fullName, 'Maya Sterling');
      expect(patient.firstName, 'Maya');
      expect(patient.initials, 'MS');
      expect(patient.email, 'maya.sterling@careconnect.health');
      expect(patient.phoneNumber, '+1 (617) 555-0194');
      expect(patient.preferredClinic, contains('CareConnect'));
      expect(patient.bloodGroup, 'A+');
      expect(patient.emergencyContactName, 'David Sterling');
      expect(patient.emergencyContactPhone, '+1 (617) 555-0812');
      expect(patient.formattedDateOfBirth, 'Jun 14, 1992');
      expect(patient.age, isNotNull);
      expect(patient.age, greaterThan(30));
    });

    test('initials computation handles various name formats', () {
      final twoWords = Patient.defaultDemoPatient().copyWith(
        fullName: 'Maya Sterling',
      );
      expect(twoWords.initials, 'MS');

      final threeWords = Patient.defaultDemoPatient().copyWith(
        fullName: 'Maya Jane Sterling',
      );
      expect(threeWords.initials, 'MS');

      final singleWord = Patient.defaultDemoPatient().copyWith(
        fullName: 'Sterling',
      );
      expect(singleWord.initials, 'ST');

      final empty = Patient.defaultDemoPatient().copyWith(fullName: '   ');
      expect(empty.initials, 'PT');
    });

    test(
      'JSON serialization and deserialization roundtrip maintains integrity',
      () {
        final original = Patient.defaultDemoPatient();
        final json = original.toJson();
        final restored = Patient.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.fullName, original.fullName);
        expect(restored.email, original.email);
        expect(restored.phoneNumber, original.phoneNumber);
        expect(restored.dateOfBirth, original.dateOfBirth);
        expect(restored.preferredClinic, original.preferredClinic);
        expect(restored.bloodGroup, original.bloodGroup);
        expect(restored.emergencyContactName, original.emergencyContactName);
        expect(restored.emergencyContactPhone, original.emergencyContactPhone);
        expect(restored, equals(original));
      },
    );

    test(
      'copyWith creates modified clone while preserving unchanged properties',
      () {
        final original = Patient.defaultDemoPatient();
        final modified = original.copyWith(
          fullName: 'Alexander Vance',
          email: 'alex.vance@example.com',
          bloodGroup: 'O-',
        );

        expect(modified.fullName, 'Alexander Vance');
        expect(modified.email, 'alex.vance@example.com');
        expect(modified.bloodGroup, 'O-');
        // Preserved fields
        expect(modified.id, original.id);
        expect(modified.phoneNumber, original.phoneNumber);
        expect(modified.preferredClinic, original.preferredClinic);
        expect(modified.emergencyContactName, original.emergencyContactName);
      },
    );

    test('age calculation correctly evaluates past dates', () {
      final dob1990 = DateTime(1990, 1, 1);
      final patient = Patient.defaultDemoPatient().copyWith(
        dateOfBirth: dob1990,
      );

      expect(patient.age, greaterThanOrEqualTo(34));

      final nullDobPatient = Patient.defaultDemoPatient().copyWith(
        dateOfBirth: null,
      );
      expect(nullDobPatient.age, isNull);
      expect(nullDobPatient.formattedDateOfBirth, 'Not Provided');
    });
  });
}
