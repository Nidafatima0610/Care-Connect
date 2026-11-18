import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/care_button.dart';
import '../../../core/widgets/care_card.dart';
import '../../../core/widgets/care_empty_state.dart';
import '../../../core/widgets/care_error_view.dart';
import '../../../core/widgets/doctor_avatar.dart';
import '../domain/doctor.dart';
import 'controllers/doctor_providers.dart';
import 'widgets/booking_placeholder_sheet.dart';
import 'widgets/doctor_detail_metrics.dart';

class DoctorDetailScreen extends ConsumerStatefulWidget {
  final String doctorId;

  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen> {
  bool _isFavorite = false;

  void _toggleFavorite(Doctor doctor) {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? '${doctor.name} added to your saved physicians.'
              : '${doctor.name} removed from your saved physicians.',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleShare(Doctor doctor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share link for ${doctor.name} copied to clipboard (CareConnect Profile).',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onBookAppointment(Doctor doctor) {
    try {
      GoRouter.of(context);
      context.pushNamed(
        AppRouteNames.booking,
        pathParameters: {'id': doctor.id},
      );
    } catch (_) {
      BookingPlaceholderSheet.show(context, doctor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorDetailProvider(widget.doctorId));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: doctorAsync.when(
        data: (doctor) {
          if (doctor == null) {
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: CareEmptyState(
                    icon: Icons.person_off_rounded,
                    title: 'Physician Profile Not Found',
                    message: 'The doctor profile you requested could not be located in our directory.',
                    actionLabel: 'Return to Directory',
                    onAction: () => context.pop(),
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App Bar with Doctor Portrait Header
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: AppColors.navy900,
                    leading: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs + 2),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Back to Discovery',
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              color: _isFavorite
                                  ? AppColors.amber
                                  : Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Save Doctor',
                            onPressed: () => _toggleFavorite(doctor),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.share_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Share Doctor Profile',
                            onPressed: () => _handleShare(doctor),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.navy950,
                              AppColors.navy900,
                              AppColors.navy800,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: AppSpacing.xl),
                              DoctorAvatar(
                                imageUrl: doctor.avatarUrl,
                                name: doctor.name,
                                size: 92,
                                isOnline: doctor.isAcceptingNewPatients,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                doctor.name,
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${doctor.specialty.displayName} • ${doctor.title}',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.teal200,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                doctor.subSpecialty,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.navy100,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Detail Body Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppSpacing.screenHorizontal,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 4-Point Metrics Summary
                          DoctorDetailMetrics(doctor: doctor),

                          const SizedBox(height: AppSpacing.xl),

                          // Biography Section
                          _buildSectionTitle(AppStrings.aboutDoctor),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            doctor.biography,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Weekly Schedule & Availability
                          _buildSectionTitle(AppStrings.scheduleTitle),
                          const SizedBox(height: AppSpacing.sm),
                          CareCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 18,
                                      color: AppColors.teal700,
                                    ),
                                    const SizedBox(width: AppSpacing.xs + 2),
                                    Expanded(
                                      child: Text(
                                        'Clinic Hours: ${doctor.workingHours}',
                                        style: AppTypography.labelMedium
                                            .copyWith(
                                              color: AppColors.navy900,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.xs + 2,
                                  children:
                                      [
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                      ].map((day) {
                                        final isAvailable = doctor.availableDays
                                            .contains(day);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm + 2,
                                            vertical: AppSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isAvailable
                                                ? AppColors.teal50
                                                : AppColors.surfaceMuted,
                                            borderRadius: AppRadii.roundedPill,
                                            border: Border.all(
                                              color: isAvailable
                                                  ? AppColors.teal200
                                                  : AppColors.borderLight,
                                            ),
                                          ),
                                          child: Text(
                                            day,
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                                  color: isAvailable
                                                      ? AppColors.teal700
                                                      : AppColors.textTertiary,
                                                  fontWeight: isAvailable
                                                      ? FontWeight.w700
                                                      : FontWeight.w400,
                                                ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: AppColors.mintDark,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        doctor.availabilitySummary,
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: AppColors.mintDark,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Consultation Modalities
                          _buildSectionTitle(
                            AppStrings.consultationOptionsTitle,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _buildModalityCard(
                                  icon: Icons.apartment_rounded,
                                  title: AppStrings.inPersonVisit,
                                  subtitle: 'Clinic Suite',
                                  isAvailable: doctor.hasInPersonConsultation,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildModalityCard(
                                  icon: Icons.videocam_rounded,
                                  title: AppStrings.videoVisit,
                                  subtitle: 'Telehealth HD',
                                  isAvailable: doctor.hasVideoConsultation,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Clinic Facility Details
                          _buildSectionTitle(AppStrings.clinicLocationTitle),
                          const SizedBox(height: AppSpacing.sm),
                          CareCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: const BoxDecoration(
                                    color: AppColors.navy50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.business_rounded,
                                    color: AppColors.teal700,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctor.clinicName,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                              color: AppColors.navy900,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        doctor.clinicAddress,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Qualifications & Credentials
                          _buildSectionTitle(AppStrings.qualificationsTitle),
                          const SizedBox(height: AppSpacing.sm),
                          Column(
                            children: doctor.qualifications.map((
                              qualification,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color: AppColors.teal700,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        qualification,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.navy900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                          // Spacer for bottom sticky bar
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Sticky Bottom Booking Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: AppSpacing.screenHorizontal,
                    right: AppSpacing.screenHorizontal,
                    top: AppSpacing.md,
                    bottom:
                        MediaQuery.of(context).padding.bottom + AppSpacing.md,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceCard,
                    border: Border(
                      top: BorderSide(color: AppColors.borderLight, width: 1),
                    ),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Consultation Fee',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${doctor.currency}${doctor.consultationFee.toInt()}',
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.navy900,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                ' / session',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: CareButton(
                          text: AppStrings.bookAppointment,
                          variant: CareButtonVariant.primary,
                          leadingIcon: Icons.calendar_today_rounded,
                          onPressed: () => _onBookAppointment(doctor),
                          height: 48,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.teal700,
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: CareErrorView(
              message: AppStrings.genericErrorMessage,
              onRetry: () => ref.refresh(doctorDetailProvider(widget.doctorId)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.navy900,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildModalityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isAvailable,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.surfaceCard : AppColors.surfaceMuted,
        borderRadius: AppRadii.roundedMd,
        border: Border.all(
          color: isAvailable ? AppColors.teal200 : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isAvailable ? AppColors.teal700 : AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: isAvailable
                        ? AppColors.navy900
                        : AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isAvailable ? subtitle : 'Unavailable',
                  style: AppTypography.labelSmall.copyWith(
                    color: isAvailable
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
