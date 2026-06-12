import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deoreonem_desktop/services/local_storage_service.dart';

void main() {
  group('LocalStorageService', () {
    late LocalStorageService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = LocalStorageService(prefs);
    });

    test('getRecentCompletedSessionIds returns empty list when nothing saved',
        () {
      expect(service.getRecentCompletedSessionIds(), isEmpty);
    });

    test('getLastCompletedSessionId returns null when nothing saved', () {
      expect(service.getLastCompletedSessionId(), isNull);
    });

    test('getLastCompletedSession returns null when nothing saved', () {
      expect(service.getLastCompletedSession(), isNull);
    });

    test('save one session returns it in list', () async {
      await service.saveLastCompletedSession(
          'session-1', DateTime.utc(2026, 6, 10));

      final ids = service.getRecentCompletedSessionIds();
      expect(ids, ['session-1']);
    });

    test('save 3 sessions returns newest first', () async {
      await service.saveLastCompletedSession(
          'session-1', DateTime.utc(2026, 6, 8));
      await service.saveLastCompletedSession(
          'session-2', DateTime.utc(2026, 6, 9));
      await service.saveLastCompletedSession(
          'session-3', DateTime.utc(2026, 6, 10));

      final ids = service.getRecentCompletedSessionIds();
      expect(ids, ['session-3', 'session-2', 'session-1']);
    });

    test('save duplicate moves it to front without duplicating', () async {
      await service.saveLastCompletedSession(
          'session-1', DateTime.utc(2026, 6, 8));
      await service.saveLastCompletedSession(
          'session-2', DateTime.utc(2026, 6, 9));
      await service.saveLastCompletedSession(
          'session-1', DateTime.utc(2026, 6, 10));

      final ids = service.getRecentCompletedSessionIds();
      expect(ids, ['session-1', 'session-2']);
    });

    test('save 8 sessions retains only 7 newest', () async {
      for (int i = 1; i <= 8; i++) {
        await service.saveLastCompletedSession(
            'session-$i', DateTime.utc(2026, 6, i));
      }

      final ids = service.getRecentCompletedSessionIds();
      expect(ids.length, 7);
      expect(ids.first, 'session-8');
      expect(ids.last, 'session-2');
      expect(ids.contains('session-1'), isFalse);
    });

    test('clearLastCompletedSession returns empty list', () async {
      await service.saveLastCompletedSession(
          'session-1', DateTime.utc(2026, 6, 10));
      await service.clearLastCompletedSession();

      expect(service.getRecentCompletedSessionIds(), isEmpty);
      expect(service.getLastCompletedSessionId(), isNull);
    });

    test('getLastCompletedSessionId returns first in list', () async {
      await service.saveLastCompletedSession(
          'session-1', DateTime.utc(2026, 6, 8));
      await service.saveLastCompletedSession(
          'session-2', DateTime.utc(2026, 6, 9));

      expect(service.getLastCompletedSessionId(), 'session-2');
    });

    test('getLastCompletedSession returns record with first session id',
        () async {
      await service.saveLastCompletedSession(
          'session-1', DateTime.utc(2026, 6, 8));
      await service.saveLastCompletedSession(
          'session-2', DateTime.utc(2026, 6, 9));

      final result = service.getLastCompletedSession();
      expect(result, isNotNull);
      expect(result!.sessionId, 'session-2');
    });
  });
}
