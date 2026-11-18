import 'package:flutter/foundation.dart';

/// Period of the day for categorized slot organization.
enum SlotPeriod {
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening');

  const SlotPeriod(this.displayName);
  final String displayName;
}

/// Domain model representing a doctor's clinical appointment slot.
@immutable
class TimeSlot {
  final String time; // e.g., "09:30 AM"
  final DateTime dateTime; // Specific appointment timestamp
  final bool isAvailable;
  final SlotPeriod period;
  final String? unavailableReason; // e.g., "Reserved", "Past time"

  const TimeSlot({
    required this.time,
    required this.dateTime,
    this.isAvailable = true,
    required this.period,
    this.unavailableReason,
  });

  TimeSlot copyWith({
    String? time,
    DateTime? dateTime,
    bool? isAvailable,
    SlotPeriod? period,
    String? unavailableReason,
  }) {
    return TimeSlot(
      time: time ?? this.time,
      dateTime: dateTime ?? this.dateTime,
      isAvailable: isAvailable ?? this.isAvailable,
      period: period ?? this.period,
      unavailableReason: unavailableReason ?? this.unavailableReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          time == other.time &&
          dateTime == other.dateTime &&
          isAvailable == other.isAvailable;

  @override
  int get hashCode => Object.hash(time, dateTime, isAvailable);

  @override
  String toString() => 'TimeSlot($time, available: $isAvailable)';
}
