import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:care_connect/core/theme/app_colors.dart';
import 'package:care_connect/core/theme/app_radii.dart';
import 'package:care_connect/core/theme/app_spacing.dart';
import 'package:care_connect/core/theme/app_typography.dart';
import 'package:care_connect/core/widgets/care_button.dart';

import '../controllers/appointment_providers.dart';

/// Modal bottom sheet displaying local reminder configuration and demo trigger.
class ReminderSettingsSheet extends ConsumerStatefulWidget {
  const ReminderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReminderSettingsSheet(),
    );
  }

  @override
  ConsumerState<ReminderSettingsSheet> createState() =>
      _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends ConsumerState<ReminderSettingsSheet> {
  bool _isTesting = false;
  String? _testSuccessMessage;

  Future<void> _handleTestReminder() async {
    setState(() {
      _isTesting = true;
      _testSuccessMessage = null;
    });

    final notifService = ref.read(notificationServiceProvider);
    await notifService.showDemoNotification(
      title: 'CareConnect Reminder: Dr. Marcus Vance',
      body: 'Upcoming Cardiology Consultation at CareConnect Metropolitan Health Center tomorrow at 10:00 AM.',
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccessMessage =
            'Demo reminder delivered successfully to notification tray!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: AppRadii.roundedPill,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  borderRadius: AppRadii.roundedMd,
                  border: Border.all(
                    color: AppColors.teal700.withValues(alpha: 0.2),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.teal700,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Reminders',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.navy900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Local notification configuration & testing',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Reminder Specifications
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.ivory,
              borderRadius: AppRadii.roundedMd,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                _buildSpecRow(
                  icon: Icons.tune_rounded,
                  title: 'Default Lead Time',
                  value: '30 min before visit',
                ),
                const Divider(height: 16),
                _buildSpecRow(
                  icon: Icons.cell_tower_rounded,
                  title: 'Android Channel',
                  value: 'careconnect_reminders',
                ),
                const Divider(height: 16),
                _buildSpecRow(
                  icon: Icons.sync_rounded,
                  title: 'Auto-Synchronization',
                  value: 'Enabled for Reschedule / Cancel',
                ),
                const Divider(height: 16),
                _buildSpecRow(
                  icon: Icons.security_rounded,
                  title: 'Privacy Mode',
                  value: '100% On-Device (No Cloud)',
                ),
              ],
            ),
          ),

          if (_testSuccessMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.mint50,
                borderRadius: AppRadii.roundedMd,
                border: Border.all(
                  color: AppColors.mint.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.mint,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testSuccessMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.mintDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Demo Trigger Action Button
          CareButton(
            text: 'Send Test Reminder Notification',
            leadingIcon: Icons.notifications_active_outlined,
            variant: CareButtonVariant.primary,
            height: 48.0,
            width: double.infinity,
            isLoading: _isTesting,
            onPressed: _isTesting ? null : _handleTestReminder,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              'Triggers an immediate test reminder on device notification bar.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.teal700),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.navy900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
