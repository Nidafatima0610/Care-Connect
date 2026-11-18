import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/features/doctors/data/doctor_repository.dart';
import 'package:care_connect/features/doctors/domain/doctor_specialty.dart';

void main() {
  group('DoctorRepository Async & Error Simulation Tests', () {
    test('getDoctors with latency executes asynchronously', () async {
      final repo = DoctorRepositoryImpl(
        latency: const Duration(milliseconds: 50),
      );
      final stopwatch = Stopwatch()..start();
      final doctors = await repo.getDoctors();
      stopwatch.stop();

      expect(doctors.length, greaterThanOrEqualTo(8));
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
    });

    test(
      'error simulation throws DoctorRepositoryException on getDoctors',
      () async {
        final repo = DoctorRepositoryImpl(
          latency: Duration.zero,
          simulateError: true,
        );

        expect(repo.isSimulatingError, isTrue);
        expect(
          () => repo.getDoctors(),
          throwsA(isA<DoctorRepositoryException>()),
        );
      },
    );

    test(
      'error simulation throws DoctorRepositoryException on searchDoctors',
      () async {
        final repo = DoctorRepositoryImpl(
          latency: Duration.zero,
          simulateError: true,
        );

        expect(
          () => repo.searchDoctors(query: 'Marcus'),
          throwsA(isA<DoctorRepositoryException>()),
        );
      },
    );

    test(
      'error simulation throws DoctorRepositoryException on getDoctorById',
      () async {
        final repo = DoctorRepositoryImpl(
          latency: Duration.zero,
          simulateError: true,
        );

        expect(
          () => repo.getDoctorById('doc-001'),
          throwsA(isA<DoctorRepositoryException>()),
        );
      },
    );

    test(
      'toggling error simulation restores successful data retrieval',
      () async {
        final repo = DoctorRepositoryImpl(
          latency: Duration.zero,
          simulateError: true,
        );

        expect(
          () => repo.getDoctors(),
          throwsA(isA<DoctorRepositoryException>()),
        );

        repo.setSimulateError(false);
        expect(repo.isSimulatingError, isFalse);

        final doctors = await repo.getDoctors();
        expect(doctors.isNotEmpty, isTrue);
      },
    );

    test(
      'searchDoctors with combined query and specialty returns precise matches',
      () async {
        final repo = DoctorRepositoryImpl(latency: Duration.zero);

        // Search 'Elena' with Cardiology should yield empty
        final mismatch = await repo.searchDoctors(
          query: 'Elena',
          specialty: DoctorSpecialty.cardiology,
        );
        expect(mismatch.isEmpty, isTrue);

        // Search 'Elena' with Dermatology should match Dr. Elena Rostova
        final match = await repo.searchDoctors(
          query: 'Elena',
          specialty: DoctorSpecialty.dermatology,
        );
        expect(match.length, 1);
        expect(match.first.name, contains('Elena Rostova'));
      },
    );

    test(
      'searchDoctors matches across qualifications and clinic name',
      () async {
        final repo = DoctorRepositoryImpl(latency: Duration.zero);

        // Match Harvard Medical
        final harvardDocs = await repo.searchDoctors(query: 'Harvard');
        expect(harvardDocs.isNotEmpty, isTrue);

        // Match Metropolitan
        final metroDocs = await repo.searchDoctors(query: 'Metropolitan');
        expect(metroDocs.isNotEmpty, isTrue);
      },
    );
  });
}
