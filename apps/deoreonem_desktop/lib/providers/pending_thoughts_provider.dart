import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds pending thoughts that haven't been submitted to the API yet.
/// Survives navigation between screens.
final pendingThoughtsProvider = StateNotifierProvider<PendingThoughtsNotifier, List<String>>((ref) {
  return PendingThoughtsNotifier();
});

class PendingThoughtsNotifier extends StateNotifier<List<String>> {
  PendingThoughtsNotifier() : super([]);

  void add(String thought) {
    state = [...state, thought];
  }

  void removeAt(int index) {
    final list = [...state];
    list.removeAt(index);
    state = list;
  }

  void clear() {
    state = [];
  }
}
