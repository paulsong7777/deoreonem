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
    expect(find.text('잠시 맡겨둔 서랍'), findsOneWidget);
    // Subtitle copy
    expect(find.text('일정은 일정 서랍에, 걱정은 감정 서랍에 잠시 맡겨두었습니다.'), findsOneWidget);
    expect(find.text('지금 다시 볼 것만 확인하고, 나머지는 그대로 두어도 괜찮습니다.'), findsOneWidget);
    // Visible items (TOMORROW + WAITING)
    expect(find.text('보고서 작성하기'), findsOneWidget);
    expect(find.text('기다리는 중'), findsOneWidget);
    // Filtered out (NOW + DROP)
    expect(find.text('이메일 확인'), findsNothing);
    expect(find.text('버린 것'), findsNothing);
    // Date label (맡김)
    expect(find.textContaining('맡김'), findsWidgets);
    // Stable group order: TOMORROW group label appears before WAITING group label
    final tomorrowLabel = find.text('내일 다시 볼 것');
    final waitingLabel = find.text('기다리는 것');
    expect(tomorrowLabel, findsOneWidget);
    expect(waitingLabel, findsOneWidget);
    // Bottom actions
    expect(find.text('새로 비우기'), findsOneWidget);
    expect(find.text('그대로 두기'), findsOneWidget);
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

  testWidgets('WORRY_ONLY items show drawer label, soft-fade copy, and worry let-go button',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'recent_completed_session_ids': ['session-1'],
    });
    final prefs = await SharedPreferences.getInstance();

    final items = [
      ItemModel(
        itemId: 'item-1',
        sessionId: 'session-1',
        content: '프로젝트 방향 맞는 걸까',
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

    // Drawer labels visible
    expect(find.text('감정 서랍'), findsOneWidget);
    expect(find.text('일정 서랍'), findsOneWidget);
    // Category labels
    expect(find.text('걱정만 남은 것'), findsOneWidget);
    expect(find.text('내일 다시 볼 것'), findsOneWidget);
    // Worry soft-fade copy
    expect(find.textContaining('이 걱정은 3일 뒤 조용히 사라집니다.'), findsOneWidget);
    expect(find.textContaining('지금 해결하지 않아도 괜찮아요.'), findsOneWidget);
    // Worry let-go button
    expect(find.text('이 걱정 내려놓기'), findsOneWidget);
    // Non-worry still shows normal button
    expect(find.text('이제 괜찮아요'), findsOneWidget);
  });

  testWidgets('Worry let-go calls updateCategory with DROP', (tester) async {
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
    when(() => mockApi.updateCategory('session-1', 'worry-1', 'DROP'))
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

    expect(find.text('걱정 항목'), findsOneWidget);

    await tester.tap(find.text('이 걱정 내려놓기'));
    await tester.pumpAndSettle();

    // Item removed
    expect(find.text('걱정 항목'), findsNothing);
    // API called correctly
    verify(() => mockApi.updateCategory('session-1', 'worry-1', 'DROP')).called(1);
  });

  testWidgets('Empty state shows soft-fade nourishment copy', (tester) async {
    SharedPreferences.setMockInitialValues({
      'recent_completed_session_ids': ['session-1'],
    });
    final prefs = await SharedPreferences.getInstance();

    // Return only one worry item so we can let it go and see empty state
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
    when(() => mockApi.updateCategory('session-1', 'worry-1', 'DROP'))
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

    // Let go of the only item
    await tester.tap(find.text('이 걱정 내려놓기'));
    await tester.pumpAndSettle();

    // Empty state with nourishment copy
    expect(find.text('지금 다시 꺼내볼 것은 없습니다.'), findsOneWidget);
    expect(find.textContaining('사라진 것이 아니라, 오늘의 쉼을 위한 작은 양분이 되었습니다.'), findsOneWidget);
  });
}
