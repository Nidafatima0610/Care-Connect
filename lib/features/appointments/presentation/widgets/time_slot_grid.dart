import 'package:flutter/material.dart';

import 'package:care_connect/core/theme/app_colors.dart';
import 'package:care_connect/core/theme/app_radii.dart';
import 'package:care_connect/core/theme/app_spacing.dart';
import 'package:care_connect/core/theme/app_typography.dart';
import 'package:care_connect/core/widgets/care_empty_state.dart';
import 'package:care_connect/features/appointments/domain/time_slot.dart';

/// Categorized grid displaying morning, afternoon, and evening slots with clear
/// distinction between available, selected, and unavailable/booked states.
class TimeSlotGrid extends StatelessWidget {
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final ValueChanged<TimeSlot> onSlotSelected;

  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        child: CareEmptyState(
          icon: Icons.event_busy_rounded,
          title: 'No Slots Available',
          message: 'There are no appointment slots available on this date. Please choose another day on the calendar.',
        ),
      );
    }

    final morningSlots = slots
        .where((s) => s.period == SlotPeriod.morning)
        .toList();
    final afternoonSlots = slots
        .where((s) => s.period == SlotPeriod.afternoon)
        .toList();
    final eveningSlots = slots
        .where((s) => s.period == SlotPeriod.evening)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (morningSlots.isNotEmpty) ...[
            _buildPeriodHeader(
              'Morning',
              Icons.wb_sunny_outlined,
              morningSlots,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSlotGrid(morningSlots),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (afternoonSlots.isNotEmpty) ...[
            _buildPeriodHeader(
              'Afternoon',
              Icons.wb_cloudy_outlined,
              afternoonSlots,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSlotGrid(afternoonSlots),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (eveningSlots.isNotEmpty) ...[
            _buildPeriodHeader(
              'Evening',
              Icons.nights_stay_outlined,
              eveningSlots,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSlotGrid(eveningSlots),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodHeader(
    String title,
    IconData icon,
    List<TimeSlot> periodSlots,
  ) {
    final availableCount = periodSlots.where((s) => s.isAvailable).length;
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.teal700),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.navy900,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: availableCount > 0
                ? AppColors.teal50
                : AppColors.surfaceMuted,
            borderRadius: AppRadii.roundedPill,
          ),
          child: Text(
            '$availableCount open',
            style: AppTypography.labelSmall.copyWith(
              color: availableCount > 0
                  ? AppColors.teal700
                  : AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotGrid(List<TimeSlot> slotList) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Render 3 slots per row for optimal mobile touch targets
        final crossAxisCount = constraints.maxWidth > 500 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.2,
          ),
          itemCount: slotList.length,
          itemBuilder: (context, index) {
            final slot = slotList[index];
            final isSelected = selectedSlot == slot;
            final isAvailable = slot.isAvailable;

            return Semantics(
              button: true,
              selected: isSelected,
              enabled: isAvailable,
              label:
                  '${slot.time}, ${isAvailable ? (isSelected ? "Selected" : "Available") : "Unavailable: ${slot.unavailableReason ?? "Reserved"}"}',
              child: InkWell(
                onTap: isAvailable ? () => onSlotSelected(slot) : null,
                borderRadius: AppRadii.roundedMd,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.teal700
                        : (isAvailable
                              ? AppColors.surfaceCard
                              : AppColors.surfaceMuted.withValues(alpha: 0.6)),
                    borderRadius: AppRadii.roundedMd,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.teal700
                          : (isAvailable
                                ? AppColors.borderLight
                                : AppColors.borderLight.withValues(alpha: 0.5)),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.teal700.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          slot.time,
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected
                                ? Colors.white
                                : (isAvailable
                                      ? AppColors.navy900
                                      : AppColors.textTertiary),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : (isAvailable
                                      ? FontWeight.w600
                                      : FontWeight.w400),
                            decoration: isAvailable
                                ? null
                                : TextDecoration.lineThrough,
                            decorationColor: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        if (!isAvailable) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 11,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
