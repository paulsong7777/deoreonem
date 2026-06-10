import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/decompression_api_service.dart';

final apiServiceProvider = Provider<DecompressionApiService>((ref) {
  return DecompressionApiService();
});
