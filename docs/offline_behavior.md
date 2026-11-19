# Offline & Unavailable-Source Handling Architecture

## 1. Overview
CareConnect follows a **local-first** paradigm. Because medical scheduling apps operate in critical clinical and mobile environments with intermittent connectivity, CareConnect guarantees that core functions—inspecting appointment history, reviewing medical consultation details, and modifying local records—remain fully operational offline.

---

## 2. Local-First Capabilities Matrix

| Functionality | Online Mode | Offline / Disconnected Mode | Fallback / Recovery Strategy |
|---|---|---|---|
| **View Past Bookings** | Persistent SQLite DB | Persistent SQLite DB | Full offline access; zero data degradation |
| **View Upcoming Bookings**| Persistent SQLite DB | Persistent SQLite DB | Full offline access; zero data degradation |
| **Reschedule Appointment**| SQLite + Slot Pool | SQLite + Local Slot Cache | Updates local SQLite; notifies patient of local-first persistence |
| **Cancel Appointment** | SQLite + Slot Pool | SQLite + Local Slot Cache | Soft-cancels locally; releases slot locally; cancels local alarm |
| **Doctor Directory** | Repository Cache | In-Memory Mock Repository | Returns pre-seeded doctor records with specialties and fees |
| **Reminders** | Local Exact Alarms | Local Exact Alarms | Operates 100% on device via `AlarmManager` without network calls |

---

## 3. UI Representation of Offline State

1. **Offline Status Banner**:
   - When offline mode is detected or simulated via `offlineModeProvider`, an amber/coral offline badge appears at the top of the screen:
     > *"Offline Mode: Showing locally saved appointments and schedule. Changes will persist on your device."*
2. **No Data Loss Guarantee**:
   - The app never displays an empty state simply because network access is unavailable. If appointments exist in SQLite, they are rendered immediately.
3. **Retry Mechanism**:
   - If an unexpected error occurs during database access or repository querying, the UI renders a structured error state with a **"Retry Connection"** action that invokes Riverpod `ref.refresh()` to reload the provider.
4. **Honest Synchronization Notice**:
   - CareConnect explicitly avoids showing deceptive "Synced to Cloud" checkmarks when running in local-first mode. It clearly communicates that data is safely stored on the patient's device.
