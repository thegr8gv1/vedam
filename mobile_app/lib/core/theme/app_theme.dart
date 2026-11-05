import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.saffronPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.saffronLight,
      onPrimaryContainer: AppColors.saffronDark,
      secondary: AppColors.goldPrimary,
      onSecondary: Colors.black,
      secondaryContainer: AppColors.goldLight,
      onSecondaryContainer: AppColors.goldDark,
      surface: AppColors.ivorySurface,
      onSurface: AppColors.textDarkPrimary,
      error: AppColors.kumkumRed,
      onError: Colors.white,
      outline: AppColors.chandanBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.creamBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.creamBackground,
        foregroundColor: AppColors.textDarkPrimary,
        elevation: 0,
        scrolledUnderElevation: 1.5,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.ivorySurface,
        elevation: 0.5,
        shadowColor: const Color(0x1A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.chandanBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.ivorySurface,
        selectedItemColor: AppColors.saffronPrimary,
        unselectedItemColor: AppColors.textDarkMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.chandanBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.ivorySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.chandanBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.chandanBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.saffronPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.saffronAccent,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF331B0E),
      onPrimaryContainer: const Color(0xFFFFDBC8),
      secondary: AppColors.goldGlow,
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF30260D),
      onSecondaryContainer: const Color(0xFFFFEFA7),
      surface: AppColors.nightSurface,
      onSurface: AppColors.textLightPrimary,
      error: const Color(0xFFF87171),
      onError: Colors.black,
      outline: AppColors.nightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.nightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.nightBackground,
        foregroundColor: AppColors.textLightPrimary,
        elevation: 0,
        scrolledUnderElevation: 1.5,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.nightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.nightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.nightSurface,
        selectedItemColor: AppColors.saffronAccent,
        unselectedItemColor: AppColors.textLightMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.nightBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.nightSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.nightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.nightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.saffronAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
