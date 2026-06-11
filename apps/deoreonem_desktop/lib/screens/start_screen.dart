import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../providers/summary_provider.dart';
import '../providers/local_storage_provider.dart';
import '../theme.dart';

class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);
    final isLoading = sessionState is AsyncLoading;

    final storage = ref.watch(localStorageProvider);
    final lastSession = storage.getLastCompletedSession();

    ref.listen<AsyncValue>(sessionProvider, (prev, next) {
      next.whenOrNull(
        data: (session) {
          if (session != null) {
            context.go('/dump');
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$error'),
              action: SnackBarAction(
                label: '다시 시도',
                onPressed: () =>
                    ref.read(sessionProvider.notifier).createSession(),
              ),
            ),
          );
        },
      );
    });

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '덜어냄',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 16),
              Text(
                '오늘 머릿속에 남아있는 것들을 꺼내 보세요.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        // Reset state for a fresh session
                        ref.read(itemsProvider.notifier).reset();
                        ref.read(summaryProvider.notifier).reset();
                        ref.read(sessionProvider.notifier).createSession();
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('시작하기'),
              ),
              if (lastSession != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/review'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryText,
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('어제 맡긴 것 보기'),
                ),
              ],
              const Spacer(),
              Text(
                'v0.2.0',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
