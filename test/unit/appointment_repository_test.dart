import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/features/appointments/data/appointment_repository_impl.dart';
import 'package:care_connect/features/appointments/domain/appointment_draft.dart';
import 'package:care_connect/features/appointments/domain/appointment_repository.dart';
import 'package:care_connect/features/appointments/domain/booking_exception.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';

void main() {
  late AppointmentRepository repository;
  // Fixed simulated reference clock: Wednesday, Nov 18, 2026, 10:00 AM
  final fixedClock = DateTime(2026, 11, 18, 10, 0);

  setUp(() async {
    repository = AppointmentRepositoryImpl(
      simulatedLatency: Duration.zero,
      clockTime: fixedClock,
    );
    await repository.init();
    repository.reset();
  });

  group('AppointmentRepository - Slot Availability Tests', () {
    test('getAvailableSlots returns organized morning, afternoon, and evening slots', () async {
      // Future Friday: Nov 20, 2026
      final targetDate = DateTime(2026, 11, 20);
      final slots = await repository.getAvailableSlots(
        doctorId: 'doc_alistair_vance',
        date: targetDate,
      );

      expect(slots, isNotEmpty);
      expect(slots.any((s) => s.period.displayName == 'Morning'), isTrue);
      expect(slots.any((s) => s.period.displayName == 'Afternoon'), isTrue);
      expect(slots.any((s) => s.period.displayName == 'Evening'), isTrue);

      // Verify that available slots and unavailable/reserved slots are distinctly represented
      final hasAvailable = slots.any((s) => s.isAvailable);
      final hasUnavailable = slots.any((s) => !s.isAvailable);
      expect(hasAvailable, isTrue);
      expect(hasUnavailable, isTrue);
    });

    test('getAvailableSlots returns empty list for past dates', () async {
      // Past date: Nov 15, 2026 (clock is Nov 18, 2026)
      final pastDate = DateTime(2026, 11, 15);
      final slots = await repository.getAvailableSlots(
        doctorId: 'doc_alistair_vance',
        date: pastDate,
      );

      expect(slots, isEmpty);
    });

    test(
      'getAvailableSlots returns empty list on Sundays (clinic closed)',
      () async {
        // Sunday: Nov 22, 2026
        final sunday = DateTime(2026, 11, 22);
        final slots = await repository.getAvailableSlots(
          doctorId: 'doc_alistair_vance',
          date: sunday,
        );

        expect(slots, isEmpty);
      },
    );

    test(
      'getAvailableSlots marks past times on current date as unavailable',
      () async {
        // Current date: Wednesday, Nov 18, 2026, 10:00 AM
        final today = DateTime(2026, 11, 18);
        final slots = await repository.getAvailableSlots(
          doctorId: 'doc_alistair_vance',
          date: today,
        );

        // 09:00 AM and 09:30 AM should be marked unavailable (past time)
        final slot9am = slots.firstWhere((s) => s.time == '09:00 AM');
        expect(slot9am.isAvailable, isFalse);
        expect(slot9am.unavailableReason, 'Time has passed');

        // 02:00 PM should remain available
        final slot2pm = slots.firstWhere((s) => s.time == '02:00 PM');
        expect(slot2pm.isAvailable, isTrue);
      },
    );
  });

  group('AppointmentRepository - Booking Creation & Validation Tests', () {
    test(
      'createBooking successfully creates and registers an appointment',
      () async {
        final appointmentDate = DateTime(2026, 11, 20);
        final draft = AppointmentDraft(
          doctorId: 'doc_alistair_vance',
          doctorName: 'Dr. Alistair Vance',
          doctorSpecialty: 'Cardiology',
          clinicName: 'CareConnect Metropolitan Health Center',
          clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
          fee: 140.0,
          patientId: 'pat_maya_01',
          patientName: 'Maya Sterling',
          patientPhone: '+1-555-0194',
          appointmentDate: appointmentDate,
          timeSlot: '02:00 PM',
        );

        final appointment = await repository.createBooking(draft);

        expect(appointment.id, startsWith('APT-'));
        expect(appointment.doctorId, 'doc_alistair_vance');
        expect(appointment.doctorName, 'Dr. Alistair Vance');
        expect(appointment.patientName, 'Maya Sterling');
        expect(appointment.timeSlot, '02:00 PM');
        expect(appointment.status, AppointmentStatus.confirmed);
        expect(appointment.fee, 140.0);
      },
    );

    test('createBooking rejects past appointment dates with BookingValidationException', () async {
      final pastDate = DateTime(2026, 11, 15);
      final draft = AppointmentDraft(
        doctorId: 'doc_alistair_vance',
        doctorName: 'Dr. Alistair Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Center',
        clinicAddress: 'East Pavilion',
        fee: 140.0,
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1-555-0194',
        appointmentDate: pastDate,
        timeSlot: '10:00 AM',
      );

      expect(
        () => repository.createBooking(draft),
        throwsA(isA<BookingValidationException>()),
      );
    });

    test('createBooking rejects past time slots on current date with BookingValidationException', () async {
      // Clock is 10:00 AM on Nov 18, 2026; attempt to book 09:00 AM
      final today = DateTime(2026, 11, 18);
      final draft = AppointmentDraft(
        doctorId: 'doc_alistair_vance',
        doctorName: 'Dr. Alistair Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Center',
        clinicAddress: 'East Pavilion',
        fee: 140.0,
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1-555-0194',
        appointmentDate: today,
        timeSlot: '09:00 AM',
      );

      expect(
        () => repository.createBooking(draft),
        throwsA(
          predicate(
            (e) =>
                e is BookingValidationException &&
                e.message.contains('already passed'),
          ),
        ),
      );
    });

    test('createBooking rejects incomplete or missing data with BookingValidationException', () async {
      final validDate = DateTime(2026, 11, 20);

      // Missing doctor ID
      expect(
        () => repository.createBooking(
          AppointmentDraft(
            doctorId: '',
            doctorName: 'Doctor',
            doctorSpecialty: 'Specialty',
            clinicName: 'Clinic',
            clinicAddress: 'Address',
            fee: 100,
            patientId: 'pat_1',
            patientName: 'Patient',
            patientPhone: '123',
            appointmentDate: validDate,
            timeSlot: '02:00 PM',
          ),
        ),
        throwsA(isA<BookingValidationException>()),
      );

      // Missing patient name
      expect(
        () => repository.createBooking(
          AppointmentDraft(
            doctorId: 'doc_1',
            doctorName: 'Doctor',
            doctorSpecialty: 'Specialty',
            clinicName: 'Clinic',
            clinicAddress: 'Address',
            fee: 100,
            patientId: 'pat_1',
            patientName: '',
            patientPhone: '123',
            appointmentDate: validDate,
            timeSlot: '02:00 PM',
          ),
        ),
        throwsA(isA<BookingValidationException>()),
      );

      // Missing time slot
      expect(
        () => repository.createBooking(
          AppointmentDraft(
            doctorId: 'doc_1',
            doctorName: 'Doctor',
            doctorSpecialty: 'Specialty',
            clinicName: 'Clinic',
            clinicAddress: 'Address',
            fee: 100,
            patientId: 'pat_1',
            patientName: 'Patient',
            patientPhone: '123',
            appointmentDate: validDate,
            timeSlot: '',
          ),
        ),
        throwsA(isA<BookingValidationException>()),
      );
    });

    test('createBooking rejects duplicate booking by same patient with BookingConflictException', () async {
      final targetDate = DateTime(2026, 11, 20);
      final draft = AppointmentDraft(
        doctorId: 'doc_alistair_vance',
        doctorName: 'Dr. Alistair Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'East Pavilion',
        fee: 140.0,
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1-555-0194',
        appointmentDate: targetDate,
        timeSlot: '02:00 PM',
      );

      // First booking succeeds
      final first = await repository.createBooking(draft);
      expect(first, isNotNull);

      // Same patient attempts identical booking again
      expect(
        repository.createBooking(draft),
        throwsA(
          predicate(
            (e) =>
                e is BookingConflictException &&
                e.message.contains('already have a confirmed appointment'),
          ),
        ),
      );
    });

    test('createBooking rejects conflict when two patients compete for the same slot', () async {
      final targetDate = DateTime(2026, 11, 20);

      // Patient A books 02:00 PM with Dr. Alistair Vance
      final draftPatientA = AppointmentDraft(
        doctorId: 'doc_alistair_vance',
        doctorName: 'Dr. Alistair Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Center',
        clinicAddress: 'East Pavilion',
        fee: 140.0,
        patientId: 'pat_patient_A',
        patientName: 'Patient Alpha',
        patientPhone: '+1-555-0001',
        appointmentDate: targetDate,
        timeSlot: '02:00 PM',
      );

      // Patient B attempts to book the same slot
      final draftPatientB = AppointmentDraft(
        doctorId: 'doc_alistair_vance',
        doctorName: 'Dr. Alistair Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Center',
        clinicAddress: 'East Pavilion',
        fee: 140.0,
        patientId: 'pat_patient_B',
        patientName: 'Patient Beta',
        patientPhone: '+1-555-0002',
        appointmentDate: targetDate,
        timeSlot: '02:00 PM',
      );

      // Patient A booking succeeds
      final bookingA = await repository.createBooking(draftPatientA);
      expect(bookingA.id, isNotEmpty);

      // Patient B booking fails with conflict error
      expect(
        repository.createBooking(draftPatientB),
        throwsA(
          predicate(
            (e) =>
                e is BookingConflictException &&
                e.message.contains('no longer available'),
          ),
        ),
      );
    });

    test('successful booking updates slot availability in subsequent getAvailableSlots', () async {
      final targetDate = DateTime(2026, 11, 20);

      // Check slot is initially available
      final slotsBefore = await repository.getAvailableSlots(
        doctorId: 'doc_alistair_vance',
        date: targetDate,
      );
      final slot2pmBefore = slotsBefore.firstWhere((s) => s.time == '02:00 PM');
      expect(slot2pmBefore.isAvailable, isTrue);

      // Book the 02:00 PM slot
      await repository.createBooking(
        AppointmentDraft(
          doctorId: 'doc_alistair_vance',
          doctorName: 'Dr. Alistair Vance',
          doctorSpecialty: 'Cardiology',
          clinicName: 'CareConnect Center',
          clinicAddress: 'East Pavilion',
          fee: 140.0,
          patientId: 'pat_patient_C',
          patientName: 'Patient Charlie',
          patientPhone: '+1-555-0003',
          appointmentDate: targetDate,
          timeSlot: '02:00 PM',
        ),
      );

      // Check slot is now unavailable in refreshed slots list
      final slotsAfter = await repository.getAvailableSlots(
        doctorId: 'doc_alistair_vance',
        date: targetDate,
      );
      final slot2pmAfter = slotsAfter.firstWhere((s) => s.time == '02:00 PM');
      expect(slot2pmAfter.isAvailable, isFalse);
      expect(slot2pmAfter.unavailableReason, 'Reserved');
    });
  });

  group('AppointmentRepository - Appointment History Retrieval Tests', () {
    test(
      'getPatientAppointments returns both upcoming and past appointments',
      () async {
        final history = await repository.getPatientAppointments(
          patientId: 'pat_sarah_jenkins_001',
        );

        expect(history, isNotEmpty);
        expect(history.any((a) => a.isUpcoming), isTrue);
        expect(history.any((a) => a.isPast), isTrue);
      },
    );

    test(
      'newly booked appointment appears in patient history immediately',
      () async {
        final targetDate = DateTime(2026, 11, 25);
        final draft = AppointmentDraft(
          doctorId: 'doc_marcus_vance',
          doctorName: 'Dr. Marcus Vance',
          doctorSpecialty: 'Cardiology',
          clinicName: 'CareConnect Metro',
          clinicAddress: 'East Pavilion',
          fee: 140.0,
          patientId: 'pat_sarah_jenkins_001',
          patientName: 'Maya Sterling',
          patientPhone: '+1-555-0194',
          appointmentDate: targetDate,
          timeSlot: '04:00 PM',
        );

        final newApt = await repository.createBooking(draft);

        final updatedHistory = await repository.getPatientAppointments(
          patientId: 'pat_sarah_jenkins_001',
        );

        expect(updatedHistory.any((a) => a.id == newApt.id), isTrue);
      },
    );

    test('getAppointmentById returns correct appointment or null', () async {
      final existing = await repository.getAppointmentById('APT-849201');
      expect(existing, isNotNull);
      expect(existing?.doctorId, 'doc_marcus_vance');

      final nonExistent = await repository.getAppointmentById('APT-UNKNOWN');
      expect(nonExistent, isNull);
    });
  });
}
