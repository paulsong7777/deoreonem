import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deoreonem_desktop/screens/entrusted_summary_screen.dart';
import 'package:deoreonem_desktop/providers/session_provider.dart';
import 'package:deoreonem_desktop/providers/summary_provider.dart';
import 'package:deoreonem_desktop/providers/api_provider.dart';
import 'package:deoreonem_desktop/models/session_model.dart';
import 'package:deoreonem_desktop/models/item_model.dart';
import 'package:deoreonem_desktop/models/summary_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deoreonem_desktop/api/decompression_api_service.dart';

class MockApiService extends Mock implements DecompressionApiService {}

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
  });

  testWidgets(
      'EntrustedSummaryScreen shows title, total count, and complete button',
      (tester) async {
    final summary = SummaryModel(
      sessionId: 'session-1',
      status: 'IN_PROGRESS',
      totalItems: 3,
      firstActionItem: ItemModel(
        itemId: 'item-1',
        sessionId: 'session-1',
        content: 'API 설계 마저 하기',
        category: 'NOW',
        isFirstAction: true,
        sortOrder: 1,
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      ),
      itemsByCategory: {
        'NOW': [
          ItemModel(
            itemId: 'item-1',
            sessionId: 'session-1',
            content: 'API 설계 마저 하기',
            category: 'NOW',
            isFirstAction: true,
            sortOrder: 1,
            createdAt: DateTime.utc(2026, 6, 9),
            updatedAt: DateTime.utc(2026, 6, 9),
          ),
        ],
        'TOMORROW': [],
        'THIS_WEEK': [],
        'WAITING': [],
        'MEMO': [],
        'WORRY_ONLY': [],
        'DROP': [],
      },
    );

    when(() => mockApi.getSummary('session-1'))
        .thenAnswer((_) async => summary);

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
          summaryProvider.overrideWith((ref) {
            final notifier = SummaryNotifier(mockApi);
            notifier.state = AsyncValue.data(summary);
            return notifier;
          }),
          apiServiceProvider.overrideWithValue(mockApi),
        ],
        child: const MaterialApp(home: EntrustedSummaryScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('오늘의 덜어냄'), findsOneWidget);
    expect(find.textContaining('맡겼습니다'), findsOneWidget);
    expect(find.text('완료하기'), findsOneWidget);
  });
}
