import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/patient.dart';

/// Abstract contract for Patient identity and profile persistence.
abstract class PatientRepository {
  /// Retrieves the current locally persisted patient, or initializes default if none exists.
  Future<Patient?> getPatient();

  /// Persists updated patient profile information to local device storage.
  Future<void> savePatient(Patient patient);

  /// Clears persisted patient profile (useful for testing empty profile state).
  Future<void> clearPatient();

  /// Resets patient profile back to default fictional demo identity.
  Future<Patient> resetToDefault();
}

/// SharedPreferences-backed local persistence implementation for patient identity.
class LocalPatientRepository implements PatientRepository {
  static const String _storageKey = 'careconnect_local_patient_profile';

  final SharedPreferences? prefs;
  final Duration latency;

  LocalPatientRepository({
    this.prefs,
    this.latency = const Duration(milliseconds: 150),
  });

  Future<SharedPreferences> _getPrefs() async {
    return prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<Patient?> getPatient() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }

    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_storageKey);

    if (jsonStr == null || jsonStr.trim().isEmpty) {
      // First launch: initialize default demo identity
      final defaultPatient = Patient.defaultDemoPatient();
      await savePatient(defaultPatient);
      return defaultPatient;
    }

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Patient.fromJson(map);
    } catch (_) {
      // Fallback on corrupt JSON
      final defaultPatient = Patient.defaultDemoPatient();
      await savePatient(defaultPatient);
      return defaultPatient;
    }
  }

  @override
  Future<void> savePatient(Patient patient) async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }

    final prefs = await _getPrefs();
    final updatedPatient = patient.copyWith(updatedAt: DateTime.now());
    final jsonStr = jsonEncode(updatedPatient.toJson());
    await prefs.setString(_storageKey, jsonStr);
  }

  @override
  Future<void> clearPatient() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }

    final prefs = await _getPrefs();
    await prefs.remove(_storageKey);
  }

  @override
  Future<Patient> resetToDefault() async {
    final defaultPatient = Patient.defaultDemoPatient();
    await savePatient(defaultPatient);
    return defaultPatient;
  }
}
