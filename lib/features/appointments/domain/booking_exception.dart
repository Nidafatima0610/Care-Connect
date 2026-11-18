/// Base exception for appointment booking errors in CareConnect.
class BookingException implements Exception {
  final String message;
  final String? code;

  const BookingException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Thrown when booking input fails business validation
/// (e.g., past date, past time, missing required doctor/patient data).
class BookingValidationException extends BookingException {
  const BookingValidationException(
    super.message, {
    super.code = 'VALIDATION_ERROR',
  });
}

/// Thrown when a booking conflict occurs
/// (e.g., slot is already reserved, duplicate booking by the same patient).
class BookingConflictException extends BookingException {
  const BookingConflictException(super.message, {super.code = 'SLOT_CONFLICT'});
}
