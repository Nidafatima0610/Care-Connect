# CareConnect — Day 3 Architectural Specification

## Architecture Overview

CareConnect Day 3 introduces a complete clinical scheduling engine within the established feature-first clean architecture:
- `features/appointments/domain/`: Pure domain entities, value objects, exceptions, and repository interface contracts.
- `features/appointments/data/`: Concrete in-memory repository implementation with seeded clinical records, validation logic, slot generation, and concurrency simulation.
- `features/appointments/presentation/`: Screens, reusable domain widgets, and Riverpod controllers/notifiers.
- `core/router/app_router.dart`: Integrated GoRouter route definitions with deep linking support.

---

## Directory Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_shadows.dart
│   │   ├── app_spacing.dart
│   │   └── app_typography.dart
│   ├── router/
│   │   └── app_router.dart                     [Updated: Added booking, confirmation, appointments routes]
│   └── widgets/
│       ├── cc_app_bar.dart
│       ├── cc_button.dart
│       ├── cc_card.dart
│       └── cc_chip.dart
├── features/
│   ├── appointments/                           [NEW FEATURE MODULE]
│   │   ├── data/
│   │   │   └── appointment_repository_impl.dart [In-memory mock repository, slot generation, validation]
│   │   ├── domain/
│   │   │   ├── appointment_draft.dart          [Immutable value object for pending bookings]
│   │   │   ├── appointment_repository.dart     [Abstract repository contract]
│   │   │   ├── booking_exception.dart          [Validation & conflict exception hierarchy]
│   │   │   └── time_slot.dart                  [TimeSlot entity with period enum (morning/afternoon/evening)]
│   │   └── presentation/
│   │       ├── appointment_history_screen.dart [Upcoming vs Past tabs, count badges, empty state]
│   │       ├── booking_confirmation_screen.dart [Receipt card, reference badge, navigation CTAs]
│   │       ├── booking_screen.dart              [Doctor summary, date strip, slot grid, sticky CTA]
│   │       ├── controllers/
│   │       │   └── appointment_providers.dart   [Riverpod providers: bookingController, slots, history]
│   │       └── widgets/
│   │           ├── appointment_history_card.dart [Interactive history item card]
│   │           ├── booking_doctor_summary_card.dart [Compact doctor header card]
│   │           ├── date_selector_strip.dart     [14-day horizontal selector strip]
│   │           └── time_slot_grid.dart          [Categorized time slot matrix]
│   ├── doctors/
│   │   ├── data/
│   │   ├── domain/
│   │   │   ├── appointment.dart                 [Extended: getters, copyWith, JSON serialization]
│   │   │   ├── doctor.dart
│   │   │   └── doctor_repository.dart
│   │   └── presentation/
│   │       ├── doctor_detail_screen.dart        [Updated: "Book Appointment" triggers booking route]
│   │       └── ...
│   ├── home/
│   │   └── presentation/
│   │       ├── home_screen.dart                 [Updated: quick booking links to booking route]
│   │       └── widgets/
│   │           └── home_header.dart             [Updated: header calendar icon links to /appointments]
│   └── patient/
│       ├── domain/
│       │   └── patient.dart                     [Updated: phone getter]
│       └── presentation/
│           └── patient_profile_screen.dart      [Updated: "View My Appointments" quick-action link]
```

---

## Riverpod Provider Dependency Graph

```
                                  ┌───────────────────────────────┐
                                  │ appointmentRepositoryProvider │
                                  └───────────────┬───────────────┘
                                                  │
                 ┌────────────────────────────────┼────────────────────────────────┐
                 ▼                                ▼                                ▼
  ┌─────────────────────────────┐  ┌─────────────────────────────┐  ┌─────────────────────────────┐
  │      doctorSlotsProvider    │  │  patientAppointmentsProvider│  │  bookingControllerProvider  │
  │ (Family: doctorId, date)    │  │ (Family: patientId)         │  │ (StateNotifier<AsyncValue>) │
  └─────────────────────────────┘  └──────────────┬──────────────┘  └─────────────────────────────┘
                                                  │
                                   ┌──────────────┴──────────────┐
                                   ▼                             ▼
                    ┌────────────────────────────┐ ┌───────────────────────────┐
                    │upcomingAppointmentsProvider│ │ pastAppointmentsProvider  │
                    └────────────────────────────┘ └───────────────────────────┘
```

1. **`appointmentRepositoryProvider`**: Provides singleton instance of `AppointmentRepository` (`AppointmentRepositoryImpl`).
2. **`doctorSlotsProvider`**: `FutureProvider.family<List<TimeSlot>, ({String doctorId, DateTime date})>` fetching real-time slots with past-time filtering and conflict checks.
3. **`patientAppointmentsProvider`**: `FutureProvider.family<List<Appointment>, String>` fetching all appointments for a patient.
4. **`upcomingAppointmentsProvider`**: Computed `FutureProvider` filtering confirmed appointments where `dateTime >= now`.
5. **`pastAppointmentsProvider`**: Computed `FutureProvider` filtering completed or elapsed appointments where `dateTime < now`.
6. **`bookingControllerProvider`**: `StateNotifierProvider<BookingNotifier, AsyncValue<Appointment?>>` orchestrating booking submission, validation, conflict catching, and repository persistence.

---

## GoRouter Routing Table

| Route Path | Route Name | Screen Component | Parameters / Extras | Description |
|---|---|---|---|---|
| `/` | `home` | `HomeScreen` | None | Doctor discovery, search, filter, and shortcuts. |
| `/doctor/:id` | `doctorDetail` | `DoctorDetailScreen` | `pathParameters['id']` | Doctor profile, bio, qualifications, and booking trigger. |
| `/doctor/:id/book` | `booking` | `BookingScreen` | `pathParameters['id']`, `extra: Doctor?` | Interactive booking engine (date, slot, modality, sticky CTA). |
| `/booking/confirmation` | `bookingConfirmation` | `BookingConfirmationScreen` | `extra: Appointment?`, query: `?id=...` | Official receipt with `#APT-XXXXXX` reference and navigation. |
| `/appointments` | `appointments` | `AppointmentHistoryScreen` | None | Upcoming & past appointment list with tab management. |
| `/patient/profile` | `patientProfile` | `PatientProfileScreen` | None | Patient profile and quick appointment access. |
| `/patient/edit` | `editPatientProfile` | `EditPatientProfileScreen` | None | Edit patient demographic information. |
