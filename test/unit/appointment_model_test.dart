import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';
import 'package:care_connect/features/appointments/domain/time_slot.dart';
import 'package:care_connect/features/appointments/domain/appointment_draft.dart';
import 'package:care_connect/features/appointments/domain/booking_exception.dart';

void main() {
  group('Appointment Model Unit Tests', () {
    test('Appointment creation with required and extended fields', () {
      final scheduled = DateTime(2026, 11, 20, 10, 30);
      final created = DateTime(2026, 11, 17, 9, 0);

      final appointment = Appointment(
        id: 'APT-1002',
        doctorId: 'doc_alistair_vance',
        doctorName: 'Dr. Alistair Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
        patientId: 'pat_sarah_jenkins_001',
        patientName: 'Sarah Jenkins',
        patientPhone: '+1 (555) 234-5678',
        scheduledDateTime: scheduled,
        timeSlot: '10:30 AM',
        status: AppointmentStatus.confirmed,
        modality: AppointmentModality.inPerson,
        fee: 140.0,
        createdAt: created,
      );

      expect(appointment.id, 'APT-1002');
      expect(appointment.doctorName, 'Dr. Alistair Vance');
      expect(appointment.doctorSpecialty, 'Cardiology');
      expect(appointment.clinicName, 'CareConnect Metropolitan Health Center');
      expect(appointment.patientName, 'Sarah Jenkins');
      expect(appointment.timeSlot, '10:30 AM');
      expect(appointment.fee, 140.0);
      expect(appointment.status, AppointmentStatus.confirmed);
      expect(appointment.isUpcoming, isTrue);
      expect(appointment.isPast, isFalse);
    });

    test('Appointment status lifecycle evaluation (isUpcoming vs isPast)', () {
      final confirmedApt = Appointment(
        id: 'apt_1',
        doctorId: 'doc_1',
        patientId: 'pat_1',
        patientName: 'Maya',
        patientPhone: '123',
        scheduledDateTime: DateTime(2026, 11, 20),
        timeSlot: '09:00 AM',
        status: AppointmentStatus.confirmed,
        fee: 100,
        clinicAddress: 'Clinic',
        createdAt: DateTime(2026, 11, 17),
      );
      expect(confirmedApt.isUpcoming, isTrue);
      expect(confirmedApt.isPast, isFalse);

      final pendingApt = Appointment(
        id: 'apt_2',
        doctorId: 'doc_1',
        patientId: 'pat_1',
        patientName: 'Maya',
        patientPhone: '123',
        scheduledDateTime: DateTime(2026, 11, 20),
        timeSlot: '09:00 AM',
        status: AppointmentStatus.pending,
        fee: 100,
        clinicAddress: 'Clinic',
        createdAt: DateTime(2026, 11, 17),
      );
      expect(pendingApt.isUpcoming, isTrue);
      expect(pendingApt.isPast, isFalse);

      final completedApt = Appointment(
        id: 'apt_3',
        doctorId: 'doc_1',
        patientId: 'pat_1',
        patientName: 'Maya',
        patientPhone: '123',
        scheduledDateTime: DateTime(2026, 11, 10),
        timeSlot: '09:00 AM',
        status: AppointmentStatus.completed,
        fee: 100,
        clinicAddress: 'Clinic',
        createdAt: DateTime(2026, 11, 10),
      );
      expect(completedApt.isUpcoming, isFalse);
      expect(completedApt.isPast, isTrue);

      final cancelledApt = Appointment(
        id: 'apt_4',
        doctorId: 'doc_1',
        patientId: 'pat_1',
        patientName: 'Maya',
        patientPhone: '123',
        scheduledDateTime: DateTime(2026, 11, 12),
        timeSlot: '09:00 AM',
        status: AppointmentStatus.cancelled,
        fee: 100,
        clinicAddress: 'Clinic',
        createdAt: DateTime(2026, 11, 10),
      );
      expect(cancelledApt.isUpcoming, isFalse);
      expect(cancelledApt.isPast, isTrue);
    });

    test('Appointment JSON serialization and deserialization roundtrip', () {
      final scheduled = DateTime(2026, 11, 25, 14, 0);
      final created = DateTime(2026, 11, 17, 8, 30);

      final appointment = Appointment(
        id: 'APT-9921',
        doctorId: 'doc_elena_rostova',
        doctorName: 'Dr. Elena Rostova',
        doctorSpecialty: 'Dermatology',
        clinicName: 'CareConnect Metro Dermatology',
        clinicAddress: 'West Pavilion, Suite 205, Boston, MA',
        patientId: 'pat_sarah_jenkins_001',
        patientName: 'Sarah Jenkins',
        patientPhone: '+1 (555) 234-5678',
        scheduledDateTime: scheduled,
        timeSlot: '02:00 PM',
        status: AppointmentStatus.confirmed,
        modality: AppointmentModality.video,
        fee: 125.0,
        patientNotes: 'Follow-up on skin consultation.',
        createdAt: created,
      );

      final json = appointment.toJson();
      expect(json['id'], 'APT-9921');
      expect(json['doctorName'], 'Dr. Elena Rostova');
      expect(json['doctorSpecialty'], 'Dermatology');
      expect(json['clinicName'], 'CareConnect Metro Dermatology');
      expect(json['status'], 'confirmed');
      expect(json['modality'], 'video');
      expect(json['fee'], 125.0);

      final restored = Appointment.fromJson(json);
      expect(restored.id, appointment.id);
      expect(restored.doctorName, appointment.doctorName);
      expect(restored.doctorSpecialty, appointment.doctorSpecialty);
      expect(restored.clinicName, appointment.clinicName);
      expect(restored.timeSlot, appointment.timeSlot);
      expect(restored.fee, appointment.fee);
      expect(restored.modality, appointment.modality);
      expect(restored.patientNotes, appointment.patientNotes);
      expect(restored.scheduledDateTime, appointment.scheduledDateTime);
    });

    test('Appointment copyWith creates modified clone correctly', () {
      final original = Appointment(
        id: 'APT-1',
        doctorId: 'doc_1',
        doctorName: 'Dr. Original',
        doctorSpecialty: 'Cardiology',
        clinicName: 'Clinic A',
        patientId: 'pat_1',
        patientName: 'Patient A',
        patientPhone: '111',
        scheduledDateTime: DateTime(2026, 11, 18),
        timeSlot: '10:00 AM',
        fee: 140,
        clinicAddress: 'Address',
        createdAt: DateTime(2026, 11, 17),
      );

      final modified = original.copyWith(
        timeSlot: '11:00 AM',
        status: AppointmentStatus.completed,
      );

      expect(modified.id, original.id);
      expect(modified.doctorName, original.doctorName);
      expect(modified.timeSlot, '11:00 AM');
      expect(modified.status, AppointmentStatus.completed);
    });
  });

  group('TimeSlot and Draft Model Unit Tests', () {
    test('TimeSlot properties, equality, and copyWith', () {
      final dt = DateTime(2026, 11, 18, 9, 30);
      final slot1 = TimeSlot(
        time: '09:30 AM',
        dateTime: dt,
        isAvailable: true,
        period: SlotPeriod.morning,
      );

      final slot2 = TimeSlot(
        time: '09:30 AM',
        dateTime: dt,
        isAvailable: true,
        period: SlotPeriod.morning,
      );

      expect(slot1, equals(slot2));
      expect(slot1.hashCode, equals(slot2.hashCode));

      final unavailableSlot = slot1.copyWith(
        isAvailable: false,
        unavailableReason: 'Reserved',
      );
      expect(unavailableSlot.isAvailable, isFalse);
      expect(unavailableSlot.unavailableReason, 'Reserved');
    });

    test('AppointmentDraft creation and copyWith', () {
      final draft = AppointmentDraft(
        doctorId: 'doc_marcus_vance',
        doctorName: 'Dr. Marcus Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metro',
        clinicAddress: 'East Pavilion',
        fee: 140.0,
        patientId: 'pat_1',
        patientName: 'Maya Sterling',
        patientPhone: '+1-555-0194',
        appointmentDate: DateTime(2026, 11, 20),
        timeSlot: '10:00 AM',
      );

      expect(draft.doctorId, 'doc_marcus_vance');
      expect(draft.doctorName, 'Dr. Marcus Vance');
      expect(draft.fee, 140.0);
      expect(draft.modality, AppointmentModality.inPerson);

      final updatedDraft = draft.copyWith(
        modality: AppointmentModality.video,
        patientNotes: 'Urgent checkup',
      );
      expect(updatedDraft.modality, AppointmentModality.video);
      expect(updatedDraft.patientNotes, 'Urgent checkup');
      expect(updatedDraft.timeSlot, '10:00 AM');
    });

    test('BookingException types contain descriptive messages and codes', () {
      const validationEx = BookingValidationException(
        'Cannot select past date',
      );
      expect(validationEx.message, 'Cannot select past date');
      expect(validationEx.code, 'VALIDATION_ERROR');
      expect(validationEx.toString(), 'Cannot select past date');

      const conflictEx = BookingConflictException('Slot already booked');
      expect(conflictEx.message, 'Slot already booked');
      expect(conflictEx.code, 'SLOT_CONFLICT');
    });
  });
}
