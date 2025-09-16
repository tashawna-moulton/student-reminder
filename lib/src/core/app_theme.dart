import 'package:flutter/material.dart';
import 'package:students_reminder/src/core/colors.dart';
import 'package:students_reminder/src/core/typography.dart';

ThemeData buildTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    textTheme: AppTypography.textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface.withAlpha(5),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIconColor: colorScheme.primary,
      prefixStyle: TextStyle(color: colorScheme.primary),
      floatingLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      border: const OutlineInputBorder(),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    textTheme: AppTypography.textTheme.apply(bodyColor: AppColors.white),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface.withOpacity(0.05),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIconColor: colorScheme.primary,
      prefixStyle: TextStyle(color: colorScheme.primary),
      floatingLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      border: const OutlineInputBorder(),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}