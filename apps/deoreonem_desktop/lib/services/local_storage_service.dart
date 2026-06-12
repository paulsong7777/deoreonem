import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _keyRecentSessions = 'recent_completed_session_ids';
  static const _maxRecentSessions = 7;
  static const _keyReviewableCount = 'reviewable_entrusted_count';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  Future<void> saveLastCompletedSession(
      String sessionId, DateTime completedAt) async {
    final current = getRecentCompletedSessionIds();
    // Remove if already exists (avoid duplicates)
    current.remove(sessionId);
    // Add to front (newest first)
    current.insert(0, sessionId);
    // Trim to max
    if (current.length > _maxRecentSessions) {
      current.removeRange(_maxRecentSessions, current.length);
    }
    await _prefs.setStringList(_keyRecentSessions, current);
  }

  List<String> getRecentCompletedSessionIds() {
    return List<String>.from(
        _prefs.getStringList(_keyRecentSessions) ?? []);
  }

  /// Returns the most recent completed session ID, or null
  String? getLastCompletedSessionId() {
    final list = getRecentCompletedSessionIds();
    return list.isNotEmpty ? list.first : null;
  }

  /// Legacy compatibility: returns record if at least one session exists
  ({String sessionId, DateTime completedAt})? getLastCompletedSession() {
    final id = getLastCompletedSessionId();
    if (id == null) return null;
    // completedAt is not stored per-session in the list model; use now as approximation
    return (sessionId: id, completedAt: DateTime.now());
  }

  Future<void> clearLastCompletedSession() async {
    await _prefs.remove(_keyRecentSessions);
  }

  int get reviewableEntrustedCount => _prefs.getInt(_keyReviewableCount) ?? 0;

  Future<void> setReviewableEntrustedCount(int count) async {
    await _prefs.setInt(_keyReviewableCount, count);
  }
}
