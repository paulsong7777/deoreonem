import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/decompression_api_service.dart';
import '../models/session_model.dart';
import 'api_provider.dart';

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<SessionModel?>>((ref) {
  return SessionNotifier(ref.read(apiServiceProvider));
});

class SessionNotifier extends StateNotifier<AsyncValue<SessionModel?>> {
  final DecompressionApiService _api;
  SessionNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> createSession() async {
    state = const AsyncValue.loading();
    try {
      final session = await _api.createSession();
      assert(() { debugPrint('[SessionNotifier] createSession success: ${session.sessionId}'); return true; }());
      state = AsyncValue.data(session);
    } catch (e, st) {
      assert(() { debugPrint('[SessionNotifier] createSession FAILED: $e'); return true; }());
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}
