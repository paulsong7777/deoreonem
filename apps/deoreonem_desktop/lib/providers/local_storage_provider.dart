import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';

/// Must be overridden at app startup with the real SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized before use');
});

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService(ref.read(sharedPreferencesProvider));
});
