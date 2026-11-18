import 'package:flutter/material.dart';

import 'package:care_connect/core/theme/app_colors.dart';
import 'package:care_connect/core/theme/app_radii.dart';
import 'package:care_connect/core/theme/app_spacing.dart';
import 'package:care_connect/core/theme/app_typography.dart';

/// Horizontal calendar date strip allowing patients to pick an appointment date.
class DateSelectorStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int daysCount;
  final List<String>? doctorAvailableDays;

  const DateSelectorStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.daysCount = 14,
    this.doctorAvailableDays,
  });

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
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
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        itemCount: daysCount,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final date = today.add(Duration(days: index));
          final isSelected =
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          final weekdayName = _weekdays[date.weekday - 1];
          final monthName = _months[date.month - 1];
          final isSunday = date.weekday == DateTime.sunday;
          final isToday = index == 0;

          return Semantics(
            button: true,
            selected: isSelected,
            label:
                '$weekdayName, $monthName ${date.day}${isToday ? ", Today" : ""}',
            child: InkWell(
              onTap: isSunday ? null : () => onDateSelected(date),
              borderRadius: AppRadii.roundedMd,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.teal700
                      : (isSunday
                            ? AppColors.surfaceMuted.withValues(alpha: 0.5)
                            : AppColors.surfaceCard),
                  borderRadius: AppRadii.roundedMd,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.teal700
                        : (isToday
                              ? AppColors.teal700.withValues(alpha: 0.5)
                              : AppColors.borderLight),
                    width: isSelected || isToday ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.teal700.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isToday ? 'Today' : weekdayName,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : (isSunday
                                  ? AppColors.textTertiary
                                  : AppColors.textSecondary),
                        fontWeight: isSelected || isToday
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}',
                      style: AppTypography.titleMedium.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isSunday
                                  ? AppColors.textTertiary
                                  : AppColors.navy900),
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      monthName,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : (isSunday
                                  ? AppColors.textTertiary
                                  : AppColors.textTertiary),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
