import 'package:flutter/material.dart';

/// Палитра Deadlock: нуар, бордовый бархат, медь и золото.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF0C0A0C);
  static const Color surface = Color(0xFF171214);
  static const Color surfaceAlt = Color(0xFF1F181B);
  static const Color surfaceLight = Color(0xFF2A2024);
  static const Color border = Color(0xFF3A2B2F);

  static const Color burgundy = Color(0xFF7C1F2D);
  static const Color burgundyBright = Color(0xFFA62B3C);
  static const Color copper = Color(0xFFB87333);
  static const Color gold = Color(0xFFD9A441);

  static const Color text = Color(0xFFF1E7DC);
  static const Color muted = Color(0xFF9C8A85);
  static const Color win = Color(0xFF67B77F);
  static const Color lose = Color(0xFFC65454);

  static Color winRateColor(double value) => value >= 0.5 ? win : lose;
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.copper,
      onPrimary: Colors.black,
      secondary: AppColors.gold,
      onSecondary: Colors.black,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.lose,
      onError: Colors.white,
    ),
  );

  final textTheme = base.textTheme
      .apply(bodyColor: AppColors.text, displayColor: AppColors.text)
      .copyWith(
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
        bodyMedium: const TextStyle(fontSize: 13, color: AppColors.text),
        bodySmall: const TextStyle(fontSize: 11.5, color: AppColors.muted),
      );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.text),
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceLight,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.copper,
      linearTrackColor: AppColors.surfaceLight,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceAlt,
      contentTextStyle: TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.copper, width: 1.4),
      ),
    ),
  );
}
