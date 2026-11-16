import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/doctor_specialty.dart';

class SpecialtyChip extends StatelessWidget {
  final DoctorSpecialty? specialty;
  final bool isSelected;
  final VoidCallback onTap;

  const SpecialtyChip({
    super.key,
    required this.specialty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = specialty?.displayName ?? 'All Specialists';
    final icon = specialty?.icon ?? Icons.medical_services_outlined;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filter by $label',
      child: Material(
        color: isSelected ? AppColors.teal700 : AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.roundedPill,
          side: BorderSide(
            color: isSelected ? AppColors.teal700 : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.roundedPill,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.teal700,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
