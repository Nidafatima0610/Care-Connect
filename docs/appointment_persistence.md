# Appointment Persistence Architecture & Implementation

## 1. Overview
In CareConnect Day 4, appointment storage transitioned from transient in-memory state to a robust, local-first persistent SQLite database using `sqflite` (with `sqflite_common_ffi` for desktop and headless unit/widget testing environments, and an in-memory fallback for web runtimes).

Every appointment booked, rescheduled, or cancelled persists across application restarts, ensuring patient records remain durable, auditable, and resilient without requiring cloud connectivity.

---

## 2. Database Schema

The database is named `careconnect_appointments.db` with schema version `2`.

```sql
CREATE TABLE appointments (
  id TEXT PRIMARY KEY,
  doctor_id TEXT NOT NULL,
  patient_id TEXT NOT NULL,
  date TEXT NOT NULL,
  start_time TEXT NOT NULL,
  status TEXT NOT NULL,
  fee REAL NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  reminder_minutes_before INTEGER NOT NULL DEFAULT 30,
  reminder_scheduled INTEGER NOT NULL DEFAULT 1
);
```

### Column Specifications
| Column Name | Type | Description |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | Unique UUID or deterministic string identifier (e.g. `apt-1700000000000-abcd`) |
| `doctor_id` | `TEXT NOT NULL` | Foreign identifier linking appointment to the doctor entity |
| `patient_id` | `TEXT NOT NULL` | Patient identity string (defaults to `pat_local_user`) |
| `date` | `TEXT NOT NULL` | ISO 8601 calendar date string (`YYYY-MM-DD`) |
| `start_time` | `TEXT NOT NULL` | Appointment start time in 12h or 24h format (e.g. `10:00 AM`) |
| `status` | `TEXT NOT NULL` | Status string: `confirmed`, `completed`, or `cancelled` |
| `fee` | `REAL NOT NULL` | Consultation fee decimal value |
| `created_at` | `TEXT NOT NULL` | ISO 8601 creation timestamp |
| `updated_at` | `TEXT` | ISO 8601 last modification timestamp (populated upon reschedule or cancellation) |
| `reminder_minutes_before` | `INTEGER` | Lead time in minutes for local notification reminder (default 30) |
| `reminder_scheduled` | `INTEGER` | Boolean flag (1/0) indicating whether local notification is registered |

---

## 3. SQLite Implementation Details

### Isolated Factory & Testing Support
The database engine is managed by `AppointmentDatabase` in [appointment_database.dart](file:///d:/Internship%20daily%20projects/care_connect/lib/features/appointments/data/appointment_database.dart).
- **Desktop/Testing**: In Windows desktop or unit/widget test environments (`Platform.isWindows` or `WidgetsBinding.instance is TestWidgetsFlutterBinding`), `databaseFactoryFfi` is initialized with `sqfliteFfiInit()`.
- **In-Memory Testing Mode**: During automated tests, SQLite runs in `:memory:` to ensure lightning-fast test execution and complete isolation without filesystem locks or Windows method-channel hangs.
- **Web Graceful Fallback**: In web environments where native SQLite FFI is unavailable, `AppointmentDatabase` transparently utilizes an in-memory cache synchronized with browser local storage emulation.

### Domain Entity Mapping
Safe bidirectional conversions between SQLite `Map<String, dynamic>` records and immutable domain `Appointment` entities are implemented via:
- `Appointment.fromMap(Map<String, dynamic> map)`
- `Appointment.toMap()`

```dart
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'doctor_id': doctorId,
    'patient_id': patientId,
    'date': date.toIso8601String().split('T').first,
    'start_time': startTime,
    'status': status.name,
    'fee': fee,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'reminder_minutes_before': reminderMinutesBefore,
    'reminder_scheduled': reminderScheduled ? 1 : 0,
  };
}
```

---

## 4. CRUD Operations & State Guarantees

1. **Insert (`insertAppointment`)**:
   - Inserts record with `ConflictAlgorithm.replace`.
   - Re-validates that no active booking exists for the same doctor at that date/slot.
2. **Retrieve (`getAllAppointments`, `getAppointmentById`)**:
   - Queries `SELECT * FROM appointments ORDER BY date ASC, start_time ASC`.
   - Filters upcoming vs. past appointments dynamically based on current system time.
3. **Update (`updateAppointment`)**:
   - Used during rescheduling and cancellation.
   - Atomically updates `status`, `date`, `start_time`, `updated_at`, and reminder flags.
4. **Delete (`deleteAppointment`)**:
   - Supported for administrative cleanup, but business logic prefers soft-deletion (`status = cancelled`) to preserve patient medical history.

---

## 5. App Restart Resilience

When the application boots:
1. `appointmentDatabaseProvider` executes `AppointmentDatabase.instance.database`.
2. Seed appointments (if database is brand new) are safely populated so the patient has realistic initial medical history.
3. All subsequent queries hit the SQLite file directly.
4. If the process is terminated and restarted, all confirmed, rescheduled, and cancelled appointments remain intact with exact timestamps.
