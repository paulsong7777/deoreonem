import 'dart:io';

/// Returns the stable runtime data directory for DeoReoNem.
/// Windows: %APPDATA%\ScopeWorks\DeoReoNem
/// Fallback: %LOCALAPPDATA%\ScopeWorks\DeoReoNem
/// Creates the directory if it doesn't exist.
String getRuntimeDirectory() {
  final appData = Platform.environment['APPDATA'];
  final localAppData = Platform.environment['LOCALAPPDATA'];
  final base = appData ?? localAppData ?? Platform.environment['TEMP'] ?? '.';
  final dir = Directory('$base\\ScopeWorks\\DeoReoNem');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir.path;
}

/// Returns null in test environments (dart_test, flutter_tester).
/// Safe to call from production code — returns the runtime directory path
/// or null if running under test harness.
String? getRuntimeDirectoryOrNull() {
  try {
    final exePath = Platform.resolvedExecutable;
    if (exePath.contains('dart_test') || exePath.contains('flutter_tester')) {
      return null;
    }
    return getRuntimeDirectory();
  } catch (_) {
    return null;
  }
}
