import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../doctors/domain/appointment.dart';

/// SQLite persistence manager for CareConnect clinical appointments.
///
/// Provides robust local-first SQLite storage across Android, iOS, desktop,
/// and automated test runners, with graceful fallback for web environments.
class AppointmentDatabase {
  static AppointmentDatabase? _instance;
  static AppointmentDatabase get instance =>
      _instance ??= AppointmentDatabase._internal();

  static int _isolatedCounter = 0;
  final int? _isolatedId;

  /// Identifier for isolated sandbox instances, null for singleton.
  int? get isolatedId => _isolatedId;

  AppointmentDatabase._internal([this._isolatedId]);

  /// Creates a dedicated, isolated database instance (ideal for tests and sandboxes).
  factory AppointmentDatabase.createIsolated() {
    return AppointmentDatabase._internal(++_isolatedCounter);
  }

  Database? _db;
  bool _isInitialized = false;

  // In-memory fallback cache used primarily during web executions where native SQLite FFI is unavailable
  final Map<String, Appointment> _memoryCache = {};

  static const String tableName = 'appointments';
  static const String databaseName = 'careconnect_appointments.db';
  static const int databaseVersion = 1;

  Database? get database => _db;
  bool get isInitialized => _isInitialized;

  /// Initializes the SQLite database engine.
  Future<void> init({
    String? dbPath,
    bool inMemory = false,
    bool force = false,
  }) async {
    if (!force && _isInitialized && _db != null && _db!.isOpen) {
      return;
    }

    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
      _isInitialized = false;
    }

    if (kIsWeb) {
      _isInitialized = true;
      await _seedFallbackIfEmpty();
      return;
    }

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final bool isFlutterTest =
          inMemory ||
          Platform.environment.containsKey('FLUTTER_TEST') ||
          Platform.script.path.contains('_test.dart') ||
          WidgetsBinding.instance.runtimeType.toString().contains('Test');

      final String finalPath;
      if (isFlutterTest && dbPath == null) {
        finalPath = inMemoryDatabasePath;
      } else if (dbPath != null) {
        finalPath = dbPath;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        finalPath = databaseName;
      } else {
        final dbDir = await databaseFactory.getDatabasesPath();
        finalPath = '$dbDir/$databaseName';
      }

      _db = await databaseFactory.openDatabase(
        finalPath,
        options: OpenDatabaseOptions(
          version: databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );

      _isInitialized = true;
      await seedInitialDataIfEmpty();
    } catch (e) {
      debugPrint('[AppointmentDatabase] Initialization warning: $e');
      _isInitialized = true;
      await _seedFallbackIfEmpty();
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        doctorId TEXT NOT NULL,
        doctorName TEXT NOT NULL,
        doctorSpecialty TEXT NOT NULL,
        clinicName TEXT NOT NULL,
        clinicAddress TEXT NOT NULL,
        patientId TEXT NOT NULL,
        patientName TEXT NOT NULL,
        patientPhone TEXT NOT NULL,
        scheduledDateTime TEXT NOT NULL,
        timeSlot TEXT NOT NULL,
        status TEXT NOT NULL,
        modality TEXT NOT NULL,
        fee REAL NOT NULL,
        currency TEXT NOT NULL,
        patientNotes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        reminderMinutesBefore INTEGER,
        reminderScheduled INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration handling for future schema versions
  }

