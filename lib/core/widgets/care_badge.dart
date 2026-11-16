import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum CareBadgeVariant { primary, secondary, success, warning, neutral }

class CareBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final CareBadgeVariant variant;
  final VoidCallback? onTap;

  const CareBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = CareBadgeVariant.neutral,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, borderColor) = switch (variant) {
      CareBadgeVariant.primary => (
        AppColors.teal50,
        AppColors.teal700,
        AppColors.teal200,
      ),
      CareBadgeVariant.secondary => (
        AppColors.navy50,
        AppColors.navy800,
        AppColors.navy100,
      ),
      CareBadgeVariant.success => (
        AppColors.mint50,
        AppColors.mintDark,
        AppColors.mintLight,
      ),
      CareBadgeVariant.warning => (
        AppColors.amber50,
        AppColors.amberDark,
        AppColors.amberLight,
      ),
      CareBadgeVariant.neutral => (
        AppColors.surfaceMuted,
        AppColors.textSecondary,
        AppColors.borderLight,
      ),
    };

    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs - 1,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.roundedPill,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadii.roundedPill,
        child: content,
      );
    }

    return content;
  }
}
