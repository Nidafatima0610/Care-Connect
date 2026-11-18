import 'package:flutter/foundation.dart';

import '../../doctors/domain/appointment.dart';

/// Value object representing a draft booking request before validation and persistence.
@immutable
class AppointmentDraft {
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String clinicName;
  final String clinicAddress;
  final double fee;
  final String currency;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final DateTime appointmentDate;
  final String timeSlot;
  final AppointmentModality modality;
  final String? patientNotes;

  const AppointmentDraft({
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.clinicName,
    required this.clinicAddress,
    required this.fee,
    this.currency = '\$',
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.appointmentDate,
    required this.timeSlot,
    this.modality = AppointmentModality.inPerson,
    this.patientNotes,
  });

  AppointmentDraft copyWith({
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? clinicName,
    String? clinicAddress,
    double? fee,
    String? currency,
    String? patientId,
    String? patientName,
    String? patientPhone,
    DateTime? appointmentDate,
    String? timeSlot,
    AppointmentModality? modality,
    String? patientNotes,
  }) {
    return AppointmentDraft(
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      fee: fee ?? this.fee,
      currency: currency ?? this.currency,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      modality: modality ?? this.modality,
      patientNotes: patientNotes ?? this.patientNotes,
    );
  }
}
