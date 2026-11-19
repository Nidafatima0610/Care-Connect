# Appointment Cancellation Specification & Workflow

## 1. Overview
The cancellation feature in CareConnect allows patients to safely cancel upcoming scheduled appointments while strictly preserving medical audit history, releasing doctor schedule slots, and cancelling scheduled local notification reminders.

---

## 2. Cancellation Workflow

The patient journey follows a clear, multi-step confirmation process:

```
[Upcoming Appointment Card]
          |
          v
  [Tap "Cancel Visit"]
          |
          v
[Cancellation Confirmation Modal]
  - Doctor Name & Specialty
  - Date & Time
  - Consultation Fee Refund notice
  - Reason selector / input
  - Disclaimer: Time slot will be released
          |
     +----+----+
     |         |
[Keep]     [Confirm Cancellation]
     |         |
  (Dismiss)    v
           [Repository: cancelAppointment(id)]
             1. SQLite status set to 'cancelled'
             2. updatedAt set to DateTime.now()
             3. Time slot released in DoctorSlotPool
             4. Local reminder notification cancelled
             5. Riverpod state invalidated & refreshed
             6. Success SnackBar with slot release confirmation
```

---

## 3. Business & Domain Rules

1. **Eligibility Restrictions**:
   - Only appointments with `status == AppointmentStatus.confirmed` are eligible.
   - Already cancelled appointments (`status == AppointmentStatus.cancelled`) display a locked "Cancelled" pill with no action buttons.
   - Past appointments (`appointment.isPast == true`) display a locked "Completed" pill and cannot be cancelled.
2. **Audit Preservation (No Hard Deletes)**:
   - Cancelled appointments are **never** deleted from SQLite.
   - The record remains with `status = 'cancelled'` and a populated `updated_at` timestamp.
   - In Appointment History, cancelled records are displayed in the "Past" or filtered views with muted red/coral badge styling, giving the patient complete clarity on their history.
3. **Slot Release**:
   - The doctor's time slot for that specific date is immediately freed up for booking by other patients.
4. **Notification Cancellation**:
   - The associated local notification reminder scheduled via `FlutterLocalNotificationsPlugin` is cancelled via `NotificationService.instance.cancelAppointmentReminder(appointmentId)`.
5. **UI Confirmation & Safety**:
   - Accidental clicks are prevented by `CancellationDialog` which requires explicit patient confirmation before executing the database write.
