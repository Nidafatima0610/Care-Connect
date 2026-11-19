import 'package:flutter/foundation.dart';

/// Status lifecycle for patient bookings in CareConnect.
enum AppointmentStatus {
  pending('Pending Confirmation'),
  confirmed('Confirmed'),
  completed('Completed'),
  cancelled('Cancelled'),
  rescheduled('Rescheduled');

  const AppointmentStatus(this.displayName);
  final String displayName;
}

/// Clinical consultation modality.
enum AppointmentModality {
  inPerson('In-Person Visit'),
  video('Telehealth Video Visit');

  const AppointmentModality(this.displayName);
  final String displayName;
}

/// Foundation domain model for clinical appointments.
///
/// Established during Day 1 to anchor future booking engine workflows,
/// slot management, and reminder notifications scheduled for Days 2-5.
@immutable
class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String clinicName;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final DateTime scheduledDateTime;
  final String timeSlot; // e.g. "02:30 PM"
  final AppointmentStatus status;
  final AppointmentModality modality;
  final double fee;
  final String currency;
  final String clinicAddress;
  final String? patientNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? reminderMinutesBefore;
  final bool reminderScheduled;

  const Appointment({
    required this.id,
    required this.doctorId,
    this.doctorName = '',
    this.doctorSpecialty = '',
    this.clinicName = '',
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.scheduledDateTime,
    required this.timeSlot,
    this.status = AppointmentStatus.pending,
    this.modality = AppointmentModality.inPerson,
    required this.fee,
    this.currency = '\$',
    required this.clinicAddress,
    this.patientNotes,
    required this.createdAt,
    DateTime? updatedAt,
    this.reminderMinutesBefore = 30,
    this.reminderScheduled = false,
  }) : updatedAt = updatedAt ?? createdAt;

  bool get isUpcoming =>
      status == AppointmentStatus.confirmed ||
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.rescheduled;

  bool get isPast =>
      status == AppointmentStatus.completed ||
      status == AppointmentStatus.cancelled;

  bool get isCancellable =>
      isUpcoming &&
      status != AppointmentStatus.cancelled &&
      status != AppointmentStatus.completed;

  bool get isReschedulable =>
      isUpcoming &&
      status != AppointmentStatus.cancelled &&
      status != AppointmentStatus.completed;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String,
      doctorName: json['doctorName'] as String? ?? '',
      doctorSpecialty: json['doctorSpecialty'] as String? ?? '',
      clinicName: json['clinicName'] as String? ?? '',
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      patientPhone: json['patientPhone'] as String? ?? '',
      scheduledDateTime: DateTime.parse(json['scheduledDateTime'] as String),
      timeSlot: json['timeSlot'] as String,
      status: AppointmentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      modality: AppointmentModality.values.firstWhere(
        (m) => m.name == json['modality'],
        orElse: () => AppointmentModality.inPerson,
      ),
      fee: (json['fee'] as num).toDouble(),
      currency: json['currency'] as String? ?? '\$',
      clinicAddress: json['clinicAddress'] as String,
      patientNotes: json['patientNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : (json['createdAt'] != null
                ? DateTime.parse(json['createdAt'] as String)
                : DateTime.now()),
      reminderMinutesBefore:
          (json['reminderMinutesBefore'] as num?)?.toInt() ?? 30,
      reminderScheduled:
          json['reminderScheduled'] == 1 || json['reminderScheduled'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'clinicName': clinicName,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status.name,
      'modality': modality.name,
      'fee': fee,
      'currency': currency,
      'clinicAddress': clinicAddress,
      'patientNotes': patientNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reminderMinutesBefore': reminderMinutesBefore,
      'reminderScheduled': reminderScheduled ? 1 : 0,
    };
  }

  Appointment copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? clinicName,
    String? patientId,
    String? patientName,
    String? patientPhone,
    DateTime? scheduledDateTime,
    String? timeSlot,
    AppointmentStatus? status,
    AppointmentModality? modality,
    double? fee,
    String? currency,
    String? clinicAddress,
    String? patientNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? reminderMinutesBefore,
    bool? reminderScheduled,
  }) {
    return Appointment(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      clinicName: clinicName ?? this.clinicName,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      modality: modality ?? this.modality,
      fee: fee ?? this.fee,
      currency: currency ?? this.currency,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      patientNotes: patientNotes ?? this.patientNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      reminderScheduled: reminderScheduled ?? this.reminderScheduled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Appointment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
