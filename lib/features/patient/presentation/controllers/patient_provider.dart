import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/patient_repository.dart';
import '../../domain/patient.dart';

/// Provider exposing the singleton PatientRepository instance.
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return LocalPatientRepository();
});

/// Async notifier managing the active local patient identity.
class PatientProfileNotifier extends AsyncNotifier<Patient?> {
  @override
  Future<Patient?> build() async {
    final repo = ref.watch(patientRepositoryProvider);
    return repo.getPatient();
  }

  /// Updates and persists patient profile information.
  Future<void> updateProfile(Patient updated) async {
    state = const AsyncLoading<Patient?>();
    final repo = ref.read(patientRepositoryProvider);
    try {
      await repo.savePatient(updated);
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Resets the patient profile back to the default demo identity.
  Future<void> resetToDefault() async {
    state = const AsyncLoading<Patient?>();
    final repo = ref.read(patientRepositoryProvider);
    try {
      final defaultPatient = await repo.resetToDefault();
      state = AsyncData(defaultPatient);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Clears the stored patient profile (for empty state testing).
  Future<void> clearProfile() async {
    state = const AsyncLoading<Patient?>();
    final repo = ref.read(patientRepositoryProvider);
    try {
      await repo.clearPatient();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// Primary provider for observing and modifying the patient profile state.
final patientProfileProvider =
    AsyncNotifierProvider<PatientProfileNotifier, Patient?>(
      PatientProfileNotifier.new,
    );
