import 'package:go_router/go_router.dart';
import 'screens/start_screen.dart';
import 'screens/dump_input_screen.dart';
import 'screens/classification_screen.dart';
import 'screens/first_action_screen.dart';
import 'screens/entrusted_summary_screen.dart';
import 'screens/completion_screen.dart';
import 'screens/review_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StartScreen()),
    GoRoute(
        path: '/dump', builder: (context, state) => const DumpInputScreen()),
    GoRoute(
        path: '/classify',
        builder: (context, state) => const ClassificationScreen()),
    GoRoute(
        path: '/first-action',
        builder: (context, state) => const FirstActionScreen()),
    GoRoute(
        path: '/summary',
        builder: (context, state) => const EntrustedSummaryScreen()),
    GoRoute(
        path: '/complete',
        builder: (context, state) => const CompletionScreen()),
    GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewScreen()),
  ],
);
