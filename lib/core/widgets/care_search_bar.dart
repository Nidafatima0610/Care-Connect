import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class CareSearchBar extends StatefulWidget {
  final String hintText;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;

  const CareSearchBar({
    super.key,
    this.hintText = 'Search doctor, specialty, or clinic...',
    this.initialValue = '',
    required this.onChanged,
    this.onClear,
    this.onFilterTap,
    this.hasActiveFilters = false,
  });

  @override
  State<CareSearchBar> createState() => _CareSearchBarState();
}

class _CareSearchBarState extends State<CareSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant CareSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadii.roundedLg,
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060E1A2D),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.teal700,
              size: 22,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md + 2,
                ),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                splashRadius: 18,
                tooltip: 'Clear search',
                onPressed: _handleClear,
              );
            },
          ),
          if (widget.onFilterTap != null) ...[
            Container(height: 24, width: 1, color: AppColors.borderLight),
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: widget.hasActiveFilters
                        ? AppColors.teal700
                        : AppColors.textSecondary,
                  ),
                  if (widget.hasActiveFilters)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.mint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              splashRadius: 20,
              tooltip: 'Filter options',
              onPressed: widget.onFilterTap,
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}
