import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.onTertiary,
          tertiaryContainer: AppColors.tertiaryContainer,
          onTertiaryContainer: AppColors.onTertiaryContainer,
          error: AppColors.error,
          onError: AppColors.onError,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.onErrorContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
          inverseSurface: AppColors.inverseSurface,
          onInverseSurface: AppColors.inverseOnSurface,
          inversePrimary: AppColors.inversePrimary,
          surfaceTint: AppColors.surfaceTint,
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.displayLg.copyWith(color: AppColors.onSurface),
          headlineLarge: AppTypography.headlineLg.copyWith(color: AppColors.onSurface),
          headlineMedium: AppTypography.headlineMd.copyWith(color: AppColors.onSurface),
          bodyLarge: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
          bodyMedium: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          labelSmall: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.onBackground,
          elevation: 0,
          titleTextStyle: AppTypography.headlineMd.copyWith(color: AppColors.onBackground),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceContainerLowest,
          selectedItemColor: AppColors.onSurface,
          unselectedItemColor: AppColors.outline,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerLowest,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: AppColors.black, width: 3),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: AppColors.black, width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: AppColors.primary, width: 3),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: AppColors.error, width: 3),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: AppColors.error, width: 3),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.inverseSurface,
          contentTextStyle: AppTypography.bodyMd.copyWith(color: AppColors.inverseOnSurface),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
