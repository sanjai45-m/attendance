import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42E8);

  // Accent
  static const Color accent = Color(0xFF00D9A6);
  static const Color accentLight = Color(0xFF5EFFD4);
  static const Color accentDark = Color(0xFF00A87E);

  // Background
  static const Color scaffoldBg = Color(0xFF0F0F23);
  static const Color cardBg = Color(0xFF1A1A2E);
  static const Color surfaceBg = Color(0xFF16213E);

  // Text
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6C6C80);

  // Status colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB40);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF448AFF);

  // Others
  static const Color divider = Color(0xFF2A2A3E);
  static const Color shadow = Color(0x40000000);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardBg, surfaceBg],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
