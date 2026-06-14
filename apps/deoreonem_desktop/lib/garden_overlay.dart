import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/local_storage_provider.dart';
import 'services/local_storage_service.dart';
import 'widgets/quiet_garden_patch.dart';
import 'theme.dart';
import 'main.dart' show isMainAppRunning;

const _keyOverlayX = 'garden_overlay_position_x';
const _keyOverlayY = 'garden_overlay_position_y';
const _keyOverlayRunning = 'garden_overlay_running';
const _keyOverlayHeartbeat = 'garden_overlay_heartbeat';
const _windowWidth = 260.0;
const _windowHeight = 190.0;
const _staleThresholdSeconds = 15;

/// Validates that a window position is within reasonable bounds.
bool isValidOverlayPosition(double x, double y) {
  if (x < 0 || y < 0) return false;
  if (x > 4000 || y > 3000) return false;
  return true;
}

/// Checks if a garden overlay instance is currently running.
/// Uses exclusive file lock probe first, falls back to heartbeat check.
Future<bool> isGardenOverlayRunning(SharedPreferences prefs) async {
  // Try file lock probe (most reliable)
  try {
    final lockFile = _getOverlayLockFile();
    if (lockFile.existsSync()) {
      final handle = lockFile.openSync(mode: FileMode.write);
      try {
        handle.lockSync(FileLock.exclusive);
        // Lock acquired — no overlay running. Release immediately.
        handle.unlockSync();
        handle.closeSync();
        // Clean up stale heartbeat if any
        await prefs.setBool(_keyOverlayRunning, false);
        return false;
      } catch (_) {
        // Lock failed — overlay IS running
        handle.closeSync();
        return true;
      }
    }
  } catch (_) {
    // File lock not available — fall through to heartbeat
  }

  // Fallback: heartbeat-based check
  try {
    await prefs.reload();
  } catch (_) {}
  final running = prefs.getBool(_keyOverlayRunning) ?? false;
  if (!running) return false;

  final heartbeat = prefs.getString(_keyOverlayHeartbeat);
  if (heartbeat == null) return false;

  final lastBeat = DateTime.tryParse(heartbeat);
  if (lastBeat == null) return false;

  final age = DateTime.now().difference(lastBeat).inSeconds;
  if (age > _staleThresholdSeconds) {
    // Stale lock — clear it
    await prefs.setBool(_keyOverlayRunning, false);
    return false;
  }

  return true;
}

Future<void> _acquireOverlayLock(SharedPreferences prefs) async {
  await prefs.setBool(_keyOverlayRunning, true);
  await prefs.setString(_keyOverlayHeartbeat, DateTime.now().toIso8601String());
}

Future<void> _releaseOverlayLock(SharedPreferences prefs) async {
  await prefs.setBool(_keyOverlayRunning, false);
  await prefs.remove(_keyOverlayHeartbeat);
}

// --- Exclusive file lock for true single instance ---

/// Returns the lock file path next to the executable.
File _getOverlayLockFile() {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  return File('$exeDir/garden_overlay.lock');
}

/// Attempts to acquire an exclusive file lock.
/// Returns the RandomAccessFile handle if successful (keep open for lifetime).
/// Returns null if another instance holds the lock.
Future<RandomAccessFile?> _acquireExclusiveOverlayLock() async {
  try {
    final lockFile = _getOverlayLockFile();
    // Create the file if it doesn't exist
    if (!lockFile.existsSync()) {
      lockFile.writeAsStringSync('');
    }
    final handle = lockFile.openSync(mode: FileMode.write);
    try {
      handle.lockSync(FileLock.exclusive);
      // Write PID for debugging
      handle.writeStringSync('${pid}\n${DateTime.now().toIso8601String()}');
      handle.flushSync();
      return handle;
    } catch (_) {
      // Lock failed — another process holds it
      handle.closeSync();
      return null;
    }
  } catch (_) {
    // File system error — fall back to allowing launch
    // (better to allow a potential duplicate than block all launches)
    return null;
  }
}

/// Releases the exclusive file lock.
void _releaseExclusiveOverlayLock(RandomAccessFile? handle) {
  try {
    if (handle != null) {
      handle.unlockSync();
      handle.closeSync();
    }
  } catch (_) {}
}

Future<void> runGardenOverlay() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // --- True single instance: exclusive file lock ---
  final lockHandle = await _acquireExclusiveOverlayLock();
  if (lockHandle == null) {
    // Another overlay is running OR lock file not available.
    // Check if lock file exists — if it does, another instance holds it.
    try {
      final lockFile = _getOverlayLockFile();
      if (lockFile.existsSync()) {
        // Lock file exists but we couldn't acquire → another instance running
        exit(0);
      }
    } catch (_) {}
    // Lock file doesn't exist or we can't access it — proceed anyway
  }

  // Acquire heartbeat lock (for main app "작은 자리 보기" check)
  await _acquireOverlayLock(prefs);

  // --- Read initial garden state immediately from file ---
  // This ensures the first render shows the correct growth stage.
  int initialNutrients;
  final fromFile = LocalStorageService.readGardenStateFromFile();
  if (fromFile != null) {
    initialNutrients = fromFile;
  } else {
    // File missing or corrupt — use SharedPreferences
    await prefs.reload();
    initialNutrients = prefs.getInt('total_worry_nutrients') ?? 0;
  }

  const windowSize = Size(_windowWidth, _windowHeight);

  WindowOptions windowOptions = const WindowOptions(
    size: windowSize,
    minimumSize: windowSize,
    maximumSize: windowSize,
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Restore saved position or default to bottom-right
    final savedX = prefs.getDouble(_keyOverlayX);
    final savedY = prefs.getDouble(_keyOverlayY);

    if (savedX != null && savedY != null && isValidOverlayPosition(savedX, savedY)) {
      await windowManager.setPosition(Offset(savedX, savedY));
    } else {
      // Default: bottom-right above taskbar
      await windowManager.setAlignment(Alignment.bottomRight);
    }

    await windowManager.show();
    await windowManager.setAsFrameless();
  });

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: _GardenOverlayApp(
      prefs: prefs,
      initialNutrients: initialNutrients,
      lockHandle: lockHandle,
    ),
  ));
}

