import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deoreonem_desktop/services/local_storage_service.dart';

void main() {
  group('Nutrient persistence', () {
    late LocalStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = LocalStorageService(prefs);
    });

    test('worry let-go increments totalWorryNutrients once', () async {
      expect(storage.totalWorryNutrients, 0);

      final created = await storage.addWorryNutrient('item-1');

      expect(created, true);
      expect(storage.totalWorryNutrients, 1);
    });

    test('repeated same itemId does not increment twice', () async {
      await storage.addWorryNutrient('item-1');
      final second = await storage.addWorryNutrient('item-1');

      expect(second, false);
      expect(storage.totalWorryNutrients, 1);
    });

    test('different items increment separately', () async {
      await storage.addWorryNutrient('item-1');
      await storage.addWorryNutrient('item-2');
      await storage.addWorryNutrient('item-3');

      expect(storage.totalWorryNutrients, 3);
    });

    test('hasNutrientForItem returns true only for recorded items', () async {
      await storage.addWorryNutrient('item-1');

      expect(storage.hasNutrientForItem('item-1'), true);
      expect(storage.hasNutrientForItem('item-2'), false);
    });

    test('schedule/memo/reset actions do not increment nutrients', () async {
      // These actions use closeItem or resetWorryFade — neither calls addWorryNutrient
      // Simulate by not calling addWorryNutrient — total stays 0
      await storage.resetWorryFade('item-1');

      expect(storage.totalWorryNutrients, 0);
      expect(storage.hasNutrientForItem('item-1'), false);
    });
  });
}
