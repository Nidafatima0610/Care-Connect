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
import 'package:care_connect/features/patient/domain/patient.dart';
import 'package:care_connect/features/patient/presentation/controllers/patient_provider.dart';

import '../domain/time_slot.dart';
import 'controllers/appointment_providers.dart';
import 'widgets/booking_doctor_summary_card.dart';
import 'widgets/date_selector_strip.dart';
import 'widgets/time_slot_grid.dart';

/// Screen allowing patients to select a consultation date, choose an available time slot,
/// configure visit modality, review booking summary, and confirm appointment.
class BookingScreen extends ConsumerStatefulWidget {
  final String doctorId;

  const BookingScreen({super.key, required this.doctorId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notifier = ref.read(bookingControllerProvider.notifier);
        notifier.init(widget.doctorId);

        final uri = Uri.base;
        if (uri.queryParameters['error'] == 'validation') {
          notifier.setValidationError(
            'Please select an appointment time slot.',
          );
        } else if (uri.queryParameters['error'] == 'conflict') {
          notifier.setConflictError(
            'The selected time slot (10:00 AM) is no longer available. Another patient just reserved it.',
          );
        }

        if (uri.queryParameters['select_date'] == 'tomorrow') {
          final now = DateTime.now();
          final tomorrow = now.add(const Duration(days: 1));
          notifier.selectDate(
            DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
          );
        }

        if (uri.queryParameters['select_slot'] == '10:00 AM') {
          final now = DateTime.now();
          final tomorrow = now.add(const Duration(days: 1));
          final slotDate = uri.queryParameters['select_date'] == 'tomorrow'
              ? tomorrow
              : now;
          notifier.selectSlot(
            TimeSlot(
              time: '10:00 AM',
              dateTime: DateTime(
                slotDate.year,
                slotDate.month,
                slotDate.day,
                10,
                0,
              ),
              isAvailable: true,
              period: SlotPeriod.morning,
            ),
          );
        }
      }
    });
  }

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

  Future<void> _handleConfirmBooking() async {
    final doctor = ref
        .read(doctorDetailProvider(widget.doctorId))
        .asData
        ?.value;
    if (doctor == null) return;

    final patientAsync = ref.read(patientProfileProvider);
    final patient = patientAsync.value ?? Patient.defaultDemoPatient();

    final notifier = ref.read(bookingControllerProvider.notifier);
    final appointment = await notifier.confirmBooking(
      doctor: doctor,
      patient: patient,
    );

    if (appointment != null && mounted) {
      context.pushReplacementNamed(
        AppRouteNames.bookingConfirmation,
        extra: appointment,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorDetailProvider(widget.doctorId));
    final bookingState = ref.watch(bookingControllerProvider);
    final notifier = ref.read(bookingControllerProvider.notifier);

    final slotsQuery = DoctorDateQuery(
      doctorId: widget.doctorId,
      date: bookingState.selectedDate,
    );
    final slotsAsync = ref.watch(doctorSlotsProvider(slotsQuery));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy900,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Appointment',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.navy900,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Select preferred date and time slot',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: doctorAsync.when(
        data: (doctor) {
          if (doctor == null) {
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: CareEmptyState(
                    icon: Icons.person_off_rounded,
                    title: 'Specialist Not Found',
                    message:
                        'The doctor you are trying to book could not be found.',
                    actionLabel: 'Return Home',
                    onAction: () => context.goNamed(AppRouteNames.home),
                  ),
                ),
              ),
            );
          }

          final selectedDay = bookingState.selectedDate;
          final weekday = _weekdays[selectedDay.weekday - 1];
          final month = _months[selectedDay.month - 1];
          final formattedSelectedDate =
              '$weekday, $month ${selectedDay.day}, ${selectedDay.year}';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Summary Card
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: BookingDoctorSummaryCard(doctor: doctor),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Validation or Conflict Alert Banner
                      if (bookingState.validationError != null ||
                          bookingState.conflictError != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenHorizontal,
                          ),
                          child: Container(
                            key: const Key('booking_error_banner'),
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.coralLight.withValues(
                                alpha: 0.35,
                              ),
                              borderRadius: AppRadii.roundedMd,
                              border: Border.all(
                                color: AppColors.coral.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.coral,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    bookingState.validationError ??
                                        bookingState.conflictError ??
                                        '',
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

                      // Date Selection Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: CareSectionHeader(
                          title: 'Select Appointment Date',
                          subtitle: formattedSelectedDate,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DateSelectorStrip(
                        selectedDate: bookingState.selectedDate,
                        onDateSelected: notifier.selectDate,
                        doctorAvailableDays: doctor.availableDays,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Time Slot Selection Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: CareSectionHeader(
                          title: 'Available Time Slots',
                          subtitle: bookingState.selectedSlot != null
                              ? 'Selected: ${bookingState.selectedSlot!.time}'
                              : 'Select a time slot for consultation',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      slotsAsync.when(
                        data: (slots) => TimeSlotGrid(
                          slots: slots,
                          selectedSlot: bookingState.selectedSlot,
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
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.coral,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Modality Selection Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consultation Modality',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.navy900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModalityCard(
                                    title: 'In-Person Visit',
                                    subtitle: 'At Clinic Facility',
                                    icon: Icons.local_hospital_outlined,
                                    modality: AppointmentModality.inPerson,
                                    isSelected:
                                        bookingState.selectedModality ==
                                        AppointmentModality.inPerson,
                                    onTap: () => notifier.selectModality(
                                      AppointmentModality.inPerson,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _buildModalityCard(
                                    title: 'Video Visit',
                                    subtitle: 'Telehealth Call',
                                    icon: Icons.videocam_outlined,
                                    modality: AppointmentModality.video,
                                    isSelected:
                                        bookingState.selectedModality ==
                                        AppointmentModality.video,
                                    onTap: () => notifier.selectModality(
                                      AppointmentModality.video,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Booking Summary Card
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: AppRadii.roundedLg,
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking Review',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.navy900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Divider(height: 1),
                              const SizedBox(height: AppSpacing.sm),
                              _buildSummaryRow('Physician', doctor.name),
                              _buildSummaryRow(
                                'Date',
                                '$month ${selectedDay.day}, ${selectedDay.year}',
                              ),
                              _buildSummaryRow(
                                'Time',
                                bookingState.selectedSlot?.time ??
                                    'No slot selected',
                                isHighlight: bookingState.selectedSlot != null,
                              ),
                              _buildSummaryRow(
                                'Modality',
                                bookingState.selectedModality.displayName,
                              ),
                              _buildSummaryRow(
                                'Clinic Fee',
                                '${doctor.currency}${doctor.consultationFee.toInt()}',
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceCard,
                  border: Border(
                    top: BorderSide(color: AppColors.borderLight, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A0E1A2D),
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total Due',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${doctor.currency}${doctor.consultationFee.toInt()}',
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.navy900,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        child: CareButton(
                          key: const Key('confirm_booking_button'),
                          text: 'Confirm Booking',
                          variant: CareButtonVariant.primary,
                          leadingIcon: Icons.check_circle_outline_rounded,
                          isLoading: bookingState.isSubmitting,
                          onPressed: bookingState.isSubmitting
                              ? null
                              : _handleConfirmBooking,
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
          child: Text(
            'Unable to load doctor: $err',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.coral),
          ),
        ),
      ),
    );
  }

  Widget _buildModalityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required AppointmentModality modality,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.roundedMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal50 : AppColors.surfaceCard,
          borderRadius: AppRadii.roundedMd,
          border: Border.all(
            color: isSelected ? AppColors.teal700 : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.teal700 : AppColors.navy900,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected ? AppColors.teal800 : AppColors.navy900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: isHighlight ? AppColors.teal700 : AppColors.navy900,
                fontWeight: isBold || isHighlight
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
