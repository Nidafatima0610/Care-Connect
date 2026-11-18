# CareConnect — Day 3 Patient Booking Flow

## Overview

The CareConnect appointment booking engine delivers an end-to-end patient experience adhering strictly to modern clinical ergonomics and the established CareConnect design system (Deep Navy `#0E1A2D`, Sophisticated Teal `#0E7490`, Warm Ivory `#FBFBFA`, and Subtle Mint `#10B981`).

The booking flow transitions the patient seamlessly from discovery to post-booking verification:
```
Doctor Discovery (Home)
       │
       ▼
 Doctor Details (/doctor/:id)
       │  [Tap "Book Appointment" CTA]
       ▼
 Appointment Booking Screen (/doctor/:id/book)
       ├── 1. Review Doctor Summary Card
       ├── 2. Select Date (14-Day Calendar Strip)
       ├── 3. Choose Time Slot (Morning / Afternoon / Evening)
       ├── 4. Select Modality (In-Person Visit vs. Video Visit)
       ├── 5. Enter Optional Symptoms / Notes
       ├── 6. Inspect Booking Review Summary
       │  [Tap "Confirm Appointment" Sticky CTA]
       ▼
 Booking Confirmation Screen (/booking/confirmation)
       ├── Animated Mint Success Badge
       ├── Unique Reference Identifier (#APT-XXXXXX)
       ├── Detailed Appointment Receipt Card
       └── Quick Navigation ("View in My Appointments" / "Done & Back to Home")
       │
       ▼
 Appointment History Screen (/appointments)
       ├── "Upcoming" Tab (Confirmed appointments with countdown indicators)
       ├── "Past" Tab (Completed historical appointments)
       └── Empty State CTAs ("Browse Doctors")
```

---

## Screen Breakdown & Interaction Lifecycle

### 1. Doctor Details Entry Point
- **Location:** `lib/features/doctors/presentation/doctor_detail_screen.dart`
- **Trigger:** Tapping the primary "Book Appointment" CTA at the bottom of the doctor detail profile.
- **Routing:** Navigates via GoRouter to `AppRouteNames.booking` (`/doctor/:id/book`), passing the active `doctor` instance in `GoRouterState.extra`. If accessed directly via URL, the booking screen falls back to loading the doctor via `doctorByIdProvider(id)`.

### 2. Interactive Booking Screen (`/doctor/:id/book`)
- **Location:** `lib/features/appointments/presentation/booking_screen.dart`
- **Components:**
  1. **Doctor Summary Card (`BookingDoctorSummaryCard`):** Displays doctor avatar with mint status badge, full name, specialty, clinic location, clinical rating, total reviews, and consultation fee in an elevated warm ivory card.
  2. **14-Day Date Selector Strip (`DateSelectorStrip`):** Horizontal scrollable calendar strip generating 14 contiguous days starting from today.
     - Displays 3-letter weekday abbreviation, calendar day number, and short month name.
     - Selectable dates are rendered in warm ivory surfaces with subtle borders; the active date is highlighted in deep teal (`#0E7490`) with white text and a mint indicator dot.
     - Sundays are styled with reduced opacity (50%), a small lock/off icon, and are non-interactive to enforce clinic weekend operating hours.
  3. **Grouped Time Slot Grid (`TimeSlotGrid`):**
     - Organized into three chronological periods: **Morning** (09:00 AM – 12:00 PM), **Afternoon** (12:00 PM – 05:00 PM), and **Evening** (05:00 PM – 08:00 PM).
     - Each slot is rendered in a 3-column responsive grid wrapped in `FittedBox` to prevent any text clipping or pixel overflow.
     - States:
       - *Available:* Crisp border, teal hover/tap state, accessible touch target.
       - *Selected:* Solid teal background, white typography, subtle mint checkmark.
       - *Unavailable / Booked:* Subdued surface (`#F1F5F9`), muted strikethrough text, lock icon.
  4. **Modality Selector (`_buildModalitySelector`):**
     - Two distinct clinical consultation options: **In-Person Visit** (clinic address listed) and **Video Visit** (telehealth link generated upon confirmation).
     - Selecting an option immediately updates the booking draft state and summary fee structure.
  5. **Symptoms / Chief Complaint Input (`_buildNotesField`):**
     - Multi-line text field allowing patients to specify their primary symptoms, concerns, or reason for visit.
  6. **Live Booking Review Summary (`_buildReviewSummary`):**
     - Collapsible/prominent summary card displaying:
       - Selected Date and Time Slot
       - Modality & Location
       - Patient Name & Contact
       - Consultation Fee Breakdown
  7. **Sticky Bottom Confirmation Bar (`_buildStickyBottomBar`):**
     - Pinned above device safe area with a frosted elevation shadow.
     - Displays total consultation fee on the left and primary "Confirm Appointment" button on the right.
     - Button automatically disables when no slot is selected or when a booking request is currently processing (showing a circular progress indicator).

### 3. Booking Confirmation Screen (`/booking/confirmation`)
- **Location:** `lib/features/appointments/presentation/booking_confirmation_screen.dart`
- **Features:**
  - **Mint Success Icon:** 72x72 container with subtle mint tint (`#ECFDF5`), deep teal check icon, and gentle scale animation.
  - **Official Appointment Receipt:**
    - Unique Reference Badge: `#APT-XXXXXX` generated via cryptographic 6-digit randomizer.
    - Doctor summary (Avatar, Name, Specialty, Clinic).
    - Patient details (Full Name, Phone).
    - Schedule details (Formatted Date, Time Slot, Modality).
    - Fee status (Paid / Consultation Fee).
  - **Action Controls:**
    - Primary CTA: "View in My Appointments" (navigates to `/appointments`).
    - Secondary CTA: "Done & Back to Home" (clears booking navigation stack and returns to `/`).

### 4. Appointment History Screen (`/appointments`)
- **Location:** `lib/features/appointments/presentation/appointment_history_screen.dart`
- **Structure:**
  - TabBar with two tabs: **Upcoming** (with count badge) and **Past**.
  - Integrated directly into the patient experience via header calendar icon and patient profile quick actions.
