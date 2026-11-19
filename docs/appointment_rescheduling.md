# Appointment Rescheduling Specification & Architecture

## 1. Overview
The rescheduling module allows patients to modify the date and time slot of an existing confirmed appointment without duplicating records, losing original booking history, or creating schedule conflicts.

---

## 2. Rescheduling Workflow

When the patient taps **"Reschedule"** on an active appointment card in `AppointmentHistoryScreen`:

```
[Upcoming Appointment Card]
          |
     (Tap "Reschedule")
          |
          v
[RescheduleScreen (/reschedule/:appointmentId)]
  - Current Appointment Summary Card (Doctor, Current Date & Slot, Fee)
  - Horizontal Interactive Date Strip (Next 14 Days)
  - Doctor Available Time-Slot Grid (Synced with SQLite active bookings)
  - Selected New Slot Summary Preview
  - Conflicting Slot Guard & Unavailable Disabled States
          |
     (Select New Date & Slot)
          |
          v
[Tap "Confirm Rescheduling"]
          |
          v
[RescheduleController.reschedule()]
  1. Atomic validation check:
     - Target appointment exists and is eligible (confirmed & future).
     - New slot is not in the past.
     - New slot is currently free for the doctor.
  2. Database Update Transaction:
     - Keep appointment ID intact.
     - Keep original created_at intact.
     - Set date = newDate.
     - Set start_time = newTime.
     - Set updated_at = DateTime.now().
     - Re-arm reminder_scheduled = 1.
  3. Doctor Slot Pool Synchronization:
     - Release old date/time slot.
     - Reserve new date/time slot.
  4. Notification Rescheduling:
     - Cancel old local reminder notification.
     - Compute new 30-min lead time reminder and schedule.
  5. UI Refresh:
     - Invalidate appointment providers.
     - Return to AppointmentHistoryScreen with animated banner confirmation.
```

---

## 3. Rescheduling Validation Matrix

| Condition | Verification | Action / Response |
|---|---|---|
| Target appointment is past | `appointment.isPast == true` | Reschedule button disabled; returns error if attempted |
| Target appointment is cancelled | `appointment.status == cancelled` | Reschedule button disabled; prevents action |
| Patient selects a past date | `selectedDate < today` | Past dates excluded or disabled in horizontal date selector |
| Patient selects an occupied slot | Doctor already has active booking at that date/slot | Slot card rendered in disabled state (`SlotStatus.booked`) |
| Patient selects current slot | `newDate == oldDate && newSlot == oldSlot` | Action disabled ("Select a different time slot") |
| Database transaction failure | SQLite write error | Rollback; old appointment remains untouched; slot reservation reverted |

---

## 4. UI Components

- **`RescheduleScreen`** (`lib/features/appointments/presentation/reschedule_screen.dart`):
  - **Current Booking Banner**: Highlights the doctor name, clinic, current date, and time.
  - **Date Selector**: Horizontal scrolling calendar strip with Day of week, Month, and Date digits.
  - **Time Slot Grid**: Chips categorized into Morning, Afternoon, and Evening intervals with real-time availability badges.
  - **Confirmation Review**: Bottom sheet summary showing "From [Old Slot] -> To [New Slot]" with estimated consultation fee and confirm CTA.
