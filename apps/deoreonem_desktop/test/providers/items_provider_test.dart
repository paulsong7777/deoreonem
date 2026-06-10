import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deoreonem_desktop/api/decompression_api_service.dart';
import 'package:deoreonem_desktop/models/item_model.dart';
import 'package:deoreonem_desktop/providers/items_provider.dart';

class MockApiService extends Mock implements DecompressionApiService {}

void main() {
  late MockApiService mockApi;
  late ItemsNotifier notifier;

  final testItem = ItemModel(
    itemId: 'item-1',
    sessionId: 'session-1',
    content: '테스트 항목',
    category: null,
    isFirstAction: false,
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 6, 9),
    updatedAt: DateTime.utc(2026, 6, 9),
  );

  setUp(() {
    mockApi = MockApiService();
    notifier = ItemsNotifier(mockApi);
  });

  group('ItemsNotifier', () {
    test('initial state is empty list', () {
      expect(notifier.state, isA<AsyncData<List<ItemModel>>>());
      expect(notifier.state.value, isEmpty);
    });

    test('addItem appends item to list', () async {
      when(() => mockApi.addItem('session-1', '테스트 항목'))
          .thenAnswer((_) async => testItem);

      await notifier.addItem('session-1', '테스트 항목');

      expect(notifier.state.value!.length, 1);
      expect(notifier.state.value!.first.content, '테스트 항목');
    });

    test('updateCategory replaces item in list', () async {
      when(() => mockApi.addItem('session-1', '테스트 항목'))
          .thenAnswer((_) async => testItem);
      await notifier.addItem('session-1', '테스트 항목');

      final updatedItem = testItem.copyWith(category: 'NOW');
      when(() => mockApi.updateCategory('session-1', 'item-1', 'NOW'))
          .thenAnswer((_) async => updatedItem);

      await notifier.updateCategory('session-1', 'item-1', 'NOW');

      expect(notifier.state.value!.first.category, 'NOW');
    });

    test('unclassifiedItems returns only items without category', () async {
      when(() => mockApi.addItem('session-1', '테스트 항목'))
          .thenAnswer((_) async => testItem);
      await notifier.addItem('session-1', '테스트 항목');

      expect(notifier.unclassifiedItems.length, 1);

      // Classify it
      final updatedItem = testItem.copyWith(category: 'NOW');
      when(() => mockApi.updateCategory('session-1', 'item-1', 'NOW'))
          .thenAnswer((_) async => updatedItem);
      await notifier.updateCategory('session-1', 'item-1', 'NOW');

      expect(notifier.unclassifiedItems.length, 0);
    });

    test('eligibleForFirstAction returns NOW/TOMORROW/THIS_WEEK items',
        () async {
      final nowItem = ItemModel(
        itemId: 'item-now',
        sessionId: 'session-1',
        content: '지금 할 일',
        category: 'NOW',
        isFirstAction: false,
        sortOrder: 1,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      );
      final worryItem = ItemModel(
        itemId: 'item-worry',
        sessionId: 'session-1',
        content: '걱정',
        category: 'WORRY_ONLY',
        isFirstAction: false,
        sortOrder: 2,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      );

      when(() => mockApi.addItem('session-1', '지금 할 일'))
          .thenAnswer((_) async => nowItem);
      when(() => mockApi.addItem('session-1', '걱정'))
          .thenAnswer((_) async => worryItem);

      await notifier.addItem('session-1', '지금 할 일');
      await notifier.addItem('session-1', '걱정');

      expect(notifier.eligibleForFirstAction.length, 1);
      expect(notifier.eligibleForFirstAction.first.content, '지금 할 일');
    });

    test('reset clears all items', () async {
      when(() => mockApi.addItem('session-1', '테스트 항목'))
          .thenAnswer((_) async => testItem);
      await notifier.addItem('session-1', '테스트 항목');

      notifier.reset();

      expect(notifier.state.value, isEmpty);
    });
  });
}
