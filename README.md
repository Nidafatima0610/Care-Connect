# CareConnect — Clinic Appointment Booking & Reminder Mobile App

CareConnect is a production-quality clinic appointment booking and reminder application built with Flutter. It delivers a distinguished, reassuring, and intuitive healthcare experience through a custom design system, feature-first clean architecture, reactive state management with Riverpod, and declarative deep-linked routing with GoRouter.

---

## 🎨 Design System & Visual Identity

CareConnect intentionally departs from generic template UIs and avoids purple gradients in favor of an authoritative, calm healthcare visual language:

- **Deep Navy (`#0E1A2D`, `#162740`):** Communicates clinical authority, structure, and security.
- **Sophisticated Teal (`#0E7490`, `#0891B2`):** Primary interactive brand color; represents vitality, clarity, and patient-centric care.
- **Warm Ivory (`#FBFBFA`) & Soft Neutrals:** Warm, comfortable reading surfaces with low eye strain.
- **Subtle Mint (`#10B981`):** Signals availability, online status, and health confirmation.
- **Warm Amber (`#F59E0B`):** Highlights verified patient satisfaction ratings and credentials.
- **Light Theme Primary with Dark Theme Readiness:** Full tokenized theme system (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadii`, `AppElevation`, `AppTheme`).

---

## 🏗️ Architecture & Feature-First Directory Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_assets.dart           # Fictional doctor portraits & placeholders
│   │   └── app_strings.dart          # Centralized UI copy & clinic metadata
│   ├── router/
│   │   └── app_router.dart           # GoRouter named routes, 404 handler & slide transitions
│   ├── theme/
│   │   ├── app_colors.dart           # Navy, Teal, Ivory, Mint color tokens
│   │   ├── app_elevation.dart        # Layered subtle drop shadows
│   │   ├── app_radii.dart            # Predictable corner radii
│   │   ├── app_spacing.dart          # 4-based spacing scale
│   │   ├── app_theme.dart            # ThemeData (lightTheme & darkTheme)
│   │   └── app_typography.dart       # Typographic scale
│   └── widgets/
│       ├── care_badge.dart           # Rating, specialty, and status badges
│       ├── care_button.dart          # Accessible tactile primary & outline buttons
│       ├── care_card.dart            # Elevated surface card container
│       ├── care_doctor_card_skeleton.dart # Shimmer pulse skeleton for doctor cards
│       ├── care_empty_state.dart     # Contextual zero-result presentation
│       ├── care_error_view.dart      # Resilient error view with retry action
│       ├── care_search_bar.dart      # Real-time search with clear & filter triggers
│       └── care_section_header.dart  # Uniform section titles with optional trailing action
├── features/
│   ├── booking/presentation/
│   │   └── booking_placeholder_sheet.dart # Day 1 appointment roadmap modal
│   ├── doctors/
│   │   ├── domain/
│   │   │   ├── doctor.dart           # Immutable Doctor entity & DoctorRepository contract
│   │   │   └── doctor_specialty.dart # Clinical specialty enum & taxonomy
│   │   ├── data/
│   │   │   ├── doctor_repository.dart# DoctorRepositoryImpl with simulated delay & errors
│   │   │   └── mock_doctor_data.dart # 9 fictional specialists across 8 specialties
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── doctor_providers.dart # Riverpod directory, search & filter providers
│   │       ├── doctor_detail_screen.dart # Full doctor clinical profile screen
│   │       └── widgets/
│   │           ├── doctor_card.dart  # Directory card with fee & actions
│   │           ├── doctor_detail_metrics.dart # 4-point clinical metrics bar
│   │           ├── doctor_featured_card.dart  # Spotlight horizontal card
│   │           └── specialty_chip.dart # Department filter chip
│   ├── home/presentation/
│   │   ├── home_screen.dart          # Doctor discovery dashboard with sliver architecture
│   │   └── widgets/
│   │       ├── home_header.dart      # Welcoming patient header & notification bell
│   │       ├── home_hero_banner.dart # Care promotion gradient hero card
│   │       └── home_specialty_selector.dart # Horizontal specialty scroll
│   └── patient/
│       ├── domain/
│       │   └── patient.dart          # Immutable Patient entity with clinical preferences
│       ├── data/
│       │   └── patient_repository.dart # LocalPatientRepository with SharedPreferences persistence
│       └── presentation/
│           ├── controllers/
│           │   └── patient_provider.dart # patientProfileProvider AsyncNotifier
│           ├── patient_profile_screen.dart # Patient identity, MRN, allergies, preferences
│           └── edit_patient_profile_screen.dart # Form-validated demographic editor
└── main.dart                         # ProviderScope & CareConnectApp entrypoint
```

---

## 🚀 Progress & Deliverables

### Day 1: Foundation & Doctor Discovery
- **Visual Foundation:** Design tokens, theme system, color palette, custom typography, elevation, and radii.
- **Home / Doctor Discovery Screen (`/`):** Dynamic clinic header, hero banner, search bar, specialty category chips, featured doctors horizontal carousel, and all doctors directory.
- **Doctor Detail Screen (`/doctor/:id`):** Physician credentials, 4-point metrics bar, clinical biography, weekly schedule, consultation modalities, hospital facility, and sticky consultation fee / booking CTA.
- **Roadmap Modal:** Transparent Day 1 booking roadmap bottom sheet.
- **Testing:** 24 unit and widget tests establishing foundational test coverage.

### Day 2: Data Integration, Patient Profile & Async States
- **Asynchronous Doctor Data Pipeline:**
  - Upgraded `DoctorRepository` interface and `DoctorRepositoryImpl` with simulated network delay (default 300ms) and simulated network failure injection.
  - Reactive search query debouncer (`debouncedSearchQueryProvider`, 250ms debounce with instant reset) preventing UI thrashing and stale race conditions.
  - Multi-attribute doctor filtering combining name, specialty, subspecialty, clinic facility, and credentials.
- **Patient Profile & Local Identity Flow:**
  - Complete `Patient` domain model with demographics (full name, email, phone, DOB, blood group, allergies, emergency contact, preferred clinic) and computed properties (`initials`, `age`).
  - Persistent `LocalPatientRepository` backed by `shared_preferences` with auto-seeding demo profile (`Sarah Jenkins`, `MRN-849204`).
  - `PatientProfileScreen` (`/profile`): Displays patient avatar, MRN badge, verified patient status, contact details, clinical preferences, and educational demo disclaimer.
  - `EditPatientProfileScreen` (`/profile/edit`): Full client-side form validation (name min 2 chars, email regex, phone min 7 digits, DOB native picker, blood group dropdown, emergency contact validation).
  - Dynamic `HomeHeader`: Reactive patient initials avatar and personalized greeting.
- **Comprehensive Asynchronous States:**
  - **Loading State:** `CareDoctorListSkeleton` featuring pulse-animated card skeletons matching the exact card hierarchy.
  - **Error State:** `CareErrorView` with informative healthcare copy and a functional "Retry" button that invalidates caches and triggers fresh retrieval.
  - **Empty State:** `CareEmptyState` with contextual zero-results messaging and a one-tap "Reset Filters" action.
  - **QA Simulation Affordance:** Built-in simulation switches in the filter modal and URL parameters (`?state=loading`, `?state=error`) for automated testing and manual QA verification.
- **Testing:** Expanded test suite to **50 fully passing automated tests** (28 unit tests and 22 widget tests) with 0 analyzer issues.

---

## 🧪 Testing & Verification

Run the complete test suite:
```bash
flutter test
```

Analyze code health:
```bash
flutter analyze
```

Format code:
```bash
dart format .
```

Run application on web / emulator:
```bash
flutter run
```

---

## 📋 Comprehensive Day 2 Verification Summary

| Metric | Target | Result | Status |
| :--- | :---: | :---: | :---: |
| Flutter Analyzer Issues | 0 | 0 issues found | ✅ PASSED |
| Unit Tests Passing | $\ge 20$ | 28 / 28 passed | ✅ PASSED |
| Widget Tests Passing | $\ge 15$ | 22 / 22 passed | ✅ PASSED |
| Total Automated Tests | $\ge 40$ | **50 / 50 passed** | ✅ PASSED |
| Real Running Screenshots | 7 PNGs | 7 captured & inspected | ✅ PASSED |
| Scope Discipline | No bookings/real auth | 100% adherence | ✅ PASSED |
