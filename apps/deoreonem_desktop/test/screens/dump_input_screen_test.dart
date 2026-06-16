import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('DumpInputScreen shows title and native input button', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.textContaining('하나씩 덜어내세요'), findsOneWidget);
    expect(find.text('생각 적기'), findsOneWidget);
    expect(find.text('분류하기'), findsOneWidget);
  });

  testWidgets('분류하기 is disabled when no pending thoughts', (tester) async {
    await tester.pumpWidget(buildWidget());
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '분류하기'));
    expect(button.onPressed, isNull);
  });

  testWidgets('Empty state shows guidance text', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.textContaining('생각 적기'), findsWidgets);
  });
}
