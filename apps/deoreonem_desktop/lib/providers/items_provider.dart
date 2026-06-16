import 'package:flutter/foundation.dart';
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
      assert(() { debugPrint('[ItemsNotifier] addItem: sessionId=$sessionId'); return true; }());
      final item = await _api.addItem(sessionId, content);
      assert(() { debugPrint('[ItemsNotifier] addItem success: itemId=${item.itemId}'); return true; }());
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([...current, item]);
    } catch (e, st) {
      assert(() { debugPrint('[ItemsNotifier] addItem FAILED: $e'); return true; }());
      // Preserve existing items on error — don't wipe the list
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncValue.data(current);
      }
      rethrow; // Let caller know save failed
    }
  }

  /// Updates item category. Throws on failure so callers can handle errors.
  Future<void> updateCategory(
      String sessionId, String itemId, String category) async {
    try {
      assert(() { debugPrint('[ItemsNotifier] updateCategory: itemId=$itemId category=$category'); return true; }());
      final updated = await _api.updateCategory(sessionId, itemId, category);
      assert(() { debugPrint('[ItemsNotifier] updateCategory success: ${updated.category}'); return true; }());
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((i) => i.itemId == itemId ? updated : i).toList(),
      );
    } catch (e, st) {
      assert(() { debugPrint('[ItemsNotifier] updateCategory FAILED: $e'); return true; }());
      // Keep existing items on error — don't wipe the list
      rethrow; // Let caller know classification failed
    }
  }

  /// Adds multiple items concurrently. Preserves order in state.
  Future<void> addItems(String sessionId, List<String> contents) async {
    // Launch all requests concurrently
    final futures = contents.asMap().entries.map((entry) async {
      final item = await _api.addItem(sessionId, entry.value);
      return MapEntry(entry.key, item);
    }).toList();

    final results = await Future.wait(futures);
    // Sort by original index to preserve order
    results.sort((a, b) => a.key.compareTo(b.key));

    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, ...results.map((e) => e.value)]);
  }

  /// Sets state directly for optimistic UI updates.
  void setOptimistic(List<ItemModel> items) {
    state = AsyncValue.data(items);
  }

  List<ItemModel> get unclassifiedItems =>
      (state.valueOrNull ?? []).where((i) => i.category == null).toList();

  List<ItemModel> get eligibleForFirstAction =>
      (state.valueOrNull ?? [])
          .where((i) => i.category == 'TOMORROW')
          .toList();

  void reset() => state = const AsyncValue.data([]);
}
