import 'package:intl/intl.dart';

/// Patient entity representing a clinical user in CareConnect.
///
/// Contains personal demographic information, clinical preferences,
/// and emergency contact details for local identity persistence.
class Patient {
  static const Object _sentinel = Object();

  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final DateTime? dateOfBirth;
  final String preferredClinic;
  final String bloodGroup;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Patient({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.dateOfBirth,
    required this.preferredClinic,
    this.bloodGroup = 'A+',
    this.emergencyContactName = 'David Sterling',
    this.emergencyContactPhone = '+1 (617) 555-0812',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convenience alias for phoneNumber.
  String get phone => phoneNumber;

  /// Extracts the patient's first name for informal greetings.
  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Patient';
    final parts = trimmed.split(' ');
    return parts.first;
  }

  /// Computes two-letter uppercase initials for avatar representation.
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'PT';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Formatted date of birth string (e.g. "Jun 14, 1992").
  String get formattedDateOfBirth {
    if (dateOfBirth == null) return 'Not Provided';
    return DateFormat('MMM d, yyyy').format(dateOfBirth!);
  }

  /// Formatted date of birth in numeric format (e.g. "1992-06-14").
  String get isoDateOfBirth {
    if (dateOfBirth == null) return '';
    return DateFormat('yyyy-MM-dd').format(dateOfBirth!);
  }

  /// Calculates patient age in years based on dateOfBirth.
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Returns a realistic default fictional demo patient.
  factory Patient.defaultDemoPatient() {
    return Patient(
      id: 'pat-84920',
      fullName: 'Maya Sterling',
      email: 'maya.sterling@careconnect.health',
      phoneNumber: '+1 (617) 555-0194',
      dateOfBirth: DateTime(1992, 6, 14),
      preferredClinic: 'CareConnect Metropolitan Health Center',
      bloodGroup: 'A+',
      emergencyContactName: 'David Sterling',
      emergencyContactPhone: '+1 (617) 555-0812',
      createdAt: DateTime(2025, 1, 10, 9, 30),
      updatedAt: DateTime(2026, 11, 17, 10, 0),
    );
  }

  /// Creates a copy with selectively updated attributes.
  Patient copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    Object? dateOfBirth = _sentinel,
    String? preferredClinic,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: identical(dateOfBirth, _sentinel)
          ? this.dateOfBirth
          : dateOfBirth as DateTime?,
      preferredClinic: preferredClinic ?? this.preferredClinic,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes entity to JSON map for local storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'preferredClinic': preferredClinic,
      'bloodGroup': bloodGroup,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Deserializes JSON map into Patient entity.
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String? ?? 'pat-unknown',
      fullName: json['fullName'] as String? ?? 'Patient',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      preferredClinic:
          json['preferredClinic'] as String? ??
          'CareConnect Metropolitan Health Center',
      bloodGroup: json['bloodGroup'] as String? ?? 'A+',
      emergencyContactName:
          json['emergencyContactName'] as String? ?? 'David Sterling',
      emergencyContactPhone:
          json['emergencyContactPhone'] as String? ?? '+1 (617) 555-0812',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Patient &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          email == other.email &&
          phoneNumber == other.phoneNumber &&
          dateOfBirth == other.dateOfBirth &&
          preferredClinic == other.preferredClinic &&
          bloodGroup == other.bloodGroup &&
          emergencyContactName == other.emergencyContactName &&
          emergencyContactPhone == other.emergencyContactPhone;

  @override
  int get hashCode =>
      id.hashCode ^
      fullName.hashCode ^
      email.hashCode ^
      phoneNumber.hashCode ^
      dateOfBirth.hashCode ^
      preferredClinic.hashCode ^
      bloodGroup.hashCode ^
      emergencyContactName.hashCode ^
      emergencyContactPhone.hashCode;
}
