import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deoreonem_desktop/screens/review_screen.dart';
import 'package:deoreonem_desktop/providers/session_provider.dart';
import 'package:deoreonem_desktop/providers/items_provider.dart';
import 'package:deoreonem_desktop/providers/summary_provider.dart';
import 'package:deoreonem_desktop/providers/api_provider.dart';
import 'package:deoreonem_desktop/providers/local_storage_provider.dart';
import 'package:deoreonem_desktop/models/item_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deoreonem_desktop/api/decompression_api_service.dart';

class MockApiService extends Mock implements DecompressionApiService {}

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
  });

  Widget buildTestWidget(SharedPreferences prefs) {
    return ProviderScope(
      overrides: [
        sessionProvider.overrideWith((ref) => SessionNotifier(mockApi)),
        itemsProvider.overrideWith((ref) => ItemsNotifier(mockApi)),
        summaryProvider.overrideWith((ref) => SummaryNotifier(mockApi)),
        apiServiceProvider.overrideWithValue(mockApi),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: ReviewScreen()),
    );
  }

  group('Drawer tabs', () {
    testWidgets('Drawer tabs exist (일정, 메모, 감정)', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_completed_session_ids': ['session-1'],
      });
      final prefs = await SharedPreferences.getInstance();

      final items = [
        ItemModel(
          itemId: 'item-1',
          sessionId: 'session-1',
          content: '보고서 작성하기',
          category: 'TOMORROW',
          isFirstAction: false,
          sortOrder: 1,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
        ItemModel(
          itemId: 'item-2',
          sessionId: 'session-1',
          content: '메모 항목',
          category: 'MEMO',
          isFirstAction: false,
          sortOrder: 2,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
        ItemModel(
          itemId: 'item-3',
          sessionId: 'session-1',
          content: '걱정 항목',
          category: 'WORRY_ONLY',
          isFirstAction: false,
          sortOrder: 3,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
      ];

      when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      // All three tabs present with counts
      expect(find.text('일정 1'), findsOneWidget);
      expect(find.text('메모 1'), findsOneWidget);
      expect(find.text('감정 1'), findsOneWidget);
    });

    testWidgets('Default drawer is 감정 when worry items exist', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_completed_session_ids': ['session-1'],
      });
      final prefs = await SharedPreferences.getInstance();

      final items = [
        ItemModel(
          itemId: 'item-1',
          sessionId: 'session-1',
          content: '보고서 작성하기',
          category: 'TOMORROW',
          isFirstAction: false,
          sortOrder: 1,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
        ItemModel(
          itemId: 'item-2',
          sessionId: 'session-1',
          content: '걱정 항목',
          category: 'WORRY_ONLY',
          isFirstAction: false,
          sortOrder: 2,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
      ];

      when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      // Worry item is visible (감정 is default drawer)
      expect(find.text('걱정 항목'), findsOneWidget);
      // Schedule item is NOT visible (일정 drawer not selected)
      expect(find.text('보고서 작성하기'), findsNothing);
    });
  });

  group('Schedule tab actions', () {
    testWidgets('Schedule tab shows "확인했어요"', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_completed_session_ids': ['session-1'],
      });
      final prefs = await SharedPreferences.getInstance();

      final items = [
        ItemModel(
          itemId: 'item-1',
          sessionId: 'session-1',
          content: '보고서 작성하기',
          category: 'TOMORROW',
          isFirstAction: false,
          sortOrder: 1,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
      ];

      when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      // Switch to 일정 tab
      await tester.tap(find.text('일정 1'));
      await tester.pumpAndSettle();

      expect(find.text('확인했어요'), findsOneWidget);
    });

    testWidgets('"확인했어요" calls updateCategory with DROP and removes item', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_completed_session_ids': ['session-1'],
      });
      final prefs = await SharedPreferences.getInstance();

      final items = [
        ItemModel(
          itemId: 'item-1',
          sessionId: 'session-1',
          content: '보고서 작성하기',
          category: 'TOMORROW',
          isFirstAction: false,
          sortOrder: 1,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
        ItemModel(
          itemId: 'item-2',
          sessionId: 'session-1',
          content: '걱정 항목',
          category: 'WORRY_ONLY',
          isFirstAction: false,
          sortOrder: 2,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
      ];

      when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);
      when(() => mockApi.updateCategory('session-1', 'item-1', 'DROP'))
          .thenAnswer((_) async => items[0].copyWith(category: 'DROP'));

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      // Switch to 일정 tab
      await tester.tap(find.text('일정 1'));
      await tester.pumpAndSettle();

      expect(find.text('보고서 작성하기'), findsOneWidget);

      await tester.tap(find.text('확인했어요'));
      await tester.pumpAndSettle();

      // Item removed
      expect(find.text('보고서 작성하기'), findsNothing);
      // API was called with DROP
      verify(() => mockApi.updateCategory('session-1', 'item-1', 'DROP')).called(1);
    });
  });

  group('Memo tab actions', () {
    testWidgets('Memo shows "보관하기"', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_completed_session_ids': ['session-1'],
      });
      final prefs = await SharedPreferences.getInstance();

      final items = [
        ItemModel(
          itemId: 'item-1',
          sessionId: 'session-1',
          content: '메모 항목',
          category: 'MEMO',
          isFirstAction: false,
          sortOrder: 1,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
      ];

      when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      // Switch to 메모 tab
      await tester.tap(find.text('메모 1'));
      await tester.pumpAndSettle();

      expect(find.text('보관하기'), findsOneWidget);
    });

    testWidgets('"보관하기" calls updateCategory with DROP and removes item', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_completed_session_ids': ['session-1'],
      });
      final prefs = await SharedPreferences.getInstance();

      final items = [
        ItemModel(
          itemId: 'item-1',
          sessionId: 'session-1',
          content: '메모 항목',
          category: 'MEMO',
          isFirstAction: false,
          sortOrder: 1,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
        ItemModel(
          itemId: 'item-2',
          sessionId: 'session-1',
          content: '걱정 항목',
          category: 'WORRY_ONLY',
          isFirstAction: false,
          sortOrder: 2,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
      ];

      when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);
      when(() => mockApi.updateCategory('session-1', 'item-1', 'DROP'))
          .thenAnswer((_) async => items[0].copyWith(category: 'DROP'));

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      // Switch to 메모 tab
      await tester.tap(find.text('메모 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('보관하기'));
      await tester.pumpAndSettle();

      // Item removed
      expect(find.text('메모 항목'), findsNothing);
      verify(() => mockApi.updateCategory('session-1', 'item-1', 'DROP')).called(1);
    });
  });

  group('Emotion tab actions', () {
    testWidgets('Emotion shows "이 걱정 내려놓기" and "다시 3일 맡겨두기"', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_completed_session_ids': ['session-1'],
      });
      final prefs = await SharedPreferences.getInstance();

      final items = [
        ItemModel(
          itemId: 'item-1',
          sessionId: 'session-1',
          content: '걱정 항목',
          category: 'WORRY_ONLY',
          isFirstAction: false,
          sortOrder: 1,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
      ];

      when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      expect(find.text('이 걱정 내려놓기'), findsOneWidget);
      expect(find.text('다시 3일 맡겨두기'), findsOneWidget);
    });

    testWidgets('"이 걱정 내려놓기" removes item and shows nutrient SnackBar', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_completed_session_ids': ['session-1'],
      });
      final prefs = await SharedPreferences.getInstance();

      final items = [
        ItemModel(
          itemId: 'worry-1',
          sessionId: 'session-1',
          content: '걱정 항목',
          category: 'WORRY_ONLY',
          isFirstAction: false,
          sortOrder: 1,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
        ItemModel(
          itemId: 'item-2',
          sessionId: 'session-1',
          content: '보고서 작성하기',
          category: 'TOMORROW',
          isFirstAction: false,
          sortOrder: 2,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
      ];

      when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);
      when(() => mockApi.updateCategory('session-1', 'worry-1', 'DROP'))
          .thenAnswer((_) async => items[0].copyWith(category: 'DROP'));

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      expect(find.text('걱정 항목'), findsOneWidget);

      await tester.tap(find.text('이 걱정 내려놓기'));
      await tester.pumpAndSettle();

      // Item removed
      expect(find.text('걱정 항목'), findsNothing);
      // API called correctly
      verify(() => mockApi.updateCategory('session-1', 'worry-1', 'DROP')).called(1);
      // Nutrient SnackBar shown
      expect(find.text('걱정 하나가 작은 양분이 되었습니다.'), findsOneWidget);
    });

    testWidgets('"다시 3일 맡겨두기" keeps item visible (no removal)', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_completed_session_ids': ['session-1'],
      });
      final prefs = await SharedPreferences.getInstance();

      final items = [
        ItemModel(
          itemId: 'worry-1',
          sessionId: 'session-1',
          content: '걱정 항목',
          category: 'WORRY_ONLY',
          isFirstAction: false,
          sortOrder: 1,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
      ];

      when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('다시 3일 맡겨두기'));
      await tester.pumpAndSettle();

      // Item is still visible — not removed
      expect(find.text('걱정 항목'), findsOneWidget);
      // No updateCategory call made
      verifyNever(() => mockApi.updateCategory(any(), any(), any()));
      // SnackBar shown
      expect(find.text('감정 서랍에 다시 3일 맡겨두었습니다.'), findsOneWidget);
    });
  });

  group('NOW/DROP hidden from Review', () {
    testWidgets('NOW and DROP items are filtered out', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_completed_session_ids': ['session-1'],
      });
      final prefs = await SharedPreferences.getInstance();

      final items = [
        ItemModel(
          itemId: 'item-1',
          sessionId: 'session-1',
          content: '지금 항목',
          category: 'NOW',
          isFirstAction: false,
          sortOrder: 1,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
        ItemModel(
          itemId: 'item-2',
          sessionId: 'session-1',
          content: '버린 것',
          category: 'DROP',
          isFirstAction: false,
          sortOrder: 2,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
        ItemModel(
          itemId: 'item-3',
          sessionId: 'session-1',
          content: '걱정 항목',
          category: 'WORRY_ONLY',
          isFirstAction: false,
          sortOrder: 3,
          createdAt: DateTime.utc(2026, 6, 10),
          updatedAt: DateTime.utc(2026, 6, 10),
        ),
      ];

      when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      // NOW and DROP are not visible
      expect(find.text('지금 항목'), findsNothing);
      expect(find.text('버린 것'), findsNothing);
      // Worry item is visible
      expect(find.text('걱정 항목'), findsOneWidget);
    });
  });

  group('Empty and error states', () {
    testWidgets('ReviewScreen shows empty state when no items', (tester) async {
      SharedPreferences.setMockInitialValues({
        'recent_completed_session_ids': ['session-1'],
      });
      final prefs = await SharedPreferences.getInstance();

      when(() => mockApi.getReview('session-1'))
          .thenAnswer((_) async => <ItemModel>[]);

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      expect(find.text('리뷰를 불러오는데 실패했어요.'), findsOneWidget);
      expect(find.text('새로 비우기'), findsOneWidget);
    });

    testWidgets('ReviewScreen shows error when no saved session', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestWidget(prefs));
      await tester.pumpAndSettle();

      expect(find.text('저장된 세션이 없습니다.'), findsOneWidget);
      expect(find.text('새로 비우기'), findsOneWidget);
    });
  });
}