  /// Seeds default clinical records synchronously into cache and into persistent storage.
  void seedSync({DateTime? now}) {
    final currentNow = now ?? DateTime.now();
    final tomorrow = currentNow.add(const Duration(days: 1));
    final pastDate = currentNow.subtract(const Duration(days: 12));

    final upcomingSeed = Appointment(
      id: 'APT-849201',
      doctorId: 'doc_marcus_vance',
      doctorName: 'Dr. Marcus Vance',
      doctorSpecialty: 'Cardiology',
      clinicName: 'CareConnect Metropolitan Health Center',
      clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
      patientId: 'pat_sarah_jenkins_001',
      patientName: 'Maya Sterling',
      patientPhone: '+1 (617) 555-0194',
      scheduledDateTime: DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        10,
        0,
      ),
      timeSlot: '10:00 AM',
      status: AppointmentStatus.confirmed,
      modality: AppointmentModality.inPerson,
      fee: 140.0,
      patientNotes: 'Routine cardiology consultation and BP check.',
      createdAt: currentNow.subtract(const Duration(days: 1)),
      updatedAt: currentNow.subtract(const Duration(days: 1)),
      reminderScheduled: true,
      reminderMinutesBefore: 30,
    );

    final pastSeed = Appointment(
      id: 'APT-849105',
      doctorId: 'doc_elena_rostova',
      doctorName: 'Dr. Elena Rostova',
      doctorSpecialty: 'Dermatology',
      clinicName: 'CareConnect Metropolitan Health Center',
      clinicAddress: 'West Pavilion, Suite 205, Boston, MA',
      patientId: 'pat_sarah_jenkins_001',
      patientName: 'Maya Sterling',
      patientPhone: '+1 (617) 555-0194',
      scheduledDateTime: DateTime(
        pastDate.year,
        pastDate.month,
        pastDate.day,
        14,
        30,
      ),
      timeSlot: '02:30 PM',
      status: AppointmentStatus.completed,
      modality: AppointmentModality.inPerson,
      fee: 125.0,
      patientNotes: 'Annual dermatological screening.',
      createdAt: pastDate.subtract(const Duration(days: 3)),
      updatedAt: pastDate.subtract(const Duration(days: 3)),
      reminderScheduled: false,
      reminderMinutesBefore: 30,
    );

    _memoryCache[upcomingSeed.id] = upcomingSeed;
    _memoryCache[pastSeed.id] = pastSeed;

