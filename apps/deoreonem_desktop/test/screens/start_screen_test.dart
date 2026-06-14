import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deoreonem_desktop/screens/start_screen.dart';
import 'package:deoreonem_desktop/providers/session_provider.dart';
import 'package:deoreonem_desktop/providers/items_provider.dart';
import 'package:deoreonem_desktop/providers/summary_provider.dart';
import 'package:deoreonem_desktop/providers/local_storage_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deoreonem_desktop/api/decompression_api_service.dart';

class MockApiService extends Mock implements DecompressionApiService {}

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
  });

  testWidgets('StartScreen displays app name, subtitle, and start button',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(mockApi)),
          itemsProvider.overrideWith((ref) => ItemsNotifier(mockApi)),
          summaryProvider.overrideWith((ref) => SummaryNotifier(mockApi)),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: StartScreen()),
      ),
    );

    expect(find.text('덜어냄'), findsOneWidget);
    expect(find.text('오늘 머릿속에 남아있는 것들을 꺼내 보세요.'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.text('v0.4.0-alpha'), findsOneWidget);
  });

  testWidgets('review button NOT shown when reviewable count is 0',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'reviewable_entrusted_count': 0,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(mockApi)),
          itemsProvider.overrideWith((ref) => ItemsNotifier(mockApi)),
          summaryProvider.overrideWith((ref) => SummaryNotifier(mockApi)),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: StartScreen()),
      ),
    );

    expect(find.text('맡겨둔 것 확인하기'), findsNothing);
  });

  testWidgets('review button shown when reviewable count > 0',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'reviewable_entrusted_count': 3,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(mockApi)),
          itemsProvider.overrideWith((ref) => ItemsNotifier(mockApi)),
          summaryProvider.overrideWith((ref) => SummaryNotifier(mockApi)),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: StartScreen()),
      ),
    );

    expect(find.text('맡겨둔 것 확인하기'), findsOneWidget);
  });
}
