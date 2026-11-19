import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:care_connect/features/appointments/data/appointment_database.dart';
import 'package:care_connect/features/appointments/data/appointment_repository_impl.dart';
import 'package:care_connect/features/appointments/data/notification_service.dart';
import 'package:care_connect/features/appointments/domain/appointment_draft.dart';
import 'package:care_connect/features/appointments/domain/booking_exception.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Appointment Cancellation Workflow & Business Rules Tests', () {
    late AppointmentDatabase db;
    late LocalNotificationServiceImpl notifService;
    late AppointmentRepositoryImpl repository;
    final fixedClock = DateTime(2026, 11, 18, 10, 0);

    setUp(() async {
      db = AppointmentDatabase.instance;
      await db.init(inMemory: true);
      await db.clearAll();

      notifService = LocalNotificationServiceImpl.instance;
      await notifService.initialize();
      await notifService.cancelAllReminders();

      repository = AppointmentRepositoryImpl(
        simulatedLatency: Duration.zero,
        clockTime: fixedClock,
        database: db,
        notificationService: notifService,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Upcoming appointment can be cancelled successfully', () async {
      final draft = AppointmentDraft(
        doctorId: 'doc_marcus_vance',
        doctorName: 'Dr. Marcus Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1 (617) 555-0194',
        appointmentDate: DateTime(2026, 11, 20),
        timeSlot: '10:00 AM',
        modality: AppointmentModality.inPerson,
        fee: 140.0,
      );

      final booked = await repository.createBooking(draft);
      expect(booked.status, AppointmentStatus.confirmed);
      expect(booked.isUpcoming, isTrue);

      // Cancel the appointment
      final cancelled = await repository.cancelAppointment(
        appointmentId: booked.id,
        cancellationReason: 'Work travel conflict',
      );

      expect(cancelled.id, booked.id);
      expect(cancelled.status, AppointmentStatus.cancelled);
      expect(cancelled.isPast, isTrue);
      expect(cancelled.isUpcoming, isFalse);
      expect(cancelled.patientNotes, contains('Work travel conflict'));

      // Verify persisted in SQLite
      final fromDb = await db.getAppointmentById(booked.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.status, AppointmentStatus.cancelled);
    });

    test(
      'Cancelled slot becomes available again for future bookings',
      () async {
        final appointmentDate = DateTime(2026, 11, 20);
        final draft1 = AppointmentDraft(
          doctorId: 'doc_marcus_vance',
          doctorName: 'Dr. Marcus Vance',
          doctorSpecialty: 'Cardiology',
          clinicName: 'CareConnect Metropolitan Health Center',
          clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
          patientId: 'pat_maya_01',
          patientName: 'Maya Sterling',
          patientPhone: '+1 (617) 555-0194',
          appointmentDate: appointmentDate,
          timeSlot: '02:00 PM',
          modality: AppointmentModality.inPerson,
          fee: 140.0,
        );

        final booked = await repository.createBooking(draft1);

        // Check slot availability: 02:00 PM should now be reserved
        var slots = await repository.getAvailableSlots(
          doctorId: 'doc_marcus_vance',
          date: appointmentDate,
        );
        var slot2pm = slots.firstWhere((s) => s.time == '02:00 PM');
        expect(slot2pm.isAvailable, isFalse);

        // Now cancel the booking
        await repository.cancelAppointment(appointmentId: booked.id);

        // Slot should immediately become available again
        slots = await repository.getAvailableSlots(
          doctorId: 'doc_marcus_vance',
          date: appointmentDate,
        );
        slot2pm = slots.firstWhere((s) => s.time == '02:00 PM');
        expect(slot2pm.isAvailable, isTrue);

        // Another patient should now be able to book this slot without conflict
        final draft2 = AppointmentDraft(
          doctorId: 'doc_marcus_vance',
          doctorName: 'Dr. Marcus Vance',
          doctorSpecialty: 'Cardiology',
          clinicName: 'CareConnect Metropolitan Health Center',
          clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
          patientId: 'pat_john_02',
          patientName: 'John Davis',
          patientPhone: '+1 (617) 555-0299',
          appointmentDate: appointmentDate,
          timeSlot: '02:00 PM',
          modality: AppointmentModality.inPerson,
          fee: 140.0,
        );

        final newBooking = await repository.createBooking(draft2);
        expect(newBooking.id, isNot(booked.id));
        expect(newBooking.status, AppointmentStatus.confirmed);
      },
    );

    test('Past appointment cannot be cancelled', () async {
      // Seed past appointment
      final pastApt = Appointment(
        id: 'APT-PAST-001',
        doctorId: 'doc_marcus_vance',
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1 555-0194',
        scheduledDateTime: fixedClock.subtract(const Duration(days: 3)),
        timeSlot: '09:00 AM',
        status: AppointmentStatus.completed,
        fee: 140.0,
        clinicAddress: 'East Pavilion, Suite 410',
        createdAt: fixedClock.subtract(const Duration(days: 5)),
      );
      await db.insertAppointment(pastApt);

      expect(
        () => repository.cancelAppointment(appointmentId: 'APT-PAST-001'),
        throwsA(
          isA<BookingValidationException>().having(
            (e) => e.message,
            'message',
            contains('Cannot cancel an appointment that has already passed'),
          ),
        ),
      );
    });

    test('Already cancelled appointment cannot be cancelled twice', () async {
      final draft = AppointmentDraft(
        doctorId: 'doc_marcus_vance',
        doctorName: 'Dr. Marcus Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'East Pavilion, Suite 410',
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1 555-0194',
        appointmentDate: DateTime(2026, 11, 20),
        timeSlot: '11:30 AM',
        fee: 140.0,
      );

      final booked = await repository.createBooking(draft);
      await repository.cancelAppointment(appointmentId: booked.id);

      // Attempting to cancel second time should throw BookingValidationException
      expect(
        () => repository.cancelAppointment(appointmentId: booked.id),
        throwsA(
          isA<BookingValidationException>().having(
            (e) => e.message,
            'message',
            contains('already been cancelled'),
          ),
        ),
      );
    });

    test(
      'Cancelling an appointment cancels associated reminder notification',
      () async {
        final draft = AppointmentDraft(
          doctorId: 'doc_marcus_vance',
          doctorName: 'Dr. Marcus Vance',
          doctorSpecialty: 'Cardiology',
          clinicName: 'CareConnect Metropolitan Health Center',
          clinicAddress: 'East Pavilion, Suite 410',
          patientId: 'pat_maya_01',
          patientName: 'Maya Sterling',
          patientPhone: '+1 555-0194',
          appointmentDate: DateTime(2026, 11, 20),
          timeSlot: '03:00 PM',
          fee: 140.0,
        );

        final booked = await repository.createBooking(draft);
        expect(notifService.scheduledReminders.containsKey(booked.id), isTrue);

        await repository.cancelAppointment(appointmentId: booked.id);
        expect(notifService.scheduledReminders.containsKey(booked.id), isFalse);
      },
    );
  });
}
