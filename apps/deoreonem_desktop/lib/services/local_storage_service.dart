import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _keyRecentSessions = 'recent_completed_session_ids';
  static const _maxRecentSessions = 7;
  static const _keyReviewableCount = 'reviewable_entrusted_count';
  static const _keyWorryFadeResets = 'worry_fade_resets';

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

  // --- Worry Fade Resets ---

  Map<String, DateTime> getWorryFadeResets() {
    final json = _prefs.getString(_keyWorryFadeResets);
    if (json == null) return {};
    final map = Map<String, String>.from(jsonDecode(json) as Map);
    return map.map((k, v) => MapEntry(k, DateTime.parse(v)));
  }

  Future<void> resetWorryFade(String itemId) async {
    final resets = getWorryFadeResets();
    resets[itemId] = DateTime.now();
    await _prefs.setString(
      _keyWorryFadeResets,
      jsonEncode(resets.map((k, v) => MapEntry(k, v.toIso8601String()))),
    );
  }

  // --- Minimal Nutrient Persistence ---
  // Bridge for future "small pot / quiet tree" widget.
  // Full event/snapshot modeling deferred until widget requirements are clearer.
  // Nutrient is symbolic emotional conversion, not game reward.
  // Created only by worry let-go ("이 걱정 내려놓기").

  static const _keyTotalWorryNutrients = 'total_worry_nutrients';
  static const _keyNutrientCreatedItemIds = 'nutrient_created_item_ids';

  int get totalWorryNutrients => _prefs.getInt(_keyTotalWorryNutrients) ?? 0;

  bool hasNutrientForItem(String itemId) {
    final ids = _prefs.getStringList(_keyNutrientCreatedItemIds) ?? [];
    return ids.contains(itemId);
  }

  /// Records one nutrient for a worry item let-go. Returns true if nutrient was
  /// created, false if already exists (duplicate prevention).
  Future<bool> addWorryNutrient(String itemId) async {
    if (hasNutrientForItem(itemId)) return false;

    final ids = List<String>.from(_prefs.getStringList(_keyNutrientCreatedItemIds) ?? []);
    ids.add(itemId);
    await _prefs.setStringList(_keyNutrientCreatedItemIds, ids);

    final current = totalWorryNutrients;
    await _prefs.setInt(_keyTotalWorryNutrients, current + 1);
    return true;
  }
}
