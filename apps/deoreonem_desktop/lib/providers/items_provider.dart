import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/decompression_api_service.dart';
import '../models/item_model.dart';
import 'api_provider.dart';

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, AsyncValue<List<ItemModel>>>((ref) {
  return ItemsNotifier(ref.read(apiServiceProvider));
});

class ItemsNotifier extends StateNotifier<AsyncValue<List<ItemModel>>> {
  final DecompressionApiService _api;
  ItemsNotifier(this._api) : super(const AsyncValue.data([]));

  Future<void> addItem(String sessionId, String content) async {
    try {
      final item = await _api.addItem(sessionId, content);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([...current, item]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCategory(
      String sessionId, String itemId, String category) async {
    try {
      final updated = await _api.updateCategory(sessionId, itemId, category);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((i) => i.itemId == itemId ? updated : i).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<ItemModel> get unclassifiedItems =>
      (state.valueOrNull ?? []).where((i) => i.category == null).toList();

  List<ItemModel> get eligibleForFirstAction =>
      (state.valueOrNull ?? [])
          .where((i) => i.category == 'TOMORROW')
          .toList();

  void reset() => state = const AsyncValue.data([]);
}
