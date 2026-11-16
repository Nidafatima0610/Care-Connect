import 'package:flutter/material.dart';

/// Clinical specialties supported by CareConnect.
enum DoctorSpecialty {
  generalMedicine(
    id: 'general_medicine',
    displayName: 'General Medicine',
    shortDescription: 'Primary Care & Preventive Health',
    icon: Icons.health_and_safety_outlined,
  ),
  cardiology(
    id: 'cardiology',
    displayName: 'Cardiology',
    shortDescription: 'Heart & Cardiovascular Wellness',
    icon: Icons.favorite_outline,
  ),
  pediatrics(
    id: 'pediatrics',
    displayName: 'Pediatrics',
    shortDescription: 'Infant & Child Health',
    icon: Icons.child_care_outlined,
  ),
  dermatology(
    id: 'dermatology',
    displayName: 'Dermatology',
    shortDescription: 'Skin, Hair & Aesthetics',
    icon: Icons.spa_outlined,
  ),
  neurology(
    id: 'neurology',
    displayName: 'Neurology',
    shortDescription: 'Brain & Nervous System',
    icon: Icons.psychology_outlined,
  ),
  orthopedics(
    id: 'orthopedics',
    displayName: 'Orthopedics',
    shortDescription: 'Bone, Joint & Sports Care',
    icon: Icons.accessibility_new_outlined,
  ),
  ophthalmology(
    id: 'ophthalmology',
    displayName: 'Ophthalmology',
    shortDescription: 'Vision & Eye Surgery',
    icon: Icons.remove_red_eye_outlined,
  ),
  psychiatry(
    id: 'psychiatry',
    displayName: 'Psychiatry',
    shortDescription: 'Mental Health & Wellbeing',
    icon: Icons.self_improvement_outlined,
  );

  const DoctorSpecialty({
    required this.id,
    required this.displayName,
    required this.shortDescription,
    required this.icon,
  });

  final String id;
  final String displayName;
  final String shortDescription;
  final IconData icon;

  static DoctorSpecialty fromString(String raw) {
    return DoctorSpecialty.values.firstWhere(
      (s) =>
          s.id == raw ||
          s.name == raw ||
          s.displayName.toLowerCase() == raw.toLowerCase(),
      orElse: () => DoctorSpecialty.generalMedicine,
    );
  }
}
