import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:care_connect/core/router/app_router.dart';
import 'package:care_connect/core/theme/app_colors.dart';
import 'package:care_connect/core/theme/app_radii.dart';
import 'package:care_connect/core/theme/app_spacing.dart';
import 'package:care_connect/core/theme/app_typography.dart';
import 'package:care_connect/core/widgets/care_badge.dart';
import 'package:care_connect/core/widgets/care_card.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';

/// Card component rendering an appointment summary in the patient's appointment history.
class AppointmentHistoryCard extends StatelessWidget {
  final Appointment appointment;

  const AppointmentHistoryCard({super.key, required this.appointment});

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  CareBadgeVariant _statusBadgeVariant(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return CareBadgeVariant.success;
      case AppointmentStatus.pending:
        return CareBadgeVariant.warning;
      case AppointmentStatus.completed:
        return CareBadgeVariant.primary;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.rescheduled:
        return CareBadgeVariant.neutral;
    }
  }

  IconData _statusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case AppointmentStatus.pending:
        return Icons.schedule_rounded;
      case AppointmentStatus.completed:
        return Icons.task_alt_rounded;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
      case AppointmentStatus.rescheduled:
        return Icons.event_repeat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = appointment.scheduledDateTime;
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];
    final formattedDate = '$weekday, $month ${date.day}, ${date.year}';

    return CareCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Booking Reference & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navy50,
                  borderRadius: AppRadii.roundedSm,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  '#${appointment.id}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.navy900,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              CareBadge(
                label: appointment.status.displayName,
                icon: _statusIcon(appointment.status),
                variant: _statusBadgeVariant(appointment.status),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // Doctor & Specialty Information
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.teal700.withValues(alpha: 0.2),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.medical_services_outlined,
                  size: 22,
                  color: AppColors.teal700,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName.isNotEmpty
                          ? appointment.doctorName
                          : 'Specialist Physician',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.navy900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.doctorSpecialty.isNotEmpty
                          ? appointment.doctorSpecialty
                          : 'CareConnect Specialty Care',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.teal700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Schedule Details Container
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.ivory,
              borderRadius: AppRadii.roundedMd,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: AppColors.teal700,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      formattedDate,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.navy900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: AppColors.teal700,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      appointment.timeSlot,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.navy900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: AppRadii.roundedPill,
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        appointment.modality.displayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                if (appointment.clinicName.isNotEmpty ||
                    appointment.clinicAddress.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          appointment.clinicAddress.isNotEmpty
                              ? appointment.clinicAddress
                              : appointment.clinicName,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Bottom Action Row: Fee & View Doctor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fee: ${appointment.currency}${appointment.fee.toInt()}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.navy900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (appointment.doctorId.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    context.pushNamed(
                      AppRouteNames.doctorDetail,
                      pathParameters: {'id': appointment.doctorId},
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('View Doctor'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal700,
                    visualDensity: VisualDensity.compact,
                    textStyle: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
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
