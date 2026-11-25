import 'package:flutter/material.dart';

/// The app's green palette. Use these instead of raw colors in widgets.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF1B7A4B);
  static const Color primaryDark = Color(0xFF145C38);
  static const Color primaryLight = Color(0xFFE3F3EA);

  // Surfaces
  static const Color background = Color(0xFFF4F6F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE1E5E3);
  static const Color inputBorder = Color(0xFFC9D0CC);
  static const Color disabled = Color(0xFFDCE1DE);

  // Text
  static const Color text = Color(0xFF17201B);
  static const Color textMuted = Color(0xFF5F6B65);
  static const Color textHint = Color(0xFF8A948F);

  // Money & status
  static const Color positive = Color(0xFF2E7D32);
  static const Color negative = Color(0xFFC62828);
  static const Color negativeLight = Color(0xFFFBE4E4);
  static const Color warningBg = Color(0xFFFCEBD0);
  static const Color warningText = Color(0xFF8A5A00);
  static const Color infoBg = Color(0xFFE3ECF7);
  static const Color infoText = Color(0xFF1E4F8A);
  static const Color neutralBg = Color(0xFFE8ECEA);
}
