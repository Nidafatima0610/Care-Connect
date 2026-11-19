import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:care_connect/features/appointments/data/appointment_database.dart';
import 'package:care_connect/features/appointments/data/appointment_repository_impl.dart';
import 'package:care_connect/features/appointments/data/notification_service.dart';
import 'package:care_connect/features/appointments/domain/appointment_draft.dart';
import 'package:care_connect/features/appointments/domain/appointment_repository.dart';
import 'package:care_connect/features/appointments/domain/booking_exception.dart';
import 'package:care_connect/features/appointments/domain/time_slot.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';
import 'package:care_connect/features/doctors/domain/doctor.dart';
import 'package:care_connect/features/patient/domain/patient.dart';
import 'package:care_connect/features/patient/presentation/controllers/patient_provider.dart';

/// Provider for the singleton AppointmentDatabase.
final appointmentDatabaseProvider = Provider<AppointmentDatabase>((ref) {
  return AppointmentDatabase.instance;
});

/// Provider for the singleton NotificationService.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationServiceImpl.instance;
});

/// Provider for the singleton AppointmentRepository backed by SQLite.
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final db = ref.watch(appointmentDatabaseProvider);
  final notif = ref.watch(notificationServiceProvider);
  return AppointmentRepositoryImpl(database: db, notificationService: notif);
});

/// Simulated / detected offline status notifier.
class OfflineModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    if (kIsWeb) {
      try {
        return Uri.base.queryParameters['offline'] == 'true';
      } catch (_) {}
    }
    return false;
  }

  void toggle() => state = !state;
  void setOffline(bool value) => state = value;
}

final offlineModeProvider = NotifierProvider<OfflineModeNotifier, bool>(
  OfflineModeNotifier.new,
);

/// Immutable query parameter for fetching doctor appointment slots on a given date.
@immutable
class DoctorDateQuery {
  final String doctorId;
  final DateTime date;
  final String? excludeAppointmentId;

