import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/models/item_model.dart';

void main() {
  group('ItemModel', () {
    final sampleJson = {
      'itemId': '661e8400-e29b-41d4-a716-446655440001',
      'sessionId': '550e8400-e29b-41d4-a716-446655440000',
      'content': 'API 설계 마저 하기',
      'category': 'TOMORROW',
      'isFirstAction': true,
      'sortOrder': 1,
      'createdAt': '2026-06-09T18:31:00Z',
      'updatedAt': '2026-06-09T18:33:00Z',
    };

    test('fromJson parses valid JSON correctly', () {
      final model = ItemModel.fromJson(sampleJson);

      expect(model.itemId, '661e8400-e29b-41d4-a716-446655440001');
      expect(model.sessionId, '550e8400-e29b-41d4-a716-446655440000');
      expect(model.content, 'API 설계 마저 하기');
      expect(model.category, 'TOMORROW');
      expect(model.isFirstAction, true);
      expect(model.sortOrder, 1);
      expect(model.createdAt, DateTime.utc(2026, 6, 9, 18, 31, 0));
      expect(model.updatedAt, DateTime.utc(2026, 6, 9, 18, 33, 0));
    });

    test('fromJson handles null category and missing isFirstAction', () {
      final json = {
        'itemId': 'item-1',
        'sessionId': 'session-1',
        'content': '생각 정리',
        'category': null,
        'sortOrder': 2,
        'createdAt': '2026-06-09T18:31:00Z',
        'updatedAt': '2026-06-09T18:31:00Z',
      };

      final model = ItemModel.fromJson(json);

      expect(model.category, isNull);
      expect(model.isFirstAction, false);
    });

    test('toJson produces expected output', () {
      final model = ItemModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['itemId'], '661e8400-e29b-41d4-a716-446655440001');
      expect(json['content'], 'API 설계 마저 하기');
      expect(json['category'], 'TOMORROW');
      expect(json['isFirstAction'], true);
      expect(json['sortOrder'], 1);
    });

    test('fromJson/toJson round-trip preserves data', () {
      final model = ItemModel.fromJson(sampleJson);
      final json = model.toJson();
      final roundTripped = ItemModel.fromJson(json);

      expect(roundTripped.itemId, model.itemId);
      expect(roundTripped.content, model.content);
      expect(roundTripped.category, model.category);
      expect(roundTripped.isFirstAction, model.isFirstAction);
      expect(roundTripped.sortOrder, model.sortOrder);
    });

    test('copyWith updates category', () {
      final model = ItemModel.fromJson(sampleJson);
      final updated = model.copyWith(category: 'NOW');

      expect(updated.category, 'NOW');
      expect(updated.content, model.content);
    });
  });
}
