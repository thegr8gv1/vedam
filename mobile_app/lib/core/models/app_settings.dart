import 'package:flutter/material.dart';

enum ThemePreference {
  system('System Default', ThemeMode.system),
  light('Sacred Light (Saffron & Marble)', ThemeMode.light),
  dark('Temple Night (Obsidian & Gold)', ThemeMode.dark);

  final String label;
  final ThemeMode mode;
  const ThemePreference(this.label, this.mode);
}

enum TextScalePreference {
  normal('Regular', 1.0),
  large('Large', 1.18),
  extraLarge('Spiritual Focus (Extra Large)', 1.35);

  final String label;
  final double scale;
  const TextScalePreference(this.label, this.scale);
}

enum ContentDisplayMode {
  sourceAndTransliteration('Source + Transliteration'),
  sourceOnly('Source Script Only'),
  allWithCommentary('Complete Study (Source + Transliteration + Commentary)');

  final String label;
  const ContentDisplayMode(this.label);
}

enum InterfaceLanguage {
  english('en', 'English', 'English'),
  telugu('te', 'Telugu', 'తెలుగు'),
  tamil('ta', 'Tamil', 'தமிழ்'),
  kannada('kn', 'Kannada', 'ಕನ್ನಡ'),
  malayalam('ml', 'Malayalam', 'മലയാളം');

  final String code;
  final String label;
  final String nativeLabel;
  const InterfaceLanguage(this.code, this.label, this.nativeLabel);

  Locale get locale => Locale(code);

  static InterfaceLanguage fromCode(String code) {
    for (final l in InterfaceLanguage.values) {
      if (l.code == code) return l;
    }
    return InterfaceLanguage.english;
  }
}
