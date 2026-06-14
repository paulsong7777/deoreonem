import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'router.dart';
import 'theme.dart';
import 'providers/local_storage_provider.dart';
import 'garden_overlay.dart';

const _keyMainAppRunning = 'main_app_running';
const _keyMainAppHeartbeat = 'main_app_heartbeat';
const _mainAppStaleThresholdSeconds = 20;

/// File-based main app heartbeat for reliable cross-process detection.
/// SharedPreferences reload is unreliable across separate processes on Windows.
File? _getMainAppHeartbeatFile() {
  try {
    final exePath = Platform.resolvedExecutable;
    if (exePath.contains('dart_test') || exePath.contains('flutter_tester')) {
      return null;
    }
    final exeDir = File(exePath).parent.path;
    return File('$exeDir/main_app_heartbeat.json');
  } catch (_) {
    return null;
  }
}

void _writeMainAppHeartbeat() {
  try {
    final file = _getMainAppHeartbeatFile();
    if (file == null) return;
    file.writeAsStringSync(
      jsonEncode({'running': true, 'heartbeat': DateTime.now().toIso8601String()}),
    );
  } catch (_) {}
}

void _clearMainAppHeartbeat() {
  try {
    final file = _getMainAppHeartbeatFile();
    if (file == null) return;
    if (file.existsSync()) file.deleteSync();
  } catch (_) {}
}

// --- Exclusive file lock for main app single-instance detection ---

/// Returns the main app lock file path next to the executable.
File? _getMainAppLockFile() {
  try {
    final exePath = Platform.resolvedExecutable;
    if (exePath.contains('dart_test') || exePath.contains('flutter_tester')) {
      return null;
    }
    final exeDir = File(exePath).parent.path;
    return File('$exeDir/main_app.lock');
  } catch (_) {
    return null;
  }
}

/// Global handle — kept open for process lifetime so lock is held.
RandomAccessFile? _mainAppLockHandle;

/// Acquires main app exclusive lock. Returns true if acquired.
bool _acquireMainAppLock() {
  try {
    final lockFile = _getMainAppLockFile();
    if (lockFile == null) return true; // test environment — allow
    if (!lockFile.existsSync()) {
      lockFile.writeAsStringSync('');
    }
    final handle = lockFile.openSync(mode: FileMode.write);
    try {
      handle.lockSync(FileLock.exclusive);
      handle.writeStringSync('${pid}\n${DateTime.now().toIso8601String()}');
      handle.flushSync();
      _mainAppLockHandle = handle;
      return true;
    } catch (_) {
      handle.closeSync();
      return false;
    }
  } catch (_) {
    return true; // file system error — allow launch
  }
}

/// Checks if the main app is already running by probing its exclusive lock file.
/// This is the primary detection mechanism. Falls back to heartbeat file.
Future<bool> isMainAppRunning(SharedPreferences prefs) async {
  // Primary: try to acquire the main app lock file
  try {
    final lockFile = _getMainAppLockFile();
    if (lockFile != null && lockFile.existsSync()) {
      final handle = lockFile.openSync(mode: FileMode.write);
      try {
        handle.lockSync(FileLock.exclusive);
        // Lock acquired — main app is NOT running. Release immediately.
        handle.unlockSync();
        handle.closeSync();
        return false;
      } catch (_) {
        // Lock failed — main app IS running
        handle.closeSync();
        return true;
      }
    }
  } catch (_) {}

  // Fallback: heartbeat file check
  try {
    final file = _getMainAppHeartbeatFile();
    if (file != null && file.existsSync()) {
      final content = file.readAsStringSync();
      final map = jsonDecode(content) as Map<String, dynamic>;
      final running = map['running'] as bool? ?? false;
      if (!running) return false;
      final heartbeat = map['heartbeat'] as String?;
      if (heartbeat == null) return false;
      final lastBeat = DateTime.tryParse(heartbeat);
      if (lastBeat == null) return false;
      final age = DateTime.now().difference(lastBeat).inSeconds;
      if (age > _mainAppStaleThresholdSeconds) {
        file.deleteSync();
        return false;
      }
      return true;
    }
  } catch (_) {}

  // Last fallback: SharedPreferences
  try {
    await prefs.reload();
  } catch (_) {}
  final running = prefs.getBool(_keyMainAppRunning) ?? false;
  if (!running) return false;

  final heartbeat = prefs.getString(_keyMainAppHeartbeat);
  if (heartbeat == null) return false;

  final lastBeat = DateTime.tryParse(heartbeat);
  if (lastBeat == null) return false;

  final age = DateTime.now().difference(lastBeat).inSeconds;
  if (age > _mainAppStaleThresholdSeconds) {
    await prefs.setBool(_keyMainAppRunning, false);
    return false;
  }
  return true;
}

void main(List<String> args) async {
  // Garden overlay mode
  if (args.contains('--garden') || args.contains('--overlay')) {
    await runGardenOverlay();
    return;
  }

  // Normal app mode
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Acquire main app exclusive lock (OS-level, released on process exit/crash)
  _acquireMainAppLock();

  // Acquire main app heartbeat (both file-based and SharedPreferences)
  await prefs.setBool(_keyMainAppRunning, true);
  await prefs.setString(_keyMainAppHeartbeat, DateTime.now().toIso8601String());
  _writeMainAppHeartbeat();

  // Heartbeat timer — keep lock alive in both stores
  Timer.periodic(const Duration(seconds: 5), (_) async {
    await prefs.setString(_keyMainAppHeartbeat, DateTime.now().toIso8601String());
    _writeMainAppHeartbeat();
  });

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const DeoreonemApp(),
  ));
}

class DeoreonemApp extends StatelessWidget {
  const DeoreonemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '덜어냄',
      theme: AppTheme.themeData,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
