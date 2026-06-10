import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deoreonem_desktop/screens/start_screen.dart';
import 'package:deoreonem_desktop/providers/session_provider.dart';
import 'package:deoreonem_desktop/providers/items_provider.dart';
import 'package:deoreonem_desktop/providers/summary_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deoreonem_desktop/api/decompression_api_service.dart';

class MockApiService extends Mock implements DecompressionApiService {}

void main() {
  testWidgets('StartScreen displays app name, subtitle, and start button',
      (tester) async {
    final mockApi = MockApiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(mockApi)),
          itemsProvider.overrideWith((ref) => ItemsNotifier(mockApi)),
          summaryProvider.overrideWith((ref) => SummaryNotifier(mockApi)),
        ],
        child: const MaterialApp(home: StartScreen()),
      ),
    );

    expect(find.text('덜어냄'), findsOneWidget);
    expect(find.text('오늘 머릿속에 남아있는 것들을 꺼내 보세요.'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.text('v0.1.0'), findsOneWidget);
  });
}
