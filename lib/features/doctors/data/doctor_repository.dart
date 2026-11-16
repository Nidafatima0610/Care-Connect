import '../domain/doctor.dart';
import '../domain/doctor_specialty.dart';
import 'mock_doctor_data.dart';

/// Abstract contract for Doctor data retrieval.
abstract class DoctorRepository {
  Future<List<Doctor>> getDoctors();
  Future<List<Doctor>> getFeaturedDoctors();
  Future<Doctor?> getDoctorById(String id);
  Future<List<Doctor>> searchDoctors({
    String? query,
    DoctorSpecialty? specialty,
  });
}

/// In-memory repository implementation initialized with mock clinical data.
class DoctorRepositoryImpl implements DoctorRepository {
  final List<Doctor> _doctors;
  final Duration latency;

  DoctorRepositoryImpl({
    List<Doctor>? initialDoctors,
    this.latency = const Duration(milliseconds: 100),
  }) : _doctors = initialDoctors ?? MockDoctorData.doctors;

  @override
  Future<List<Doctor>> getDoctors() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    return List.unmodifiable(_doctors);
  }

  @override
  Future<List<Doctor>> getFeaturedDoctors() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    return _doctors.where((doc) => doc.isFeatured).toList(growable: false);
  }

  @override
  Future<Doctor?> getDoctorById(String id) async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    try {
      return _doctors.firstWhere((doc) => doc.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Doctor>> searchDoctors({
    String? query,
    DoctorSpecialty? specialty,
  }) async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }

    final trimmedQuery = query?.trim().toLowerCase() ?? '';

    return _doctors
        .where((doc) {
          final matchesSpecialty =
              specialty == null || doc.specialty == specialty;
          if (!matchesSpecialty) return false;

          if (trimmedQuery.isEmpty) return true;

          final nameMatch = doc.name.toLowerCase().contains(trimmedQuery);
          final specialtyMatch = doc.specialty.displayName
              .toLowerCase()
              .contains(trimmedQuery);
          final subSpecialtyMatch = doc.subSpecialty.toLowerCase().contains(
            trimmedQuery,
          );
          final clinicMatch = doc.clinicName.toLowerCase().contains(
            trimmedQuery,
          );

          return nameMatch ||
              specialtyMatch ||
              subSpecialtyMatch ||
              clinicMatch;
        })
        .toList(growable: false);
  }
}
