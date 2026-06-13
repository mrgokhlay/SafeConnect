// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_color.dart';

class AppTheme {
  // =========================
  // DARK THEME
  // =========================

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    brightness: Brightness.dark,

    scaffoldBackgroundColor: AppColors.darkBackground,

    cardColor: AppColors.darkSurface,

    dividerColor: AppColors.darkBorder,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkAppBar,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      centerTitle: false,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.darkText,
        fontWeight: FontWeight.w700,
      ),

      bodyLarge: TextStyle(color: AppColors.darkText),

      bodyMedium: TextStyle(color: AppColors.darkSubtext),
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white,
      textColor: Colors.white,
    ),
  );

  // =========================
  // LIGHT THEME
  // =========================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    brightness: Brightness.light,

    scaffoldBackgroundColor: AppColors.lightBackground,

    cardColor: AppColors.lightSurface,

    dividerColor: AppColors.lightBorder,

    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightSurface,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightAppBar,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      centerTitle: false,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.lightText,
        fontWeight: FontWeight.w700,
      ),

      bodyLarge: TextStyle(color: AppColors.lightText),

      bodyMedium: TextStyle(color: AppColors.lightSubtext),
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.lightText,
      textColor: AppColors.lightText,
    ),
  );
}
