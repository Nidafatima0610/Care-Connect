import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/care_badge.dart';
import '../../../../core/widgets/care_button.dart';
import '../../../../core/widgets/care_card.dart';
import '../../../../core/widgets/doctor_avatar.dart';
import '../../domain/doctor.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;
  final VoidCallback onBookTap;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    return CareCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DoctorAvatar(
                imageUrl: doctor.avatarUrl,
                name: doctor.name,
                size: 64,
                isOnline: doctor.isAcceptingNewPatients,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor.name,
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.navy900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${doctor.specialty.displayName} • ${doctor.title}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.teal700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (doctor.isFeatured)
                          const CareBadge(
                            label: 'Featured',
                            variant: CareBadgeVariant.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Badges row: Rating, Experience
                    Wrap(
                      spacing: AppSpacing.xs + 2,
                      runSpacing: AppSpacing.xs,
                      children: [
                        CareBadge(
                          label: '${doctor.rating} (${doctor.reviewCount})',
                          icon: Icons.star_rounded,
                          variant: CareBadgeVariant.warning,
                        ),
                        CareBadge(
                          label: '${doctor.experienceYears}+ yrs exp',
                          icon: Icons.timeline_rounded,
                          variant: CareBadgeVariant.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Clinic and Availability Summary
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppRadii.roundedMd,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_hospital_outlined,
                  size: 15,
                  color: AppColors.teal700,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    doctor.clinicName,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  doctor.availabilitySummary.replaceFirst(
                    'Next Available: ',
                    '',
                  ),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.mintDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          // Footer: Fee + Action Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consultation Fee',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text.rich(
                      TextSpan(
                        text:
                            '${doctor.currency}${doctor.consultationFee.toInt()}',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.navy900,
                          fontWeight: FontWeight.w800,
                        ),
                        children: [
                          TextSpan(
                            text: ' / visit',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              CareButton(
                text: 'View Profile',
                variant: CareButtonVariant.primary,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: onTap,
                height: 38,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
