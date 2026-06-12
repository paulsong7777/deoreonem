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

  testWidgets('ReviewScreen shows title and items with entrusted copy',
      (tester) async {
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
        isFirstAction: true,
        sortOrder: 1,
        createdAt: DateTime.utc(2026, 6, 10),
        updatedAt: DateTime.utc(2026, 6, 10),
      ),
      ItemModel(
        itemId: 'item-2',
        sessionId: 'session-1',
        content: '이메일 확인',
        category: 'NOW',
        isFirstAction: false,
        sortOrder: 2,
        createdAt: DateTime.utc(2026, 6, 10),
        updatedAt: DateTime.utc(2026, 6, 10),
      ),
      ItemModel(
        itemId: 'item-3',
        sessionId: 'session-1',
        content: '버린 것',
        category: 'DROP',
        isFirstAction: false,
        sortOrder: 3,
        createdAt: DateTime.utc(2026, 6, 10),
        updatedAt: DateTime.utc(2026, 6, 10),
      ),
      ItemModel(
        itemId: 'item-4',
        sessionId: 'session-1',
        content: '기다리는 중',
        category: 'WAITING',
        isFirstAction: false,
        sortOrder: 4,
        createdAt: DateTime.utc(2026, 6, 10),
        updatedAt: DateTime.utc(2026, 6, 10),
      ),
    ];

    when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(mockApi)),
          itemsProvider.overrideWith((ref) => ItemsNotifier(mockApi)),
          summaryProvider.overrideWith((ref) => SummaryNotifier(mockApi)),
          apiServiceProvider.overrideWithValue(mockApi),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: ReviewScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // New title
    expect(find.text('맡겨둔 것들이 있습니다'), findsOneWidget);
    // Subtitle copy
    expect(find.text('지난번 덜어냄에서 이런 생각들을 잠시 맡겨두고 갔어요.'), findsOneWidget);
    expect(find.text('지금 다시 볼 것만 확인하고, 나머지는 그대로 두어도 됩니다.'), findsOneWidget);
    // Visible items (TOMORROW + WAITING)
    expect(find.text('보고서 작성하기'), findsOneWidget);
    expect(find.text('기다리는 중'), findsOneWidget);
    // Filtered out (NOW + DROP)
    expect(find.text('이메일 확인'), findsNothing);
    expect(find.text('버린 것'), findsNothing);
    // Bottom actions
    expect(find.text('새로 비우기'), findsOneWidget);
    expect(find.text('그대로 닫기'), findsOneWidget);
  });

  testWidgets('이제 괜찮아요 button removes item from list', (tester) async {
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
        content: '기다리는 중',
        category: 'WAITING',
        isFirstAction: false,
        sortOrder: 2,
        createdAt: DateTime.utc(2026, 6, 10),
        updatedAt: DateTime.utc(2026, 6, 10),
      ),
    ];

    when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);
    when(() => mockApi.updateCategory('session-1', 'item-1', 'DROP'))
        .thenAnswer((_) async => items[0].copyWith(category: 'DROP'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(mockApi)),
          itemsProvider.overrideWith((ref) => ItemsNotifier(mockApi)),
          summaryProvider.overrideWith((ref) => SummaryNotifier(mockApi)),
          apiServiceProvider.overrideWithValue(mockApi),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: ReviewScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Both items visible
    expect(find.text('보고서 작성하기'), findsOneWidget);
    expect(find.text('기다리는 중'), findsOneWidget);

    // Tap 이제 괜찮아요 on first item
    final letGoButtons = find.text('이제 괜찮아요');
    expect(letGoButtons, findsNWidgets(2));
    await tester.tap(letGoButtons.first);
    await tester.pumpAndSettle();

    // First item should be removed
    expect(find.text('보고서 작성하기'), findsNothing);
    // Second item still there
    expect(find.text('기다리는 중'), findsOneWidget);
    // API was called with DROP
    verify(() => mockApi.updateCategory('session-1', 'item-1', 'DROP'))
        .called(1);
  });

  testWidgets('firstAction star is NOT shown in review items', (tester) async {
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
        isFirstAction: true,
        sortOrder: 1,
        createdAt: DateTime.utc(2026, 6, 10),
        updatedAt: DateTime.utc(2026, 6, 10),
      ),
    ];

    when(() => mockApi.getReview('session-1')).thenAnswer((_) async => items);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(mockApi)),
          itemsProvider.overrideWith((ref) => ItemsNotifier(mockApi)),
          summaryProvider.overrideWith((ref) => SummaryNotifier(mockApi)),
          apiServiceProvider.overrideWithValue(mockApi),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: ReviewScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Item is visible
    expect(find.text('보고서 작성하기'), findsOneWidget);
    // But no star icon
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('ReviewScreen shows empty state when no items', (tester) async {
    SharedPreferences.setMockInitialValues({
      'recent_completed_session_ids': ['session-1'],
    });
    final prefs = await SharedPreferences.getInstance();

    when(() => mockApi.getReview('session-1'))
        .thenAnswer((_) async => <ItemModel>[]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(mockApi)),
          itemsProvider.overrideWith((ref) => ItemsNotifier(mockApi)),
          summaryProvider.overrideWith((ref) => SummaryNotifier(mockApi)),
          apiServiceProvider.overrideWithValue(mockApi),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: ReviewScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('리뷰를 불러오는데 실패했어요.'), findsOneWidget);
    expect(find.text('새로 비우기'), findsOneWidget);
  });

  testWidgets('ReviewScreen shows error when no saved session',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(mockApi)),
          itemsProvider.overrideWith((ref) => ItemsNotifier(mockApi)),
          summaryProvider.overrideWith((ref) => SummaryNotifier(mockApi)),
          apiServiceProvider.overrideWithValue(mockApi),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: ReviewScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('저장된 세션이 없습니다.'), findsOneWidget);
    expect(find.text('새로 비우기'), findsOneWidget);
  });
}
