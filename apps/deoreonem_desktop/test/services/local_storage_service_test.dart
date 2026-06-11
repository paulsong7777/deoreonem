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

    test('getLastCompletedSession returns null when nothing saved', () {
      expect(service.getLastCompletedSession(), isNull);
    });

    test('saveLastCompletedSession stores and retrieves session', () async {
      final completedAt = DateTime.utc(2026, 6, 10, 18, 30);
      await service.saveLastCompletedSession('session-123', completedAt);

      final result = service.getLastCompletedSession();
      expect(result, isNotNull);
      expect(result!.sessionId, 'session-123');
      expect(result.completedAt, completedAt);
    });

    test('clearLastCompletedSession removes stored session', () async {
      await service.saveLastCompletedSession(
          'session-123', DateTime.utc(2026, 6, 10));
      await service.clearLastCompletedSession();

      expect(service.getLastCompletedSession(), isNull);
    });

    test('saveLastCompletedSession overwrites previous session', () async {
      await service.saveLastCompletedSession(
          'session-1', DateTime.utc(2026, 6, 9));
      await service.saveLastCompletedSession(
          'session-2', DateTime.utc(2026, 6, 10));

      final result = service.getLastCompletedSession();
      expect(result!.sessionId, 'session-2');
    });
  });
}