class _GardenOverlayApp extends ConsumerWidget {
  final SharedPreferences prefs;
  final int initialNutrients;
  final RandomAccessFile? lockHandle;

  const _GardenOverlayApp({
    required this.prefs,
    required this.initialNutrients,
    this.lockHandle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _GardenOverlayHome(
        totalNutrients: initialNutrients,
        prefs: prefs,
        lockHandle: lockHandle,
      ),
    );
  }
}

class _GardenOverlayHome extends StatefulWidget {
  final int totalNutrients;
  final SharedPreferences prefs;
  final RandomAccessFile? lockHandle;

  const _GardenOverlayHome({
    required this.totalNutrients,
    required this.prefs,
    this.lockHandle,
  });

  @override
  State<_GardenOverlayHome> createState() => _GardenOverlayHomeState();
}

class _GardenOverlayHomeState extends State<_GardenOverlayHome>
    with WindowListener {
  Timer? _saveTimer;
  Timer? _refreshTimer;
  late int _currentNutrients;

  @override
  void initState() {
    super.initState();
    _currentNutrients = widget.totalNutrients;
    windowManager.addListener(this);

    // Periodically refresh nutrient state.
    // Uses file-based sync first (reliable on Windows), falls back to SharedPreferences.
    // Also update heartbeat for instance lock.
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      int fresh;
      // Try file-based sync first (written by main app after worry let-go)
      final fromFile = LocalStorageService.readGardenStateFromFile();
      if (fromFile != null) {
        fresh = fromFile;
      } else {
        // Fall back to SharedPreferences reload
        await widget.prefs.reload();
        fresh = widget.prefs.getInt('total_worry_nutrients') ?? 0;
      }
      if (fresh != _currentNutrients && mounted) {
        setState(() => _currentNutrients = fresh);
      }
      // Update heartbeat
      await widget.prefs.setString(_keyOverlayHeartbeat, DateTime.now().toIso8601String());
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _refreshTimer?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMoved() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () async {
      final pos = await windowManager.getPosition();
      await widget.prefs.setDouble(_keyOverlayX, pos.dx);
      await widget.prefs.setDouble(_keyOverlayY, pos.dy);
    });
  }

  void _closeOverlay() async {
    await _releaseOverlayLock(widget.prefs);
    _releaseExclusiveOverlayLock(widget.lockHandle);
    exit(0);
  }

  bool _isLaunching = false;

  void _openMainApp() async {
    // Debounce rapid clicks
    if (_isLaunching) return;
    _isLaunching = true;

    // Prevent duplicate main app windows
    if (await isMainAppRunning(widget.prefs)) {
      _isLaunching = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('덜어냄이 이미 열려 있어요.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    final exePath = Platform.resolvedExecutable;
    await Process.start(exePath, [], mode: ProcessStartMode.detached);

    // Keep debounce for 3 seconds to prevent rapid spawn
    Future.delayed(const Duration(seconds: 3), () => _isLaunching = false);
  }

  Future<void> _resetPosition() async {
    await widget.prefs.remove(_keyOverlayX);
    await widget.prefs.remove(_keyOverlayY);
    await windowManager.setAlignment(Alignment.bottomRight);
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'open':
        _openMainApp();
      case 'reset_position':
        _resetPosition();
      case 'close':
        _closeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const _CloseIntent(),
      },
      child: Actions(
        actions: {
          _CloseIntent: CallbackAction<_CloseIntent>(onInvoke: (_) {
            _closeOverlay();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            onPanStart: (_) async => await windowManager.startDragging(),
            onDoubleTap: _openMainApp,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Stack(
                  children: [
                    // Garden visual — the main focus
                    QuietGardenPatch(totalNutrients: _currentNutrients),

                  // Close button (top-right, subtle)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Tooltip(
                      message: '닫기 (Esc)',
                      child: GestureDetector(
                        onTap: _closeOverlay,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 12,
                              color: AppTheme.secondaryText),
                        ),
                      ),
                    ),
                  ),

                  // Context menu button (top-left, subtle)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: PopupMenuButton<String>(
                      tooltip: '메뉴',
                      icon: Icon(Icons.more_horiz, size: 14,
                          color: AppTheme.secondaryText.withValues(alpha: 0.6)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(maxWidth: 160),
                      onSelected: _handleMenuSelection,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'open',
                          height: 36,
                          child: Text('덜어냄 열기 (두 번 클릭)', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuItem(
                          value: 'reset_position',
                          height: 36,
                          child: Text('위치 초기화', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuDivider(height: 1),
                        const PopupMenuItem(
                          value: 'close',
                          height: 36,
                          child: Text('작은 자리 닫기', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                  // No bottom hint — double-click guidance lives in menu.
                  // Bottom space is reserved for QuietGardenPatch stage message.
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class _CloseIntent extends Intent {
  const _CloseIntent();
}
