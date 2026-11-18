import 'package:flutter/material.dart';

import 'package:care_connect/core/theme/app_colors.dart';
import 'package:care_connect/core/theme/app_radii.dart';
import 'package:care_connect/core/theme/app_spacing.dart';
import 'package:care_connect/core/theme/app_typography.dart';
import 'package:care_connect/core/widgets/care_badge.dart';
import 'package:care_connect/core/widgets/care_card.dart';
import 'package:care_connect/core/widgets/doctor_avatar.dart';
import 'package:care_connect/features/doctors/domain/doctor.dart';

/// Clean doctor summary card displayed prominently at the top of the booking screen.
class BookingDoctorSummaryCard extends StatelessWidget {
  final Doctor doctor;

  const BookingDoctorSummaryCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return CareCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DoctorAvatar(
            name: doctor.name,
            imageUrl: doctor.avatarUrl,
            size: 60,
            isOnline: true,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        doctor.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.navy900,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${doctor.specialty.displayName} • ${doctor.title}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.teal700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctor.clinicName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CareBadge(
                      label:
                          '${doctor.rating.toStringAsFixed(1)} (${doctor.reviewCount})',
                      icon: Icons.star_rounded,
                      variant: CareBadgeVariant.warning,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal50,
                        borderRadius: AppRadii.roundedSm,
                        border: Border.all(
                          color: AppColors.teal700.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '${doctor.currency}${doctor.consultationFee.toInt()} / visit',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.teal800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
