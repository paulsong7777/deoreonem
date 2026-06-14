import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
    // Always merge BOTH sources to prevent data loss across sessions
    final merged = _getMergedSessionIds();
    // Remove if already exists (avoid duplicates)
    merged.remove(sessionId);
    // Add to front (newest first)
    merged.insert(0, sessionId);
    // Trim to max
    if (merged.length > _maxRecentSessions) {
      merged.removeRange(_maxRecentSessions, merged.length);
    }
    // Write to both stores atomically
    await _prefs.setStringList(_keyRecentSessions, merged);
    _writeSessionIdsFile(merged);
  }

  List<String> getRecentCompletedSessionIds() {
    return _getMergedSessionIds();
  }

  /// Reads from both SharedPreferences AND file, merges/deduplicates.
  /// Maintains newest-first order from SharedPreferences as primary,
  /// then appends any IDs only found in the file fallback.
  List<String> _getMergedSessionIds() {
    final fromPrefs = List<String>.from(
        _prefs.getStringList(_keyRecentSessions) ?? []);
    final fromFile = _readSessionIdsFromFile();

    if (fromPrefs.isEmpty && fromFile.isEmpty) return [];
    if (fromFile.isEmpty) return List<String>.from(fromPrefs);
    if (fromPrefs.isEmpty) return List<String>.from(fromFile);

    // Merge: prefs is primary order, append file-only entries
    final seen = <String>{};
    final merged = <String>[];
    for (final id in fromPrefs) {
      if (seen.add(id)) merged.add(id);
    }
    for (final id in fromFile) {
      if (seen.add(id)) merged.add(id);
    }
    // Trim to max
    if (merged.length > _maxRecentSessions) {
      return merged.sublist(0, _maxRecentSessions);
    }
    return merged;
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

  int get reviewableEntrustedCount {
    final fromPrefs = _prefs.getInt(_keyReviewableCount) ?? 0;
    if (fromPrefs > 0) return fromPrefs;
    // Fallback: if session IDs exist in file but count is 0, report positive
    // so the review button shows (review screen will fetch actual items)
    final sessionIds = getRecentCompletedSessionIds();
    return sessionIds.isNotEmpty ? 1 : 0;
  }

  Future<void> setReviewableEntrustedCount(int count) async {
    // Only update the reviewable count — never touch session IDs here.
    assert(() {
      debugPrint('[LocalStorage] setReviewableEntrustedCount($count)');
      return true;
    }());
    await _prefs.setInt(_keyReviewableCount, count);
  }

  // --- File-based session ID persistence ---
  // SharedPreferences on Windows (registry-based) may not reliably persist
  // across all launch scenarios (different exe paths, build vs ZIP, etc.)

  static File? _getSessionIdsFile() {
    try {
      final exePath = Platform.resolvedExecutable;
      if (exePath.contains('dart_test') || exePath.contains('flutter_tester')) {
        return null;
      }
      final exeDir = File(exePath).parent.path;
      return File('$exeDir/completed_sessions.json');
    } catch (_) {
      return null;
    }
  }

  void _writeSessionIdsFile(List<String> sessionIds) {
    try {
      final file = _getSessionIdsFile();
      if (file == null) return;
      final content = jsonEncode({
        'sessionIds': sessionIds,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      // Atomic-safe: write to temp file, then rename to prevent partial writes
      final tempFile = File('${file.path}.tmp');
      tempFile.writeAsStringSync(content, flush: true);
      tempFile.renameSync(file.path);
    } catch (_) {
      // Non-critical: SharedPreferences is still the primary store
    }
  }

  static List<String> _readSessionIdsFromFile() {
    try {
      final file = _getSessionIdsFile();
      if (file == null || !file.existsSync()) return [];
      final content = file.readAsStringSync();
      final map = jsonDecode(content) as Map<String, dynamic>;
      final ids = (map['sessionIds'] as List?)?.cast<String>() ?? [];
      return ids;
    } catch (_) {
      return [];
    }
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
    final newTotal = current + 1;
    await _prefs.setInt(_keyTotalWorryNutrients, newTotal);

    // Fire-and-forget: write garden state file for reliable cross-process sync.
    // SharedPreferences.reload() is unreliable on Windows in some scenarios.
    // Do NOT await — this is non-critical and must not block the caller.
    _writeGardenStateFile(newTotal);
    return true;
  }

  /// Writes a simple JSON file that the garden overlay can poll directly.
  void _writeGardenStateFile(int totalNutrients) {
    try {
      final file = _getGardenStateFile();
      if (file == null) return;
      file.writeAsString(
        jsonEncode({'totalWorryNutrients': totalNutrients, 'updatedAt': DateTime.now().toIso8601String()}),
      );
    } catch (_) {
      // Non-critical: overlay falls back to SharedPreferences
    }
  }

  /// Returns the path to garden_state.json next to the executable, or null in test.
  static File? _getGardenStateFile() {
    try {
      final exePath = Platform.resolvedExecutable;
      // In test environments, resolvedExecutable may point to dart test runner —
      // skip file sync in that case.
      if (exePath.contains('dart_test') || exePath.contains('flutter_tester')) {
        return null;
      }
      final exeDir = File(exePath).parent.path;
      return File('$exeDir/garden_state.json');
    } catch (_) {
      return null;
    }
  }

  /// Read total nutrients from the garden state file (cross-process sync).
  /// Returns null if file doesn't exist or is unreadable.
  static int? readGardenStateFromFile() {
    try {
      final file = _getGardenStateFile();
      if (file == null || !file.existsSync()) return null;
      final content = file.readAsStringSync();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return map['totalWorryNutrients'] as int?;
    } catch (_) {
      return null;
    }
  }
}
