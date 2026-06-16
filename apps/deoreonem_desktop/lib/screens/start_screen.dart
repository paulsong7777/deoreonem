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
import '../design/app_tokens.dart';
import '../design/app_components.dart';
import '../build_info.dart';
import '../services/plant_stage_helper.dart';

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
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  // A. Hero title — "덜어냄" large
                  Text(
                    '덜어냄',
                    textAlign: TextAlign.center,
                    style: AppTokens.titleBanner,
                  ),
                  const SizedBox(height: 24),
                  // Subtitle
                  Text(
                    '오늘 머릿속에 남아있는 것들을\n잠시 내려놓아 보세요.',
                    textAlign: TextAlign.center,
                    style: AppTokens.body,
                  ),

                  // B. Tree visual in center area
                  const SizedBox(height: 36),
                  _buildTreePreview(),

                  // C. Primary button — "시작하기" sage green full-width
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              ref.read(itemsProvider.notifier).reset();
                              ref.read(summaryProvider.notifier).reset();
                              ref
                                  .read(firstActionSelectedIdProvider.notifier)
                                  .state = null;
                              ref
                                  .read(sessionProvider.notifier)
                                  .createSession();
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('시작하기', style: AppTokens.buttonPrimary),
                    ),
                  ),
                  // Secondary — "맡겨둔 것 확인하기"
                  if (hasReviewable) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => context.go('/review'),
                        child: Text('맡겨둔 것 확인하기',
                            style: AppTokens.buttonSecondary
                                .copyWith(fontSize: 13)),
                      ),
                    ),
                  ],
                  // Tertiary — "조용한 나무 보기"
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _isLaunchingGarden ? null : _launchGarden,
                    child: Text(
                      '조용한 나무 보기',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTokens.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ),

                  // D. Footer
                  const SizedBox(height: 48),
                  Text(
                    'v${BuildInfo.appVersion} ${BuildInfo.buildChannel} · ${BuildInfo.commitSha}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTokens.textSecondary.withOpacity(0.35),
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

    return SizedBox(
      width: double.infinity,
      height: 200,
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
            getPotSignalMessage(nutrients),
            style: AppTokens.caption,
            textAlign: TextAlign.center,
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
          CalmSnackBar.show('조용한 나무가 이미 열려 있어요.'),
        );
      }
      return;
    }

    setState(() => _isLaunchingGarden = true);

    final exePath = Platform.resolvedExecutable;
    await Process.start(exePath, ['--garden'],
        mode: ProcessStartMode.detached);

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

    final stage = getPlantStage(nutrients);

    // Stem height based on stage
    double stemHeight;
    if (stage.index >= 8) {
      stemHeight = 50.0;
    } else if (stage.index >= 6) {
      stemHeight = 42.0;
    } else if (stage.index >= 4) {
      stemHeight = 35.0;
    } else if (stage.index >= 2) {
      stemHeight = 24.0;
    } else {
      stemHeight = 14.0;
    }

    final stemPaint = Paint()
      ..color = stage.index >= 4
          ? const Color(0xFF6B5B4B)
          : const Color(0xFF6B8E6B)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, groundY - 3),
      Offset(cx, groundY - 3 - stemHeight),
      stemPaint,
    );

    // Canopy
    if (stage.index >= 2) {
      final leafPaint = Paint()
        ..color = const Color(0xFF7B9E87).withOpacity(0.5);
      double canopySize;
      if (stage.index >= 8) {
        canopySize = 36.0;
      } else if (stage.index >= 6) {
        canopySize = 30.0;
      } else if (stage.index >= 4) {
        canopySize = 24.0;
      } else {
        canopySize = 16.0;
      }
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
