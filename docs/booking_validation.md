# CareConnect — Day 3 Booking Validation & Conflict Protection

## Overview

Clinical appointment scheduling requires strict integrity controls to prevent overbooking, invalid scheduling windows, retroactive appointments, and orphaned records. CareConnect Day 3 implements a robust validation engine residing at the domain and repository layers (`lib/features/appointments/data/appointment_repository_impl.dart` and `lib/features/appointments/domain/booking_exception.dart`).

---

## The 6 Core Validation Rules

| Rule # | Validation Rule | Condition Evaluated | Exception / User Error Message |
|---|---|---|---|
| **Rule 1** | **Required Fields** | Doctor ID, Doctor Name, Patient ID, Patient Name, Date, or Time Slot is empty or null. | `BookingValidationException("All booking fields (doctor, patient, date, slot) are required.")` |
| **Rule 2** | **No Past Dates** | Selected calendar date is strictly before the current local date (`date.isBefore(today)`). | `BookingValidationException("Cannot book appointments for past dates.")` |
| **Rule 3** | **No Past Times on Current Date** | If appointment date is today, slot start time parsed into `DateTime` is before current local timestamp (`slotDateTime.isBefore(now)`). | `BookingValidationException("The selected time slot has already passed for today.")` |
| **Rule 4** | **Clinic Operating Hours (Sunday Closure)** | Selected date falls on Sunday (`date.weekday == DateTime.sunday`). | `BookingValidationException("The clinic is closed on Sundays. Please select Monday through Saturday.")` |
| **Rule 5** | **Patient Duplicate Prevention** | The same patient already has an active, confirmed appointment with the specified doctor on the selected date. | `BookingConflictException("You already have an appointment with this doctor on the selected date.")` |
| **Rule 6** | **Slot Availability & Concurrency Lock** | Target slot is marked unavailable or has already been reserved by another patient. | `BookingConflictException("The selected slot (HH:MM) is no longer available. Please select another time.")` |

---

## Validation Architecture & Exception Hierarchy

```
                 Object
                   │
                   ▼
               Exception
                   │
                   ▼
            BookingException (abstract)
            ├── message: String
            ├── code: String
            │
      ┌────────────┴────────────┐
      ▼                         ▼
BookingValidationException   BookingConflictException
(code: 'VALIDATION_ERROR')   (code: 'SLOT_CONFLICT')
```

### Exception Implementations (`lib/features/appointments/domain/booking_exception.dart`)
```dart
sealed class BookingException implements Exception {
  final String message;
  final String code;
  const BookingException(this.message, {this.code = 'BOOKING_ERROR'});
}

class BookingValidationException extends BookingException {
  const BookingValidationException(super.message)
      : super(code: 'VALIDATION_ERROR');
}

class BookingConflictException extends BookingException {
  const BookingConflictException(super.message)
      : super(code: 'SLOT_CONFLICT');
}
```

---

## Slot Availability & Concurrency Resolution

### Concurrency Mechanism
In clinical booking systems, two patients viewing the same schedule concurrently might attempt to confirm the same slot at the exact same moment.
In CareConnect:
1. When generating slots via `getAvailableSlots(doctorId, date)`, the repository evaluates all existing confirmed appointments for that doctor and date.
2. If an existing appointment matches `doctorId`, `date`, and `slot.id`, the slot's `isAvailable` property is computed as `false`.
3. When `createAppointment(draft)` is invoked, an atomic validation check verifies if any confirmed appointment in the in-memory store already holds `(doctorId, date, slot.id)`.
4. **First-write-wins:** The first transaction successfully writes the new appointment to the store and returns a confirmed receipt.
5. **Conflict Rejection:** Any subsequent transaction for the same slot is rejected immediately with a `BookingConflictException`.
6. The UI catches `BookingConflictException`, refreshes the doctor slots provider (`ref.refresh(doctorSlotsProvider(...))`), displays a high-visibility amber/coral alert banner, and prompts the user to select an alternate time slot.

---

## Edge Cases Verified in Automated Tests

1. **Past Date Boundary:** Tested with `DateTime.now().subtract(const Duration(days: 1))`. Verified that the repository throws `BookingValidationException` and prevents creation.
2. **Current Day Elapsed Slots:** Tested with slot starting at `09:00 AM` when simulated clock is `02:00 PM`. Verified that elapsed slots are flagged as unavailable or rejected if submitted.
3. **Sunday Closure:** Tested with contiguous dates spanning across weekends. Verified that Sunday date cards are locked, disabled, and repository rejects Sunday booking drafts.
4. **Duplicate Patient Booking:** Tested by creating an initial appointment for Patient A with Doctor B on Day D, then immediately submitting a second draft for Patient A with Doctor B on Day D. Verified that second attempt throws `BookingConflictException`.
5. **Simulated Concurrency Race:** Tested by simulating a pre-existing booking made by another client (`APT-SIMULATED-CONCURRENT`) for the same doctor and slot. Verified that attempting to confirm this slot throws `BookingConflictException` with the slot's time clearly stated.
6. **In-Flight Cancellation / Draft Reset:** Verified that navigating away or resetting the draft does not contaminate repository state or leave dangling partial appointments.