    if (_db != null && _db!.isOpen) {
      _db!.insert(
        tableName,
        upcomingSeed.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _db!.insert(
        tableName,
        pastSeed.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Seeds default clinical records if storage is currently empty.
  Future<void> seedInitialDataIfEmpty({DateTime? now}) async {
    final existing = await getAllAppointments();
    if (existing.isNotEmpty) {
      return;
    }
    seedSync(now: now);
  }

  Future<void> _seedFallbackIfEmpty() async {
    if (_memoryCache.isNotEmpty) return;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final pastDate = now.subtract(const Duration(days: 12));

    final apt1 = Appointment(
      id: 'APT-849201',
      doctorId: 'doc_marcus_vance',
      doctorName: 'Dr. Marcus Vance',
      doctorSpecialty: 'Cardiology',
      clinicName: 'CareConnect Metropolitan Health Center',
      clinicAddress: 'East Pavilion, Suite 410, Boston, MA',
      patientId: 'pat_sarah_jenkins_001',
      patientName: 'Maya Sterling',
      patientPhone: '+1 (617) 555-0194',
      scheduledDateTime: DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        10,
        0,
      ),
      timeSlot: '10:00 AM',
      status: AppointmentStatus.confirmed,
      modality: AppointmentModality.inPerson,
      fee: 140.0,
      patientNotes: 'Routine cardiology consultation and BP check.',
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
      reminderScheduled: true,
      reminderMinutesBefore: 30,
    );

    final apt2 = Appointment(
      id: 'APT-849105',
      doctorId: 'doc_elena_rostova',
      doctorName: 'Dr. Elena Rostova',
      doctorSpecialty: 'Dermatology',
      clinicName: 'CareConnect Metropolitan Health Center',
      clinicAddress: 'West Pavilion, Suite 205, Boston, MA',
      patientId: 'pat_sarah_jenkins_001',
      patientName: 'Maya Sterling',
      patientPhone: '+1 (617) 555-0194',
      scheduledDateTime: DateTime(
        pastDate.year,
        pastDate.month,
        pastDate.day,
        14,
        30,
      ),
      timeSlot: '02:30 PM',
      status: AppointmentStatus.completed,
      modality: AppointmentModality.inPerson,
      fee: 125.0,
      patientNotes: 'Annual dermatological screening.',
      createdAt: pastDate.subtract(const Duration(days: 3)),
      updatedAt: pastDate.subtract(const Duration(days: 3)),
      reminderScheduled: false,
      reminderMinutesBefore: 30,
    );

    _memoryCache[apt1.id] = apt1;
    _memoryCache[apt2.id] = apt2;

    if (kIsWeb) {
      try {
        if (Uri.base.queryParameters['cancelled'] == 'true') {
          final cancelledApt = apt1.copyWith(
            status: AppointmentStatus.cancelled,
            patientNotes: 'Patient initiated cancellation. Time slot released.',
          );
          _memoryCache[cancelledApt.id] = cancelledApt;
        } else if (Uri.base.queryParameters['rescheduled'] == 'true') {
          final nextWeek = now.add(const Duration(days: 6));
          final rescheduledApt = apt1.copyWith(
            status: AppointmentStatus.rescheduled,
            scheduledDateTime: DateTime(
              nextWeek.year,
              nextWeek.month,
              nextWeek.day,
              14,
              30,
            ),
            timeSlot: '02:30 PM',
            updatedAt: now,
          );
          _memoryCache[rescheduledApt.id] = rescheduledApt;
        }
      } catch (_) {}
    }
  }

  /// Inserts a new appointment record or replaces an existing record.
  Future<void> insertAppointment(Appointment appointment) async {
    _memoryCache[appointment.id] = appointment;
    if (_db == null || !_db!.isOpen) {
      return;
    }

    await _db!.insert(
      tableName,
      appointment.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all persisted appointments, optionally filtered by patient ID.
  Future<List<Appointment>> getAllAppointments({String? patientId}) async {
    if (_db == null || !_db!.isOpen) {
      final list = _memoryCache.values.toList();
      if (patientId == null || patientId.isEmpty) return list;
      return list.where((a) => a.patientId == patientId).toList();
    }

    final List<Map<String, dynamic>> maps;
    if (patientId != null && patientId.isNotEmpty) {
      maps = await _db!.query(
        tableName,
        where: 'patientId = ?',
        whereArgs: [patientId],
        orderBy: 'scheduledDateTime ASC',
      );
    } else {
      maps = await _db!.query(tableName, orderBy: 'scheduledDateTime ASC');
    }

    if (maps.isEmpty && _memoryCache.isNotEmpty) {
      final list = _memoryCache.values.toList();
      if (patientId == null || patientId.isEmpty) return list;
      return list.where((a) => a.patientId == patientId).toList();
    }

    return maps.map((m) => Appointment.fromJson(m)).toList();
  }

  /// Retrieves a specific appointment by its ID.
  Future<Appointment?> getAppointmentById(String id) async {
    if (_db == null || !_db!.isOpen) {
      return _memoryCache[id];
    }

    final maps = await _db!.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return _memoryCache[id];
    return Appointment.fromJson(maps.first);
  }

  /// Updates an existing appointment record.
  Future<int> updateAppointment(Appointment appointment) async {
    _memoryCache[appointment.id] = appointment;
    if (_db == null || !_db!.isOpen) {
      return 1;
    }

    return await _db!.update(
      tableName,
      appointment.toJson(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  /// Deletes an appointment record by ID.
  Future<int> deleteAppointment(String id) async {
    _memoryCache.remove(id);
    if (_db == null || !_db!.isOpen) {
      return 1;
    }

    return await _db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Clears all appointment records from the table.
  Future<void> clearAll() async {
    _memoryCache.clear();
    if (_db != null && _db!.isOpen) {
      await _db!.delete(tableName);
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
    _memoryCache.clear();
    _isInitialized = false;
  }
}
