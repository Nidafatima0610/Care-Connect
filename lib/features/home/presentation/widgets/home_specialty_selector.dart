import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../doctors/domain/doctor_specialty.dart';
import '../../../doctors/presentation/controllers/doctor_providers.dart';
import '../../../doctors/presentation/widgets/specialty_chip.dart';

class HomeSpecialtySelector extends ConsumerWidget {
  const HomeSpecialtySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSpecialty = ref.watch(selectedSpecialtyProvider);

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        itemCount: DoctorSpecialty.values.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedSpecialty == null;
            return SpecialtyChip(
              specialty: null,
              isSelected: isSelected,
              onTap: () {
                ref.read(selectedSpecialtyProvider.notifier).clear();
              },
            );
          }

          final specialty = DoctorSpecialty.values[index - 1];
          final isSelected = selectedSpecialty == specialty;

          return SpecialtyChip(
            specialty: specialty,
            isSelected: isSelected,
            onTap: () {
              ref.read(selectedSpecialtyProvider.notifier).toggle(specialty);
            },
          );
        },
      ),
    );
  }
}
