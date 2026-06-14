import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deoreonem_desktop/screens/dump_input_screen.dart';
import 'package:deoreonem_desktop/providers/session_provider.dart';
import 'package:deoreonem_desktop/providers/items_provider.dart';
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
      ],
      child: const MaterialApp(home: DumpInputScreen()),
    );
  }

  testWidgets('DumpInputScreen has title, multiline input, and always-enabled button',
      (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('오늘 남은 것들'), findsOneWidget);
    expect(find.textContaining('줄마다 적어보세요'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    // Button is always enabled (validates on click, not on text change)
    // This avoids Korean IME crash from controller listeners
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Multiline text enables classify button without API call',
      (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.enterText(find.byType(TextField), '항목 하나\n항목 둘\n항목 셋');
    await tester.pump();

    // Button should be enabled
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
    // API should NOT have been called yet
    verifyNever(() => mockApi.addItem(any(), any()));
  });

  testWidgets('Blank lines are ignored when parsing input', (tester) async {
    final item1 = ItemModel(
      itemId: 'item-1', sessionId: 'session-1', content: '항목 하나',
      category: null, isFirstAction: false, sortOrder: 1,
      createdAt: DateTime.utc(2026, 6, 9), updatedAt: DateTime.utc(2026, 6, 9),
    );
    final item2 = ItemModel(
      itemId: 'item-2', sessionId: 'session-1', content: '항목 둘',
      category: null, isFirstAction: false, sortOrder: 2,
      createdAt: DateTime.utc(2026, 6, 9), updatedAt: DateTime.utc(2026, 6, 9),
    );

    when(() => mockApi.addItem('session-1', '항목 하나'))
        .thenAnswer((_) async => item1);
    when(() => mockApi.addItem('session-1', '항목 둘'))
        .thenAnswer((_) async => item2);

    await tester.pumpWidget(buildWidget());

    // Input with blank lines
    await tester.enterText(find.byType(TextField), '항목 하나\n\n  \n항목 둘\n');
    await tester.pump();

    // Tap classify button
    await tester.tap(find.text('분류하기'));
    await tester.pumpAndSettle();

    // Only non-empty lines should be saved
    verify(() => mockApi.addItem('session-1', '항목 하나')).called(1);
    verify(() => mockApi.addItem('session-1', '항목 둘')).called(1);
    verifyNoMoreInteractions(mockApi);
  });

  testWidgets('Save failure keeps text input accessible',
      (tester) async {
    when(() => mockApi.addItem('session-1', '실패할 항목'))
        .thenThrow(Exception('네트워크 오류'));

    await tester.pumpWidget(buildWidget());

    await tester.enterText(find.byType(TextField), '실패할 항목');
    await tester.pump();

    await tester.tap(find.text('분류하기'));
    await tester.pumpAndSettle();

    // Should still be on DumpInputScreen (not navigated away)
    expect(find.text('오늘 남은 것들'), findsOneWidget);
    // Error message should be shown
    expect(find.textContaining('실패'), findsWidgets);
  });
}
