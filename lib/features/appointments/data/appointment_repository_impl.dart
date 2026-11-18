import '../../doctors/domain/appointment.dart';
import '../domain/appointment_draft.dart';
import '../domain/appointment_repository.dart';
import '../domain/booking_exception.dart';
import '../domain/time_slot.dart';

/// In-memory repository implementing appointment booking, realistic slot generation,
/// conflict protection, and appointment history retrieval for CareConnect Day 3.
class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl({
    this.simulatedLatency = const Duration(milliseconds: 250),
    this.clockTime,
  }) {
    _seedInitialAppointments();
  }

  final Duration simulatedLatency;
  final DateTime? clockTime;

  DateTime get _now => clockTime ?? DateTime.now();

  final List<Appointment> _appointments = [];
  final Set<String> _simulatedPreBookings = {};

  static const List<String> _standardMorningSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
  ];

  static const List<String> _standardAfternoonSlots = [
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
  ];

  static const List<String> _standardEveningSlots = ['05:00 PM', '05:30 PM'];

  void _seedInitialAppointments() {
    _appointments.clear();
    _simulatedPreBookings.clear();

    final now = _now;
    final tomorrow = now.add(const Duration(days: 1));
    final pastDate = now.subtract(const Duration(days: 12));

    // Seed 1 confirmed upcoming appointment
    _appointments.add(
      Appointment(
        id: 'APT-849201',
        doctorId: 'doc_marcus_vance',
        doctorName: 'Dr. Marcus Vance',
        doctorSpecialty: 'Cardiology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
        patientId: 'pat_sarah_jenkins_001',
        patientName: 'Maya Sterling',
        patientPhone: '+1 (617) 555-0194',
        scheduledDateTime: DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          10,
          0,
        ),
        timeSlot: '10:00 AM',
        status: AppointmentStatus.confirmed,
        modality: AppointmentModality.inPerson,
        fee: 140.0,
        patientNotes: 'Routine cardiology consultation and BP check.',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    );

    // Seed 1 completed past appointment
    _appointments.add(
      Appointment(
        id: 'APT-849105',
        doctorId: 'doc_elena_rostova',
        doctorName: 'Dr. Elena Rostova',
        doctorSpecialty: 'Dermatology',
        clinicName: 'CareConnect Metropolitan Health Center',
        clinicAddress: 'West Pavilion, Suite 205, Boston, MA',
        patientId: 'pat_sarah_jenkins_001',
        patientName: 'Maya Sterling',
        patientPhone: '+1 (617) 555-0194',
        scheduledDateTime: DateTime(
          pastDate.year,
          pastDate.month,
          pastDate.day,
          14,
          30,
        ),
        timeSlot: '02:30 PM',
        status: AppointmentStatus.completed,
        modality: AppointmentModality.inPerson,
        fee: 125.0,
        patientNotes: 'Annual dermatological screening.',
        createdAt: pastDate.subtract(const Duration(days: 3)),
      ),
    );
  }

  @override
  void reset() {
    _seedInitialAppointments();
  }

  @override
  void simulatePreExistingBooking({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
  }) {
    final key = _slotKey(doctorId, date, timeSlot);
    _simulatedPreBookings.add(key);
  }

  String _slotKey(String doctorId, DateTime date, String timeSlot) {
    return '$doctorId|${date.year}-${date.month}-${date.day}|$timeSlot';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _parseSlotDateTime(DateTime date, String timeSlot) {
    final parts = timeSlot.split(' ');
    final timeParts = parts[0].split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';

    if (isPm && hour < 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  @override
  Future<List<TimeSlot>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);

    // If date is before today, no available slots
    if (targetDay.isBefore(today)) {
      return const [];
    }

    // Clinic closed on Sundays
    if (date.weekday == DateTime.sunday) {
      return const [];
    }

    final slots = <TimeSlot>[];

    void addGroup(List<String> slotTimes, SlotPeriod period) {
      for (final timeStr in slotTimes) {
        final slotDateTime = _parseSlotDateTime(date, timeStr);
        final key = _slotKey(doctorId, date, timeStr);

        bool available = true;
        String? reason;

        // Check if slot has already passed today
        if (targetDay.isAtSameMomentAs(today) && slotDateTime.isBefore(now)) {
          available = false;
          reason = 'Time has passed';
        }

        // Check if reserved by user appointments
        final isBooked = _appointments.any(
          (apt) =>
              apt.doctorId == doctorId &&
              _isSameDay(apt.scheduledDateTime, date) &&
              apt.timeSlot == timeStr &&
              apt.status != AppointmentStatus.cancelled,
        );

        if (isBooked || _simulatedPreBookings.contains(key)) {
          available = false;
          reason = 'Reserved';
        }

        // Add realistic pre-booked slots for demo variety on certain hours
        // E.g., 11:00 AM on even days, 03:30 PM on odd days
        if (available &&
            ((date.day.isEven && timeStr == '11:00 AM') ||
                (date.day.isOdd && timeStr == '03:30 PM'))) {
          available = false;
          reason = 'Reserved';
        }

        slots.add(
          TimeSlot(
            time: timeStr,
            dateTime: slotDateTime,
            isAvailable: available,
            period: period,
            unavailableReason: reason,
          ),
        );
      }
    }

    addGroup(_standardMorningSlots, SlotPeriod.morning);
    addGroup(_standardAfternoonSlots, SlotPeriod.afternoon);
    addGroup(_standardEveningSlots, SlotPeriod.evening);

    return slots;
  }

  @override
  Future<Appointment> createBooking(AppointmentDraft draft) async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDay = DateTime(
      draft.appointmentDate.year,
      draft.appointmentDate.month,
      draft.appointmentDate.day,
    );

    // Rule 1: Validate required fields
    if (draft.doctorId.trim().isEmpty) {
      throw const BookingValidationException('Doctor reference is missing.');
    }
    if (draft.patientId.trim().isEmpty) {
      throw const BookingValidationException('Patient reference is missing.');
    }
    if (draft.patientName.trim().isEmpty) {
      throw const BookingValidationException('Patient name is required.');
    }
    if (draft.timeSlot.trim().isEmpty) {
      throw const BookingValidationException(
        'Please select an appointment time slot.',
      );
    }

    // Rule 2: Past date rejection
    if (appointmentDay.isBefore(today)) {
      throw const BookingValidationException(
        'Cannot schedule an appointment for a past date.',
      );
    }

    // Rule 3: Past time slot on current date rejection
    final slotDateTime = _parseSlotDateTime(
      draft.appointmentDate,
      draft.timeSlot,
    );
    if (appointmentDay.isAtSameMomentAs(today) && slotDateTime.isBefore(now)) {
      throw const BookingValidationException(
        'Cannot select a time slot that has already passed.',
      );
    }

    // Rule 4: Duplicate booking by same patient for same doctor, date & time
    final hasPatientDuplicate = _appointments.any(
      (apt) =>
          apt.patientId == draft.patientId &&
          apt.doctorId == draft.doctorId &&
          _isSameDay(apt.scheduledDateTime, draft.appointmentDate) &&
          apt.timeSlot == draft.timeSlot &&
          apt.status != AppointmentStatus.cancelled,
    );

    if (hasPatientDuplicate) {
      final formattedDate =
          '${draft.appointmentDate.month}/${draft.appointmentDate.day}/${draft.appointmentDate.year}';
      throw BookingConflictException(
        'You already have a confirmed appointment with ${draft.doctorName.isNotEmpty ? draft.doctorName : "this doctor"} on $formattedDate at ${draft.timeSlot}.',
      );
    }

    // Rule 5: Conflict check (slot already booked by any patient or simulated lock)
    final key = _slotKey(draft.doctorId, draft.appointmentDate, draft.timeSlot);
    final isSlotTaken =
        _appointments.any(
          (apt) =>
              apt.doctorId == draft.doctorId &&
              _isSameDay(apt.scheduledDateTime, draft.appointmentDate) &&
              apt.timeSlot == draft.timeSlot &&
              apt.status != AppointmentStatus.cancelled,
        ) ||
        _simulatedPreBookings.contains(key);

    if (isSlotTaken) {
      throw BookingConflictException(
        'The selected time slot (${draft.timeSlot}) is no longer available. Another patient just reserved it.',
      );
    }

    // Success: Generate unique appointment ID
    final idSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(
      7,
    );
    final appointmentId = 'APT-$idSuffix';

    final appointment = Appointment(
      id: appointmentId,
      doctorId: draft.doctorId,
      doctorName: draft.doctorName,
      doctorSpecialty: draft.doctorSpecialty,
      clinicName: draft.clinicName,
      clinicAddress: draft.clinicAddress,
      patientId: draft.patientId,
      patientName: draft.patientName,
      patientPhone: draft.patientPhone,
      scheduledDateTime: slotDateTime,
      timeSlot: draft.timeSlot,
      status: AppointmentStatus.confirmed,
      modality: draft.modality,
      fee: draft.fee,
      currency: draft.currency,
      patientNotes: draft.patientNotes,
      createdAt: now,
    );

    // Add to beginning of session appointments list
    _appointments.insert(0, appointment);

    return appointment;
  }

  @override
  Future<List<Appointment>> getPatientAppointments({
    required String patientId,
  }) async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    // Match patient ID or return demo patient appointments
    final patientList = _appointments.where((apt) {
      return apt.patientId == patientId ||
          patientId.isEmpty ||
          apt.patientId == 'pat_sarah_jenkins_001' ||
          apt.patientId == 'pat_maya_sterling_001';
    }).toList();

    // Sort upcoming first (by scheduledDateTime ascending), then past (by scheduledDateTime descending)
    final upcoming = patientList.where((a) => a.isUpcoming).toList()
      ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

    final past = patientList.where((a) => a.isPast).toList()
      ..sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));

    return [...upcoming, ...past];
  }

  @override
  Future<Appointment?> getAppointmentById(String id) async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    try {
      return _appointments.firstWhere((apt) => apt.id == id);
    } catch (_) {
      return null;
    }
  }
}
