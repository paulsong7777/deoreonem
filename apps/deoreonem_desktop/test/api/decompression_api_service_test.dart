import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:deoreonem_desktop/api/decompression_api_service.dart';
import 'package:deoreonem_desktop/api/api_exception.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late DecompressionApiService api;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
    dioAdapter = DioAdapter(dio: dio);
    api = DecompressionApiService(dio: dio);
  });

  group('DecompressionApiService', () {
    test('createSession returns SessionModel on success', () async {
      dioAdapter.onPost(
        '/decompression-sessions',
        (server) => server.reply(201, {
          'success': true,
          'data': {
            'sessionId': 'session-1',
            'status': 'IN_PROGRESS',
            'firstActionItemId': null,
            'createdAt': '2026-06-09T18:30:00Z',
            'updatedAt': '2026-06-09T18:30:00Z',
          },
        }),
      );

      final session = await api.createSession();

      expect(session.sessionId, 'session-1');
      expect(session.status, 'IN_PROGRESS');
    });

    test('addItem returns ItemModel on success', () async {
      dioAdapter.onPost(
        '/decompression-sessions/session-1/items',
        (server) => server.reply(201, {
          'success': true,
          'data': {
            'itemId': 'item-1',
            'sessionId': 'session-1',
            'content': '테스트 항목',
            'category': null,
            'isFirstAction': false,
            'sortOrder': 1,
            'createdAt': '2026-06-09T18:31:00Z',
            'updatedAt': '2026-06-09T18:31:00Z',
          },
        }),
        data: {'content': '테스트 항목'},
      );

      final item = await api.addItem('session-1', '테스트 항목');

      expect(item.itemId, 'item-1');
      expect(item.content, '테스트 항목');
      expect(item.category, isNull);
    });

    test('updateCategory returns updated ItemModel', () async {
      dioAdapter.onPatch(
        '/decompression-items/item-1/category',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'itemId': 'item-1',
            'sessionId': 'session-1',
            'content': '테스트 항목',
            'category': 'NOW',
            'isFirstAction': false,
            'sortOrder': 1,
            'createdAt': '2026-06-09T18:31:00Z',
            'updatedAt': '2026-06-09T18:32:00Z',
          },
        }),
        data: {'category': 'NOW'},
      );

      final item = await api.updateCategory('session-1', 'item-1', 'NOW');

      expect(item.category, 'NOW');
    });

    test('setFirstAction completes without error', () async {
      dioAdapter.onPatch(
        '/decompression-sessions/session-1/first-action',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'sessionId': 'session-1',
            'firstActionItemId': 'item-1',
          },
        }),
        data: {'itemId': 'item-1'},
      );

      await expectLater(
        api.setFirstAction('session-1', 'item-1'),
        completes,
      );
    });

    test('completeSession completes without error', () async {
      dioAdapter.onPost(
        '/decompression-sessions/session-1/complete',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'sessionId': 'session-1',
            'status': 'COMPLETED',
            'completedAt': '2026-06-09T18:45:00Z',
          },
        }),
      );

      await expectLater(
        api.completeSession('session-1'),
        completes,
      );
    });

    test('getSummary returns SummaryModel', () async {
      dioAdapter.onGet(
        '/decompression-sessions/session-1/summary',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'sessionId': 'session-1',
            'status': 'IN_PROGRESS',
            'totalItems': 2,
            'firstActionItem': {
              'itemId': 'item-1',
              'sessionId': 'session-1',
              'content': '테스트',
              'category': 'NOW',
              'isFirstAction': true,
              'sortOrder': 1,
              'createdAt': '2026-06-09T18:31:00Z',
              'updatedAt': '2026-06-09T18:31:00Z',
            },
            'itemsByCategory': {
              'NOW': [
                {
                  'itemId': 'item-1',
                  'sessionId': 'session-1',
                  'content': '테스트',
                  'category': 'NOW',
                  'isFirstAction': true,
                  'sortOrder': 1,
                  'createdAt': '2026-06-09T18:31:00Z',
                  'updatedAt': '2026-06-09T18:31:00Z',
                },
              ],
              'TOMORROW': [],
              'THIS_WEEK': [],
              'WAITING': [],
              'MEMO': [],
              'WORRY_ONLY': [],
              'DROP': [],
            },
          },
        }),
      );

      final summary = await api.getSummary('session-1');

      expect(summary.totalItems, 2);
      expect(summary.firstActionItem, isNotNull);
      expect(summary.firstActionItem!.content, '테스트');
    });

    test('throws ApiException on server error with error body', () async {
      dioAdapter.onPost(
        '/decompression-sessions',
        (server) => server.reply(404, {
          'success': false,
          'error': {
            'code': 'SESSION_NOT_FOUND',
            'message': 'Session not found.',
          },
        }),
      );

      expect(
        () => api.createSession(),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'SESSION_NOT_FOUND')
            .having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });
}
