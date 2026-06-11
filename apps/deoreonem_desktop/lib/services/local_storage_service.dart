import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _keySessionId = 'last_completed_session_id';
  static const _keyCompletedAt = 'last_completed_at';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  Future<void> saveLastCompletedSession(
      String sessionId, DateTime completedAt) async {
    await _prefs.setString(_keySessionId, sessionId);
    await _prefs.setString(_keyCompletedAt, completedAt.toIso8601String());
  }

  ({String sessionId, DateTime completedAt})? getLastCompletedSession() {
    final sessionId = _prefs.getString(_keySessionId);
    final completedAtStr = _prefs.getString(_keyCompletedAt);
    if (sessionId == null || completedAtStr == null) return null;
    return (sessionId: sessionId, completedAt: DateTime.parse(completedAtStr));
  }

  Future<void> clearLastCompletedSession() async {
    await _prefs.remove(_keySessionId);
    await _prefs.remove(_keyCompletedAt);
  }
}
