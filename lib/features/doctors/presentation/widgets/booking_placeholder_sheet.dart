import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/care_badge.dart';
import '../../../../core/widgets/care_button.dart';
import '../../../../core/widgets/doctor_avatar.dart';
import '../../domain/doctor.dart';

class BookingPlaceholderSheet extends StatelessWidget {
  final Doctor doctor;

  const BookingPlaceholderSheet({super.key, required this.doctor});

  static Future<void> show(BuildContext context, Doctor doctor) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingPlaceholderSheet(doctor: doctor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: AppRadii.roundedPill,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Doctor mini preview
          Row(
            children: [
              DoctorAvatar(
                imageUrl: doctor.avatarUrl,
                name: doctor.name,
                size: 52,
                isOnline: doctor.isAcceptingNewPatients,
              ),
              const SizedBox(width: AppSpacing.md),
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
                    Text(
                      '${doctor.specialty.displayName} • ${doctor.currency}${doctor.consultationFee.toInt()}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.teal700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              CareBadge(
                label: 'Day 1 Scope',
                variant: CareBadgeVariant.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          // Roadmap Callout Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.navy50,
              borderRadius: AppRadii.roundedLg,
              border: Border.all(color: AppColors.navy100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_note_rounded,
                      color: AppColors.teal700,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Booking Engine Roadmap',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.navy900,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.bookingPhasePlaceholderDesc,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildUpcomingFeature(
                  Icons.check_circle_outline_rounded,
                  'Calendar Date & Real-time Slot Picker (Day 2)',
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildUpcomingFeature(
                  Icons.check_circle_outline_rounded,
                  'Consultation Modality: In-Person vs Video Telehealth',
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildUpcomingFeature(
                  Icons.check_circle_outline_rounded,
                  'Appointment State Machine & Persistent History',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CareButton(
            text: 'Acknowledge & Return to Directory',
            variant: CareButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingFeature(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.teal700),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.navy800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
