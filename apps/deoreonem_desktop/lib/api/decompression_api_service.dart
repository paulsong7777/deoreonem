import 'package:dio/dio.dart';
import 'api_exception.dart';
import '../models/session_model.dart';
import '../models/item_model.dart';
import '../models/summary_model.dart';

class DecompressionApiService {
  final Dio _dio;

  DecompressionApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'http://localhost:8080/api/v1',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              contentType: 'application/json',
            ));

  /// For testing injection
  Dio get dio => _dio;

  Future<SessionModel> createSession() async {
    final response = await _request(() => _dio.post('/decompression-sessions'));
    return SessionModel.fromJson(response['data']);
  }

  Future<ItemModel> addItem(String sessionId, String content) async {
    final response = await _request(() => _dio.post(
          '/decompression-sessions/$sessionId/items',
          data: {'content': content},
        ));
    return ItemModel.fromJson(response['data']);
  }

  Future<ItemModel> updateCategory(
      String sessionId, String itemId, String category) async {
    final response = await _request(() => _dio.patch(
          '/decompression-items/$itemId/category',
          data: {'category': category},
        ));
    return ItemModel.fromJson(response['data']);
  }

  Future<void> setFirstAction(String sessionId, String itemId) async {
    await _request(() => _dio.patch(
          '/decompression-sessions/$sessionId/first-action',
          data: {'itemId': itemId},
        ));
  }

  Future<void> completeSession(String sessionId) async {
    await _request(
        () => _dio.post('/decompression-sessions/$sessionId/complete'));
  }

  Future<SummaryModel> getSummary(String sessionId) async {
    final response = await _request(
        () => _dio.get('/decompression-sessions/$sessionId/summary'));
    return SummaryModel.fromJson(response['data']);
  }

  Future<Map<String, dynamic>> _request(
      Future<Response> Function() call) async {
    try {
      final response = await call();
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['error'] != null) {
          throw ApiException(
            code: data['error']['code'] ?? 'UNKNOWN',
            message: data['error']['message'] ?? '알 수 없는 오류가 발생했습니다.',
            statusCode: e.response!.statusCode ?? 500,
          );
        }
      }
      throw ApiException(
        code: 'NETWORK_ERROR',
        message: '연결에 문제가 생겼어요. 다시 시도해 주세요.',
        statusCode: 0,
      );
    }
  }
}
