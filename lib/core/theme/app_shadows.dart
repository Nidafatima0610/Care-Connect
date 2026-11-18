import 'package:flutter/material.dart';

/// Soft, sophisticated shadows using tinted Navy rather than harsh pitch black.
abstract final class AppShadows {
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x080E1A2D),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0C0E1A2D),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x040E1A2D),
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x140E1A2D),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> tealGlow = [
    BoxShadow(
      color: Color(0x330E7490),
      blurRadius: 18,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];
}
