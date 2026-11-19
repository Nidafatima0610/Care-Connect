import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:care_connect/features/appointments/data/appointment_database.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AppointmentDatabase Persistent Storage Tests', () {
    late AppointmentDatabase db;

    setUp(() async {
      db = AppointmentDatabase.instance;
      await db.init(inMemory: true);
      await db.clearAll();
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Database initializes successfully and creates appointments table',
      () async {
        expect(db.isInitialized, isTrue);
        final appointments = await db.getAllAppointments();
        expect(appointments, isEmpty);
      },
    );

    test(
      'seedInitialDataIfEmpty populates default Day 3 appointments',
      () async {
        final now = DateTime(2026, 11, 18, 10, 0);
        await db.seedInitialDataIfEmpty(now: now);

        final appointments = await db.getAllAppointments();
        expect(appointments.length, 2);

        final upcoming = appointments.firstWhere((a) => a.id == 'APT-849201');
        expect(upcoming.doctorName, 'Dr. Marcus Vance');
        expect(upcoming.status, AppointmentStatus.confirmed);
        expect(upcoming.isUpcoming, isTrue);

        final past = appointments.firstWhere((a) => a.id == 'APT-849105');
        expect(past.doctorName, 'Dr. Elena Rostova');
        expect(past.status, AppointmentStatus.completed);
        expect(past.isPast, isTrue);
      },
    );

    test('Appointment can be inserted and retrieved by ID', () async {
      final now = DateTime(2026, 11, 18, 10, 0);
      final appointment = Appointment(
        id: 'APT-TEST-001',
        doctorId: 'doc_marcus_vance',
        doctorName: 'Dr. Marcus Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1 555-0194',
        scheduledDateTime: DateTime(2026, 11, 20, 14, 30),
        timeSlot: '02:30 PM',
        status: AppointmentStatus.confirmed,
        modality: AppointmentModality.inPerson,
        fee: 140.0,
        createdAt: now,
        updatedAt: now,
        reminderScheduled: true,
        reminderMinutesBefore: 30,
      );

      await db.insertAppointment(appointment);

      final retrieved = await db.getAppointmentById('APT-TEST-001');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'APT-TEST-001');
      expect(retrieved.doctorName, 'Dr. Marcus Vance');
      expect(retrieved.patientName, 'Maya Sterling');
      expect(retrieved.fee, 140.0);
      expect(retrieved.timeSlot, '02:30 PM');
      expect(retrieved.reminderScheduled, isTrue);
      expect(retrieved.reminderMinutesBefore, 30);
    });

    test('Appointment update persists modifications correctly', () async {
      final now = DateTime(2026, 11, 18, 10, 0);
      final appointment = Appointment(
        id: 'APT-TEST-002',
        doctorId: 'doc_elena_rostova',
        doctorName: 'Dr. Elena Rostova',
        doctorSpecialty: 'Dermatology',
        clinicName: 'CareConnect Metro Dermatology',
        clinicAddress: 'West Pavilion, Suite 205, Boston, MA',
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1 555-0194',
        scheduledDateTime: DateTime(2026, 11, 20, 10, 0),
        timeSlot: '10:00 AM',
        status: AppointmentStatus.confirmed,
        modality: AppointmentModality.inPerson,
        fee: 125.0,
        createdAt: now,
        updatedAt: now,
      );

      await db.insertAppointment(appointment);

      // Update to cancelled with new updatedAt timestamp
      final later = now.add(const Duration(hours: 2));
      final updated = appointment.copyWith(
        status: AppointmentStatus.cancelled,
        updatedAt: later,
        patientNotes: 'Cancelled by patient due to conflict',
      );

      final rowsAffected = await db.updateAppointment(updated);
      expect(rowsAffected, 1);

      final refreshed = await db.getAppointmentById('APT-TEST-002');
      expect(refreshed, isNotNull);
      expect(refreshed!.status, AppointmentStatus.cancelled);
      expect(refreshed.isPast, isTrue);
      expect(refreshed.isUpcoming, isFalse);
      expect(refreshed.patientNotes, 'Cancelled by patient due to conflict');
      expect(refreshed.updatedAt, later);
    });

    test(
      'Appointment survives database reopening (simulated app restart)',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('cc_db_test_');
        final dbFilePath = '${tempDir.path}/careconnect_test.db';

        // Phase 1: Open, insert appointment, and close
        final dbInstance = AppointmentDatabase.createIsolated();
        await dbInstance.init(dbPath: dbFilePath, force: true);
        await dbInstance.clearAll();

        final now = DateTime(2026, 11, 18, 10, 0);
        final apt = Appointment(
          id: 'APT-PERSIST-999',
          doctorId: 'doc_marcus_vance',
          patientId: 'pat_maya_01',
          patientName: 'Maya Sterling',
          patientPhone: '+1 555-0194',
          scheduledDateTime: DateTime(2026, 11, 25, 9, 30),
          timeSlot: '09:30 AM',
          status: AppointmentStatus.confirmed,
          fee: 140.0,
          clinicAddress: 'East Pavilion, Suite 410',
          createdAt: now,
        );

        await dbInstance.insertAppointment(apt);
        await dbInstance.close();

        // Phase 2: Reopen from disk (simulating cold app launch)
        await dbInstance.init(dbPath: dbFilePath, force: true);
        final restored = await dbInstance.getAppointmentById('APT-PERSIST-999');

        expect(restored, isNotNull);
        expect(restored!.id, 'APT-PERSIST-999');
        expect(restored.timeSlot, '09:30 AM');
        expect(restored.status, AppointmentStatus.confirmed);

        await dbInstance.close();
        await tempDir.delete(recursive: true);
      },
    );

    test('Appointment deletion removes record correctly', () async {
      final now = DateTime(2026, 11, 18, 10, 0);
      final appointment = Appointment(
        id: 'APT-DELETE-001',
        doctorId: 'doc_marcus_vance',
        patientId: 'pat_maya_01',
        patientName: 'Maya Sterling',
        patientPhone: '+1 555-0194',
        scheduledDateTime: DateTime(2026, 11, 20, 10, 0),
        timeSlot: '10:00 AM',
        status: AppointmentStatus.confirmed,
        fee: 140.0,
        clinicAddress: 'East Pavilion, Suite 410',
        createdAt: now,
      );

      await db.insertAppointment(appointment);
      expect(await db.getAppointmentById('APT-DELETE-001'), isNotNull);

      await db.deleteAppointment('APT-DELETE-001');
      expect(await db.getAppointmentById('APT-DELETE-001'), isNull);
    });
  });
}
