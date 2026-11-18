import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:care_connect/core/router/app_router.dart';
import 'package:care_connect/core/theme/app_colors.dart';
import 'package:care_connect/core/theme/app_radii.dart';
import 'package:care_connect/core/theme/app_spacing.dart';
import 'package:care_connect/core/theme/app_typography.dart';
import 'package:care_connect/core/widgets/care_badge.dart';
import 'package:care_connect/core/widgets/care_button.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';

import 'controllers/appointment_providers.dart';

/// Screen presented immediately upon successful appointment booking creation,
/// providing an official receipt summary and routing affordances.
class BookingConfirmationScreen extends ConsumerWidget {
  final Appointment? appointment;
  final String? appointmentId;

  const BookingConfirmationScreen({
    super.key,
    this.appointment,
    this.appointmentId,
  });

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointment != null) {
      return _buildContent(context, appointment!);
    }

    if (appointmentId != null && appointmentId!.isNotEmpty) {
      return FutureBuilder<Appointment?>(
        future: ref
            .read(appointmentRepositoryProvider)
            .getAppointmentById(appointmentId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.ivory,
              body: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.teal700,
                ),
              ),
            );
          }
          final apt = snapshot.data;
          if (apt != null) {
            return _buildContent(context, apt);
          }
          return _buildFallback(context);
        },
      );
    }

    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.mint,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Appointment Confirmed',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.navy900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your appointment has been registered in the system.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                CareButton(
                  text: 'View Appointments',
                  variant: CareButtonVariant.primary,
                  onPressed: () => context.goNamed(AppRouteNames.appointments),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Appointment apt) {
    final date = apt.scheduledDateTime;
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];
    final formattedDate = '$weekday, $month ${date.day}, ${date.year}';

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // Animated Mint Success Indicator Icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.mintLight.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.mint.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: AppColors.mint,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'Appointment Confirmed!',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.navy900,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                'Your clinical consultation has been successfully scheduled.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Official Receipt Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadii.roundedLg,
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080E1A2D),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reference and status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BOOKING REFERENCE',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                  letterSpacing: 0.8,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '#${apt.id}',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.navy900,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CareBadge(
                          label: apt.status.displayName,
                          icon: Icons.check_circle_rounded,
                          variant: CareBadgeVariant.success,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),

                    _buildReceiptItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Doctor / Specialist',
                      value: apt.doctorName.isNotEmpty
                          ? apt.doctorName
                          : 'Specialist Physician',
                      subvalue: apt.doctorSpecialty,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    _buildReceiptItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date & Time',
                      value: '$formattedDate at ${apt.timeSlot}',
                      subvalue: apt.modality.displayName,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    _buildReceiptItem(
                      icon: Icons.local_hospital_outlined,
                      label: 'Clinical Facility',
                      value: apt.clinicName.isNotEmpty
                          ? apt.clinicName
                          : 'CareConnect Center',
                      subvalue: apt.clinicAddress,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    _buildReceiptItem(
                      icon: Icons.badge_outlined,
                      label: 'Patient',
                      value: apt.patientName,
                      subvalue: apt.patientPhone,
                    ),

                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),

                    // Consultation Fee
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Total Consultation Fee',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${apt.currency}${apt.fee.toInt()}.00',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.teal700,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Clinic Preparation Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.navy50,
                  borderRadius: AppRadii.roundedMd,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.teal700,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Please arrive 10 minutes prior to your scheduled time with photo ID. You can review your bookings anytime under My Appointments.',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Action Buttons
              CareButton(
                key: const Key('view_history_button'),
                text: 'View in Appointment History',
                variant: CareButtonVariant.primary,
                leadingIcon: Icons.calendar_month_outlined,
                onPressed: () => context.goNamed(AppRouteNames.appointments),
              ),

              const SizedBox(height: AppSpacing.sm),

              CareButton(
                key: const Key('return_home_button'),
                text: 'Return to Home',
                variant: CareButtonVariant.outlined,
                leadingIcon: Icons.home_outlined,
                onPressed: () => context.goNamed(AppRouteNames.home),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptItem({
    required IconData icon,
    required String label,
    required String value,
    String? subvalue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.teal700),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.navy900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subvalue != null && subvalue.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  subvalue,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
