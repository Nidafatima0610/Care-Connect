import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/doctor.dart';

class DoctorDetailMetrics extends StatelessWidget {
  final Doctor doctor;

  const DoctorDetailMetrics({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadii.roundedLg,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060E1A2D),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetric(
              icon: Icons.star_rounded,
              iconColor: AppColors.amber,
              value: '${doctor.rating}',
              label: 'Rating',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildMetric(
              icon: Icons.medical_services_rounded,
              iconColor: AppColors.teal700,
              value: '${doctor.experienceYears} Yrs',
              label: 'Experience',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildMetric(
              icon: Icons.people_alt_rounded,
              iconColor: AppColors.mintDark,
              value: '${doctor.patientsCount}+',
              label: 'Patients',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildMetric(
              icon: Icons.translate_rounded,
              iconColor: AppColors.navy700,
              value: '${doctor.languages.length}',
              label: 'Languages',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs + 1),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.navy900,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 32, width: 1, color: AppColors.borderLight);
  }
}
