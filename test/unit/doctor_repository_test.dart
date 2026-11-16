import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/features/doctors/data/doctor_repository.dart';
import 'package:care_connect/features/doctors/domain/doctor_specialty.dart';

void main() {
  group('DoctorRepository Tests', () {
    late DoctorRepository repository;

    setUp(() {
      repository = DoctorRepositoryImpl(latency: Duration.zero);
    });

    test('getDoctors returns at least 8 fictional doctors', () async {
      final doctors = await repository.getDoctors();
      expect(doctors.length, greaterThanOrEqualTo(8));
      expect(
        doctors.any((d) => d.specialty == DoctorSpecialty.cardiology),
        isTrue,
      );
      expect(
        doctors.any((d) => d.specialty == DoctorSpecialty.dermatology),
        isTrue,
      );
      expect(
        doctors.any((d) => d.specialty == DoctorSpecialty.pediatrics),
        isTrue,
      );
      expect(
        doctors.any((d) => d.specialty == DoctorSpecialty.generalMedicine),
        isTrue,
      );
    });

    test(
      'getFeaturedDoctors returns only doctors marked as featured',
      () async {
        final featured = await repository.getFeaturedDoctors();
        expect(featured.isNotEmpty, isTrue);
        for (final doc in featured) {
          expect(doc.isFeatured, isTrue);
        }
      },
    );

    test('getDoctorById returns correct doctor when ID exists', () async {
      final doc = await repository.getDoctorById('doc_alistair_vance');
      expect(doc, isNotNull);
      expect(doc!.name, contains('Alistair Vance'));
      expect(doc.specialty, DoctorSpecialty.cardiology);
    });

    test('getDoctorById returns null when ID does not exist', () async {
      final doc = await repository.getDoctorById('non_existent_doctor_id');
      expect(doc, isNull);
    });

    test('searchDoctors filters by name query', () async {
      final results = await repository.searchDoctors(query: 'Alistair');
      expect(results.length, 1);
      expect(results.first.name, contains('Alistair Vance'));
    });

    test('searchDoctors filters by specialty', () async {
      final results = await repository.searchDoctors(
        specialty: DoctorSpecialty.cardiology,
      );
      expect(results.isNotEmpty, isTrue);
      for (final doc in results) {
        expect(doc.specialty, DoctorSpecialty.cardiology);
      }
    });

    test('searchDoctors filters by clinic name', () async {
      final results = await repository.searchDoctors(query: 'Neuroscience');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.specialty, DoctorSpecialty.neurology);
    });
  });
}
