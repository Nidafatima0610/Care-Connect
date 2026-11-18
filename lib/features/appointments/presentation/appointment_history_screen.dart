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

/// Screen presenting the patient's upcoming and past clinical appointment bookings.
class AppointmentHistoryScreen extends ConsumerWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingAppointmentsProvider);
    final pastAsync = ref.watch(pastAppointmentsProvider);

    final upcomingCount = upcomingAsync.asData?.value.length ?? 0;
    final pastCount = pastAsync.asData?.value.length ?? 0;

    return DefaultTabController(
      length: 2,
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
        body: TabBarView(
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
                        onAction: () => context.goNamed(AppRouteNames.home),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  itemCount: appointments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return AppointmentHistoryCard(
                      appointment: appointments[index],
                    );
                  },
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
                  'Failed to load appointments: $err',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.coral,
                  ),
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
                        onAction: () => context.goNamed(AppRouteNames.home),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  itemCount: appointments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return AppointmentHistoryCard(
                      appointment: appointments[index],
                    );
                  },
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
    );
  }
}
