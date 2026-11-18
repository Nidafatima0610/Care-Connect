import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/features/appointments/data/appointment_repository_impl.dart';
import 'package:care_connect/features/appointments/domain/appointment_repository.dart';
import 'package:care_connect/features/appointments/domain/time_slot.dart';
import 'package:care_connect/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';
import 'package:care_connect/features/doctors/domain/doctor.dart';
import 'package:care_connect/features/doctors/domain/doctor_specialty.dart';
import 'package:care_connect/features/patient/domain/patient.dart';

void main() {
  late ProviderContainer container;
  late AppointmentRepository mockRepository;
  final fixedClock = DateTime(2026, 11, 18, 10, 0);

  const testDoctor = Doctor(
    id: 'doc_alistair_vance',
    name: 'Dr. Alistair Vance',
    title: 'MD, FACC',
    specialty: DoctorSpecialty.cardiology,
    subSpecialty: 'Cardiovascular Disease',
    experienceYears: 14,
    rating: 4.9,
    reviewCount: 312,
    consultationFee: 140.0,
    biography: 'Cardiology specialist.',
    qualifications: ['MD'],
    clinicName: 'CareConnect Metropolitan Health Center',
    clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
    availabilitySummary: 'Mon - Fri',
    availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    workingHours: '9:00 AM - 5:30 PM',
    languages: ['English'],
    patientsCount: 1850,
  );

  final testPatient = Patient(
    id: 'pat_test_01',
    fullName: 'Maya Sterling',
    email: 'maya.sterling@careconnect.health',
    phoneNumber: '+1 (617) 555-0194',
    preferredClinic: 'CareConnect Metropolitan Health Center',
    createdAt: DateTime(2026, 11, 16),
    updatedAt: DateTime(2026, 11, 16),
  );

  setUp(() {
    mockRepository = AppointmentRepositoryImpl(
      simulatedLatency: Duration.zero,
      clockTime: fixedClock,
    );

    container = ProviderContainer(
      overrides: [
        appointmentRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('BookingNotifier State & Controller Tests', () {
    test('Initial BookingState sets default future date and null slot', () {
      final state = container.read(bookingControllerProvider);
      expect(state.selectedDate, isNotNull);
      expect(state.selectedSlot, isNull);
      expect(state.isSubmitting, isFalse);
      expect(state.validationError, isNull);
      expect(state.conflictError, isNull);
    });

    test('init sets doctor ID and resets date', () {
      final notifier = container.read(bookingControllerProvider.notifier);
      notifier.init('doc_alistair_vance');

      final state = container.read(bookingControllerProvider);
      expect(state.doctorId, 'doc_alistair_vance');
    });

    test('selectDate updates date and resets selectedSlot', () {
      final notifier = container.read(bookingControllerProvider.notifier);
      notifier.init('doc_alistair_vance');

      // Pre-select a slot
      notifier.selectSlot(
        TimeSlot(
          time: '02:00 PM',
          dateTime: DateTime(2026, 11, 19, 14, 0),
          isAvailable: true,
          period: SlotPeriod.afternoon,
        ),
      );
      expect(container.read(bookingControllerProvider).selectedSlot, isNotNull);

      // Select new date
      final newDate = DateTime(2026, 11, 24);
      notifier.selectDate(newDate);

      final state = container.read(bookingControllerProvider);
      expect(state.selectedDate, newDate);
      expect(state.selectedSlot, isNull);
    });

    test(
      'selectSlot updates selected slot if available and ignores unavailable',
      () {
        final notifier = container.read(bookingControllerProvider.notifier);

        final availableSlot = TimeSlot(
          time: '10:00 AM',
          dateTime: DateTime(2026, 11, 20, 10, 0),
          isAvailable: true,
          period: SlotPeriod.morning,
        );
        notifier.selectSlot(availableSlot);
        expect(
          container.read(bookingControllerProvider).selectedSlot,
          availableSlot,
        );

        final unavailableSlot = TimeSlot(
          time: '11:00 AM',
          dateTime: DateTime(2026, 11, 20, 11, 0),
          isAvailable: false,
          period: SlotPeriod.morning,
        );
        notifier.selectSlot(unavailableSlot);
        // Still remains availableSlot
        expect(
          container.read(bookingControllerProvider).selectedSlot,
          availableSlot,
        );
      },
    );

    test(
      'confirmBooking without slot sets validationError and returns null',
      () async {
        final notifier = container.read(bookingControllerProvider.notifier);
        notifier.init(testDoctor.id);

        final result = await notifier.confirmBooking(
          doctor: testDoctor,
          patient: testPatient,
        );

        expect(result, isNull);
        final state = container.read(bookingControllerProvider);
        expect(
          state.validationError,
          'Please select an appointment time slot.',
        );
      },
    );

    test(
      'confirmBooking with valid slot creates appointment successfully',
      () async {
        final notifier = container.read(bookingControllerProvider.notifier);
        notifier.init(testDoctor.id);

        final validDate = DateTime(2026, 11, 20);
        notifier.selectDate(validDate);

        final validSlot = TimeSlot(
          time: '02:00 PM',
          dateTime: DateTime(2026, 11, 20, 14, 0),
          isAvailable: true,
          period: SlotPeriod.afternoon,
        );
        notifier.selectSlot(validSlot);

        final appointment = await notifier.confirmBooking(
          doctor: testDoctor,
          patient: testPatient,
        );

        expect(appointment, isNotNull);
        expect(appointment?.doctorId, testDoctor.id);
        expect(appointment?.timeSlot, '02:00 PM');
        expect(appointment?.status, AppointmentStatus.confirmed);

        final state = container.read(bookingControllerProvider);
        expect(state.lastBookedAppointment, appointment);
        expect(state.isSubmitting, isFalse);
      },
    );

    test(
      'confirmBooking handles conflict, sets conflictError and deselects slot',
      () async {
        final notifier = container.read(bookingControllerProvider.notifier);
        notifier.init(testDoctor.id);

        final conflictDate = DateTime(2026, 11, 20);
        notifier.selectDate(conflictDate);

        // Pre-reserve the slot in repository
        mockRepository.simulatePreExistingBooking(
          doctorId: testDoctor.id,
          date: conflictDate,
          timeSlot: '02:00 PM',
        );

        final slot = TimeSlot(
          time: '02:00 PM',
          dateTime: DateTime(2026, 11, 20, 14, 0),
          isAvailable: true,
          period: SlotPeriod.afternoon,
        );
        notifier.selectSlot(slot);

        final appointment = await notifier.confirmBooking(
          doctor: testDoctor,
          patient: testPatient,
        );

        expect(appointment, isNull);
        final state = container.read(bookingControllerProvider);
        expect(state.conflictError, contains('no longer available'));
        expect(state.selectedSlot, isNull);
      },
    );
  });

  group('Appointment History Providers Tests', () {
    test('upcomingAppointmentsProvider and pastAppointmentsProvider filter correctly', () async {
      final upcomingAsync = await container.read(
        patientAppointmentsProvider.future,
      );
      expect(upcomingAsync, isNotEmpty);

      final upcomingFiltered = container.read(upcomingAppointmentsProvider);
      expect(upcomingFiltered.asData?.value.every((a) => a.isUpcoming), isTrue);

      final pastFiltered = container.read(pastAppointmentsProvider);
      expect(pastFiltered.asData?.value.every((a) => a.isPast), isTrue);
    });
  });
}
