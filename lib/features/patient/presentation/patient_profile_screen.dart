import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/care_badge.dart';
import '../../../core/widgets/care_button.dart';
import '../../../core/widgets/care_card.dart';
import '../../../core/widgets/care_empty_state.dart';
import '../../../core/widgets/care_error_view.dart';
import '../domain/patient.dart';
import 'controllers/patient_provider.dart';

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key});

  void _navigateToEdit(BuildContext context) {
    context.pushNamed(AppRouteNames.editProfile);
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.roundedLg),
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          'Reset Demo Profile?',
          style: AppTypography.titleMedium.copyWith(color: AppColors.navy900),
        ),
        content: Text(
          'This will restore the profile fields back to the default fictional patient (Maya Sterling).',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(patientProfileProvider.notifier).resetToDefault();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo profile reset to Maya Sterling.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientProfileProvider);

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
          'Patient Profile',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.navy900,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            color: AppColors.teal700,
            tooltip: 'Edit Profile',
            onPressed: () => _navigateToEdit(context),
          ),
        ],
      ),
      body: SafeArea(
        child: patientAsync.when(
          data: (patient) {
            if (patient == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: CareEmptyState(
                    icon: Icons.person_off_rounded,
                    title: 'No Profile Found',
                    message: 'No local patient identity exists on this device. Initialize the demo identity to proceed.',
                    actionLabel: 'Create Demo Profile',
                    onAction: () => ref
                        .read(patientProfileProvider.notifier)
                        .resetToDefault(),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Identity Header Card
                  _buildHeaderCard(context, patient),

                  const SizedBox(height: AppSpacing.lg),

                  // Demo Identity Notice
                  _buildDemoNotice(),

                  const SizedBox(height: AppSpacing.lg),

                  // Personal Contact Information Card
                  _buildContactCard(patient),

                  const SizedBox(height: AppSpacing.lg),

                  // Clinical Preferences & Emergency Contact Card
                  _buildClinicalCard(patient),

                  const SizedBox(height: AppSpacing.xl),

                  // Appointments History Quick-Action Button
                  CareButton(
                    text: 'View My Appointments',
                    leadingIcon: Icons.calendar_month_outlined,
                    variant: CareButtonVariant.outlined,
                    onPressed: () =>
                        context.pushNamed(AppRouteNames.appointments),
                    height: 50,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Primary Edit Profile Button
                  CareButton(
                    text: 'Edit Profile Details',
                    leadingIcon: Icons.edit_rounded,
                    onPressed: () => _navigateToEdit(context),
                    height: 50,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Secondary Reset Demo Profile Button
                  CareButton(
                    text: 'Reset to Demo Default',
                    leadingIcon: Icons.restart_alt_rounded,
                    variant: CareButtonVariant.outlined,
                    onPressed: () => _confirmReset(context, ref),
                    height: 44,
                  ),

                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.teal700,
              strokeWidth: 2.5,
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: CareErrorView(
                title: 'Failed to Load Profile',
                message: err.toString(),
                onRetry: () => ref.invalidate(patientProfileProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Patient patient) {
    return CareCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          // Large Avatar Circle with Initials
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy800, AppColors.teal700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x180E1A2D),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              patient.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 26,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            patient.fullName,
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.navy900,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Medical Record ID: #${patient.id.toUpperCase()}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const CareBadge(
            label: 'Verified Patient Account',
            icon: Icons.verified_rounded,
            variant: CareBadgeVariant.success,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoNotice() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.teal50.withValues(alpha: 0.6),
        borderRadius: AppRadii.roundedMd,
        border: Border.all(
          color: AppColors.teal700.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.teal700,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local Demo Identity',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.navy900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Patient profile changes are stored locally on your device using persistent storage. No real protected health information (PHI) or external authentication is used.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Patient patient) {
    return CareCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: patient.email,
          ),
          const Divider(color: AppColors.borderLight, height: AppSpacing.lg),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: patient.phoneNumber,
          ),
          const Divider(color: AppColors.borderLight, height: AppSpacing.lg),
          _buildInfoRow(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: patient.age != null
                ? '${patient.formattedDateOfBirth} (${patient.age} years)'
                : patient.formattedDateOfBirth,
          ),
          const Divider(color: AppColors.borderLight, height: AppSpacing.lg),
          _buildInfoRow(
            icon: Icons.bloodtype_outlined,
            label: 'Blood Group',
            value: patient.bloodGroup,
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalCard(Patient patient) {
    return CareCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clinical & Emergency',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            icon: Icons.local_hospital_outlined,
            label: 'Preferred Health Center',
            value: patient.preferredClinic,
          ),
          const Divider(color: AppColors.borderLight, height: AppSpacing.lg),
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Emergency Contact',
            value: patient.emergencyContactName,
          ),
          const Divider(color: AppColors.borderLight, height: AppSpacing.lg),
          _buildInfoRow(
            icon: Icons.phone_in_talk_outlined,
            label: 'Emergency Phone',
            value: patient.emergencyContactPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.navy50,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(icon, size: 18, color: AppColors.teal700),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : 'Not provided',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.navy900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
