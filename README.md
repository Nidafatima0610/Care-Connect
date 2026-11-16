# CareConnect — Appointment Booking & Reminder Mobile App

CareConnect is a production-quality clinic appointment booking and reminder application built with Flutter. It delivers a distinguished, reassuring, and intuitive healthcare experience through a custom design system, feature-first clean architecture, reactive state management with Riverpod, and declarative deep-linked routing with GoRouter.

---

## 🎨 Design System & Visual Identity

CareConnect intentionally departs from generic template UIs and avoids purple gradients in favor of an authoritative, calm healthcare visual language:

- **Deep Navy (`#0E1A2D`, `#162740`):** Communicates clinical authority, structure, and security.
- **Sophisticated Teal (`#0E7490`, `#0891B2`):** Primary interactive brand color; represents vitality, clarity, and patient-centric care.
- **Warm Ivory (`#FBFBFA`) & Soft Neutrals:** Warm, comfortable reading surfaces with low eye strain.
- **Subtle Mint (`#10B981`):** Signals availability, online status, and health confirmation.
- **Warm Amber (`#F59E0B`):** Highlights verified patient satisfaction ratings and credentials.
- **Light Theme Primary with Dark Theme Readiness:** Full tokenized theme system (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadii`, `AppShadows`, `AppTheme`).

---

## 🏗️ Architecture & Feature-First Directory Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_strings.dart             # Centralized UI copy & clinic metadata
│   ├── router/
│   │   └── app_router.dart              # GoRouter named routes, 404 handler & slide transitions
│   ├── theme/
│   │   ├── app_colors.dart              # Navy, Teal, Ivory, Mint color tokens
│   │   ├── app_radii.dart               # Predictable corner radii
│   │   ├── app_shadows.dart             # Navy-tinted soft elevation shadows
│   │   ├── app_spacing.dart             # 4-based spacing scale
│   │   ├── app_theme.dart               # ThemeData (lightTheme & darkTheme)
│   │   └── app_typography.dart          # Typographic scale
│   └── widgets/
│       ├── care_badge.dart              # Rating, specialty, and status badges
│       ├── care_button.dart             # Accessible tactile primary & outline buttons
│       ├── care_card.dart               # Elevated surface card container
│       ├── care_empty_state.dart        # Search & filter empty state view
│       ├── care_error_view.dart         # Graceful error & retry container
│       ├── care_search_bar.dart         # Real-time search with clear & filter triggers
│       ├── care_section_header.dart     # Section title with subtitle & actions
│       ├── doctor_avatar.dart           # Portrait avatar with fallback gradient initials
│       └── notification_bottom_sheet.dart # Clinic notices & updates sheet
├── features/
│   ├── doctors/
│   │   ├── data/
│   │   │   ├── doctor_repository.dart   # Abstract contract & in-memory implementation
│   │   │   └── mock_doctor_data.dart    # 9 fictional specialists across 8 specialties
│   │   ├── domain/
│   │   │   ├── appointment.dart         # Appointment foundation schema (Days 2-5)
│   │   │   ├── doctor.dart              # Physician domain entity
│   │   │   └── doctor_specialty.dart    # Departmental specialties enum
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── doctor_providers.dart# Riverpod Notifier & Future providers
│   │       ├── doctor_detail_screen.dart# Full doctor clinical profile screen
│   │       └── widgets/
│   │           ├── booking_placeholder_sheet.dart # Day 1 milestone modal
│   │           ├── doctor_card.dart     # Directory card with fee & actions
│   │           ├── doctor_detail_metrics.dart # 4-point clinical metrics bar
│   │           ├── doctor_featured_card.dart  # Spotlight horizontal card
│   │           └── specialty_chip.dart  # Department filter chip
│   └── home/
│       └── presentation/
│           ├── home_screen.dart         # Home / Doctor Discovery dashboard
│           └── widgets/
│               ├── home_header.dart     # Welcoming patient header & notification bell
│               ├── home_hero_banner.dart# Care promotion gradient hero card
│               └── home_specialty_selector.dart # Horizontal specialty scroll
└── main.dart                            # ProviderScope & CareConnectApp entrypoint
```

---

## 📱 Implemented Day 1 Scope

### Screen 1: Home / Doctor Discovery Dashboard
1. **Clinic Header:** CareConnect Metropolitan Center branding, personalized greeting to patient "Maya Sterling", patient avatar opening profile sheet, and notification bell opening real-time clinic updates.
2. **Promotional Hero Banner:** Deep Navy & Teal banner communicating immediate and scheduled clinical care options across departments.
3. **Interactive Search Bar:** Real-time query matching filtering doctors by name, specialty, subspecialty, qualification, and clinic name. Includes clear button and filter options modal.
4. **Specialty Filter Selector:** One-tap departmental chips (Cardiology, Dermatology, Pediatrics, General Medicine, Neurology, Orthopedics, Ophthalmology, Psychiatry). Active selection highlights in Teal.
5. **Featured Specialists Carousel:** Curated spotlight section displaying verified top-rated physicians with instant availability summaries and fee previews.
6. **Available Doctors Directory:** Full physician cards featuring portrait avatars, online status, credentials, experience badges, patient review counts, clinic facility, consultation fees, and profile navigation.
7. **Comprehensive States:** Pull-to-refresh, loading indicator, graceful error handling, and clean empty state with a "Reset Filters" action.

### Screen 2: Doctor Detail Clinical Profile
1. **Header & Portrait:** Deep navy header with back navigation, bookmark/save physician toggle with SnackBar feedback, share link action, doctor portrait avatar with online status, and full credentials.
2. **Clinical Performance Bar:** 4-point metrics summary: Star Rating, Years of Experience, Total Patients Treated, and Spoken Consultation Languages.
3. **About Specialist:** Detailed narrative biography explaining care approach and clinical focus.
4. **Weekly Availability Schedule:** Operational hours and weekly schedule day chips with immediate availability callout.
5. **Consultation Modalities:** Visual status cards for In-Person Clinic Visits and Telehealth HD Video Consultations.
6. **Clinic Facility:** Outpatient center name and physical pavilion/suite location.
7. **Education & Credentials:** Verified badge list of medical degrees, residency hospitals, and board certifications.
8. **Sticky Bottom Action Bar:** Transparent consultation fee and prominent **"Book Appointment"** button.
9. **Day 1 Milestone Booking Roadmap Modal:** Tapping "Book Appointment" surfaces a clearly marked bottom sheet detailing the upcoming Day 2 slot selection engine. Completely honest—no dead buttons and no fake completed bookings.

---

## 🛠️ Tech Stack & Packages

- **Flutter SDK:** 3.47.1 (Dart 3.13.1)
- **State Management:** `flutter_riverpod: ^3.5.0` (Notifier & FutureProvider)
- **Navigation:** `go_router: ^18.1.4` (Declarative named routes & CustomTransitionPage)
- **Localization & Formatting:** `intl: ^0.20.3`
- **Linting:** `flutter_lints: ^6.0.0`

---

## 🚀 Run & Verification Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Format Code
```bash
dart format .
```

### 3. Run Static Analyzer
```bash
flutter analyze
```
*(Result: 0 issues found!)*

### 4. Run Test Suite
```bash
flutter test
```
*(Result: 28 unit and widget tests passed!)*

### 5. Launch the Application
- **Web (Chrome):**
  ```bash
  flutter run -d chrome
  ```
- **Windows Desktop:**
  ```bash
  flutter run -d windows
  ```
- **Android Device / Emulator:**
  ```bash
  flutter run -d android
  ```

---

## 📸 Runtime Evidence

Authentic runtime evidence captured directly from the Flutter rendering pipeline is preserved in [`evidence/day_1/`](evidence/day_1/):

1. **`01_home_screen.png`**: Home dashboard with CareConnect branding, patient greeting, promotional hero, specialty chips, featured doctors, and available doctor directory.
2. **`02_doctor_search_filtering.png`**: Real-time search query filtering results dynamically.
3. **`03_doctor_detail_screen.png`**: Physician clinical profile with 4-point metrics bar, biography, schedule, clinic location, credentials, and sticky booking bar.
4. **`04_booking_roadmap_modal.png`**: Day 1 milestone modal surfacing the Day 2 booking engine roadmap upon tapping "Book Appointment".
5. **`test_run_output.txt`**: Execution transcript verifying all tests passed.
6. **`analyzer_output.txt`**: Static analysis report verifying 0 warnings or errors.

---

## 🗓️ 5-Day Internship Roadmap (16–20 November 2026)

- **Day 1 (Completed):** Complete architecture foundation, custom design system, patient journey specification, appointment data model foundation, connected doctor discovery dashboard, and doctor detail screens.
- **Day 2:** Interactive calendar slot picker, morning/afternoon/evening time slot selection, and consultation modality toggle (In-Person vs. Telehealth).
- **Day 3:** Patient intake reason notes, appointment booking confirmation review, and appointment state machine (`pending` → `confirmed`).
- **Day 4:** Appointment history dual-tab view (Upcoming vs. Past), appointment cancellation, and rescheduling workflows.
- **Day 5:** Automated appointment reminder triggers, digital visit summary notes, and final end-to-end integration polish.
