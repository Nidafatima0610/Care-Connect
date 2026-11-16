import 'package:flutter/foundation.dart';

import 'doctor_specialty.dart';

/// Immutable domain model representing a physician in CareConnect.
@immutable
class Doctor {
  final String id;
  final String name;
  final String title;
  final DoctorSpecialty specialty;
  final String subSpecialty;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final double consultationFee;
  final String currency;
  final String biography;
  final List<String> qualifications;
  final String clinicName;
  final String clinicAddress;
  final String availabilitySummary;
  final List<String> availableDays;
  final String workingHours;
  final String? avatarUrl;
  final bool isFeatured;
  final bool isAcceptingNewPatients;
  final List<String> languages;
  final int patientsCount;
  final bool hasVideoConsultation;
  final bool hasInPersonConsultation;

  const Doctor({
    required this.id,
    required this.name,
    required this.title,
    required this.specialty,
    required this.subSpecialty,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    required this.consultationFee,
    this.currency = '\$',
    required this.biography,
    required this.qualifications,
    required this.clinicName,
    required this.clinicAddress,
    required this.availabilitySummary,
    required this.availableDays,
    required this.workingHours,
    this.avatarUrl,
    this.isFeatured = false,
    this.isAcceptingNewPatients = true,
    required this.languages,
    required this.patientsCount,
    this.hasVideoConsultation = true,
    this.hasInPersonConsultation = true,
  });

  /// Factory constructor to deserialize from Map (JSON).
  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String? ?? 'MD',
      specialty: DoctorSpecialty.fromString(json['specialty'] as String),
      subSpecialty: json['subSpecialty'] as String? ?? '',
      experienceYears: json['experienceYears'] as int,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int? ?? 0,
      consultationFee: (json['consultationFee'] as num).toDouble(),
      currency: json['currency'] as String? ?? '\$',
      biography: json['biography'] as String,
      qualifications:
          (json['qualifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      clinicName: json['clinicName'] as String,
      clinicAddress: json['clinicAddress'] as String,
      availabilitySummary: json['availabilitySummary'] as String,
      availableDays:
          (json['availableDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      workingHours: json['workingHours'] as String? ?? '9:00 AM - 5:00 PM',
      avatarUrl: json['avatarUrl'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isAcceptingNewPatients: json['isAcceptingNewPatients'] as bool? ?? true,
      languages:
          (json['languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['English'],
      patientsCount: json['patientsCount'] as int? ?? 500,
      hasVideoConsultation: json['hasVideoConsultation'] as bool? ?? true,
      hasInPersonConsultation: json['hasInPersonConsultation'] as bool? ?? true,
    );
  }

  /// Converts the Doctor model into a Map (JSON).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'specialty': specialty.id,
      'subSpecialty': subSpecialty,
      'experienceYears': experienceYears,
      'rating': rating,
      'reviewCount': reviewCount,
      'consultationFee': consultationFee,
      'currency': currency,
      'biography': biography,
      'qualifications': qualifications,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'availabilitySummary': availabilitySummary,
      'availableDays': availableDays,
      'workingHours': workingHours,
      'avatarUrl': avatarUrl,
      'isFeatured': isFeatured,
      'isAcceptingNewPatients': isAcceptingNewPatients,
      'languages': languages,
      'patientsCount': patientsCount,
      'hasVideoConsultation': hasVideoConsultation,
      'hasInPersonConsultation': hasInPersonConsultation,
    };
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? title,
    DoctorSpecialty? specialty,
    String? subSpecialty,
    int? experienceYears,
    double? rating,
    int? reviewCount,
    double? consultationFee,
    String? currency,
    String? biography,
    List<String>? qualifications,
    String? clinicName,
    String? clinicAddress,
    String? availabilitySummary,
    List<String>? availableDays,
    String? workingHours,
    String? avatarUrl,
    bool? isFeatured,
    bool? isAcceptingNewPatients,
    List<String>? languages,
    int? patientsCount,
    bool? hasVideoConsultation,
    bool? hasInPersonConsultation,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      specialty: specialty ?? this.specialty,
      subSpecialty: subSpecialty ?? this.subSpecialty,
      experienceYears: experienceYears ?? this.experienceYears,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      consultationFee: consultationFee ?? this.consultationFee,
      currency: currency ?? this.currency,
      biography: biography ?? this.biography,
      qualifications: qualifications ?? this.qualifications,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      availabilitySummary: availabilitySummary ?? this.availabilitySummary,
      availableDays: availableDays ?? this.availableDays,
      workingHours: workingHours ?? this.workingHours,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      isAcceptingNewPatients:
          isAcceptingNewPatients ?? this.isAcceptingNewPatients,
      languages: languages ?? this.languages,
      patientsCount: patientsCount ?? this.patientsCount,
      hasVideoConsultation: hasVideoConsultation ?? this.hasVideoConsultation,
      hasInPersonConsultation:
          hasInPersonConsultation ?? this.hasInPersonConsultation,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Doctor &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          specialty == other.specialty;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ specialty.hashCode;

  @override
  String toString() =>
      'Doctor(id: $id, name: $name, specialty: ${specialty.displayName})';
}
