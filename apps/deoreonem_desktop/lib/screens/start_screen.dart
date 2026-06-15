import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../providers/summary_provider.dart';
import '../providers/local_storage_provider.dart';
import '../providers/first_action_provider.dart';
import '../garden_overlay.dart';
import '../theme.dart';
import '../build_info.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  bool _isLaunchingGarden = false;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final isLoading = sessionState is AsyncLoading;

    final storage = ref.watch(localStorageProvider);
    final hasReviewable = storage.reviewableEntrustedCount > 0;

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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Title
                Text(
                  '덜어냄',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.primaryText,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 14),
                // Subtitle
                Text(
                  '오늘 머릿속에 남아있는 것들을\n잠시 내려놓아 보세요.',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondaryText,
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Supporting concept line
                Text(
                  '걱정은 잠시 맡겨두고, 필요한 것만 다시 꺼내볼 수 있습니다.',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.secondaryText.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                // Primary button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            // Reset state for a fresh session
                            ref.read(itemsProvider.notifier).reset();
                            ref.read(summaryProvider.notifier).reset();
                            ref
                                .read(firstActionSelectedIdProvider.notifier)
                                .state = null;
                            ref.read(sessionProvider.notifier).createSession();
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('시작하기',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                ),
                if (hasReviewable) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => context.go('/review'),
                      child: const Text('맡겨둔 것 확인하기',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Tree button — subtle
                TextButton(
                  onPressed: _isLaunchingGarden ? null : _launchGarden,
                  child: Text(
                    '조용한 나무 보기',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText.withOpacity(0.8)),
                  ),
                ),
                const Spacer(flex: 3),
                // Footer
                Text(
                  'v${BuildInfo.appVersion} ${BuildInfo.buildChannel} · ${BuildInfo.commitSha}',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.secondaryText.withOpacity(0.4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchGarden() async {
    if (_isLaunchingGarden) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final alreadyRunning = await isGardenOverlayRunning(prefs);
    if (alreadyRunning) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('조용한 나무가 이미 열려 있어요.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF5B4A3F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() => _isLaunchingGarden = true);

    final exePath = Platform.resolvedExecutable;
    await Process.start(exePath, ['--garden'],
        mode: ProcessStartMode.detached);

    // 3-second cooldown to prevent rapid clicks
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isLaunchingGarden = false);
    });
  }
}
