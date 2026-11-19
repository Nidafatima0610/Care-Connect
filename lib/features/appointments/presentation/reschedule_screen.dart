import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:care_connect/core/router/app_router.dart';
import 'package:care_connect/core/theme/app_colors.dart';
import 'package:care_connect/core/theme/app_radii.dart';
import 'package:care_connect/core/theme/app_spacing.dart';
import 'package:care_connect/core/theme/app_typography.dart';
import 'package:care_connect/core/widgets/care_button.dart';
import 'package:care_connect/core/widgets/care_empty_state.dart';
import 'package:care_connect/core/widgets/care_section_header.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';
import 'package:care_connect/features/doctors/presentation/controllers/doctor_providers.dart';

import '../domain/time_slot.dart';
import 'controllers/appointment_providers.dart';
import 'widgets/date_selector_strip.dart';
import 'widgets/time_slot_grid.dart';

/// Screen allowing patients to reschedule an active upcoming appointment.
class RescheduleScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  final Appointment? initialAppointment;

  const RescheduleScreen({
    super.key,
    required this.appointmentId,
    this.initialAppointment,
  });

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
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

  bool _hasInitialized = false;

  void _initRescheduleState(Appointment appointment) {
    if (_hasInitialized) return;
    _hasInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notifier = ref.read(rescheduleControllerProvider.notifier);
        notifier.init(appointment);

        // Pre-select slot if requested via query params (useful for automated screenshot capture)
        final uri = Uri.base;
        if (uri.queryParameters['reschedule_slot'] != null) {
          final slotStr = uri.queryParameters['reschedule_slot']!;
          final date = ref.read(rescheduleControllerProvider).selectedDate;
          notifier.selectSlot(
            TimeSlot(
              time: slotStr,
              dateTime: DateTime(date.year, date.month, date.day, 14, 30),
              isAvailable: true,
              period: SlotPeriod.afternoon,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If appointment passed directly, use it; otherwise read from repository provider
    if (widget.initialAppointment != null) {
      _initRescheduleState(widget.initialAppointment!);
      return _buildContent(widget.initialAppointment!);
    }

    final appointmentAsync = ref.watch(
      appointmentByIdProvider(widget.appointmentId),
    );

    return appointmentAsync.when(
      data: (appointment) {
        if (appointment == null) {
          return Scaffold(
            backgroundColor: AppColors.ivory,
            appBar: AppBar(
              backgroundColor: AppColors.ivory,
              title: const Text('Reschedule Appointment'),
            ),
            body: Center(
              child: CareEmptyState(
                icon: Icons.search_off_rounded,
                title: 'Appointment Not Found',
                message:
                    'The requested appointment #${widget.appointmentId} could not be located in local storage.',
                actionLabel: 'Return to Appointments',
                onAction: () => context.goNamed(AppRouteNames.appointments),
              ),
            ),
          );
        }
        _initRescheduleState(appointment);
        return _buildContent(appointment);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.ivory,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.teal700,
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          backgroundColor: AppColors.ivory,
          title: const Text('Reschedule Appointment'),
        ),
        body: Center(
          child: Text(
            'Failed to load appointment details: $err',
            style: const TextStyle(color: AppColors.coral),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Appointment appointment) {
    final rescheduleState = ref.watch(rescheduleControllerProvider);
    final notifier = ref.read(rescheduleControllerProvider.notifier);

    // Fetch doctor for available days metadata
    final doctorAsync = ref.watch(doctorDetailProvider(appointment.doctorId));
    final doctor = doctorAsync.asData?.value;

    // Available slots for selected new date, excluding this appointment so original slot is available
    final slotsQuery = DoctorDateQuery(
      doctorId: appointment.doctorId,
      date: rescheduleState.selectedDate,
      excludeAppointmentId: appointment.id,
    );
    final slotsAsync = ref.watch(doctorSlotsProvider(slotsQuery));

    final originalDate = appointment.scheduledDateTime;
    final origWeekday = _weekdays[originalDate.weekday - 1];
    final origMonth = _months[originalDate.month - 1];
    final origFormatted =
        '$origWeekday, $origMonth ${originalDate.day}, ${originalDate.year}';

    final selectedDay = rescheduleState.selectedDate;
    final newWeekday = _weekdays[selectedDay.weekday - 1];
    final newMonth = _months[selectedDay.month - 1];
    final newFormatted =
        '$newWeekday, $newMonth ${selectedDay.day}, ${selectedDay.year}';

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy900,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRouteNames.appointments);
            }
          },
        ),
        title: Text(
          'Reschedule Appointment',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.navy900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Currently Scheduled Booking Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.teal50,
                        borderRadius: AppRadii.roundedMd,
                        border: Border.all(
                          color: AppColors.teal700.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.teal700,
                                  borderRadius: AppRadii.roundedPill,
                                ),
                                child: Text(
                                  'CURRENT BOOKING',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '#${appointment.id}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.teal700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            appointment.doctorName,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.navy900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            appointment.doctorSpecialty,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.teal700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: AppColors.teal700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$origFormatted at ${appointment.timeSlot}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.navy900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Error banner if any
                  if (rescheduleState.error != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.coralLight.withValues(alpha: 0.35),
                          borderRadius: AppRadii.roundedMd,
                          border: Border.all(
                            color: AppColors.coral.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.coral,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                rescheduleState.error!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Section 1: Choose New Date
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: CareSectionHeader(
                      title: 'Select New Date',
                      subtitle: newFormatted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DateSelectorStrip(
                    selectedDate: rescheduleState.selectedDate,
                    onDateSelected: notifier.selectDate,
                    doctorAvailableDays: doctor?.availableDays,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Section 2: Choose New Slot
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: CareSectionHeader(
                      title: 'Select New Time Slot',
                      subtitle: rescheduleState.selectedSlot != null
                          ? 'New Slot: ${rescheduleState.selectedSlot!.time}'
                          : 'Select an available consultation slot',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  slotsAsync.when(
                    data: (slots) => TimeSlotGrid(
                      slots: slots,
                      selectedSlot: rescheduleState.selectedSlot,
                      onSlotSelected: notifier.selectSlot,
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.teal700,
                        ),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: Text(
                        'Unable to load slots: $err',
                        style: const TextStyle(color: AppColors.coral),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Reschedule Review Card
                  if (rescheduleState.selectedSlot != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: AppRadii.roundedMd,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rescheduling Summary',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.navy900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Your appointment reference #${appointment.id} will remain unchanged. Local reminder notifications will be updated for the new schedule.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_repeat_rounded,
                                  size: 16,
                                  color: AppColors.teal700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'New Schedule: $newFormatted at ${rescheduleState.selectedSlot!.time}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.teal700,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Fixed Action Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: const Border(
                top: BorderSide(color: AppColors.borderLight),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: CareButton(
                text: 'Confirm Reschedule',
                leadingIcon: Icons.check_circle_outline_rounded,
                variant: CareButtonVariant.primary,
                height: 48.0,
                width: double.infinity,
                isLoading: rescheduleState.isSubmitting,
                onPressed: rescheduleState.isSubmitting
                    ? null
                    : () async {
                        final updated = await notifier.confirmReschedule();
                        if (!mounted) return;
                        if (updated != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.teal700,
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Appointment rescheduled to $newFormatted at ${updated.timeSlot}!',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.goNamed(AppRouteNames.appointments);
                          }
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
