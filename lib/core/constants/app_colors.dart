import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette – Tea greens
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryDark = Color(0xFF1B4332);
  static const Color primaryMid = Color(0xFF40916C);
  static const Color primaryLight = Color(0xFF74C69D);
  static const Color primaryFaint = Color(0xFFD8F3DC);

  // Accent – Golden tea
  static const Color accent = Color(0xFFB7943A);
  static const Color accentLight = Color(0xFFE9C46A);

  // Backgrounds
  static const Color background = Color(0xFFF8F4EE);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A2E1A);
  static const Color textSecondary = Color(0xFF5A6E5A);
  static const Color textHint = Color(0xFFAABAAA);

  // UI elements
  static const Color border = Color(0xFFDDE8DD);
  static const Color divider = Color(0xFFE8F0E8);
  static const Color inputFill = Color(0xFFF0F5F0);

  // Status
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF00875A);

  // Gradients
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primary],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryMid],
  );
}
