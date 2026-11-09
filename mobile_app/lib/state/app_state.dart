import 'package:flutter/material.dart';
import '../core/models/app_settings.dart';
import '../core/models/verse.dart';

class AppState extends ChangeNotifier {
  ThemePreference _themePreference = ThemePreference.system;
  TextScalePreference _textScalePreference = TextScalePreference.normal;
  ScriptOption _activeScript = ScriptOption.devanagari;
  InterfaceLanguage _interfaceLanguage = InterfaceLanguage.english;
  final Set<int> _favoriteScriptureIds = {1, 2, 5}; // Ganesha Pancharatnam, Shiva Tandava, Mahamrityunjaya pre-favorited
  final List<int> _recentlyReadScriptureIds = [1, 2, 7, 8];

  ThemePreference get themePreference => _themePreference;
  TextScalePreference get textScalePreference => _textScalePreference;
  ScriptOption get activeScript => _activeScript;
  InterfaceLanguage get interfaceLanguage => _interfaceLanguage;
  Locale get locale => _interfaceLanguage.locale;
  Set<int> get favoriteScriptureIds => Set.unmodifiable(_favoriteScriptureIds);
  List<int> get recentlyReadScriptureIds => List.unmodifiable(_recentlyReadScriptureIds);

  ThemeMode get themeMode => _themePreference.mode;
  double get fontScale => _textScalePreference.scale;

  void setThemePreference(ThemePreference pref) {
    if (_themePreference != pref) {
      _themePreference = pref;
      notifyListeners();
    }
  }

  void setTextScalePreference(TextScalePreference pref) {
    if (_textScalePreference != pref) {
      _textScalePreference = pref;
      notifyListeners();
    }
  }

  void setActiveScript(ScriptOption script) {
    if (_activeScript != script) {
      _activeScript = script;
      notifyListeners();
    }
  }

  void setInterfaceLanguage(InterfaceLanguage lang) {
    if (_interfaceLanguage != lang) {
      _interfaceLanguage = lang;
      notifyListeners();
    }
  }

  bool isFavorite(int scriptureId) {
    return _favoriteScriptureIds.contains(scriptureId);
  }

  void toggleFavorite(int scriptureId) {
    if (_favoriteScriptureIds.contains(scriptureId)) {
      _favoriteScriptureIds.remove(scriptureId);
    } else {
      _favoriteScriptureIds.add(scriptureId);
    }
    notifyListeners();
  }

  void recordRecentlyRead(int scriptureId) {
    _recentlyReadScriptureIds.remove(scriptureId);
    _recentlyReadScriptureIds.insert(0, scriptureId);
    if (_recentlyReadScriptureIds.length > 20) {
      _recentlyReadScriptureIds.removeLast();
    }
    notifyListeners();
  }
}
