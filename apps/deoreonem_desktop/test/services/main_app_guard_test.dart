import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deoreonem_desktop/main.dart';

void main() {
  group('isMainAppRunning', () {
    // In test environment, file-based lock probe returns false (no lock file),
    // so these tests exercise the SharedPreferences fallback path.

    test('returns false when no flag is set', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final running = await isMainAppRunning(prefs);
      expect(running, isFalse);
    });

    test('returns true when flag is set with fresh heartbeat (prefs fallback)', () async {
      SharedPreferences.setMockInitialValues({
        'main_app_running': true,
        'main_app_heartbeat': DateTime.now().toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();

      final running = await isMainAppRunning(prefs);
      expect(running, isTrue);
    });

    test('returns false when heartbeat is stale (older than threshold)', () async {
      final staleTime = DateTime.now().subtract(const Duration(seconds: 30));
      SharedPreferences.setMockInitialValues({
        'main_app_running': true,
        'main_app_heartbeat': staleTime.toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();

      final running = await isMainAppRunning(prefs);
      expect(running, isFalse);
    });

    test('returns false when running flag is false', () async {
      SharedPreferences.setMockInitialValues({
        'main_app_running': false,
        'main_app_heartbeat': DateTime.now().toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();

      final running = await isMainAppRunning(prefs);
      expect(running, isFalse);
    });

    test('returns false when heartbeat is null', () async {
      SharedPreferences.setMockInitialValues({
        'main_app_running': true,
      });
      final prefs = await SharedPreferences.getInstance();

      final running = await isMainAppRunning(prefs);
      expect(running, isFalse);
    });

    test('returns false when heartbeat is unparseable', () async {
      SharedPreferences.setMockInitialValues({
        'main_app_running': true,
        'main_app_heartbeat': 'not-a-date',
      });
      final prefs = await SharedPreferences.getInstance();

      final running = await isMainAppRunning(prefs);
      expect(running, isFalse);
    });

    test('clears stale flag when heartbeat expired', () async {
      final staleTime = DateTime.now().subtract(const Duration(seconds: 30));
      SharedPreferences.setMockInitialValues({
        'main_app_running': true,
        'main_app_heartbeat': staleTime.toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();

      await isMainAppRunning(prefs);

      // After calling isMainAppRunning with stale heartbeat, flag should be cleared
      expect(prefs.getBool('main_app_running'), isFalse);
    });
  });
}