  const DoctorDateQuery({
    required this.doctorId,
    required this.date,
    this.excludeAppointmentId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorDateQuery &&
          runtimeType == other.runtimeType &&
          doctorId == other.doctorId &&
          excludeAppointmentId == other.excludeAppointmentId &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => Object.hash(
    doctorId,
    date.year,
    date.month,
    date.day,
    excludeAppointmentId,
  );
}

/// Family FutureProvider retrieving available time slots for a specific doctor on a target date.
final doctorSlotsProvider =
    FutureProvider.family<List<TimeSlot>, DoctorDateQuery>((ref, query) async {
      final repository = ref.watch(appointmentRepositoryProvider);
      return repository.getAvailableSlots(
        doctorId: query.doctorId,
        date: query.date,
        excludeAppointmentId: query.excludeAppointmentId,
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
  Future<Appointment?> confirmBooking({
    required Doctor doctor,
    required Patient patient,
  }) async {
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
      ref.invalidate(
        doctorSlotsProvider(
          DoctorDateQuery(doctorId: doctor.id, date: state.selectedDate),
        ),
      );

      state = state.copyWith(
        isSubmitting: false,
        conflictError: () => e.message,
        selectedSlot: () => null,
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

/// Controller managing appointment cancellation.
class CancellationNotifier extends Notifier<AsyncValue<Appointment?>> {
  @override
  AsyncValue<Appointment?> build() => const AsyncValue.data(null);

  Future<Appointment?> cancelAppointment({
    required String appointmentId,
    String? cancellationReason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      final cancelled = await repository.cancelAppointment(
        appointmentId: appointmentId,
        cancellationReason: cancellationReason,
      );

      // Invalidate appointment collections to trigger fresh reads from SQLite
      ref.invalidate(patientAppointmentsProvider);
      ref.invalidate(appointmentByIdProvider(appointmentId));

      state = AsyncValue.data(cancelled);
      return cancelled;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final cancellationControllerProvider =
    NotifierProvider<CancellationNotifier, AsyncValue<Appointment?>>(
      CancellationNotifier.new,
    );

/// State for the appointment rescheduling workflow.
@immutable
class RescheduleState {
  final String appointmentId;
  final Appointment? originalAppointment;
  final DateTime selectedDate;
  final TimeSlot? selectedSlot;
  final bool isSubmitting;
  final String? error;
  final Appointment? rescheduledAppointment;

  const RescheduleState({
    required this.appointmentId,
    this.originalAppointment,
    required this.selectedDate,
    this.selectedSlot,
    this.isSubmitting = false,
    this.error,
    this.rescheduledAppointment,
  });

  RescheduleState copyWith({
    String? appointmentId,
    Appointment? originalAppointment,
    DateTime? selectedDate,
    TimeSlot? Function()? selectedSlot,
    bool? isSubmitting,
    String? Function()? error,
    Appointment? rescheduledAppointment,
  }) {
    return RescheduleState(
      appointmentId: appointmentId ?? this.appointmentId,
      originalAppointment: originalAppointment ?? this.originalAppointment,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: selectedSlot != null ? selectedSlot() : this.selectedSlot,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error != null ? error() : this.error,
      rescheduledAppointment:
          rescheduledAppointment ?? this.rescheduledAppointment,
    );
  }
}

/// Controller managing appointment rescheduling.
class RescheduleNotifier extends Notifier<RescheduleState> {
  @override
  RescheduleState build() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final initialDate = tomorrow.weekday == DateTime.sunday
        ? tomorrow.add(const Duration(days: 1))
        : DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    return RescheduleState(appointmentId: '', selectedDate: initialDate);
  }

  void init(Appointment appointment) {
    final now = DateTime.now();
    // Default reschedule date to next available day after original date or tomorrow
    DateTime targetDate = appointment.scheduledDateTime.add(
      const Duration(days: 1),
    );
    if (targetDate.isBefore(now)) {
      targetDate = now.add(const Duration(days: 1));
    }
    if (targetDate.weekday == DateTime.sunday) {
      targetDate = targetDate.add(const Duration(days: 1));
    }
    targetDate = DateTime(targetDate.year, targetDate.month, targetDate.day);

    state = RescheduleState(
      appointmentId: appointment.id,
      originalAppointment: appointment,
      selectedDate: targetDate,
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      selectedSlot: () => null,
      error: () => null,
    );
  }

  void selectSlot(TimeSlot slot) {
    if (!slot.isAvailable) return;
    state = state.copyWith(selectedSlot: () => slot, error: () => null);
  }

  Future<Appointment?> confirmReschedule() async {
    if (state.selectedSlot == null) {
      state = state.copyWith(
        error: () => 'Please select a new appointment time slot.',
      );
      return null;
    }

    state = state.copyWith(isSubmitting: true, error: () => null);

    try {
      final repository = ref.read(appointmentRepositoryProvider);
      final updated = await repository.rescheduleAppointment(
        appointmentId: state.appointmentId,
        newDate: state.selectedDate,
        newTimeSlot: state.selectedSlot!.time,
      );

      // Invalidate appointment history and slot cache
      ref.invalidate(patientAppointmentsProvider);
      ref.invalidate(appointmentByIdProvider(state.appointmentId));
      if (state.originalAppointment != null) {
        ref.invalidate(
          doctorSlotsProvider(
            DoctorDateQuery(
              doctorId: state.originalAppointment!.doctorId,
              date: state.selectedDate,
            ),
          ),
        );
        ref.invalidate(
          doctorSlotsProvider(
            DoctorDateQuery(
              doctorId: state.originalAppointment!.doctorId,
              date: state.originalAppointment!.scheduledDateTime,
            ),
          ),
        );
      }

      state = state.copyWith(
        isSubmitting: false,
        rescheduledAppointment: updated,
      );

      return updated;
    } on BookingValidationException catch (e) {
      state = state.copyWith(isSubmitting: false, error: () => e.message);
      return null;
    } on BookingConflictException catch (e) {
      state = state.copyWith(isSubmitting: false, error: () => e.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: () => 'Failed to reschedule appointment. Please try again.',
      );
      return null;
    }
  }
}

final rescheduleControllerProvider =
    NotifierProvider<RescheduleNotifier, RescheduleState>(
      RescheduleNotifier.new,
    );

/// FutureProvider retrieving the complete list of appointments for the current active patient from SQLite.
final patientAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  final patientId = ref.watch(
    patientProfileProvider.select(
      (p) => p.asData?.value?.id ?? 'pat_sarah_jenkins_001',
    ),
  );

  return repository.getPatientAppointments(patientId: patientId);
});

/// FutureProvider retrieving a single appointment by ID.
final appointmentByIdProvider = FutureProvider.family<Appointment?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getAppointmentById(id);
});

/// Provider filtering upcoming (confirmed/pending/rescheduled) appointments.
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
