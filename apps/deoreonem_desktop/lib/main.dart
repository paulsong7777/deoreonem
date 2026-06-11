import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'router.dart';
import 'theme.dart';
import 'providers/local_storage_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

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
