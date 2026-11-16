import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/care_badge.dart';
import '../../../core/widgets/care_empty_state.dart';
import '../../../core/widgets/care_error_view.dart';
import '../../../core/widgets/care_search_bar.dart';
import '../../../core/widgets/care_section_header.dart';
import '../../doctors/domain/doctor.dart';
import '../../doctors/presentation/controllers/doctor_providers.dart';
import '../../doctors/presentation/widgets/booking_placeholder_sheet.dart';
import '../../doctors/presentation/widgets/doctor_card.dart';
import '../../doctors/presentation/widgets/doctor_featured_card.dart';
import 'widgets/home_header.dart';
import 'widgets/home_hero_banner.dart';
import 'widgets/home_specialty_selector.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _scrollToDoctors() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        380,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _navigateToDoctor(String doctorId) {
    context.pushNamed(
      AppRouteNames.doctorDetail,
      pathParameters: {'id': doctorId},
    );
  }

  void _showBookingSheet(Doctor doctor) {
    BookingPlaceholderSheet.show(context, doctor);
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xxl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Specialists',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.navy900,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(selectedSpecialtyProvider.notifier).clear();
                    ref.read(searchQueryProvider.notifier).clear();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Select Specialty',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.navy900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const HomeSpecialtySelector(),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDoctorsAsync = ref.watch(filteredDoctorsProvider);
    final featuredDoctorsAsync = ref.watch(featuredDoctorsProvider);
    final currentQuery = ref.watch(searchQueryProvider);
    final selectedSpecialty = ref.watch(selectedSpecialtyProvider);
    final hasActiveFilters =
        currentQuery.isNotEmpty || selectedSpecialty != null;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.teal700,
          onRefresh: () async {
            ref.invalidate(allDoctorsProvider);
            ref.invalidate(featuredDoctorsProvider);
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Top padding
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // Header (Greeting, Patient Avatar, Notifications)
              const SliverToBoxAdapter(child: HomeHeader()),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // Hero Promotional Banner
              SliverToBoxAdapter(
                child: HomeHeroBanner(onActionTap: _scrollToDoctors),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Search Bar with real-time reactive filtering
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: CareSearchBar(
                    initialValue: currentQuery,
                    hasActiveFilters: hasActiveFilters,
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).setQuery(val);
                    },
                    onClear: () {
                      ref.read(searchQueryProvider.notifier).clear();
                    },
                    onFilterTap: () => _showFilterModal(context),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Specialty Selector Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: CareSectionHeader(
                        title: AppStrings.specialtiesSectionTitle,
                        subtitle: AppStrings.specialtiesSectionSubtitle,
                        trailing: selectedSpecialty != null
                            ? CareBadge(
                                label: 'Clear Filter',
                                icon: Icons.close_rounded,
                                variant: CareBadgeVariant.neutral,
                                onTap: () {
                                  ref
                                      .read(selectedSpecialtyProvider.notifier)
                                      .clear();
                                },
                              )
                            : null,
                      ),
                    ),
                    const HomeSpecialtySelector(),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

              // Featured Doctors Section (displayed when not actively filtering by text)
              if (currentQuery.isEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: CareSectionHeader(
                      title: AppStrings.featuredDoctorsTitle,
                      subtitle: AppStrings.featuredDoctorsSubtitle,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: featuredDoctorsAsync.when(
                      data: (featuredList) {
                        if (featuredList.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenHorizontal,
                          ),
                          itemCount: featuredList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final doc = featuredList[index];
                            return DoctorFeaturedCard(
                              doctor: doc,
                              onTap: () => _navigateToDoctor(doc.id),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.teal700,
                        ),
                      ),
                      error: (err, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],

              // All / Filtered Doctors Directory Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: CareSectionHeader(
                    title: selectedSpecialty != null
                        ? '${selectedSpecialty.displayName} Doctors'
                        : AppStrings.allDoctorsTitle,
                    subtitle: currentQuery.isNotEmpty
                        ? 'Search results matching "$currentQuery"'
                        : AppStrings.allDoctorsSubtitle,
                  ),
                ),
              ),

              // Filtered Doctors List Content
              filteredDoctorsAsync.when(
                data: (doctors) {
                  if (doctors.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: CareEmptyState(
                          icon: Icons.person_search_rounded,
                          title: AppStrings.noDoctorsFoundTitle,
                          message: AppStrings.noDoctorsFoundMessage,
                          actionLabel: AppStrings.resetFilters,
                          onAction: () {
                            ref.read(searchQueryProvider.notifier).clear();
                            ref
                                .read(selectedSpecialtyProvider.notifier)
                                .clear();
                          },
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final doc = doctors[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: DoctorCard(
                            doctor: doc,
                            onTap: () => _navigateToDoctor(doc.id),
                            onBookTap: () => _showBookingSheet(doc),
                          ),
                        );
                      }, childCount: doctors.length),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxxl),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.teal700,
                      ),
                    ),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: CareErrorView(
                      message: AppStrings.genericErrorMessage,
                      onRetry: () => ref.refresh(allDoctorsProvider),
                    ),
                  ),
                ),
              ),

              // Bottom safe spacer
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.huge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
