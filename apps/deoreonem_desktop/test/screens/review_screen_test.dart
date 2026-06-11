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

  testWidgets('ReviewScreen shows grouped items from API', (tester) async {
    SharedPreferences.setMockInitialValues({
      'last_completed_session_id': 'session-1',
      'last_completed_at': '2026-06-10T18:30:00.000Z',
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

    expect(find.text('어제 맡긴 것들'), findsOneWidget);
    expect(find.text('총 2개의 항목'), findsOneWidget);
    expect(find.text('보고서 작성하기'), findsOneWidget);
    expect(find.text('이메일 확인'), findsOneWidget);
    expect(find.text('내일'), findsOneWidget);
    expect(find.text('지금'), findsOneWidget);
    expect(find.text('오늘 새로 덜어내기'), findsOneWidget);
  });

  testWidgets('ReviewScreen shows empty state when no items', (tester) async {
    SharedPreferences.setMockInitialValues({
      'last_completed_session_id': 'session-1',
      'last_completed_at': '2026-06-10T18:30:00.000Z',
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

    expect(find.text('리뷰할 항목이 없습니다.'), findsOneWidget);
    expect(find.text('오늘 새로 덜어내기'), findsOneWidget);
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
    expect(find.text('오늘 새로 덜어내기'), findsOneWidget);
  });
}
