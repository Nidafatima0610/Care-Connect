import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DoctorAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;
  final bool showBadge;

  const DoctorAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 64,
    this.isOnline = true,
    this.showBadge = true,
  });

  String _getInitials(String rawName) {
    final cleaned = rawName
        .replaceAll('Dr.', '')
        .replaceAll('MD', '')
        .replaceAll('DO', '')
        .replaceAll('PhD', '')
        .replaceAll(',', '')
        .trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'DR';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final indicatorSize = (size * 0.22).clamp(10.0, 16.0);

    return Semantics(
      label: 'Portrait avatar of $name',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              gradient: const LinearGradient(
                colors: [AppColors.navy800, AppColors.teal800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120E1A2D),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.28),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackInitials(initials),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildFallbackInitials(initials);
                      },
                    )
                  : _buildFallbackInitials(initials),
            ),
          ),
          if (showBadge && isOnline)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: indicatorSize,
                height: indicatorSize,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: indicatorSize > 12 ? 2.5 : 2.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackInitials(String initials) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy800, AppColors.teal700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
