import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  /// Robust font fallbacks for Pan-Indic scripts across Android, Web, and desktop platforms.
  static const List<String> indicFontFamilyFallback = [
    'Noto Sans Devanagari',
    'Noto Sans Telugu',
    'Noto Sans Tamil',
    'Noto Sans Kannada',
    'Noto Sans Malayalam',
    'Roboto',
    'sans-serif',
  ];

  // Headings
  static TextStyle titleLarge(bool isDark) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle titleMedium(bool isDark) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle titleSmall(bool isDark) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
      );

  // Sacred Verse Styles with guaranteed Indic font fallbacks
  static TextStyle verseDevanagari(bool isDark, {double scale = 1.0}) => TextStyle(
        fontSize: 20 * scale,
        fontWeight: FontWeight.w600,
        height: 1.75,
        letterSpacing: 0.4,
        fontFamilyFallback: indicFontFamilyFallback,
        color: isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1F1610),
      );

  static TextStyle verseTransliteration(bool isDark, {double scale = 1.0}) => TextStyle(
        fontSize: 15 * scale,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        height: 1.6,
        letterSpacing: 0.2,
        fontFamilyFallback: indicFontFamilyFallback,
        color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
      );

  static TextStyle verseMeaning(bool isDark, {double scale = 1.0}) => TextStyle(
        fontSize: 15 * scale,
        fontWeight: FontWeight.w400,
        height: 1.6,
        fontFamilyFallback: indicFontFamilyFallback,
        color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
      );

  // Liturgical & Metadata Tags
  static TextStyle metadataTag(bool isDark) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
      );

  static TextStyle bodyMedium(bool isDark) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
      );

  static TextStyle bodySmall(bool isDark) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
      );

  static TextStyle caption(bool isDark) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
      );
}
