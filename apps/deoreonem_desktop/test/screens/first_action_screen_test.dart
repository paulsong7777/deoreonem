import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deoreonem_desktop/screens/first_action_screen.dart';
import 'package:deoreonem_desktop/providers/session_provider.dart';
import 'package:deoreonem_desktop/providers/items_provider.dart';
import 'package:deoreonem_desktop/providers/api_provider.dart';
import 'package:deoreonem_desktop/providers/first_action_provider.dart';
import 'package:deoreonem_desktop/models/session_model.dart';
import 'package:deoreonem_desktop/models/item_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deoreonem_desktop/api/decompression_api_service.dart';

class MockApiService extends Mock implements DecompressionApiService {}

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
  });

  testWidgets('FirstActionScreen shows prompt and item list', (tester) async {
    final eligibleItems = [
      ItemModel(
        itemId: 'item-1',
        sessionId: 'session-1',
        content: 'API 설계 마저 하기',
        category: 'NOW',
        isFirstAction: false,
        sortOrder: 1,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      ),
      ItemModel(
        itemId: 'item-2',
        sessionId: 'session-1',
        content: '리뷰 요청 답변 보내기',
        category: 'TOMORROW',
        isFirstAction: false,
        sortOrder: 2,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) {
            final notifier = SessionNotifier(mockApi);
            notifier.state = AsyncValue.data(SessionModel(
              sessionId: 'session-1',
              status: 'IN_PROGRESS',
              createdAt: DateTime.utc(2026, 6, 9),
              updatedAt: DateTime.utc(2026, 6, 9),
            ));
            return notifier;
          }),
          itemsProvider.overrideWith((ref) {
            final notifier = ItemsNotifier(mockApi);
            notifier.state = AsyncValue.data(eligibleItems);
            return notifier;
          }),
          apiServiceProvider.overrideWithValue(mockApi),
        ],
        child: const MaterialApp(home: FirstActionScreen()),
      ),
    );

    expect(find.text('내일 가장 먼저 할 일 하나를 고르세요.'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);
    expect(find.byType(Radio<int>), findsWidgets);
  });

  testWidgets('FirstActionScreen pre-selects item with isFirstAction == true',
      (tester) async {
    final eligibleItems = [
      ItemModel(
        itemId: 'item-1',
        sessionId: 'session-1',
        content: 'API 설계 마저 하기',
        category: 'TOMORROW',
        isFirstAction: false,
        sortOrder: 1,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      ),
      ItemModel(
        itemId: 'item-2',
        sessionId: 'session-1',
        content: '리뷰 요청 답변 보내기',
        category: 'TOMORROW',
        isFirstAction: true,
        sortOrder: 2,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) {
            final notifier = SessionNotifier(mockApi);
            notifier.state = AsyncValue.data(SessionModel(
              sessionId: 'session-1',
              status: 'IN_PROGRESS',
              createdAt: DateTime.utc(2026, 6, 9),
              updatedAt: DateTime.utc(2026, 6, 9),
            ));
            return notifier;
          }),
          itemsProvider.overrideWith((ref) {
            final notifier = ItemsNotifier(mockApi);
            notifier.state = AsyncValue.data(eligibleItems);
            return notifier;
          }),
          apiServiceProvider.overrideWithValue(mockApi),
        ],
        child: const MaterialApp(home: FirstActionScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // The second radio (index 1) should be selected since item-2 has isFirstAction=true
    final radios = tester.widgetList<Radio<int>>(find.byType(Radio<int>)).toList();
    expect(radios.length, 2);
    expect(radios[1].groupValue, 1);
  });

  testWidgets('FirstActionScreen restores selection from firstActionSelectedIdProvider',
      (tester) async {
    final eligibleItems = [
      ItemModel(
        itemId: 'item-1',
        sessionId: 'session-1',
        content: 'API 설계 마저 하기',
        category: 'TOMORROW',
        isFirstAction: false,
        sortOrder: 1,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      ),
      ItemModel(
        itemId: 'item-2',
        sessionId: 'session-1',
        content: '리뷰 요청 답변 보내기',
        category: 'TOMORROW',
        isFirstAction: false,
        sortOrder: 2,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) {
            final notifier = SessionNotifier(mockApi);
            notifier.state = AsyncValue.data(SessionModel(
              sessionId: 'session-1',
              status: 'IN_PROGRESS',
              createdAt: DateTime.utc(2026, 6, 9),
              updatedAt: DateTime.utc(2026, 6, 9),
            ));
            return notifier;
          }),
          itemsProvider.overrideWith((ref) {
            final notifier = ItemsNotifier(mockApi);
            notifier.state = AsyncValue.data(eligibleItems);
            return notifier;
          }),
          apiServiceProvider.overrideWithValue(mockApi),
          firstActionSelectedIdProvider.overrideWith((ref) => 'item-2'),
        ],
        child: const MaterialApp(home: FirstActionScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // The second radio (index 1) should be selected since provider has item-2
    final radios = tester.widgetList<Radio<int>>(find.byType(Radio<int>)).toList();
    expect(radios.length, 2);
    expect(radios[1].groupValue, 1);
  });
}
