import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: DeoreonemApp()));
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
