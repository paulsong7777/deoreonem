import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deoreonem_desktop/screens/classification_screen.dart';
import 'package:deoreonem_desktop/providers/session_provider.dart';
import 'package:deoreonem_desktop/providers/items_provider.dart';
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

  Widget buildWidget(List<ItemModel> items) {
    return ProviderScope(
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
          notifier.state = AsyncValue.data(items);
          return notifier;
        }),
      ],
      child: const MaterialApp(home: ClassificationScreen()),
    );
  }

  testWidgets('ClassificationScreen shows item card and 7 category buttons',
      (tester) async {
    final items = [
      ItemModel(
        itemId: 'item-1',
        sessionId: 'session-1',
        content: 'API 설계 마저 하기',
        category: null,
        isFirstAction: false,
        sortOrder: 1,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      ),
      ItemModel(
        itemId: 'item-2',
        sessionId: 'session-1',
        content: '리뷰 요청 답변 보내기',
        category: null,
        isFirstAction: false,
        sortOrder: 2,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      ),
    ];

    await tester.pumpWidget(buildWidget(items));

    // Progress text
    expect(find.textContaining('분류됨'), findsOneWidget);
    // Category buttons - some may require scrolling with grouped layout
    expect(find.text('지금'), findsOneWidget);
    expect(find.text('내일'), findsOneWidget);
    expect(find.text('이번 주'), findsOneWidget);
    expect(find.text('대기 중'), findsOneWidget);

    // Scroll down to reveal remaining buttons
    await tester.scrollUntilVisible(
      find.text('바로 흘려보내기'),
      50.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();

    expect(find.text('메모'), findsOneWidget);
    expect(find.text('걱정만'), findsOneWidget);
    expect(find.text('바로 흘려보내기'), findsOneWidget);
    expect(find.text('서랍에 넣지 않고 지금은 흘려보냅니다.'), findsOneWidget);
    // Item card with content
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('ClassificationScreen does not crash with empty items list',
      (tester) async {
    await tester.pumpWidget(buildWidget([]));

    // Should show empty state message, not crash
    expect(find.text('분류할 항목이 없습니다.'), findsOneWidget);
    expect(find.text('돌아가기'), findsOneWidget);
  });

  testWidgets('ClassificationScreen shows worry soft-fade description and helper copy',
      (tester) async {
    final items = [
      ItemModel(
        itemId: 'item-1',
        sessionId: 'session-1',
        content: '테스트 항목',
        category: null,
        isFirstAction: false,
        sortOrder: 1,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      ),
    ];

    await tester.pumpWidget(buildWidget(items));

    // Scroll to find worry button description
    await tester.scrollUntilVisible(
      find.text('3일 뒤 조용히 사라질 걱정'),
      50.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();

    expect(find.text('3일 뒤 조용히 사라질 걱정'), findsOneWidget);

    // Minimal helper copy
    expect(find.textContaining('걱정은 맡겨두면 3일 뒤 조용히 사라집니다.'), findsOneWidget);
  });
}
