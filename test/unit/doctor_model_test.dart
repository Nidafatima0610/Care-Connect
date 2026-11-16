import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/features/doctors/domain/doctor.dart';
import 'package:care_connect/features/doctors/domain/doctor_specialty.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';

void main() {
  group('Doctor Model Tests', () {
    test('Doctor JSON serialization and deserialization roundtrip', () {
      const doctor = Doctor(
        id: 'doc_test_1',
        name: 'Dr. Test Physician',
        title: 'MD',
        specialty: DoctorSpecialty.cardiology,
        subSpecialty: 'Cardiovascular Health',
        experienceYears: 10,
        rating: 4.9,
        reviewCount: 150,
        consultationFee: 120.0,
        currency: '\$',
        biography: 'Experienced cardiologist testing clinical systems.',
        qualifications: ['MD - Harvard', 'Board Certified Cardiology'],
        clinicName: 'CareConnect Test Clinic',
        clinicAddress: '100 Medical Way, Boston, MA',
        availabilitySummary: 'Next Available: Tomorrow, 2:00 PM',
        availableDays: ['Mon', 'Wed', 'Fri'],
        workingHours: '09:00 AM - 05:00 PM',
        avatarUrl: 'https://example.com/avatar.jpg',
        isFeatured: true,
        isAcceptingNewPatients: true,
        languages: ['English', 'Spanish'],
        patientsCount: 1200,
        hasVideoConsultation: true,
        hasInPersonConsultation: true,
      );

      final json = doctor.toJson();
      expect(json['id'], 'doc_test_1');
      expect(json['specialty'], 'cardiology');
      expect(json['rating'], 4.9);
      expect(json['isFeatured'], true);

      final parsed = Doctor.fromJson(json);
      expect(parsed.id, doctor.id);
      expect(parsed.name, doctor.name);
      expect(parsed.specialty, DoctorSpecialty.cardiology);
      expect(parsed.consultationFee, 120.0);
      expect(parsed.qualifications.length, 2);
      expect(parsed.languages, contains('Spanish'));
      expect(parsed, equals(doctor));
    });

    test('Doctor copyWith creates correct modified instance', () {
      const doctor = Doctor(
        id: 'doc_1',
        name: 'Dr. Alpha',
        title: 'MD',
        specialty: DoctorSpecialty.pediatrics,
        subSpecialty: 'General Pediatrics',
        experienceYears: 5,
        rating: 4.7,
        reviewCount: 80,
        consultationFee: 90.0,
        biography: 'Bio text',
        qualifications: ['Degree 1'],
        clinicName: 'Clinic A',
        clinicAddress: 'Address A',
        availabilitySummary: 'Available Today',
        availableDays: ['Mon'],
        workingHours: '9am - 5pm',
        languages: ['English'],
        patientsCount: 500,
      );

      final modified = doctor.copyWith(
        name: 'Dr. Alpha Beta',
        experienceYears: 6,
        rating: 4.8,
      );

      expect(modified.name, 'Dr. Alpha Beta');
      expect(modified.experienceYears, 6);
      expect(modified.rating, 4.8);
      expect(modified.id, doctor.id);
      expect(modified.specialty, doctor.specialty);
    });

    test('DoctorSpecialty fromString resolves correctly', () {
      expect(
        DoctorSpecialty.fromString('cardiology'),
        DoctorSpecialty.cardiology,
      );
      expect(
        DoctorSpecialty.fromString('Cardiology'),
        DoctorSpecialty.cardiology,
      );
      expect(
        DoctorSpecialty.fromString('dermatology'),
        DoctorSpecialty.dermatology,
      );
      expect(
        DoctorSpecialty.fromString('unknown_specialty'),
        DoctorSpecialty.generalMedicine,
      );
    });
  });

  group('Appointment Model Foundation Tests', () {
    test('Appointment serialization and deserialization', () {
      final now = DateTime(2026, 11, 16, 14, 30);
      final created = DateTime(2026, 11, 16, 10, 0);

      final appointment = Appointment(
        id: 'apt_1001',
        doctorId: 'doc_alistair_vance',
        patientId: 'pat_maya_sterling',
        patientName: 'Maya Sterling',
        patientPhone: '+1-555-0192',
        scheduledDateTime: now,
        timeSlot: '02:30 PM',
        status: AppointmentStatus.confirmed,
        modality: AppointmentModality.inPerson,
        fee: 140.0,
        clinicAddress: 'East Pavilion, Suite 410, Boston',
        patientNotes: 'Routine cardiology consultation and BP check.',
        createdAt: created,
      );

      final json = appointment.toJson();
      expect(json['id'], 'apt_1001');
      expect(json['status'], 'confirmed');
      expect(json['modality'], 'inPerson');

      final parsed = Appointment.fromJson(json);
      expect(parsed.id, 'apt_1001');
      expect(parsed.doctorId, 'doc_alistair_vance');
      expect(parsed.patientName, 'Maya Sterling');
      expect(parsed.status, AppointmentStatus.confirmed);
      expect(parsed.modality, AppointmentModality.inPerson);
      expect(parsed.fee, 140.0);
    });
  });
}

