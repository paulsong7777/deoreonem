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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  // A. Hero text
                  Text(
                    '덜어냄',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      color: AppTheme.primaryText,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '오늘 머릿속에 남아있는 것들을\n잠시 내려놓아 보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: AppTheme.secondaryText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '걱정은 잠시 맡겨두고, 필요한 것만 다시 꺼내볼 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.secondaryText.withOpacity(0.6),
                    ),
                  ),

                  // B. Tree preview
                  const SizedBox(height: 36),
                  _buildTreePreview(),

                  // C. Actions
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
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
                              ref
                                  .read(sessionProvider.notifier)
                                  .createSession();
                            },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
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
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => context.go('/review'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('맡겨둔 것 확인하기',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _isLaunchingGarden ? null : _launchGarden,
                    child: Text(
                      '조용한 나무 보기',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText.withOpacity(0.7),
                      ),
                    ),
                  ),

                  // D. Footer
                  const SizedBox(height: 48),
                  Text(
                    'v${BuildInfo.appVersion} ${BuildInfo.buildChannel} · ${BuildInfo.commitSha}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.secondaryText.withOpacity(0.35),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTreePreview() {
    final storage = ref.watch(localStorageProvider);
    final nutrients = storage.totalWorryNutrients;

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFC),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFEDE7DD), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 120,
            child: CustomPaint(
              size: const Size(150, 120),
              painter: _MiniTreePainter(nutrients: nutrients),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '조용한 나무',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '내려놓은 걱정은 나무의 양분이 됩니다.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.secondaryText.withOpacity(0.7),
            ),
          ),
        ],
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

class _MiniTreePainter extends CustomPainter {
  final int nutrients;
  _MiniTreePainter({required this.nutrients});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final groundY = size.height - 6;

    // Ground
    final groundPaint = Paint()
      ..color = const Color(0xFFB5A48B).withOpacity(0.5);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY), width: 50, height: 12),
      groundPaint,
    );

    if (nutrients == 0) return;

    // Stem
    final stemHeight = nutrients >= 15
        ? 35.0
        : nutrients >= 7
            ? 28.0
            : nutrients >= 3
                ? 20.0
                : 12.0;
    final stemPaint = Paint()
      ..color = const Color(0xFF6B8E6B)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, groundY - 3),
      Offset(cx, groundY - 3 - stemHeight),
      stemPaint,
    );

    // Canopy
    if (nutrients >= 3) {
      final leafPaint = Paint()
        ..color = const Color(0xFF7B9E87).withOpacity(0.5);
      final canopySize = nutrients >= 15
          ? 28.0
          : nutrients >= 7
              ? 20.0
              : 14.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, groundY - 3 - stemHeight + 4),
          width: canopySize,
          height: canopySize * 0.8,
        ),
        leafPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTreePainter old) =>
      old.nutrients != nutrients;
}
