import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/care_button.dart';
import '../../../core/widgets/care_card.dart';
import '../domain/patient.dart';
import 'controllers/patient_provider.dart';

class EditPatientProfileScreen extends ConsumerStatefulWidget {
  const EditPatientProfileScreen({super.key});

  @override
  ConsumerState<EditPatientProfileScreen> createState() =>
      _EditPatientProfileScreenState();
}

class _EditPatientProfileScreenState
    extends ConsumerState<EditPatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _clinicController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  DateTime? _selectedDob;
  String _selectedBloodGroup = 'A+';
  bool _isSaving = false;

  final List<String> _bloodGroups = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  void initState() {
    super.initState();
    final patient = ref.read(patientProfileProvider).asData?.value;

    _nameController = TextEditingController(text: patient?.fullName ?? '');
    _emailController = TextEditingController(text: patient?.email ?? '');
    _phoneController = TextEditingController(text: patient?.phoneNumber ?? '');
    _clinicController = TextEditingController(
      text:
          patient?.preferredClinic ?? 'CareConnect Metropolitan Health Center',
    );
    _emergencyNameController = TextEditingController(
      text: patient?.emergencyContactName ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: patient?.emergencyContactPhone ?? '',
    );
    _selectedDob = patient?.dateOfBirth;
    if (patient?.bloodGroup != null &&
        _bloodGroups.contains(patient!.bloodGroup)) {
      _selectedBloodGroup = patient.bloodGroup;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _clinicController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(1995, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal700,
              onPrimary: Colors.white,
              surface: AppColors.surfaceCard,
              onSurface: AppColors.navy900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentPatient =
          ref.read(patientProfileProvider).asData?.value ??
          Patient.defaultDemoPatient();

      final updatedPatient = currentPatient.copyWith(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _selectedDob,
        preferredClinic: _clinicController.text.trim(),
        bloodGroup: _selectedBloodGroup,
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
      );

      await ref
          .read(patientProfileProvider.notifier)
          .updateProfile(updatedPatient);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Profile updated successfully'),
              ],
            ),
            backgroundColor: AppColors.teal700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.navy900,
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Edit Profile',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.navy900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Personal Information Card
                CareCard(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Demographics',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.navy900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Full Name
                      _buildTextField(
                        fieldKey: const Key('edit_patient_name_field'),
                        controller: _nameController,
                        label: 'Full Name *',
                        hint: 'e.g. Maya Sterling',
                        icon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Email
                      _buildTextField(
                        fieldKey: const Key('edit_patient_email_field'),
                        controller: _emailController,
                        label: 'Email Address *',
                        hint: 'e.g. maya@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailRegExp = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegExp.hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Phone Number
                      _buildTextField(
                        fieldKey: const Key('edit_patient_phone_field'),
                        controller: _phoneController,
                        label: 'Phone Number *',
                        hint: 'e.g. +1 (617) 555-0194',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          final digitsOnly = value.replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          if (digitsOnly.length < 7) {
                            return 'Please enter a valid phone number (min 7 digits)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Date of Birth Field & Picker
                      Text(
                        'Date of Birth',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.navy900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      InkWell(
                        onTap: _pickDateOfBirth,
                        borderRadius: AppRadii.roundedMd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: AppRadii.roundedMd,
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: AppColors.teal700,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  _selectedDob != null
                                      ? DateFormat('MMMM d, yyyy')
                                            .format(_selectedDob!)
                                      : 'Select your date of birth',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: _selectedDob != null
                                        ? AppColors.navy900
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down_rounded,
                                color: AppColors.textTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Blood Group Dropdown
                      Text(
                        'Blood Group',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.navy900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBloodGroup,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.bloodtype_outlined,
                            size: 18,
                            color: AppColors.teal700,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.roundedMd,
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadii.roundedMd,
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadii.roundedMd,
                            borderSide: const BorderSide(
                              color: AppColors.teal700,
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: _bloodGroups.map((bg) {
                          return DropdownMenuItem(
                            value: bg,
                            child: Text(
                              bg,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.navy900,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedBloodGroup = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Clinical & Emergency Information Card
                CareCard(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical & Emergency Contacts',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.navy900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Preferred Clinic
                      _buildTextField(
                        controller: _clinicController,
                        label: 'Preferred Health Center',
                        hint: 'CareConnect Metropolitan Health Center',
                        icon: Icons.local_hospital_outlined,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Emergency Contact Name
                      _buildTextField(
                        controller: _emergencyNameController,
                        label: 'Emergency Contact Name',
                        hint: 'e.g. David Sterling',
                        icon: Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Emergency Contact Phone
                      _buildTextField(
                        controller: _emergencyPhoneController,
                        label: 'Emergency Contact Phone',
                        hint: 'e.g. +1 (617) 555-0812',
                        icon: Icons.phone_in_talk_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Save Changes CTA
                CareButton(
                  text: 'Save Changes',
                  leadingIcon: Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _handleSave,
                  height: 50,
                ),

                const SizedBox(height: AppSpacing.md),

                // Cancel Button
                CareButton(
                  text: 'Cancel',
                  variant: CareButtonVariant.subtle,
                  onPressed: () => context.pop(),
                  height: 44,
                ),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    Key? fieldKey,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.navy900,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.navy900),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: Icon(icon, size: 18, color: AppColors.teal700),
            filled: true,
            fillColor: AppColors.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadii.roundedMd,
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.roundedMd,
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.roundedMd,
              borderSide: const BorderSide(
                color: AppColors.teal700,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadii.roundedMd,
              borderSide: const BorderSide(color: AppColors.coral),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadii.roundedMd,
              borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
