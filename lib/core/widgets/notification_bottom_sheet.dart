import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'care_badge.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  final CareBadgeVariant badgeVariant;
  final String badgeText;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    required this.badgeVariant,
    required this.badgeText,
  });
}

class NotificationBottomSheet extends StatelessWidget {
  const NotificationBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationBottomSheet(),
    );
  }

  static const List<NotificationItem> _sampleNotifications = [
    NotificationItem(
      id: 'n1',
      title: 'Annual Cardiovascular Health Check',
      message: 'Specialist availability open for Dr. Alistair Vance this week. Schedule your preventive assessment.',
      timeAgo: '2 hours ago',
      icon: Icons.favorite_rounded,
      badgeVariant: CareBadgeVariant.primary,
      badgeText: 'Health Alert',
    ),
    NotificationItem(
      id: 'n2',
      title: 'Clinic Operating Hours Update',
      message: 'CareConnect Metropolitan Center has extended Saturday morning pediatric walk-in hours from 8:00 AM to 1:00 PM.',
      timeAgo: 'Yesterday',
      icon: Icons.schedule_rounded,
      badgeVariant: CareBadgeVariant.secondary,
      badgeText: 'Clinic Update',
    ),
    NotificationItem(
      id: 'n3',
      title: 'Flu & Respiratory Immunizations Available',
      message: 'Seasonal vaccinations are currently accessible with no waiting line at the Primary Health Suite.',
      timeAgo: '3 days ago',
      icon: Icons.medical_services_rounded,
      badgeVariant: CareBadgeVariant.success,
      badgeText: 'Preventive Care',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs + 2),
                        decoration: const BoxDecoration(
                          color: AppColors.teal50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          size: 20,
                          color: AppColors.teal700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Clinic Notices & Updates',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.navy900,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close notifications',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              itemCount: _sampleNotifications.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = _sampleNotifications[index];
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: AppRadii.roundedMd,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CareBadge(
                            label: item.badgeText,
                            icon: item.icon,
                            variant: item.badgeVariant,
                          ),
                          Text(
                            item.timeAgo,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        item.title,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.navy900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.message,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
