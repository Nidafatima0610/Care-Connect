import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/doctor_repository.dart';
import '../../domain/doctor.dart';
import '../../domain/doctor_specialty.dart';

/// Provider for the singleton DoctorRepository.
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  final uri = Uri.base;
  final simulateLoading = uri.queryParameters['simulate_loading'] == 'true';
  final simulateError = uri.queryParameters['simulate_error'] == 'true';

  return DoctorRepositoryImpl(
    latency: simulateLoading
        ? const Duration(seconds: 20)
        : const Duration(milliseconds: 300),
    simulateError: simulateError,
  );
});

/// Error simulation controller for testing, manual verification, and error state demos.
class DoctorErrorSimulationNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    setError(!state);
  }

  void setError(bool value) {
    state = value;
    ref.read(doctorRepositoryProvider).setSimulateError(value);
    ref.invalidate(allDoctorsProvider);
    ref.invalidate(featuredDoctorsProvider);
  }
}

final doctorErrorSimulationProvider =
    NotifierProvider<DoctorErrorSimulationNotifier, bool>(
      DoctorErrorSimulationNotifier.new,
    );

/// Loading simulation controller for testing, manual verification, and skeleton state demos.
class DoctorLoadingSimulationNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool value) {
    state = value;
  }
}

final doctorLoadingSimulationProvider =
    NotifierProvider<DoctorLoadingSimulationNotifier, bool>(
      DoctorLoadingSimulationNotifier.new,
    );

/// Notifier for real-time immediate doctor search query (updates on each keystroke).
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Debounced search query notifier. Delays query propagation by 250ms when typing
/// to prevent UI thrashing and stale race conditions, but applies instantly when cleared.
class DebouncedSearchNotifier extends Notifier<String> {
  Timer? _timer;

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());

    // Listen to immediate searchQuery changes
    ref.listen<String>(searchQueryProvider, (previous, next) {
      _timer?.cancel();
      if (next.trim().isEmpty) {
        // Immediate reset when query is cleared
        state = '';
      } else {
        _timer = Timer(const Duration(milliseconds: 250), () {
          state = next;
        });
      }
    });

    return ref.read(searchQueryProvider);
  }

  /// Manually flushes immediate query without waiting for timer (useful for tests).
  void flushImmediate(String query) {
    _timer?.cancel();
    state = query;
  }
}

final debouncedSearchQueryProvider =
    NotifierProvider<DebouncedSearchNotifier, String>(
      DebouncedSearchNotifier.new,
    );

/// Notifier for selected specialty filter chip. Null represents "All Specialties".
class SelectedSpecialtyNotifier extends Notifier<DoctorSpecialty?> {
  @override
  DoctorSpecialty? build() => null;

  void select(DoctorSpecialty? specialty) {
    state = specialty;
  }

  void toggle(DoctorSpecialty specialty) {
    if (state == specialty) {
      state = null;
    } else {
      state = specialty;
    }
  }

  void clear() {
    state = null;
  }
}

final selectedSpecialtyProvider =
    NotifierProvider<SelectedSpecialtyNotifier, DoctorSpecialty?>(
      SelectedSpecialtyNotifier.new,
    );

/// Provider fetching all available doctors from the repository.
final allDoctorsProvider = FutureProvider<List<Doctor>>((ref) async {
  final repo = ref.watch(doctorRepositoryProvider);
  return repo.getDoctors();
});

/// Provider fetching curated featured doctors for the spotlight section.
final featuredDoctorsProvider = FutureProvider<List<Doctor>>((ref) async {
  final repo = ref.watch(doctorRepositoryProvider);
  return repo.getFeaturedDoctors();
});

/// Reactive provider computing filtered doctors according to debounced search query and specialty.
final filteredDoctorsProvider = Provider<AsyncValue<List<Doctor>>>((ref) {
  final allDoctorsAsync = ref.watch(allDoctorsProvider);
  final debouncedQuery = ref
      .watch(debouncedSearchQueryProvider)
      .trim()
      .toLowerCase();
  final selectedSpecialty = ref.watch(selectedSpecialtyProvider);
  final isErrorSimulated = ref.watch(doctorErrorSimulationProvider);
  final isLoadingSimulated = ref.watch(doctorLoadingSimulationProvider);

  if (isErrorSimulated || debouncedQuery == 'trigger_error') {
    return const AsyncError(
      DoctorRepositoryException(
        'Unable to reach CareConnect directory service. Network timeout or service unavailable.',
      ),
      StackTrace.empty,
    );
  }

  if (isLoadingSimulated || debouncedQuery == 'trigger_loading') {
    return const AsyncLoading();
  }

  return allDoctorsAsync.whenData((doctors) {
    return doctors
        .where((doctor) {
          final matchesSpecialty =
              selectedSpecialty == null ||
              doctor.specialty == selectedSpecialty;
          if (!matchesSpecialty) return false;

          if (debouncedQuery.isEmpty) return true;

          final nameMatch = doctor.name.toLowerCase().contains(debouncedQuery);
          final specialtyMatch = doctor.specialty.displayName
              .toLowerCase()
              .contains(debouncedQuery);
          final subSpecialtyMatch = doctor.subSpecialty.toLowerCase().contains(
            debouncedQuery,
          );
          final clinicMatch = doctor.clinicName.toLowerCase().contains(
            debouncedQuery,
          );
          final qualificationMatch = doctor.qualifications.any(
            (q) => q.toLowerCase().contains(debouncedQuery),
          );

          return nameMatch ||
              specialtyMatch ||
              subSpecialtyMatch ||
              clinicMatch ||
              qualificationMatch;
        })
        .toList(growable: false);
  });
});

/// Family provider to retrieve a specific doctor by unique ID.
final doctorDetailProvider = FutureProvider.family<Doctor?, String>((
  ref,
  doctorId,
) async {
  final repo = ref.watch(doctorRepositoryProvider);
  return repo.getDoctorById(doctorId);
});
