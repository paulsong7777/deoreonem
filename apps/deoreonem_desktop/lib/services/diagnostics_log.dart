import 'dart:io';
import 'runtime_paths.dart';

/// Appends a timestamped entry to launch_diagnostics.log.
/// Safe to call from anywhere — failures are silently ignored.
/// Uses async write to avoid blocking the UI thread.
void logDiagnostic(String message) {
  try {
    final dir = getRuntimeDirectoryOrNull();
    if (dir == null) return;
    final file = File('$dir\\launch_diagnostics.log');
    final timestamp = DateTime.now().toIso8601String();
    // Use async write to avoid blocking UI thread
    file.writeAsString(
      '[$timestamp] $message\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {}
}
