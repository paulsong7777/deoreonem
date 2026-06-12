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

  testWidgets('DumpInputScreen has title, text field, and disabled next button',
      (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('오늘 남은 것들'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    // Next button should be disabled when list is empty
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'Typing and pressing Enter adds to visible list without API call',
      (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.enterText(find.byType(TextField), '테스트 항목');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Item should be visible in the list
    expect(find.text('테스트 항목'), findsOneWidget);
    // Button should be enabled
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
    // API should NOT have been called
    verifyNever(() => mockApi.addItem(any(), any()));
  });

  testWidgets('Navigating to classify saves all drafts via API',
      (tester) async {
    final testItem = ItemModel(
      itemId: 'item-1',
      sessionId: 'session-1',
      content: '항목 하나',
      category: null,
      isFirstAction: false,
      sortOrder: 1,
      createdAt: DateTime.utc(2026, 6, 9),
      updatedAt: DateTime.utc(2026, 6, 9),
    );
    final testItem2 = ItemModel(
      itemId: 'item-2',
      sessionId: 'session-1',
      content: '항목 둘',
      category: null,
      isFirstAction: false,
      sortOrder: 2,
      createdAt: DateTime.utc(2026, 6, 9),
      updatedAt: DateTime.utc(2026, 6, 9),
    );

    when(() => mockApi.addItem('session-1', '항목 하나'))
        .thenAnswer((_) async => testItem);
    when(() => mockApi.addItem('session-1', '항목 둘'))
        .thenAnswer((_) async => testItem2);

    await tester.pumpWidget(buildWidget());

    // Add two drafts
    await tester.enterText(find.byType(TextField), '항목 하나');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    await tester.enterText(find.byType(TextField), '항목 둘');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // Tap the classify button
    await tester.tap(find.text('분류하기'));
    await tester.pumpAndSettle();

    // Both items should be saved via API
    verify(() => mockApi.addItem('session-1', '항목 하나')).called(1);
    verify(() => mockApi.addItem('session-1', '항목 둘')).called(1);
  });

  testWidgets('TextField is never disabled during operation', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.enterText(find.byType(TextField), '항목');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // TextField should still be enabled
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isNot(false));
  });
}
