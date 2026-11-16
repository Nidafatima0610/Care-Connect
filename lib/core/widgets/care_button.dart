import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum CareButtonVariant { primary, secondary, outlined, subtle }

class CareButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CareButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const CareButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = CareButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.width,
    this.height = 42.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, borderColor) = switch (variant) {
      CareButtonVariant.primary => (
        AppColors.teal700,
        Colors.white,
        Colors.transparent,
      ),
      CareButtonVariant.secondary => (
        AppColors.navy900,
        Colors.white,
        Colors.transparent,
      ),
      CareButtonVariant.outlined => (
        Colors.transparent,
        AppColors.teal700,
        AppColors.teal700,
      ),
      CareButtonVariant.subtle => (
        AppColors.surfaceMuted,
        AppColors.navy800,
        AppColors.borderLight,
      ),
    };

    final isEnabled = onPressed != null && !isLoading;

    final childWidget = isLoading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 14, color: fgColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  text,
                  style: AppTypography.labelLarge.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(trailingIcon, size: 14, color: fgColor),
              ],
            ],
          );

    return Material(
      color: isEnabled ? bgColor : AppColors.surfaceMuted,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.roundedMd,
        side: BorderSide(
          color: isEnabled ? borderColor : AppColors.borderLight,
          width: variant == CareButtonVariant.outlined ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: AppRadii.roundedMd,
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
            child: Center(
              widthFactor: width != null ? null : 1.0,
              child: childWidget,
            ),
          ),
        ),
      ),
    );
  }
}
