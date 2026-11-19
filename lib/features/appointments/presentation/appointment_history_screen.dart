import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:care_connect/core/router/app_router.dart';
import 'package:care_connect/core/theme/app_colors.dart';
import 'package:care_connect/core/theme/app_radii.dart';
import 'package:care_connect/core/theme/app_spacing.dart';
import 'package:care_connect/core/theme/app_typography.dart';
import 'package:care_connect/core/widgets/care_empty_state.dart';

import 'controllers/appointment_providers.dart';
import 'widgets/appointment_history_card.dart';
import 'widgets/cancellation_dialog.dart';
import 'widgets/reminder_settings_sheet.dart';

/// Screen presenting the patient's upcoming and past clinical appointment bookings
/// loaded from local SQLite persistent storage, with cancellation, rescheduling,
/// local reminder management, and offline indicators.
class AppointmentHistoryScreen extends ConsumerWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingAppointmentsProvider);
    final pastAsync = ref.watch(pastAppointmentsProvider);
    final isOffline = ref.watch(offlineModeProvider);

    final upcomingCount = upcomingAsync.asData?.value.length ?? 0;
    final pastCount = pastAsync.asData?.value.length ?? 0;

    final initialIndex = Uri.base.queryParameters['tab'] == 'past' ? 1 : 0;

    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final uri = Uri.base;
        if (uri.queryParameters['show_reminders'] == 'true') {
          ReminderSettingsSheet.show(context);
        } else if (uri.queryParameters['show_cancel'] == 'true') {
          final apts = upcomingAsync.asData?.value;
          if (apts != null && apts.isNotEmpty) {
            CancellationDialog.show(context, apts.first);
          }
        } else if (uri.queryParameters['show_demo'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.navy900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.roundedMd),
              content: const Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.mint,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Test reminder scheduled! Notification channel active (Simulation / Desktop FFI).',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    }

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          backgroundColor: AppColors.ivory,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy900,
              size: 20,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AppRouteNames.home);
              }
            },
          ),
          title: Text(
            'My Appointments',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            // Offline Mode Toggle
            IconButton(
              tooltip: isOffline
                  ? 'Offline Mode Active (Tap to toggle)'
                  : 'Online (Tap to simulate offline)',
              icon: Icon(
                isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                color: isOffline ? AppColors.coral : AppColors.teal700,
                size: 22,
              ),
              onPressed: () {
                ref.read(offlineModeProvider.notifier).toggle();
              },
            ),
            // Reminder Notification Settings & Demo
            IconButton(
              tooltip: 'Reminder Notifications & Demo',
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.navy900,
                size: 22,
              ),
              onPressed: () => ReminderSettingsSheet.show(context),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              decoration: BoxDecoration(
                color: AppColors.navy50,
                borderRadius: AppRadii.roundedMd,
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.teal700,
                  borderRadius: AppRadii.roundedMd,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal700.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Upcoming'),
                        if (upcomingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: AppRadii.roundedPill,
                            ),
                            child: Text(
                              '$upcomingCount',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Past'),
                        if (pastCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: AppRadii.roundedPill,
                            ),
                            child: Text(
                              '$pastCount',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Persistent Offline Storage Banner
            if (isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: AppColors.navy900,
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.mint,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline Storage Active',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Appointments & history loaded directly from local SQLite database.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.borderLight,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(patientAppointmentsProvider);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.mint,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),

            // Tab Views for Upcoming vs Past Appointments
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Upcoming Appointments
                  upcomingAsync.when(
                    data: (appointments) {
                      if (appointments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Center(
                            child: CareEmptyState(
                              icon: Icons.calendar_today_rounded,
                              title: 'No Upcoming Appointments',
                              message: 'You have no appointments scheduled at this time. Book a consultation with a certified CareConnect specialist.',
                              actionLabel: 'Book an Appointment',
                              onAction: () =>
                                  context.goNamed(AppRouteNames.home),
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.teal700,
                        onRefresh: () async {
                          ref.invalidate(patientAppointmentsProvider);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(
                            AppSpacing.screenHorizontal,
                          ),
                          itemCount: appointments.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            return AppointmentHistoryCard(
                              appointment: appointments[index],
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.teal700,
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.coral,
                            size: 36,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Failed to load appointments from storage: $err',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.coral,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton(
                            onPressed: () =>
                                ref.invalidate(patientAppointmentsProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal700,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab 2: Past Appointments
                  pastAsync.when(
                    data: (appointments) {
                      if (appointments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Center(
                            child: CareEmptyState(
                              icon: Icons.history_rounded,
                              title: 'No Past Appointments',
                              message: 'You have no completed or historical clinical consultations on record.',
                              actionLabel: 'Explore Specialists',
                              onAction: () =>
                                  context.goNamed(AppRouteNames.home),
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.teal700,
                        onRefresh: () async {
                          ref.invalidate(patientAppointmentsProvider);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(
                            AppSpacing.screenHorizontal,
                          ),
                          itemCount: appointments.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            return AppointmentHistoryCard(
                              appointment: appointments[index],
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.teal700,
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Failed to load history: $err',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.coral,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
