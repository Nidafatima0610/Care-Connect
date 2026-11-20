# CareConnect — Setup, Installation & Build Guide

## 1. Environment & Prerequisites

To set up, run, and build the CareConnect application, ensure the following tools are installed:

- **Flutter SDK:** Version `3.38.3` (or Dart SDK `>=3.3.0 <4.0.0`)
- **Java Development Kit (JDK):** JDK 17 (OpenJDK or Oracle JDK 17)
- **Android SDK:**
  - `compileSdkVersion`: **37** (required by `androidx.core:core:1.19.0` via `flutter_local_notifications` 23.0.3)
  - `minSdkVersion`: **21** (Android 5.0 Lollipop)
  - `targetSdkVersion`: **34** (Android 14)
- **Node.js (Optional):** Node v18+ for automated headless Chrome DevTools screenshot verification.

---

## 2. Project Installation & Setup

1. **Clone or Navigate to the Workspace:**
   ```bash
   cd "D:\Internship daily projects\care_connect"
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Dependencies and Tooling:**
   ```bash
   flutter doctor
   ```

---

## 3. Running the Project

### Running in Debug Mode
- **Chrome / Web:**
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

## 4. Verification & Testing Commands

To run the complete quality assurance pipeline:

1. **Format Code:**
   ```bash
   dart format .
   ```

2. **Static Analysis:**
   ```bash
   flutter analyze
   ```
   *Expected result: 0 issues found.*

3. **Automated Test Suite (117 Tests):**
   ```bash
   flutter test
   ```
   *Expected result: All 117 tests pass (100% success rate).*

4. **Run Specific Feature Tests:**
   ```bash
   # Persistent SQLite Database tests
   flutter test test/unit/appointment_database_test.dart

   # Cancellation workflow & slot release tests
   flutter test test/unit/appointment_cancellation_test.dart

   # Rescheduling & conflict validation tests
   flutter test test/unit/appointment_rescheduling_test.dart

   # Local notification reminder tests
   flutter test test/unit/reminder_service_test.dart
   ```

---

## 5. Android Build Guide & Known Host Limitations

### Command to Build Release APK
```bash
flutter build apk --release
```

### Critical Build Configuration Requirements
- **`compileSdk = 37`:** Configured in [android/app/build.gradle.kts](file:///d:/Internship%20daily%20projects/care_connect/android/app/build.gradle.kts).
- **Core Library Desugaring:** Configured for Java 8+ time APIs (`desugar_jdk_libs:2.1.4`).
- **Kotlin Incremental Daemon Settings:** Configured in [android/gradle.properties](file:///d:/Internship%20daily%20projects/care_connect/android/gradle.properties):
  ```properties
  kotlin.incremental=false
  kotlin.incremental.useClasspathSnapshot=false
  ```
  *This setting prevents the cross-drive Kotlin path root failure (`IllegalArgumentException: this and base files have different roots`) on Windows multi-drive environments.*

### Known Build Environment Blocker
- **Disk Drive Capacity (`errno = 112`):**
  When running `flutter build apk --release` on host drive `D:`, the build completed Dart tree-shaking and resource packaging, but failed during snapshot caching with:
  `FileSystemException: writeFrom failed, path = '...filecache' (OS Error: There is not enough space on the disk, errno = 112)`.
  Drive `D:` had 0.00 GB free space. To generate an APK on this host, at least 2.5 GB of free physical disk space must be available on the active drive.
