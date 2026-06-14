import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/local_storage_provider.dart';
import 'widgets/quiet_garden_patch.dart';

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
      home: GestureDetector(
        onPanUpdate: (details) async {
          // Allow dragging the overlay window
          await windowManager.startDragging();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: QuietGardenPatch(totalNutrients: nutrients),
        ),
      ),
    );
  }
}
