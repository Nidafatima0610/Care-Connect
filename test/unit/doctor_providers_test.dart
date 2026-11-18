import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/features/doctors/data/doctor_repository.dart';
import 'package:care_connect/features/doctors/domain/doctor_specialty.dart';
import 'package:care_connect/features/doctors/presentation/controllers/doctor_providers.dart';

void main() {
  group('Doctor Providers State Tests', () {
    test('SearchQueryNotifier updates and clears search query state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(searchQueryProvider), '');

      container.read(searchQueryProvider.notifier).setQuery('Cardiology');
      expect(container.read(searchQueryProvider), 'Cardiology');

      container.read(searchQueryProvider.notifier).clear();
      expect(container.read(searchQueryProvider), '');
    });

    test('SelectedSpecialtyNotifier toggles specialty selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedSpecialtyProvider), isNull);

      container
          .read(selectedSpecialtyProvider.notifier)
          .toggle(DoctorSpecialty.dermatology);
      expect(
        container.read(selectedSpecialtyProvider),
        DoctorSpecialty.dermatology,
      );

      // Toggling same specialty resets it to null (All)
      container
          .read(selectedSpecialtyProvider.notifier)
          .toggle(DoctorSpecialty.dermatology);
      expect(container.read(selectedSpecialtyProvider), isNull);
    });

    test(
      'DoctorErrorSimulationNotifier toggles error simulation and sets value',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(doctorErrorSimulationProvider), isFalse);

        container.read(doctorErrorSimulationProvider.notifier).toggle();
        expect(container.read(doctorErrorSimulationProvider), isTrue);

        container.read(doctorErrorSimulationProvider.notifier).setError(false);
        expect(container.read(doctorErrorSimulationProvider), isFalse);
      },
    );

    test(
      'DoctorErrorSimulationNotifier toggles error simulation and sets value',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(doctorErrorSimulationProvider), isFalse);

        container.read(doctorErrorSimulationProvider.notifier).toggle();
        expect(container.read(doctorErrorSimulationProvider), isTrue);

        container.read(doctorErrorSimulationProvider.notifier).setError(false);
        expect(container.read(doctorErrorSimulationProvider), isFalse);
      },
    );

    test(
      'filteredDoctorsProvider reacts to search query and specialty filter',
      () async {
        final container = ProviderContainer(
          overrides: [
            doctorRepositoryProvider.overrideWithValue(
              DoctorRepositoryImpl(latency: Duration.zero),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Await initial allDoctorsProvider load
        final allDocs = await container.read(allDoctorsProvider.future);
        expect(allDocs.length, greaterThanOrEqualTo(8));

        // Check default filtered list matches all
        final initialFiltered = container.read(filteredDoctorsProvider);
        expect(initialFiltered.value!.length, allDocs.length);

        // Apply search query with immediate flush
        container.read(searchQueryProvider.notifier).setQuery('Elena');
        container
            .read(debouncedSearchQueryProvider.notifier)
            .flushImmediate('Elena');
        container
            .read(debouncedSearchQueryProvider.notifier)
            .flushImmediate('Elena');
        final searchFiltered = container.read(filteredDoctorsProvider);
        expect(searchFiltered.value!.length, 1);
        expect(searchFiltered.value!.first.name, contains('Elena Rostova'));

        // Clear search query and filter by specialty
        container.read(searchQueryProvider.notifier).clear();
        container
            .read(debouncedSearchQueryProvider.notifier)
            .flushImmediate('');
        container
            .read(debouncedSearchQueryProvider.notifier)
            .flushImmediate('');
        container
            .read(selectedSpecialtyProvider.notifier)
            .select(DoctorSpecialty.pediatrics);
        final pediatricsFiltered = container.read(filteredDoctorsProvider);
        expect(
          pediatricsFiltered.value!.every(
            (d) => d.specialty == DoctorSpecialty.pediatrics,
          ),
          isTrue,
        );
      },
    );
  });
}
