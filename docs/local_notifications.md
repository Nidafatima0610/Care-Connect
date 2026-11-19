# Local Appointment Reminders Architecture

## 1. Overview
CareConnect incorporates local-first notifications via `flutter_local_notifications` (v23.0.3) to provide timely, offline-capable reminders without depending on Firebase Cloud Messaging (FCM) or remote cloud push services.

---

## 2. Notification System Design

### Architecture Diagram
```
[Appointment Confirmed / Rescheduled]
                 |
                 v
   [NotificationService.scheduleReminder()]
                 |
                 +---> Calculate Lead Time (Appointment Time - 30 minutes)
                 |
                 +---> Safety Checks:
                 |     - Is appointment in the past? -> Skip
                 |     - Is lead time in past but appointment in future?
                 |       -> Schedule immediate or +2 min warning
                 |     - Is appointment cancelled? -> Cancel notification
                 |
                 v
  [FlutterLocalNotificationsPlugin.zonedSchedule()]
                 |
                 +---> Android Notification Channel:
                 |     - ID: 'careconnect_reminders_channel'
                 |     - Name: 'Appointment Reminders'
                 |     - Importance: High / Priority: High
                 |     - Sound: Default alert tone
                 |     - Vibration: Enabled
                 |
                 v
      [Local Device Alarm Manager]
```

---

## 3. Lead Time Logic & Boundary Rules

1. **Standard Scheduling**:
   - Default reminder lead time is **30 minutes** prior to the appointment start time.
   - Example: For an appointment at 10:00 AM on Nov 20, 2026, the reminder fires at 9:30 AM on Nov 20, 2026.
2. **Proximity Edge Cases**:
   - If a patient books an appointment that starts in 15 minutes, a 30-minute lead time would be in the past. In this scenario, `NotificationService` schedules the reminder to trigger within 1 minute of booking so the patient still receives an alert.
3. **Past Appointments**:
   - No reminders are scheduled for historical appointments.
4. **Stable ID Hashing**:
   - Android notification IDs are 32-bit integers. Appointment UUIDs (e.g., `apt-1700000000000-abcd`) are stably mapped to a deterministic integer using `appointmentId.hashCode.abs() % 1000000`. This ensures that updating or cancelling an appointment targets the exact same notification ID.
5. **Channel Specifications**:
   - Channel ID: `careconnect_reminders_channel`
   - Channel Name: `CareConnect Appointment Reminders`
   - Description: `Notifications for upcoming consultations and medical appointments`
   - Importance: `Importance.high`
   - Priority: `Priority.high`

---

## 4. Android Configuration & Permissions

### Permissions in `AndroidManifest.xml`
```xml
<!-- Local reminder permissions -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

### In-App Demo & Testing Trigger
To allow testing and demonstration without waiting for a real-world appointment time:
- The UI features a **"Notification Settings & Demo"** bottom sheet (`ReminderSettingsSheet`).
- Includes a **"Trigger Instant Demo Reminder"** button that dispatches a simulated 5-second notification with doctor name and time.
