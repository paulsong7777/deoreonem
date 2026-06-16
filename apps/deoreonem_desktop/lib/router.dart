import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/start_screen.dart';
import 'screens/dump_input_screen.dart';
import 'screens/classification_screen.dart';
import 'screens/first_action_screen.dart';
import 'screens/entrusted_summary_screen.dart';
import 'screens/completion_screen.dart';
import 'screens/review_screen.dart';
import 'screens/ime_test_screen.dart';

Page<void> _fadeTransition(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 100),
    reverseTransitionDuration: const Duration(milliseconds: 80),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', pageBuilder: (ctx, state) => _fadeTransition(ctx, state, const StartScreen())),
    GoRoute(path: '/dump', pageBuilder: (ctx, state) => _fadeTransition(ctx, state, const DumpInputScreen())),
    GoRoute(path: '/classify', pageBuilder: (ctx, state) => _fadeTransition(ctx, state, const ClassificationScreen())),
    GoRoute(path: '/first-action', pageBuilder: (ctx, state) => _fadeTransition(ctx, state, const FirstActionScreen())),
    GoRoute(path: '/summary', pageBuilder: (ctx, state) => _fadeTransition(ctx, state, const EntrustedSummaryScreen())),
    GoRoute(path: '/complete', pageBuilder: (ctx, state) => _fadeTransition(ctx, state, const CompletionScreen())),
    GoRoute(path: '/review', pageBuilder: (ctx, state) => _fadeTransition(ctx, state, const ReviewScreen())),
    GoRoute(path: '/ime-test', pageBuilder: (ctx, state) => _fadeTransition(ctx, state, const ImeTestScreen())),
  ],
);
