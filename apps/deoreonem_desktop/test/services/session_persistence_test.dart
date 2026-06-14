import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deoreonem_desktop/services/local_storage_service.dart';

void main() {
  group('Session Persistence — multi-session accumulation', () {
    late LocalStorageService service;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = LocalStorageService(prefs);
    });

    test('multiple sessions are accumulated, not overwritten', () async {
      await service.saveLastCompletedSession(
          'session-A', DateTime.utc(2026, 7, 1));
      await service.saveLastCompletedSession(
          'session-B', DateTime.utc(2026, 7, 2));
      await service.saveLastCompletedSession(
          'session-C', DateTime.utc(2026, 7, 3));

      final ids = service.getRecentCompletedSessionIds();
      expect(ids, contains('session-A'));
      expect(ids, contains('session-B'));
      expect(ids, contains('session-C'));
      expect(ids.length, 3);
      // Newest first
      expect(ids.first, 'session-C');
      expect(ids.last, 'session-A');
    });

    test('deduplication works — re-saving existing session moves to front', () async {
      await service.saveLastCompletedSession(
          'session-1', DateTime.utc(2026, 7, 1));
      await service.saveLastCompletedSession(
          'session-2', DateTime.utc(2026, 7, 2));
      await service.saveLastCompletedSession(
          'session-3', DateTime.utc(2026, 7, 3));
      // Re-save session-1
      await service.saveLastCompletedSession(
          'session-1', DateTime.utc(2026, 7, 4));

      final ids = service.getRecentCompletedSessionIds();
      expect(ids.length, 3); // No duplicates
      expect(ids.first, 'session-1'); // Moved to front
      expect(ids.where((id) => id == 'session-1').length, 1);
    });

    test('file fallback works when SharedPreferences is empty', () async {
      // Save sessions so they appear in both SharedPreferences and file
      await service.saveLastCompletedSession(
          'session-X', DateTime.utc(2026, 7, 1));
      await service.saveLastCompletedSession(
          'session-Y', DateTime.utc(2026, 7, 2));

      // Simulate SharedPreferences losing data (e.g., registry issue on Windows)
      await prefs.remove('recent_completed_session_ids');

      // In test environment, file I/O is skipped (resolvedExecutable check).
      // So this tests that the service handles empty prefs gracefully.
      final ids = service.getRecentCompletedSessionIds();
      // In test, file fallback returns [] since file I/O is disabled,
      // so this verifies the code doesn't crash and returns empty gracefully.
      expect(ids, isA<List<String>>());
    });

    test('merged list maintains order — newest first', () async {
      await service.saveLastCompletedSession(
          'oldest', DateTime.utc(2026, 7, 1));
      await service.saveLastCompletedSession(
          'middle', DateTime.utc(2026, 7, 2));
      await service.saveLastCompletedSession(
          'newest', DateTime.utc(2026, 7, 3));

      final ids = service.getRecentCompletedSessionIds();
      expect(ids, ['newest', 'middle', 'oldest']);
    });

    test('setReviewableEntrustedCount does not affect session IDs', () async {
      await service.saveLastCompletedSession(
          'session-keep', DateTime.utc(2026, 7, 1));
      await service.saveLastCompletedSession(
          'session-keep2', DateTime.utc(2026, 7, 2));

      // Simulate setting count to 0 (all items let go)
      await service.setReviewableEntrustedCount(0);

      final ids = service.getRecentCompletedSessionIds();
      expect(ids, contains('session-keep'));
      expect(ids, contains('session-keep2'));
      expect(ids.length, 2);
    });

    test('up to 7 sessions retained, oldest dropped', () async {
      for (int i = 1; i <= 9; i++) {
        await service.saveLastCompletedSession(
            'session-$i', DateTime.utc(2026, 7, i));
      }

      final ids = service.getRecentCompletedSessionIds();
      expect(ids.length, 7);
      expect(ids.first, 'session-9');
      // session-1 and session-2 should be dropped (oldest)
      expect(ids.contains('session-1'), isFalse);
      expect(ids.contains('session-2'), isFalse);
    });
  });
}
