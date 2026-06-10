import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/models/summary_model.dart';

void main() {
  group('SummaryModel', () {
    test('fromJson parses nested items and firstActionItem', () {
      final json = {
        'sessionId': '550e8400-e29b-41d4-a716-446655440000',
        'status': 'IN_PROGRESS',
        'totalItems': 3,
        'firstActionItem': {
          'itemId': 'item-1',
          'sessionId': '550e8400-e29b-41d4-a716-446655440000',
          'content': '리뷰 요청 답변 보내기',
          'category': 'TOMORROW',
          'isFirstAction': true,
          'sortOrder': 2,
          'createdAt': '2026-06-09T18:32:00Z',
          'updatedAt': '2026-06-09T18:33:00Z',
        },
        'itemsByCategory': {
          'NOW': [],
          'TOMORROW': [
            {
              'itemId': 'item-1',
              'sessionId': '550e8400-e29b-41d4-a716-446655440000',
              'content': '리뷰 요청 답변 보내기',
              'isFirstAction': true,
              'sortOrder': 2,
              'category': 'TOMORROW',
              'createdAt': '2026-06-09T18:32:00Z',
              'updatedAt': '2026-06-09T18:33:00Z',
            },
          ],
          'THIS_WEEK': [
            {
              'itemId': 'item-2',
              'sessionId': '550e8400-e29b-41d4-a716-446655440000',
              'content': '독서 모임 준비',
              'isFirstAction': false,
              'sortOrder': 3,
              'category': 'THIS_WEEK',
              'createdAt': '2026-06-09T18:32:00Z',
              'updatedAt': '2026-06-09T18:33:00Z',
            },
          ],
          'WAITING': [],
          'MEMO': [],
          'WORRY_ONLY': [],
          'DROP': [],
        },
      };

      final model = SummaryModel.fromJson(json);

      expect(model.sessionId, '550e8400-e29b-41d4-a716-446655440000');
      expect(model.status, 'IN_PROGRESS');
      expect(model.totalItems, 3);
      expect(model.firstActionItem, isNotNull);
      expect(model.firstActionItem!.content, '리뷰 요청 답변 보내기');
      expect(model.itemsByCategory['TOMORROW']!.length, 1);
      expect(model.itemsByCategory['THIS_WEEK']!.length, 1);
      expect(model.itemsByCategory['NOW']!.length, 0);
    });

    test('fromJson handles null firstActionItem', () {
      final json = {
        'sessionId': 'session-1',
        'status': 'IN_PROGRESS',
        'totalItems': 0,
        'firstActionItem': null,
        'itemsByCategory': {
          'NOW': [],
          'TOMORROW': [],
          'THIS_WEEK': [],
          'WAITING': [],
          'MEMO': [],
          'WORRY_ONLY': [],
          'DROP': [],
        },
      };

      final model = SummaryModel.fromJson(json);

      expect(model.firstActionItem, isNull);
      expect(model.totalItems, 0);
    });
  });
}
