import 'dart:io';
import 'runtime_paths.dart';

/// Appends a timestamped entry to launch_diagnostics.log.
/// Safe to call from anywhere — failures are silently ignored.
void logDiagnostic(String message) {
  try {
    final dir = getRuntimeDirectoryOrNull();
    if (dir == null) return;
    final file = File('$dir\\launch_diagnostics.log');
    final timestamp = DateTime.now().toIso8601String();
    file.writeAsStringSync(
      '[$timestamp] $message\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {}
}
