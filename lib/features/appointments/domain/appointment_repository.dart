import '../../doctors/domain/appointment.dart';
import 'appointment_draft.dart';
import 'time_slot.dart';

/// Abstract contract for appointment management, persistent storage,
/// slot availability, cancellation, and rescheduling in CareConnect.
abstract class AppointmentRepository {
  /// Initializes underlying persistent storage and notification services.
  Future<void> init();

  /// Retrieves organized time slots with availability flags for a specific doctor and date.
  ///
  /// Optionally accepts [excludeAppointmentId] when evaluating slot availability
  /// during a rescheduling operation.
  Future<List<TimeSlot>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
    String? excludeAppointmentId,
  });

  /// Validates and confirms an appointment booking request, storing it in SQLite.
  ///
  /// Throws [BookingValidationException] if input validation fails.
  /// Throws [BookingConflictException] if the slot is no longer available or a duplicate exists.
  Future<Appointment> createBooking(AppointmentDraft draft);

  /// Retrieves all appointments for the specified patient ID from SQLite storage.
  Future<List<Appointment>> getPatientAppointments({required String patientId});

  /// Retrieves a specific appointment by its unique identifier.
  Future<Appointment?> getAppointmentById(String id);

  /// Cancels an eligible upcoming appointment.
  ///
  /// Releases the reserved slot and cancels any scheduled local reminder notification.
  /// Throws [BookingValidationException] if the appointment cannot be cancelled (e.g. past or already cancelled).
  Future<Appointment> cancelAppointment({
    required String appointmentId,
    String? cancellationReason,
  });

  /// Reschedules an eligible upcoming appointment to a new date and time slot.
  ///
  /// Preserves the original appointment ID and creation date, updates the scheduled time,
  /// releases the previous slot, reserves the new slot, and synchronizes reminders.
  /// Throws [BookingValidationException] or [BookingConflictException] on validation failure.
  Future<Appointment> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTimeSlot,
  });

  /// Resets persistent storage to initial seeded state (useful for tests and demos).
  void reset();

  /// Simulates a pre-existing booking reservation to test conflict handling.
  void simulatePreExistingBooking({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
  });
}
