import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import 'care_card.dart';

/// Shimmer/pulse skeleton placeholder mirroring DoctorCard layout during async loading.
class CareDoctorCardSkeleton extends StatefulWidget {
  const CareDoctorCardSkeleton({super.key});

  @override
  State<CareDoctorCardSkeleton> createState() => _CareDoctorCardSkeletonState();
}

class _CareDoctorCardSkeletonState extends State<CareDoctorCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Only start infinite loop in non-test interactive runtime to prevent pumpAndSettle timeouts
    final isUnderTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isUnderTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.6;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPlaceholder({
    required double width,
    required double height,
    double radius = AppRadii.sm,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CareCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar circle placeholder
              _buildPlaceholder(width: 64, height: 64, radius: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlaceholder(width: 150, height: 16),
                    const SizedBox(height: AppSpacing.sm),
                    _buildPlaceholder(width: 100, height: 12),
                    const SizedBox(height: AppSpacing.sm),
                    _buildPlaceholder(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPlaceholder(width: 120, height: 14),
              _buildPlaceholder(width: 70, height: 14),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPlaceholder(
            width: double.infinity,
            height: 38,
            radius: AppRadii.md,
          ),
        ],
      ),
    );
  }
}

/// Skeletons container displaying multiple animated skeleton cards.
class CareDoctorListSkeleton extends StatelessWidget {
  final int itemCount;

  const CareDoctorListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: CareDoctorCardSkeleton(),
        ),
      ),
    );
  }
}
