import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/care_badge.dart';
import '../../../../core/widgets/care_card.dart';
import '../../../../core/widgets/doctor_avatar.dart';
import '../../domain/doctor.dart';

class DoctorFeaturedCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const DoctorFeaturedCard({
    super.key,
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: CareCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DoctorAvatar(
                  imageUrl: doctor.avatarUrl,
                  name: doctor.name,
                  size: 46,
                  isOnline: doctor.isAcceptingNewPatients,
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CareBadge(
                            label: 'Featured',
                            icon: Icons.verified_rounded,
                            variant: CareBadgeVariant.primary,
                          ),
                          Text(
                            '${doctor.currency}${doctor.consultationFee.toInt()}',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.navy900,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        doctor.name,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.navy900,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        doctor.specialty.displayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.teal700,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Info Row: Badges
            Row(
              children: [
                CareBadge(
                  label: '${doctor.rating} Rating',
                  icon: Icons.star_rounded,
                  variant: CareBadgeVariant.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                CareBadge(
                  label: '${doctor.experienceYears}y exp',
                  variant: CareBadgeVariant.secondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs + 1,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: AppRadii.roundedSm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    size: 13,
                    color: AppColors.teal700,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      doctor.availabilitySummary,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
