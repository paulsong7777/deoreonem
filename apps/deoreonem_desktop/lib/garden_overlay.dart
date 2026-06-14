import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/local_storage_provider.dart';
import 'widgets/quiet_garden_patch.dart';
import 'theme.dart';

Future<void> runGardenOverlay() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowSize = Size(220, 160);

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
    await windowManager.show();
    await windowManager.setAsFrameless();
  });

  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const GardenOverlayApp(),
  ));
}

class GardenOverlayApp extends ConsumerWidget {
  const GardenOverlayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(localStorageProvider);
    final nutrients = storage.totalWorryNutrients;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _GardenOverlayHome(totalNutrients: nutrients),
    );
  }
}

class _GardenOverlayHome extends StatelessWidget {
  final int totalNutrients;

  const _GardenOverlayHome({required this.totalNutrients});

  void _closeOverlay() {
    exit(0);
  }

  void _openMainApp() async {
    final exePath = Platform.resolvedExecutable;
    await Process.start(exePath, [], mode: ProcessStartMode.detached);
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
            onSecondaryTap: () {
              // Right-click context menu handled via overlay menu below
            },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Garden visual
                  QuietGardenPatch(totalNutrients: totalNutrients),

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
                            color: Colors.black.withOpacity(0.1),
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
                          color: AppTheme.secondaryText.withOpacity(0.6)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(maxWidth: 160),
                      onSelected: (value) {
                        switch (value) {
                          case 'open':
                            _openMainApp();
                          case 'hide':
                            _closeOverlay();
                          case 'quit':
                            _closeOverlay();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'open',
                          height: 36,
                          child: Text('덜어냄 열기', style: TextStyle(fontSize: 13)),
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
                          color: AppTheme.secondaryText.withOpacity(0.4),
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
