import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/local_storage_provider.dart';
import 'widgets/quiet_garden_patch.dart';
import 'theme.dart';

const _keyOverlayX = 'garden_overlay_position_x';
const _keyOverlayY = 'garden_overlay_position_y';
const _windowWidth = 220.0;
const _windowHeight = 160.0;

/// Validates that a window position is within reasonable bounds.
/// Rejects negative or extremely large values that could place
/// the window off-screen.
bool isValidOverlayPosition(double x, double y) {
  if (x < 0 || y < 0) return false;
  if (x > 4000 || y > 3000) return false; // Reasonable upper bound for multi-display
  return true;
}

Future<void> runGardenOverlay() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

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
    child: _GardenOverlayApp(prefs: prefs),
  ));
}

class _GardenOverlayApp extends ConsumerWidget {
  final SharedPreferences prefs;

  const _GardenOverlayApp({required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(localStorageProvider);
    final nutrients = storage.totalWorryNutrients;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _GardenOverlayHome(totalNutrients: nutrients, prefs: prefs),
    );
  }
}

class _GardenOverlayHome extends StatefulWidget {
  final int totalNutrients;
  final SharedPreferences prefs;

  const _GardenOverlayHome({required this.totalNutrients, required this.prefs});

  @override
  State<_GardenOverlayHome> createState() => _GardenOverlayHomeState();
}

class _GardenOverlayHomeState extends State<_GardenOverlayHome>
    with WindowListener {
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
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

  void _closeOverlay() {
    exit(0);
  }

  void _openMainApp() async {
    final exePath = Platform.resolvedExecutable;
    await Process.start(exePath, [], mode: ProcessStartMode.detached);
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
      case 'hide':
        _closeOverlay();
      case 'reset_position':
        _resetPosition();
      case 'quit':
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
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Garden visual
                  QuietGardenPatch(totalNutrients: widget.totalNutrients),

                  // Close button (top-right, subtle)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Tooltip(
                      message: '작은 자리 닫기 (Esc)',
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
                          child: Text('덜어냄 열기', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuItem(
                          value: 'reset_position',
                          height: 36,
                          child: Text('위치 초기화', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuItem(
                          value: 'hide',
                          height: 36,
                          child: Text('작은 자리 숨기기', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuDivider(height: 1),
                        const PopupMenuItem(
                          value: 'quit',
                          height: 36,
                          child: Text('종료', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                  // Drag hint (bottom center, very subtle)
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '드래그로 이동',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.secondaryText.withValues(alpha: 0.4),
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
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
