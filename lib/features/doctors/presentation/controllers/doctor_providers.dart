import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/doctor_repository.dart';
import '../../domain/doctor.dart';
import '../../domain/doctor_specialty.dart';

/// Provider for the singleton DoctorRepository.
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepositoryImpl();
});

/// Notifier for real-time doctor search query.
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

/// Reactive provider computing filtered doctors according to active search query and specialty.
final filteredDoctorsProvider = Provider<AsyncValue<List<Doctor>>>((ref) {
  final allDoctorsAsync = ref.watch(allDoctorsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final selectedSpecialty = ref.watch(selectedSpecialtyProvider);

  return allDoctorsAsync.whenData((doctors) {
    return doctors
        .where((doctor) {
          final matchesSpecialty =
              selectedSpecialty == null ||
              doctor.specialty == selectedSpecialty;
          if (!matchesSpecialty) return false;

          if (query.isEmpty) return true;

          final nameMatch = doctor.name.toLowerCase().contains(query);
          final specialtyMatch = doctor.specialty.displayName
              .toLowerCase()
              .contains(query);
          final subSpecialtyMatch = doctor.subSpecialty.toLowerCase().contains(
            query,
          );
          final clinicMatch = doctor.clinicName.toLowerCase().contains(query);
          final qualificationMatch = doctor.qualifications.any(
            (q) => q.toLowerCase().contains(query),
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
