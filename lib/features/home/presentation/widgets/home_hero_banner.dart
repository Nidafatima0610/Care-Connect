import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class HomeHeroBanner extends StatelessWidget {
  final VoidCallback onActionTap;

  const HomeHeroBanner({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy900, AppColors.navy800, AppColors.teal900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadii.roundedXl,
        boxShadow: const [
          BoxShadow(
            color: Color(0x220E1A2D),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle background decorative icon
          Positioned(
            right: -10,
            bottom: -15,
            child: Icon(
              Icons.health_and_safety_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.teal500.withValues(alpha: 0.2),
                  borderRadius: AppRadii.roundedPill,
                  border: Border.all(
                    color: AppColors.teal500.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 12,
                      color: AppColors.teal200,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Trusted Clinical Network',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.teal100,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.quickBookingBannerTitle,
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                AppStrings.quickBookingBannerSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.navy100,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Material(
                color: Colors.white,
                borderRadius: AppRadii.roundedMd,
                child: InkWell(
                  onTap: onActionTap,
                  borderRadius: AppRadii.roundedMd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm + 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: AppColors.navy900,
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Text(
                          AppStrings.quickBookingAction,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.navy900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
