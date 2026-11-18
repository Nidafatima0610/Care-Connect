import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:care_connect/features/appointments/data/appointment_repository_impl.dart';
import 'package:care_connect/features/appointments/domain/appointment_draft.dart';
import 'package:care_connect/features/appointments/domain/appointment_repository.dart';
import 'package:care_connect/features/appointments/domain/booking_exception.dart';
import 'package:care_connect/features/appointments/domain/time_slot.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';
import 'package:care_connect/features/doctors/domain/doctor.dart';
import 'package:care_connect/features/patient/domain/patient.dart';
import 'package:care_connect/features/patient/presentation/controllers/patient_provider.dart';

/// Provider for the singleton AppointmentRepository.
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepositoryImpl();
});

/// Immutable query parameter for fetching doctor appointment slots on a given date.
@immutable
class DoctorDateQuery {
  final String doctorId;
  final DateTime date;

  const DoctorDateQuery({required this.doctorId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorDateQuery &&
          runtimeType == other.runtimeType &&
          doctorId == other.doctorId &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => Object.hash(doctorId, date.year, date.month, date.day);
}

/// Family FutureProvider retrieving available time slots for a specific doctor on a target date.
final doctorSlotsProvider =
    FutureProvider.family<List<TimeSlot>, DoctorDateQuery>((ref, query) async {
      final repository = ref.watch(appointmentRepositoryProvider);
      return repository.getAvailableSlots(
        doctorId: query.doctorId,
        date: query.date,
      );
    });

/// State representation of the active appointment booking flow.
@immutable
class BookingState {
  final String doctorId;
  final DateTime selectedDate;
  final TimeSlot? selectedSlot;
  final AppointmentModality selectedModality;
  final String patientNotes;
  final bool isSubmitting;
  final String? validationError;
  final String? conflictError;
  final Appointment? lastBookedAppointment;

  const BookingState({
    required this.doctorId,
    required this.selectedDate,
    this.selectedSlot,
    this.selectedModality = AppointmentModality.inPerson,
    this.patientNotes = '',
    this.isSubmitting = false,
    this.validationError,
    this.conflictError,
    this.lastBookedAppointment,
  });

  BookingState copyWith({
    String? doctorId,
    DateTime? selectedDate,
    TimeSlot? Function()? selectedSlot,
    AppointmentModality? selectedModality,
    String? patientNotes,
    bool? isSubmitting,
    String? Function()? validationError,
    String? Function()? conflictError,
    Appointment? lastBookedAppointment,
  }) {
    return BookingState(
      doctorId: doctorId ?? this.doctorId,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: selectedSlot != null ? selectedSlot() : this.selectedSlot,
      selectedModality: selectedModality ?? this.selectedModality,
      patientNotes: patientNotes ?? this.patientNotes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      validationError: validationError != null
          ? validationError()
          : this.validationError,
      conflictError: conflictError != null
          ? conflictError()
          : this.conflictError,
      lastBookedAppointment:
          lastBookedAppointment ?? this.lastBookedAppointment,
    );
  }
}

/// Controller managing booking state, slot selections, validation, and submission.
class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() {
    final now = DateTime.now();
    // If today is Sunday, default to Monday
    final initialDate = now.weekday == DateTime.sunday
        ? now.add(const Duration(days: 1))
        : DateTime(now.year, now.month, now.day);

    return BookingState(doctorId: '', selectedDate: initialDate);
  }

  void init(String doctorId) {
    if (state.doctorId != doctorId) {
      final now = DateTime.now();
      final initialDate = now.weekday == DateTime.sunday
          ? now.add(const Duration(days: 1))
          : DateTime(now.year, now.month, now.day);

      state = BookingState(doctorId: doctorId, selectedDate: initialDate);
    }
  }

  void selectDate(DateTime date) {
    if (state.selectedDate.year == date.year &&
        state.selectedDate.month == date.month &&
        state.selectedDate.day == date.day) {
      return;
    }

    state = state.copyWith(
      selectedDate: date,
      selectedSlot: () => null,
      validationError: () => null,
      conflictError: () => null,
    );
  }

  void selectSlot(TimeSlot slot) {
    if (!slot.isAvailable) return;
    state = state.copyWith(
      selectedSlot: () => slot,
      validationError: () => null,
      conflictError: () => null,
    );
  }

  void selectModality(AppointmentModality modality) {
    state = state.copyWith(selectedModality: modality);
  }

  void setPatientNotes(String notes) {
    state = state.copyWith(patientNotes: notes);
  }

  void setValidationError(String message) {
    state = state.copyWith(
      validationError: () => message,
      conflictError: () => null,
    );
  }

  void setConflictError(String message) {
    state = state.copyWith(
      conflictError: () => message,
      validationError: () => null,
      selectedSlot: () => null,
    );
  }

  void clearErrors() {
    state = state.copyWith(
      validationError: () => null,
      conflictError: () => null,
    );
  }

  /// Validates and confirms the appointment booking request.
  ///
  /// Returns the newly created [Appointment] on success, or null on validation/conflict failure.
  Future<Appointment?> confirmBooking({
    required Doctor doctor,
    required Patient patient,
  }) async {
    // UI Validation check
    if (state.selectedSlot == null) {
      state = state.copyWith(
        validationError: () => 'Please select an appointment time slot.',
      );
      return null;
    }

    state = state.copyWith(
      isSubmitting: true,
      validationError: () => null,
      conflictError: () => null,
    );

    final draft = AppointmentDraft(
      doctorId: doctor.id,
      doctorName: doctor.name,
      doctorSpecialty: doctor.specialty.displayName,
      clinicName: doctor.clinicName,
      clinicAddress: doctor.clinicAddress,
      fee: doctor.consultationFee,
      currency: doctor.currency,
      patientId: patient.id,
      patientName: patient.fullName,
      patientPhone: patient.phone,
      appointmentDate: state.selectedDate,
      timeSlot: state.selectedSlot!.time,
      modality: state.selectedModality,
      patientNotes: state.patientNotes.trim().isNotEmpty
          ? state.patientNotes.trim()
          : null,
    );

    try {
      final repository = ref.read(appointmentRepositoryProvider);
      final appointment = await repository.createBooking(draft);

      // Invalidate appointment history and slots to refresh UI
      ref.invalidate(patientAppointmentsProvider);
      ref.invalidate(
        doctorSlotsProvider(
          DoctorDateQuery(doctorId: doctor.id, date: state.selectedDate),
        ),
      );

      state = state.copyWith(
        isSubmitting: false,
        lastBookedAppointment: appointment,
      );

      return appointment;
    } on BookingConflictException catch (e) {
      // Invalidate slots cache so the newly reserved slot renders as unavailable
      ref.invalidate(
        doctorSlotsProvider(
          DoctorDateQuery(doctorId: doctor.id, date: state.selectedDate),
        ),
      );

      state = state.copyWith(
        isSubmitting: false,
        conflictError: () => e.message,
        selectedSlot: () => null, // Deselect the conflicted slot
      );
      return null;
    } on BookingValidationException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        validationError: () => e.message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        validationError: () =>
            'An unexpected error occurred while booking. Please try again.',
      );
      return null;
    }
  }
}

final bookingControllerProvider =
    NotifierProvider<BookingNotifier, BookingState>(BookingNotifier.new);

/// FutureProvider retrieving the complete list of appointments for the current active patient.
final patientAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  final patientAsync = ref.watch(patientProfileProvider);
  final patientId = patientAsync.asData?.value?.id ?? 'pat_sarah_jenkins_001';

  return repository.getPatientAppointments(patientId: patientId);
});

/// Provider filtering upcoming (confirmed/pending) appointments.
final upcomingAppointmentsProvider = Provider<AsyncValue<List<Appointment>>>((
  ref,
) {
  final appointmentsAsync = ref.watch(patientAppointmentsProvider);
  return appointmentsAsync.whenData(
    (list) => list.where((a) => a.isUpcoming).toList(),
  );
});

/// Provider filtering past (completed/cancelled) appointments.
final pastAppointmentsProvider = Provider<AsyncValue<List<Appointment>>>((ref) {
  final appointmentsAsync = ref.watch(patientAppointmentsProvider);
  return appointmentsAsync.whenData(
    (list) => list.where((a) => a.isPast).toList(),
  );
});
