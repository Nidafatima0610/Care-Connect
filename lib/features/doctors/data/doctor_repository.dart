import '../domain/doctor.dart';
import '../domain/doctor_specialty.dart';
import 'mock_doctor_data.dart';

/// Exception thrown when doctor repository data retrieval encounters an error.
class DoctorRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const DoctorRepositoryException(this.message, [this.cause]);

  @override
  String toString() => 'DoctorRepositoryException: $message';
}

/// Abstract contract for Doctor data retrieval and search.
abstract class DoctorRepository {
  /// Whether error simulation is currently active.
  bool get isSimulatingError;

  /// Toggles simulated network failure for testing error handling and retry workflows.
  void setSimulateError(bool value);

  /// Fetches all registered doctors in the clinical directory.
  Future<List<Doctor>> getDoctors();

  /// Fetches doctors highlighted for featured spotlight.
  Future<List<Doctor>> getFeaturedDoctors();

  /// Retrieves a specific doctor by unique clinical ID.
  Future<Doctor?> getDoctorById(String id);

  /// Performs multi-field search and specialty filtering.
  Future<List<Doctor>> searchDoctors({
    String? query,
    DoctorSpecialty? specialty,
  });
}

/// In-memory repository implementation initialized with mock clinical data
/// and realistic asynchronous latency & error injection simulation.
class DoctorRepositoryImpl implements DoctorRepository {
  final List<Doctor> _doctors;
  final Duration latency;
  bool simulateError;

  DoctorRepositoryImpl({
    List<Doctor>? initialDoctors,
    this.latency = const Duration(milliseconds: 300),
    this.simulateError = false,
  }) : _doctors = initialDoctors ?? MockDoctorData.doctors;

  @override
  bool get isSimulatingError => simulateError;

  @override
  void setSimulateError(bool value) {
    simulateError = value;
  }

  void _checkSimulatedError() {
    if (simulateError) {
      throw const DoctorRepositoryException(
        'Unable to reach CareConnect directory service. Network timeout or service unavailable.',
      );
    }
  }

  @override
  Future<List<Doctor>> getDoctors() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    _checkSimulatedError();
    return List.unmodifiable(_doctors);
  }

  @override
  Future<List<Doctor>> getFeaturedDoctors() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    _checkSimulatedError();
    return _doctors.where((doc) => doc.isFeatured).toList(growable: false);
  }

  @override
  Future<Doctor?> getDoctorById(String id) async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    _checkSimulatedError();
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
    _checkSimulatedError();

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
          final qualificationMatch = doc.qualifications.any(
            (q) => q.toLowerCase().contains(trimmedQuery),
          );

          return nameMatch ||
              specialtyMatch ||
              subSpecialtyMatch ||
              clinicMatch ||
              qualificationMatch;
        })
        .toList(growable: false);
  }
}
