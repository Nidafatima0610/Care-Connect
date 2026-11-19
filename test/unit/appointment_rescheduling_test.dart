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

  group('Appointment Rescheduling Workflow & Business Rules Tests', () {
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

    test(
      'Upcoming appointment can be rescheduled to a new future date & slot',
      () async {
        final initialDate = DateTime(2026, 11, 20); // Friday
        final newDate = DateTime(2026, 11, 24); // Tuesday

        final draft = AppointmentDraft(
          doctorId: 'doc_marcus_vance',
          doctorName: 'Dr. Marcus Vance',
          doctorSpecialty: 'Cardiology',
          clinicName: 'CareConnect Metropolitan Health Center',
          clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
          patientId: 'pat_maya_01',
          patientName: 'Maya Sterling',
          patientPhone: '+1 (617) 555-0194',
          appointmentDate: initialDate,
          timeSlot: '10:00 AM',
          modality: AppointmentModality.inPerson,
          fee: 140.0,
        );

        final original = await repository.createBooking(draft);
        final originalId = original.id;
        final originalCreatedAt = original.createdAt;

        // Reschedule to Nov 24 at 02:30 PM
        final rescheduled = await repository.rescheduleAppointment(
          appointmentId: originalId,
          newDate: newDate,
          newTimeSlot: '02:30 PM',
        );

        // Verify ID and createdAt remain unchanged
        expect(rescheduled.id, originalId);
        expect(rescheduled.createdAt, originalCreatedAt);

        // Verify updated schedule details
        expect(rescheduled.timeSlot, '02:30 PM');
        expect(rescheduled.scheduledDateTime.year, newDate.year);
        expect(rescheduled.scheduledDateTime.month, newDate.month);
        expect(rescheduled.scheduledDateTime.day, newDate.day);
        expect(rescheduled.status, AppointmentStatus.confirmed);
        expect(
          rescheduled.updatedAt.isAfter(originalCreatedAt) ||
              rescheduled.updatedAt.isAtSameMomentAs(fixedClock),
          isTrue,
        );

        // Verify saved in SQLite database
        final fromDb = await db.getAppointmentById(originalId);
        expect(fromDb, isNotNull);
        expect(fromDb!.timeSlot, '02:30 PM');
        expect(fromDb.scheduledDateTime.day, 24);
      },
    );

    test(
      'Old slot is released and new slot is reserved upon rescheduling',
      () async {
        final date1 = DateTime(2026, 11, 20);
        final date2 = DateTime(2026, 11, 24);

        final draft = AppointmentDraft(
          doctorId: 'doc_marcus_vance',
          doctorName: 'Dr. Marcus Vance',
          doctorSpecialty: 'Cardiology',
          clinicName: 'CareConnect Metropolitan Health Center',
          clinicAddress: 'East Pavilion, Suite 410',
          patientId: 'pat_maya_01',
          patientName: 'Maya Sterling',
          patientPhone: '+1 555-0194',
          appointmentDate: date1,
          timeSlot: '09:00 AM',
          fee: 140.0,
        );

        final apt = await repository.createBooking(draft);

        // Date 1, 09:00 AM is reserved; Date 2, 09:30 AM is available
        var slotsDate1 = await repository.getAvailableSlots(
          doctorId: 'doc_marcus_vance',
          date: date1,
        );
        expect(
          slotsDate1.firstWhere((s) => s.time == '09:00 AM').isAvailable,
          isFalse,
        );

        // Reschedule to Date 2 at 09:30 AM
        await repository.rescheduleAppointment(
          appointmentId: apt.id,
          newDate: date2,
          newTimeSlot: '09:30 AM',
        );

        // Date 1, 09:00 AM should now be released (available)
        slotsDate1 = await repository.getAvailableSlots(
          doctorId: 'doc_marcus_vance',
          date: date1,
        );
        expect(
          slotsDate1.firstWhere((s) => s.time == '09:00 AM').isAvailable,
          isTrue,
        );

        // Date 2, 09:30 AM should now be reserved (unavailable)
        final slotsDate2 = await repository.getAvailableSlots(
          doctorId: 'doc_marcus_vance',
          date: date2,
        );
        expect(
          slotsDate2.firstWhere((s) => s.time == '09:30 AM').isAvailable,
          isFalse,
        );
      },
    );

    test('Rescheduling rejects past dates and past times', () async {
      final initialDate = DateTime(2026, 11, 20);
      final draft = AppointmentDraft(
        doctorId: 'doc_marcus_vance',
        doctorName: 'Dr. Marcus Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'East Pavilion, Suite 410',
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1 555-0194',
        appointmentDate: initialDate,
        timeSlot: '10:00 AM',
        fee: 140.0,
      );

      final apt = await repository.createBooking(draft);

      // Rejects past date (Nov 15)
      expect(
        () => repository.rescheduleAppointment(
          appointmentId: apt.id,
          newDate: DateTime(2026, 11, 15),
          newTimeSlot: '10:00 AM',
        ),
        throwsA(
          isA<BookingValidationException>().having(
            (e) => e.message,
            'message',
            contains('past date'),
          ),
        ),
      );

      // Rejects past time on current date (09:00 AM on Nov 18, reference clock is 10:00 AM)
      expect(
        () => repository.rescheduleAppointment(
          appointmentId: apt.id,
          newDate: DateTime(2026, 11, 18),
          newTimeSlot: '09:00 AM',
        ),
        throwsA(
          isA<BookingValidationException>().having(
            (e) => e.message,
            'message',
            contains('passed'),
          ),
        ),
      );
    });

    test('Rescheduling rejects conflicting slots and preserves original appointment', () async {
      final date = DateTime(2026, 11, 20);

      // Patient A books 02:00 PM
      final draftA = AppointmentDraft(
        doctorId: 'doc_marcus_vance',
        doctorName: 'Dr. Marcus Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'East Pavilion, Suite 410',
        patientId: 'pat_patient_a',
        patientName: 'Patient A',
        patientPhone: '+1 555-0001',
        appointmentDate: date,
        timeSlot: '02:00 PM',
        fee: 140.0,
      );
      final aptA = await repository.createBooking(draftA);
      expect(aptA.status, AppointmentStatus.confirmed);

      // Patient B books 04:00 PM
      final draftB = AppointmentDraft(
        doctorId: 'doc_marcus_vance',
        doctorName: 'Dr. Marcus Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'East Pavilion, Suite 410',
        patientId: 'pat_patient_b',
        patientName: 'Patient B',
        patientPhone: '+1 555-0002',
        appointmentDate: date,
        timeSlot: '04:00 PM',
        fee: 140.0,
      );
      final aptB = await repository.createBooking(draftB);

      // Patient B tries to reschedule into 02:00 PM (which Patient A holds)
      expect(
        () => repository.rescheduleAppointment(
          appointmentId: aptB.id,
          newDate: date,
          newTimeSlot: '02:00 PM',
        ),
        throwsA(isA<BookingConflictException>()),
      );

      // Verify Patient B's appointment is preserved unmodified at 04:00 PM
      final originalB = await repository.getAppointmentById(aptB.id);
      expect(originalB, isNotNull);
      expect(originalB!.timeSlot, '04:00 PM');
    });

    test('Rescheduling updates reminder notification time', () async {
      final initialDate = DateTime(2026, 11, 20);
      final newDate = DateTime(2026, 11, 25);

      final draft = AppointmentDraft(
        doctorId: 'doc_marcus_vance',
        doctorName: 'Dr. Marcus Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'East Pavilion, Suite 410',
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1 555-0194',
        appointmentDate: initialDate,
        timeSlot: '10:00 AM',
        fee: 140.0,
      );

      final apt = await repository.createBooking(draft);
      final initialReminderTime = notifService.scheduledReminders[apt.id];
      expect(initialReminderTime, isNotNull);

      // Reschedule to Nov 25 at 03:00 PM
      await repository.rescheduleAppointment(
        appointmentId: apt.id,
        newDate: newDate,
        newTimeSlot: '03:00 PM',
      );

      final updatedReminderTime = notifService.scheduledReminders[apt.id];
      expect(updatedReminderTime, isNotNull);
      expect(updatedReminderTime!.day, 25);
      expect(updatedReminderTime.hour, 14); // 30 minutes before 15:00 is 14:30
      expect(updatedReminderTime.minute, 30);
    });
  });
}
