# CareConnect — Day 3 Appointment History & Lifecycle

## Overview

The Appointment History screen (`/appointments`) provides patients with clear visibility into their clinical schedule, upcoming consultations, and past care records. It is structured into two main views: **Upcoming** and **Past**.

---

## Architectural Structure

- **Screen Implementation:** `lib/features/appointments/presentation/appointment_history_screen.dart`
- **Card Component:** `lib/features/appointments/presentation/widgets/appointment_history_card.dart`
- **State Management:**
  - `upcomingAppointmentsProvider`: Filters appointments for the current patient where `status != AppointmentStatus.completed` and `dateTime >= now`.
  - `pastAppointmentsProvider`: Filters appointments for the current patient where `status == AppointmentStatus.completed` or `dateTime < now`.
  - Providers auto-sort in chronological order: upcoming appointments are sorted ascending (nearest first), while past appointments are sorted descending (most recent first).

---

## Status Lifecycle & Visual Representation

```
      [Draft Creation]
             │
             ▼
     [Confirm Booking]
             │
             ▼
      Status: Confirmed  ─── (Consultation Occurs) ───►  Status: Completed
     (Mint Accent Pill)                               (Muted Slate Pill)
```

### 1. Confirmed Status
- **Badge Styling:** Background `#ECFDF5` (Mint 50), text `#065F46` (Mint 800), border `#A7F3D0` (Mint 200).
- **Icon:** Calendar with checkmark (`Icons.event_available`).
- **Placement:** Displayed in the "Upcoming" tab.
- **Card Actions:** Direct link to Doctor Details ("View Doctor Profile") and consultation instructions (e.g. clinic arrival details or telehealth link).

### 2. Completed Status
- **Badge Styling:** Background `#F1F5F9` (Slate 100), text `#475569` (Slate 600), border `#CBD5E1` (Slate 300).
- **Icon:** Checkmark circle (`Icons.check_circle_outline`).
- **Placement:** Displayed in the "Past" tab.
- **Card Actions:** "Book Again" or "Review Doctor" shortcuts.

---

## Doctor Profile Linking

Every appointment card in the history list contains an interactive link or tap target directing the patient back to the full Doctor Details screen (`/doctor/:id`). This allows patients to review clinic instructions, doctor qualifications, or initiate follow-up bookings with the same physician.

```dart
GestureDetector(
  onTap: () => context.pushNamed(
    AppRouteNames.doctorDetail,
    pathParameters: {'id': appointment.doctorId},
  ),
  child: ...
)
```

---

## Empty States & Patient Recovery CTAs

When a patient has no upcoming bookings or historical consultations, the interface avoids blank displays. Instead, it renders an empathetic empty state with a direct CTA:

1. **Upcoming Empty State:**
   - **Illustration / Icon:** Calendar outline with soft teal circular badge (`Icons.calendar_today_outlined`).
   - **Headline:** "No Upcoming Appointments"
   - **Subtitle:** "You have no scheduled doctor visits. Explore our clinical specialists and book your consultation in seconds."
   - **Action Button:** "Find a Doctor" $\rightarrow$ Navigates directly to `/` (Doctor Discovery screen).

2. **Past Empty State:**
   - **Illustration / Icon:** History outline icon (`Icons.history`).
   - **Headline:** "No Past Appointments"
   - **Subtitle:** "Your completed appointment history and medical consultation records will be archived here."
