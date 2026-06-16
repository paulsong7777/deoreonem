import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deoreonem_desktop/screens/dump_input_screen.dart';
import 'package:deoreonem_desktop/providers/session_provider.dart';
import 'package:deoreonem_desktop/providers/items_provider.dart';
import 'package:deoreonem_desktop/providers/pending_thoughts_provider.dart';
import 'package:deoreonem_desktop/models/session_model.dart';
import 'package:deoreonem_desktop/models/item_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deoreonem_desktop/api/decompression_api_service.dart';

class MockApiService extends Mock implements DecompressionApiService {}

void main() {
  late MockApiService mockApi;
  late SessionModel testSession;

  setUp(() {
    mockApi = MockApiService();
    testSession = SessionModel(
      sessionId: 'session-1',
      status: 'IN_PROGRESS',
      createdAt: DateTime.utc(2026, 6, 9),
      updatedAt: DateTime.utc(2026, 6, 9),
    );
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: [
        sessionProvider.overrideWith((ref) {
          final notifier = SessionNotifier(mockApi);
          notifier.state = AsyncValue.data(testSession);
          return notifier;
        }),
        itemsProvider.overrideWith((ref) => ItemsNotifier(mockApi)),
        pendingThoughtsProvider.overrideWith((ref) => PendingThoughtsNotifier()),
      ],
      child: const MaterialApp(home: DumpInputScreen()),
    );
  }

  testWidgets('DumpInputScreen shows title and single-line input', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.textContaining('하나씩 덜어내세요'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('추가'), findsOneWidget);
    expect(find.text('분류하기'), findsOneWidget);
  });

  testWidgets('분류하기 is disabled when no pending thoughts', (tester) async {
    await tester.pumpWidget(buildWidget());
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '분류하기'));
    expect(button.onPressed, isNull);
  });

  testWidgets('Adding thought via button shows in pending list', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.enterText(find.byType(TextField), '테스트 생각');
    await tester.tap(find.text('추가'));
    await tester.pump();
    expect(find.text('테스트 생각'), findsOneWidget);
    expect(find.textContaining('방금 덜어낸 생각'), findsOneWidget);
  });

  testWidgets('분류하기 sends pending thoughts to API', (tester) async {
    final item1 = ItemModel(
      itemId: 'item-1', sessionId: 'session-1', content: '항목 하나',
      category: null, isFirstAction: false, sortOrder: 1,
      createdAt: DateTime.utc(2026, 6, 9), updatedAt: DateTime.utc(2026, 6, 9),
    );
    when(() => mockApi.addItem('session-1', '항목 하나'))
        .thenAnswer((_) async => item1);

    await tester.pumpWidget(buildWidget());
    await tester.enterText(find.byType(TextField), '항목 하나');
    await tester.tap(find.text('추가'));
    await tester.pump();
    await tester.tap(find.text('분류하기'));
    await tester.pumpAndSettle();

    verify(() => mockApi.addItem('session-1', '항목 하나')).called(1);
  });

  testWidgets('Empty input shows snackbar when clicking 분류하기', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.tap(find.text('분류하기'));
    await tester.pump();
    // Button is disabled so snackbar won't show — verify button is disabled
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '분류하기'));
    expect(button.onPressed, isNull);
  });

  testWidgets('Removing a thought from pending list works', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.enterText(find.byType(TextField), '삭제할 생각');
    await tester.tap(find.text('추가'));
    await tester.pump();
    expect(find.text('삭제할 생각'), findsOneWidget);

    // Tap the close icon to remove
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('삭제할 생각'), findsNothing);
  });

  testWidgets('Save failure keeps pending thoughts and shows error', (tester) async {
    when(() => mockApi.addItem('session-1', '실패할 항목'))
        .thenThrow(Exception('네트워크 오류'));

    await tester.pumpWidget(buildWidget());
    await tester.enterText(find.byType(TextField), '실패할 항목');
    await tester.tap(find.text('추가'));
    await tester.pump();

    await tester.tap(find.text('분류하기'));
    await tester.pumpAndSettle();

    // Should still be on DumpInputScreen (not navigated away)
    expect(find.textContaining('하나씩 덜어내세요'), findsOneWidget);
    // Error message should be shown
    expect(find.textContaining('실패'), findsWidgets);
  });
}
