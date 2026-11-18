import '../../doctors/domain/appointment.dart';
import 'appointment_draft.dart';
import 'time_slot.dart';

/// Abstract contract for appointment management and slot availability in CareConnect.
abstract class AppointmentRepository {
  /// Retrieves organized time slots with availability flags for a specific doctor and date.
  Future<List<TimeSlot>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  });

  /// Validates and confirms an appointment booking request.
  ///
  /// Throws [BookingValidationException] if input validation fails.
  /// Throws [BookingConflictException] if the slot is no longer available or a duplicate exists.
  Future<Appointment> createBooking(AppointmentDraft draft);

  /// Retrieves all appointments for the specified patient ID (both upcoming and past).
  Future<List<Appointment>> getPatientAppointments({required String patientId});

  /// Retrieves a specific appointment by its unique identifier.
  Future<Appointment?> getAppointmentById(String id);

  /// Resets in-memory storage to initial seeded state (useful for tests and demos).
  void reset();

  /// Simulates a pre-existing booking reservation to test conflict handling.
  void simulatePreExistingBooking({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
  });
}
