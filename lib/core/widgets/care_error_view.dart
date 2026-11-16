import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'care_button.dart';

class CareErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const CareErrorView({
    super.key,
    this.title = 'Unable to Load Data',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.coralLight.withValues(alpha: 0.3),
        borderRadius: AppRadii.roundedLg,
        border: Border.all(
          color: AppColors.coral.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 36,
            color: AppColors.coral,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(color: AppColors.navy900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            CareButton(
              text: 'Try Again',
              onPressed: onRetry,
              variant: CareButtonVariant.outlined,
              height: 40,
            ),
          ],
        ],
      ),
    );
  }
}
