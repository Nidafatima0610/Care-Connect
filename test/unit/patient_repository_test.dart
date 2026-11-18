import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:care_connect/features/patient/data/patient_repository.dart';
import 'package:care_connect/features/patient/domain/patient.dart';

void main() {
  group('LocalPatientRepository Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'getPatient seeds and returns default demo patient when storage is empty',
      () async {
        final repo = LocalPatientRepository(latency: Duration.zero);
        final patient = await repo.getPatient();

        expect(patient, isNotNull);
        expect(patient!.fullName, 'Maya Sterling');
        expect(patient.email, 'maya.sterling@careconnect.health');
        expect(patient.bloodGroup, 'A+');
      },
    );

    test(
      'savePatient persists changes and getPatient restores updated values',
      () async {
        final repo = LocalPatientRepository(latency: Duration.zero);
        final initial = await repo.getPatient();
        expect(initial, isNotNull);

        final updated = initial!.copyWith(
          fullName: 'Dr. Sophia Reyes',
          email: 'sophia.reyes@careconnect.health',
          phoneNumber: '+1 (617) 555-9988',
          bloodGroup: 'B+',
        );

        await repo.savePatient(updated);

        final retrieved = await repo.getPatient();
        expect(retrieved, isNotNull);
        expect(retrieved!.fullName, 'Dr. Sophia Reyes');
        expect(retrieved.email, 'sophia.reyes@careconnect.health');
        expect(retrieved.phoneNumber, '+1 (617) 555-9988');
        expect(retrieved.bloodGroup, 'B+');
      },
    );

    test('clearPatient removes persisted data from storage', () async {
      final repo = LocalPatientRepository(latency: Duration.zero);
      await repo.getPatient(); // Seeding

      await repo.clearPatient();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('careconnect_local_patient_profile'), isFalse);
    });

    test('resetToDefault restores default fictional patient', () async {
      final repo = LocalPatientRepository(latency: Duration.zero);
      final modified = Patient.defaultDemoPatient().copyWith(
        fullName: 'Custom Modified Name',
      );
      await repo.savePatient(modified);

      final resetResult = await repo.resetToDefault();
      expect(resetResult.fullName, 'Maya Sterling');

      final current = await repo.getPatient();
      expect(current!.fullName, 'Maya Sterling');
    });

    test(
      'getPatient falls back to default patient when stored JSON is malformed',
      () async {
        SharedPreferences.setMockInitialValues({
          'careconnect_local_patient_profile': '{invalid_json_corrupted',
        });

        final repo = LocalPatientRepository(latency: Duration.zero);
        final patient = await repo.getPatient();

        expect(patient, isNotNull);
        expect(patient!.fullName, 'Maya Sterling');
      },
    );
  });
}
