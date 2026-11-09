import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/guided_sadhana_session.dart';

/// Offline persistence service for guided Sadhana sessions.
/// Completely local, private, and resilient to storage corruption.
class GuidedSadhanaSessionService {
  static const String keyActiveSession = 'vedam_active_guided_sadhana_session';
  static const String keySessionHistory = 'vedam_guided_sadhana_history';
  static const int maxHistoryEntries = 50;

  final SharedPreferences _prefs;

  GuidedSadhanaSessionService(this._prefs);

  /// Factory helper that gets shared preferences instance if not injected.
  static Future<GuidedSadhanaSessionService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return GuidedSadhanaSessionService(prefs);
  }

  /// Loads the active or paused session if one exists.
  GuidedSadhanaSession? loadActiveSession() {
    final raw = _prefs.getString(keyActiveSession);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GuidedSadhanaSession.fromJson(map);
    } catch (e) {
      debugPrint('GuidedSadhanaSessionService: Corrupted active session recovered safely: $e');
      _prefs.remove(keyActiveSession);
      return null;
    }
  }

  /// Persists current active or paused session.
  Future<bool> saveActiveSession(GuidedSadhanaSession session) async {
    try {
      final jsonStr = jsonEncode(session.toJson());
      return await _prefs.setString(keyActiveSession, jsonStr);
    } catch (e) {
      debugPrint('GuidedSadhanaSessionService: Failed to save active session: $e');
      return false;
    }
  }

  /// Clears active session from storage.
  Future<bool> clearActiveSession() async {
    return await _prefs.remove(keyActiveSession);
  }

  /// Archives a completed session into history and clears the active session key.
  Future<void> recordCompletedSession(GuidedSadhanaSession session) async {
    final finalized = session.copyWith(
      status: SadhanaSessionStatus.completed,
      lastUpdatedTime: DateTime.now(),
    );

    await _addToHistory(finalized);
    await clearActiveSession();
  }

  /// Archives an abandoned / concluded early session into history.
  Future<void> abandonActiveSession(GuidedSadhanaSession session) async {
    final abandoned = session.copyWith(
      status: SadhanaSessionStatus.abandoned,
      lastUpdatedTime: DateTime.now(),
    );

    await _addToHistory(abandoned);
    await clearActiveSession();
  }

  /// Loads the chronological list of completed and abandoned sessions (most recent first).
  List<GuidedSadhanaSession> loadSessionHistory() {
    final raw = _prefs.getString(keySessionHistory);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) {
            try {
              return GuidedSadhanaSession.fromJson(item as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<GuidedSadhanaSession>()
          .toList();
    } catch (e) {
      debugPrint('GuidedSadhanaSessionService: Corrupted history recovered safely: $e');
      _prefs.remove(keySessionHistory);
      return [];
    }
  }

  /// Clears practice history.
  Future<bool> clearHistory() async {
    return await _prefs.remove(keySessionHistory);
  }

  Future<void> _addToHistory(GuidedSadhanaSession session) async {
    try {
      final history = loadSessionHistory();
      // Remove any existing entry with the same session ID to prevent duplicates
      history.removeWhere((s) => s.id == session.id);
      history.insert(0, session);

      // Cap at maxHistoryEntries
      final capped = history.take(maxHistoryEntries).toList();
      final encoded = jsonEncode(capped.map((s) => s.toJson()).toList());
      await _prefs.setString(keySessionHistory, encoded);
    } catch (e) {
      debugPrint('GuidedSadhanaSessionService: Error appending to history: $e');
    }
  }
}
