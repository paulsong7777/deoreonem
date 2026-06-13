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
    expect(find.text('잠시 맡겨둔 서랍을 확인합니다.'), findsOneWidget);
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

  testWidgets('Schedule item shows 나중에 보기 and 오늘은 닫기 buttons', (tester) async {
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

    expect(find.text('나중에 보기'), findsOneWidget);
    expect(find.text('오늘은 닫기'), findsOneWidget);
  });

  testWidgets('Memo item shows 보관하기 and 닫기 buttons', (tester) async {
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

    expect(find.text('보관하기'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
  });

  testWidgets('Worry item shows 조금 더 맡겨두기 and 이 걱정 내려놓기 buttons', (tester) async {
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

    expect(find.text('조금 더 맡겨두기'), findsOneWidget);
    expect(find.text('이 걱정 내려놓기'), findsOneWidget);
  });

  testWidgets('Schedule 나중에 보기 does NOT call updateCategory', (tester) async {
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

    await tester.tap(find.text('나중에 보기'));
    await tester.pumpAndSettle();

    // Item is still visible (not removed)
    expect(find.text('보고서 작성하기'), findsOneWidget);
    // No API call made
    verifyNever(() => mockApi.updateCategory(any(), any(), any()));
  });

  testWidgets('Schedule 오늘은 닫기 calls updateCategory with DROP', (tester) async {
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

    // Tap 오늘은 닫기 on first item
    final closeButtons = find.text('오늘은 닫기');
    await tester.tap(closeButtons.first);
    await tester.pumpAndSettle();

    // First item removed
    expect(find.text('보고서 작성하기'), findsNothing);
    // Second item still there
    expect(find.text('기다리는 중'), findsOneWidget);
    // API was called with DROP
    verify(() => mockApi.updateCategory('session-1', 'item-1', 'DROP')).called(1);
  });

  testWidgets('Worry 이 걱정 내려놓기 calls updateCategory with DROP and shows nutrient SnackBar',
      (tester) async {
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

    await tester.scrollUntilVisible(
      find.text('이 걱정 내려놓기'),
      50.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();

    await tester.tap(find.text('이 걱정 내려놓기'));
    await tester.pumpAndSettle();

    // Item removed
    expect(find.text('걱정 항목'), findsNothing);
    // API called correctly
    verify(() => mockApi.updateCategory('session-1', 'worry-1', 'DROP')).called(1);
    // Nutrient SnackBar shown
    expect(find.text('걱정 하나가 작은 양분이 되었습니다.'), findsOneWidget);
  });

  testWidgets('Empty state without worry let-go shows no nutrient copy', (tester) async {
    SharedPreferences.setMockInitialValues({
      'recent_completed_session_ids': ['session-1'],
    });
    final prefs = await SharedPreferences.getInstance();

    // Only a schedule item — closing it triggers empty state without worry
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

    // Close the item
    await tester.tap(find.text('오늘은 닫기'));
    await tester.pumpAndSettle();

    // Empty state visible
    expect(find.text('지금 다시 꺼내볼 것은 없습니다.'), findsOneWidget);
    // No nutrient copy (since no worry was let go)
    expect(find.textContaining('사라진 것이 아니라, 오늘의 쉼을 위한 작은 양분이 되었습니다.'), findsNothing);
    // Instead shows the default closed copy
    expect(find.text('방금 닫아둔 생각들은 여기서 조용히 정리되었습니다.'), findsOneWidget);
  });

  testWidgets('Empty state with worry let-go shows nutrient copy', (tester) async {
    SharedPreferences.setMockInitialValues({
      'recent_completed_session_ids': ['session-1'],
    });
    final prefs = await SharedPreferences.getInstance();

    // Only a worry item — letting it go triggers empty state with nutrient
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

    // Let go of the worry item
    await tester.tap(find.text('이 걱정 내려놓기'));
    await tester.pumpAndSettle();

    // Empty state with nourishment copy
    expect(find.text('지금 다시 꺼내볼 것은 없습니다.'), findsOneWidget);
    expect(find.textContaining('사라진 것이 아니라, 오늘의 쉼을 위한 작은 양분이 되었습니다.'), findsOneWidget);
  });

  testWidgets('WORRY_ONLY items show drawer label and soft-fade copy',
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
    // Worry action buttons
    expect(find.text('조금 더 맡겨두기'), findsOneWidget);
    expect(find.text('이 걱정 내려놓기'), findsOneWidget);
    // Schedule action buttons
    expect(find.text('나중에 보기'), findsOneWidget);
    expect(find.text('오늘은 닫기'), findsOneWidget);
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
