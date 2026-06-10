import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/decompression_api_service.dart';
import '../models/summary_model.dart';
import 'api_provider.dart';

final summaryProvider =
    StateNotifierProvider<SummaryNotifier, AsyncValue<SummaryModel?>>((ref) {
  return SummaryNotifier(ref.read(apiServiceProvider));
});

class SummaryNotifier extends StateNotifier<AsyncValue<SummaryModel?>> {
  final DecompressionApiService _api;
  SummaryNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> loadSummary(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final summary = await _api.getSummary(sessionId);
      state = AsyncValue.data(summary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}
