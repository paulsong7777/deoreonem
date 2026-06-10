import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deoreonem_desktop/api/decompression_api_service.dart';
import 'package:deoreonem_desktop/models/session_model.dart';
import 'package:deoreonem_desktop/providers/session_provider.dart';

class MockApiService extends Mock implements DecompressionApiService {}

void main() {
  late MockApiService mockApi;
  late SessionNotifier notifier;

  setUp(() {
    mockApi = MockApiService();
    notifier = SessionNotifier(mockApi);
  });

  group('SessionNotifier', () {
    test('initial state is AsyncData(null)', () {
      final state = notifier.state;
      expect(state, isA<AsyncData<SessionModel?>>());
      expect(state.value, isNull);
    });

    test('createSession updates state with session on success', () async {
      final session = SessionModel(
        sessionId: 'session-1',
        status: 'IN_PROGRESS',
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      );
      when(() => mockApi.createSession()).thenAnswer((_) async => session);

      await notifier.createSession();

      expect(notifier.state, isA<AsyncData<SessionModel?>>());
      expect(notifier.state.value, isNotNull);
      expect(notifier.state.value!.sessionId, 'session-1');
    });

    test('createSession sets error state on failure', () async {
      when(() => mockApi.createSession()).thenThrow(Exception('network error'));

      await notifier.createSession();

      expect(notifier.state, isA<AsyncError<SessionModel?>>());
    });

    test('reset clears state to null', () async {
      final session = SessionModel(
        sessionId: 'session-1',
        status: 'IN_PROGRESS',
        createdAt: DateTime.utc(2026, 6, 9),
        updatedAt: DateTime.utc(2026, 6, 9),
      );
      when(() => mockApi.createSession()).thenAnswer((_) async => session);
      await notifier.createSession();

      notifier.reset();

      expect(notifier.state, isA<AsyncData<SessionModel?>>());
      expect(notifier.state.value, isNull);
    });
  });
}
