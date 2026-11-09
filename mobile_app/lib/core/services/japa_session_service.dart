import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/japa_practice_session.dart';

/// Local offline persistence service for Japa practice sessions and history.
///
/// Ensures devotee practice sessions survive application restarts without
/// losing progress, generating phantom counts, or depending on cloud databases.
class JapaSessionService {
  static const String keyActiveSession = 'vedam_japa_active_session_v1';
  static const String keySessionHistory = 'vedam_japa_history_v1';
  static const int maxHistoryEntries = 100;

  final SharedPreferences? _injectedPrefs;

  JapaSessionService({SharedPreferences? prefs}) : _injectedPrefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _injectedPrefs ?? await SharedPreferences.getInstance();
  }

  /// Load active or paused session if one exists.
  /// Safely handles corrupted JSON without throwing errors or incrementing counts.
  Future<JapaPracticeSession?> loadActiveSession() async {
    try {
      final prefs = await _getPrefs();
      final rawJson = prefs.getString(keyActiveSession);
      if (rawJson == null || rawJson.trim().isEmpty) return null;

      final Map<String, dynamic> decoded = jsonDecode(rawJson);
      final session = JapaPracticeSession.fromJson(decoded);

      // Only return if active or paused
      if (session.status == JapaSessionStatus.active ||
          session.status == JapaSessionStatus.paused) {
        return session;
      }
      return null;
    } catch (e) {
      debugPrint('JapaSessionService: Corrupted active session recovered safely: $e');
      return null;
    }
  }

  /// Persist current active or paused session.
  Future<void> saveActiveSession(JapaPracticeSession session) async {
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(session.toJson());
      await prefs.setString(keyActiveSession, encoded);
    } catch (e) {
      debugPrint('JapaSessionService: Error saving active session: $e');
    }
  }

  /// Remove active session key.
  Future<void> clearActiveSession() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(keyActiveSession);
    } catch (e) {
      debugPrint('JapaSessionService: Error clearing active session: $e');
    }
  }

  /// Record a concluded or completed session into practice history and clear active slot.
  Future<void> recordCompletedSession(JapaPracticeSession session) async {
    try {
      final prefs = await _getPrefs();
      final history = await loadSessionHistory();

      // Avoid duplicate entries by session ID
      history.removeWhere((item) => item.id == session.id);

      // Prepend the new session (most recent first)
      history.insert(0, session);

      // Cap history at maxHistoryEntries
      if (history.length > maxHistoryEntries) {
        history.removeRange(maxHistoryEntries, history.length);
      }

      final encodedList = jsonEncode(history.map((s) => s.toJson()).toList());
      await prefs.setString(keySessionHistory, encodedList);

      // Clear the active session key
      await prefs.remove(keyActiveSession);
    } catch (e) {
      debugPrint('JapaSessionService: Error recording completed session: $e');
    }
  }

  /// Deliberately abandon current active session.
  /// If legitimate progress was made (> 0 counts), archives as abandoned to history
  /// before clearing active session.
  Future<void> abandonActiveSession() async {
    final active = await loadActiveSession();
    if (active != null) {
      if (active.completedRepetitions > 0) {
        final abandoned = active.copyWith(
          status: JapaSessionStatus.abandoned,
          lastUpdatedTime: DateTime.now(),
        );
        await recordCompletedSession(abandoned);
      } else {
        await clearActiveSession();
      }
    } else {
      await clearActiveSession();
    }
  }

  /// Load complete practice history.
  /// Gracefully skips any corrupted entries.
  Future<List<JapaPracticeSession>> loadSessionHistory() async {
    try {
      final prefs = await _getPrefs();
      final rawJson = prefs.getString(keySessionHistory);
      if (rawJson == null || rawJson.trim().isEmpty) return [];

      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! List) return [];

      final List<JapaPracticeSession> result = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            result.add(JapaPracticeSession.fromJson(item));
          } catch (e) {
            debugPrint('JapaSessionService: Skipped corrupted history entry: $e');
          }
        }
      }
      return result;
    } catch (e) {
      debugPrint('JapaSessionService: Error loading session history: $e');
      return [];
    }
  }

  /// Clear entire practice history.
  Future<void> clearHistory() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(keySessionHistory);
    } catch (e) {
      debugPrint('JapaSessionService: Error clearing history: $e');
    }
  }
}
