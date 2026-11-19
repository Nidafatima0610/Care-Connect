import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:care_connect/core/theme/app_colors.dart';
import 'package:care_connect/core/theme/app_radii.dart';
import 'package:care_connect/core/theme/app_spacing.dart';
import 'package:care_connect/core/theme/app_typography.dart';
import 'package:care_connect/features/doctors/domain/appointment.dart';

import '../controllers/appointment_providers.dart';

/// Modal dialog confirming patient intent to cancel a clinical appointment.
class CancellationDialog extends ConsumerStatefulWidget {
  final Appointment appointment;

  const CancellationDialog({super.key, required this.appointment});

  static Future<bool?> show(BuildContext context, Appointment appointment) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CancellationDialog(appointment: appointment),
    );
  }

  @override
  ConsumerState<CancellationDialog> createState() => _CancellationDialogState();
}

class _CancellationDialogState extends ConsumerState<CancellationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String _selectedReason = 'Schedule conflict';
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<String> _reasons = [
    'Schedule conflict',
    'Feeling better / Symptoms resolved',
    'Wish to reschedule to another date',
    'Emergency / Personal reasons',
    'Other reason',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmCancel() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final reason =
        _selectedReason == 'Other reason' &&
            _reasonController.text.trim().isNotEmpty
        ? _reasonController.text.trim()
        : _selectedReason;

    final result = await ref
        .read(cancellationControllerProvider.notifier)
        .cancelAppointment(
          appointmentId: widget.appointment.id,
          cancellationReason: reason,
        );

    if (!mounted) return;

    if (result != null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to cancel appointment. Please check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.appointment.scheduledDateTime;
    final dateStr = '${date.month}/${date.day}/${date.year}';

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.roundedLg),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert Header Icon & Title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.coral,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel Appointment?',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.navy900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Booking ID: #${widget.appointment.id}',
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

              // Appointment Summary Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: AppRadii.roundedMd,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.appointment.doctorName,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.navy900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.appointment.doctorSpecialty,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.teal700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.teal700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$dateStr at ${widget.appointment.timeSlot}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.navy900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Explanation & Disclaimer
              Text(
                'Cancelling will release your reserved time slot for other patients and cancel your scheduled local reminder notification.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Cancellation Reason Dropdown
              Text(
                'Reason for cancellation (optional):',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.navy900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.navy50,
                  borderRadius: AppRadii.roundedSm,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.navy900,
                    ),
                    items: _reasons.map((r) {
                      return DropdownMenuItem<String>(value: r, child: Text(r));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedReason = val);
                      }
                    },
                  ),
                ),
              ),

              if (_selectedReason == 'Other reason') ...[
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Please describe briefly...',
                    hintStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.navy50,
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.roundedSm,
                      borderSide: const BorderSide(
                        color: AppColors.borderLight,
                      ),
                    ),
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.1),
                    borderRadius: AppRadii.roundedSm,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppColors.coral,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Action Buttons: Keep vs Confirm Cancel
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy900,
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.roundedMd,
                        ),
                      ),
                      child: Text(
                        'Keep Visit',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleConfirmCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.roundedMd,
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Cancel Visit',
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
