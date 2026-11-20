# CareConnect — Clinic Appointment Booking & Reminder Mobile App

CareConnect is a production-quality clinic appointment booking and reminder application built with Flutter. It delivers an intuitive, reassuring healthcare experience through a custom clinical design system, feature-first clean architecture, reactive state management with Riverpod, declarative routing with GoRouter, durable local SQLite persistence, and local notification reminders.

---

## 🎨 Design System & Visual Identity

CareConnect intentionally departs from generic template UIs and avoids purple gradients in favor of an authoritative, calm healthcare visual language:

- **Deep Navy (`#0E1A2D`, `#162740`):** Communicates clinical authority, structure, and security.
- **Sophisticated Teal (`#0E7490`, `#0891B2`):** Primary interactive brand color; represents vitality, clarity, and patient-centric care.
- **Warm Ivory (`#FBFBFA`) & Soft Neutrals:** Warm, comfortable reading surfaces with low eye strain.
- **Subtle Mint (`#10B981`):** Signals availability, online status, confirmed bookings, and health confirmation.
- **Warm Coral (`#EF4444`):** Soft destructive feedback for cancellations and critical disclaimers.
- **Warm Amber (`#F59E0B`):** Highlights offline status and patient satisfaction ratings.
- **Strict Theme System:** Tokenized design architecture (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadii`, `AppElevation`, `AppTheme`).

---

## 🏗️ Architecture & Feature-First Directory Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_assets.dart           # Fictional doctor portraits & placeholders
│   │   └── app_strings.dart          # Centralized UI copy & clinic metadata
│   ├── router/
│   │   └── app_router.dart           # GoRouter named routes, 404 handler & transitions
│   ├── theme/                        # AppColors, AppTypography, AppSpacing, AppTheme
│   └── widgets/                      # CareButton, CareCard, CareBadge, CareErrorView, etc.
├── features/
│   ├── appointments/
│   │   ├── domain/                   # AppointmentDraft, AppointmentRepository, BookingException
│   │   ├── data/
│   │   │   ├── appointment_database.dart       # SQLite database engine (v2 schema)
│   │   │   ├── appointment_repository_impl.dart# Persistent booking, cancel, reschedule repo
│   │   │   └── notification_service.dart       # flutter_local_notifications 23.0.3 integration
│   │   └── presentation/
│   │       ├── appointment_history_screen.dart # Persistent appointment history tabs
│   │       ├── booking_screen.dart             # 14-day date picker & slot selection
│   │       ├── booking_confirmation_screen.dart# Booking receipt & confirmation
│   │       ├── reschedule_screen.dart          # Interactive reschedule date/slot selector
│   │       └── widgets/                        # AppointmentHistoryCard, CancellationDialog, etc.
│   ├── doctors/
│   │   ├── domain/                   # Doctor, DoctorSpecialty, Appointment model
│   │   ├── data/                     # DoctorRepositoryImpl with simulated delay & errors
│   │   └── presentation/             # DoctorDetailScreen, DoctorCard, SpecialtyChips
│   ├── home/presentation/            # HomeScreen, HomeHeader, HomeHeroBanner
│   └── patient/
│       ├── domain/                   # Patient demographic model
│       ├── data/                     # LocalPatientRepository (SharedPreferences)
│       └── presentation/             # PatientProfileScreen, EditPatientProfileScreen
└── main.dart                         # ProviderScope & CareConnectApp entrypoint
```

---

## 🚀 5-Day Curriculum Progression

### Day 1: Foundation & Doctor Discovery
- Custom clinical design system and tokens (Navy, Teal, Ivory, Mint).
- Home dashboard with hero banner, specialty chips, and featured doctor carousels.
- Doctor details profile with 4-point clinical metrics bar and weekly schedule.

### Day 2: Data Integration, Patient Profile & Async States
- Reactive search query debouncer and multi-attribute specialty filtering.
- Patient profile with local identity backed by `shared_preferences`.
- Async loading shimmer skeletons, contextual empty states, and resilient error retry views.

### Day 3: Appointment Booking & Validation
- Interactive 14-day horizontal calendar date picker.
- Dynamic Morning, Afternoon, and Evening time-slot grid.
- Strict booking validation matrix (rejection of past dates/times, conflict protection).
- Booking confirmation receipt card and initial history list.

### Day 4: Persistence, Cancellation, Rescheduling & Local Reminders
- Upgraded storage to persistent local SQLite database (`sqflite`).
- Functional appointment cancellation with time-slot release and reminder cancellation.
- Functional appointment rescheduling with atomic slot swap and availability re-validation.
- Local notification reminders scheduled 30 minutes in advance (`flutter_local_notifications`).
- Offline-first capabilities with offline banner indicator and retry controls.

### Day 5: Quality Assurance, Final Verification & Submission
- Comprehensive automated testing across all layers: **117 / 117 tests passed (100%)**.
- Zero static analysis issues (`flutter analyze` clean).
- Complete code formatting (`dart format .`).
- Responsive verification across small (360 × 800) and standard (412 × 915) screen sizes.
- Automated headless Chrome capture of all 12 genuine evidence screenshots.
- Complete architectural documentation in `docs/`.

---

## 🧪 Testing & Verification Commands

```bash
# 1. Format code
dart format .

# 2. Run static analysis (0 issues)
flutter analyze

# 3. Run complete test suite (117 tests)
flutter test

# 4. Run application
flutter run
```

---

## 📋 Final Day 5 Quality Assurance Summary

| Metric | Target | Result | Status |
| :--- | :---: | :---: | :---: |
| **Flutter Analyzer Issues** | 0 | **0 issues found** (in 8.1s) | ✅ PASSED |
| **Unit Tests Passing** | $\ge 40$ | **45 / 45 passed** | ✅ PASSED |
| **Widget Tests Passing** | $\ge 50$ | **72 / 72 passed** | ✅ PASSED |
| **Total Automated Tests** | $\ge 90$ | **117 / 117 passed (100%)** | ✅ PASSED |
| **Responsive Verification** | 360x800 & 412x915 | Zero RenderFlex overflows | ✅ PASSED |
| **Visual Evidence** | 12 Genuine PNGs | Cataloged in `evidence/day_5/` | ✅ PASSED |
| **Walkthrough Video** | 1080p MP4 (3m 51s) | [careconnect_final_walkthrough.mp4](file:///d:/Internship%20daily%20projects/care_connect/evidence/day_5/careconnect_final_walkthrough.mp4) | ✅ PASSED |
| **Persistence Verification** | SQLite Across Restarts | Fully verified | ✅ PASSED |
| **Cancellation & Rescheduling** | Slot release & swap | Fully verified | ✅ PASSED |
| **Local Reminders** | 30m Lead Time | Verified in tests & demo | ✅ PASSED |
| **Scope Discipline** | No Firebase / No purple | 100% adherence | ✅ PASSED |
