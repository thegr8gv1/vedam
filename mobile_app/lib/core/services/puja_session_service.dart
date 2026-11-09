import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/puja_session.dart';

/// Offline-first persistence service for active and completed Guided Puja sessions.
/// Guarantees safe session recovery across app restarts, prevents duplicate sessions,
/// and maintains local worship history with strict corruption tolerance.
class PujaSessionService {
  final SharedPreferences _prefs;

  static const String activeSessionKey = 'vedam_active_puja_session';
  static const String sessionHistoryKey = 'vedam_puja_history';
  static const int maxHistoryEntries = 50;

  PujaSessionService(this._prefs);

  /// Loads the currently in-flight or paused Puja session.
  /// Safely recovers if JSON is corrupted by clearing the corrupted value.
  PujaSession? loadActiveSession() {
    final raw = _prefs.getString(activeSessionKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final session = PujaSession.fromJson(decoded);
        if (session.isActive || session.isPaused) {
          return session;
        }
      }
      _prefs.remove(activeSessionKey);
      return null;
    } catch (e) {
      debugPrint('PujaSessionService: corrupted active session detected, clearing. Error: $e');
      _prefs.remove(activeSessionKey);
      return null;
    }
  }

  /// Persists the active session state.
  Future<bool> saveActiveSession(PujaSession session) async {
    try {
      final jsonStr = jsonEncode(session.toJson());
      return await _prefs.setString(activeSessionKey, jsonStr);
    } catch (e) {
      debugPrint('PujaSessionService: failed to save active session: $e');
      return false;
    }
  }

  /// Clears the active session key upon completion or exit.
  Future<bool> clearActiveSession() async {
    return await _prefs.remove(activeSessionKey);
  }

  /// Records a completed session into historical records (capped at 50) and clears active state.
  Future<bool> recordCompletedSession(PujaSession session) async {
    final completedSession = session.copyWith(
      status: PujaSessionStatus.completed,
      lastUpdatedTime: DateTime.now(),
    );

    // 1. Clear active session
    await clearActiveSession();

    // 2. Append to history
    final history = loadSessionHistory();
    // Prepend to show most recent first, filter out any duplicates with same id
    final updatedHistory = [
      completedSession,
      ...history.where((s) => s.id != completedSession.id),
    ];

    // Cap to maxHistoryEntries
    final cappedHistory = updatedHistory.take(maxHistoryEntries).toList();

    try {
      final rawList = cappedHistory.map((s) => s.toJson()).toList();
      return await _prefs.setString(sessionHistoryKey, jsonEncode(rawList));
    } catch (e) {
      debugPrint('PujaSessionService: failed to save session history: $e');
      return false;
    }
  }

  /// Explicitly marks active session as abandoned and clears active state.
  Future<bool> abandonActiveSession(PujaSession session) async {
    await clearActiveSession();
    return true;
  }

  /// Loads completed Puja session history. Safe against corruption.
  List<PujaSession> loadSessionHistory() {
    final raw = _prefs.getString(sessionHistoryKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final sessions = <PujaSession>[];
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            sessions.add(PujaSession.fromJson(item));
          }
        }
        return sessions;
      }
      return [];
    } catch (e) {
      debugPrint('PujaSessionService: corrupted history detected, resetting. Error: $e');
      _prefs.remove(sessionHistoryKey);
      return [];
    }
  }

  /// Clears worship history upon explicit user request.
  Future<bool> clearHistory() async {
    return await _prefs.remove(sessionHistoryKey);
  }
}
