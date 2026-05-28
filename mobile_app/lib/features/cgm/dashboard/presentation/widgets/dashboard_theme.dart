import 'package:flutter/material.dart';

/// Design tokens shared by the redesigned dashboard widgets.
///
/// Centralising these guarantees a single source of truth for colours,
/// spacing and radius across all dashboard cards and matches the
/// figma reference in `figma-screenshot/dashboard/`.
class DashboardTheme {
  DashboardTheme._();

  // --- Surfaces ---
  static const screenBg = Color(0xFFF5F6F8);
  static const surface = Colors.white;
  static const callout = Color(0xFF1B1F23);

  // --- Brand / status ---
  static const accent = Color(0xFF1F8B4C);
  static const accentSoft = Color(0xFFE7F4EC);
  static const warn = Color(0xFFE89E2A);
  static const warnSoft = Color(0xFFFCE9CC);
  static const danger = Color(0xFFE5484D);
  static const dangerSoft = Color(0xFFFDE6E7);
  static const track = Color(0xFFE6E8EC);

  // --- Text ---
  static const textPrimary = Color(0xFF101418);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFFA0A6AE);

  // --- Radius ---
  static const radiusLg = 22.0;
  static const radiusMd = 16.0;
  static const radiusSm = 12.0;
  static const radiusPill = 999.0;

  // --- Spacing scale (4/8 system) ---
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;

  // --- Shadows ---
  static const cardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const calloutShadow = [
    BoxShadow(
      color: Color(0x331B1F23),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  // --- Type ---
  static const display = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    height: 1,
    letterSpacing: -1.5,
  );

  static const heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );

  static const body = TextStyle(
    fontSize: 13,
    color: textSecondary,
    fontWeight: FontWeight.w500,
  );

  static const caption = TextStyle(
    fontSize: 11,
    color: textMuted,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );
}
