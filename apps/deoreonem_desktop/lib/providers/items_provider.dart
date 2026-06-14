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

  /// Adds an item to the session. Throws on failure so callers can handle errors.
  Future<void> addItem(String sessionId, String content) async {
    try {
      final item = await _api.addItem(sessionId, content);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([...current, item]);
    } catch (e, st) {
      // Preserve existing items on error — don't wipe the list
      final current = state.valueOrNull;
      if (current != null) {
        // Keep items but surface error to callers
        state = AsyncValue.data(current);
      }
      rethrow; // Let caller know save failed
    }
  }

  /// Updates item category. Throws on failure so callers can handle errors.
  Future<void> updateCategory(
      String sessionId, String itemId, String category) async {
    try {
      final updated = await _api.updateCategory(sessionId, itemId, category);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((i) => i.itemId == itemId ? updated : i).toList(),
      );
    } catch (e, st) {
      // Keep existing items on error — don't wipe the list
      rethrow; // Let caller know classification failed
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
