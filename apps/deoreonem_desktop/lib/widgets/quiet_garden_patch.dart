import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/plant_stage_helper.dart';
import '../design/app_tokens.dart';

/// A small calm garden visual representing the plant stage.
/// Visual metaphor: 내려놓은 걱정이 조용한 나무의 양분이 되어 자란다.
/// Not a game. Not a pet. A quiet reflection.
class QuietGardenPatch extends StatefulWidget {
  final int totalNutrients;
  final bool showGlow;

  const QuietGardenPatch({
    super.key,
    required this.totalNutrients,
    this.showGlow = false,
  });

  @override
  State<QuietGardenPatch> createState() => _QuietGardenPatchState();
}

class _QuietGardenPatchState extends State<QuietGardenPatch>
    with TickerProviderStateMixin {
  late final AnimationController _swayController;
  late final AnimationController _windController;
  late final AnimationController _glowController;
  late final Animation<double> _glowOpacity;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    // Idle sway — 5s gentle rotation
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    // Wind effect — 8s cycle, gentle lateral rustle
    _windController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Nutrient glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 75),
    ]).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant QuietGardenPatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showGlow && !oldWidget.showGlow) {
      _glowController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _swayController.dispose();
    _windController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = getPlantStage(widget.totalNutrients);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFE), // nearly white
              Color(0xFFF8F4ED), // barely warm
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: AnimatedScale(
                      scale: _isHovered ? 1.02 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        transform: Matrix4.translationValues(
                            0, _isHovered ? -2.0 : 0.0, 0),
                        child: SizedBox(
                          width: 200,
                          height: 180,
                          child: AnimatedBuilder(
                            animation: Listenable.merge(
                                [_swayController, _windController]),
                            builder: (context, child) {
                              final swayAngle = stage == PlantStage.seed
                                  ? 0.0
                                  : (_swayController.value - 0.5) * 0.04;
                              // Wind: ±3 degrees rotation + ±2px horizontal
                              final windAngle =
                                  (_windController.value - 0.5) *
                                      (3.0 * math.pi / 180);
                              final windDx =
                                  (_windController.value - 0.5) * 4.0;
                              final totalAngle = swayAngle + windAngle;

                              return Transform(
                                alignment: Alignment.bottomCenter,
                                transform: Matrix4.identity()
                                  ..translate(windDx, 0.0)
                                  ..rotateZ(totalAngle),
                                child: CustomPaint(
                                  size: const Size(200, 180),
                                  painter: _GardenPainter(stage: stage),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Status text
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  child: Text(
                    getPotSignalMessage(widget.totalNutrients),
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTokens.textSecondary.withOpacity(0.8),
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Warm amber glow from below when nutrients increase
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _glowOpacity,
                builder: (context, child) {
                  if (_glowOpacity.value <= 0.01) {
                    return const SizedBox.shrink();
                  }
                  return Center(
                    child: Container(
                      width: 110,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: AppTokens.glowAmber
                                .withOpacity(_glowOpacity.value),
                            blurRadius: 32,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenPainter extends CustomPainter {
  final PlantStage stage;

  _GardenPainter({required this.stage});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final groundY = size.height - 10;

    // --- Ground layers ---
    final shadowPaint = Paint()
      ..color = const Color(0xFF8B7355).withOpacity(0.12);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY + 3), width: 80, height: 12),
      shadowPaint,
    );

    final groundPaint = Paint()
      ..color = const Color(0xFFB5A48B).withOpacity(0.5);
    final groundWidth = stage.index >= 5 ? 82.0 : 68.0;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY), width: groundWidth, height: 16),
      groundPaint,
    );

    final soilPaint = Paint()
      ..color = const Color(0xFF8B7355).withOpacity(0.25);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY), width: groundWidth * 0.6, height: 10),
      soilPaint,
    );

    // Tiny grass hints
    if (stage != PlantStage.seed) {
      final grassPaint = Paint()
        ..color = const Color(0xFF8FAF8F).withOpacity(0.4)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - 22, groundY - 4),
          Offset(cx - 24, groundY - 8), grassPaint);
      canvas.drawLine(Offset(cx + 20, groundY - 3),
          Offset(cx + 22, groundY - 7), grassPaint);
      canvas.drawLine(Offset(cx - 12, groundY - 5),
          Offset(cx - 11, groundY - 9), grassPaint);
    }

    if (stage == PlantStage.seed) {
      final seedPaint = Paint()
        ..color = const Color(0xFF8B7355).withOpacity(0.4);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, groundY - 2), width: 6, height: 4),
        seedPaint,
      );
      return;
    }

    // --- Stem / Trunk ---
    double stemHeight;
    double stemWidth;
    switch (stage) {
      case PlantStage.seed:
        stemHeight = 0;
        stemWidth = 1.5;
      case PlantStage.sprout:
        stemHeight = 18;
        stemWidth = 2.0;
      case PlantStage.youngTree:
        stemHeight = 28;
        stemWidth = 2.4;
      case PlantStage.youngTreePlus:
        stemHeight = 35;
        stemWidth = 2.8;
      case PlantStage.greenTree:
        stemHeight = 45;
        stemWidth = 3.2;
      case PlantStage.growingTree:
        stemHeight = 55;
        stemWidth = 3.6;
      case PlantStage.strongTree:
        stemHeight = 65;
        stemWidth = 4.0;
      case PlantStage.bigTree:
        stemHeight = 75;
        stemWidth = 4.4;
      case PlantStage.quietTree:
        stemHeight = 85;
        stemWidth = 4.8;
    }

    final stemBottom = Offset(cx, groundY - 4);
    final stemTop = Offset(cx, groundY - 4 - stemHeight);

    // Trunk color darkens with growth
    final trunkColor = stage.index >= 4
        ? const Color(0xFF6B5B4B)
        : const Color(0xFF6B8E6B);
    final stemPaint = Paint()
      ..color = trunkColor
      ..strokeWidth = stemWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(stemBottom, stemTop, stemPaint);

    // --- Branches for larger stages ---
    if (stage.index >= 5) {
      final branchPaint = Paint()
        ..color = trunkColor.withOpacity(0.7)
        ..strokeWidth = stemWidth * 0.5
        ..strokeCap = StrokeCap.round;
      final midY = stemTop.dy + stemHeight * 0.4;
      canvas.drawLine(
          Offset(cx, midY), Offset(cx - 16, midY - 10), branchPaint);
      canvas.drawLine(
          Offset(cx, midY), Offset(cx + 14, midY - 8), branchPaint);
      if (stage.index >= 7) {
        final upperY = stemTop.dy + stemHeight * 0.2;
        canvas.drawLine(
            Offset(cx, upperY), Offset(cx - 10, upperY - 8), branchPaint);
        canvas.drawLine(
            Offset(cx, upperY), Offset(cx + 12, upperY - 6), branchPaint);
      }
    }

    // --- Leaves / Canopy ---
    final leafColor = const Color(0xFF7B9E87);

    switch (stage) {
      case PlantStage.seed:
        break;
      case PlantStage.sprout:
        final leafPaint = Paint()..color = leafColor.withOpacity(0.7);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - 5, stemTop.dy + 3), width: 10, height: 7),
          leafPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + 5, stemTop.dy + 3), width: 10, height: 7),
          leafPaint,
        );
      case PlantStage.youngTree:
        final leafPaint = Paint()..color = leafColor.withOpacity(0.65);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - 7, stemTop.dy + 4), width: 14, height: 10),
          leafPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + 7, stemTop.dy + 4), width: 14, height: 10),
          leafPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, stemTop.dy), width: 12, height: 9),
          leafPaint,
        );
      case PlantStage.youngTreePlus:
        final leafPaint = Paint()..color = leafColor.withOpacity(0.6);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, stemTop.dy + 4), width: 28, height: 20),
          leafPaint,
        );
        final highlightPaint = Paint()..color = leafColor.withOpacity(0.35);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - 3, stemTop.dy - 2), width: 16, height: 12),
          highlightPaint,
        );
      case PlantStage.greenTree:
        final canopyPaint = Paint()..color = leafColor.withOpacity(0.55);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, stemTop.dy + 6), width: 38, height: 28),
          canopyPaint,
        );
        final upperPaint = Paint()..color = leafColor.withOpacity(0.4);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, stemTop.dy - 2), width: 26, height: 18),
          upperPaint,
        );
      case PlantStage.growingTree:
        final canopyPaint = Paint()..color = leafColor.withOpacity(0.5);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, stemTop.dy + 8), width: 48, height: 34),
          canopyPaint,
        );
        final midPaint = Paint()..color = leafColor.withOpacity(0.4);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - 4, stemTop.dy), width: 30, height: 22),
          midPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + 6, stemTop.dy - 4), width: 22, height: 16),
          midPaint,
        );
      case PlantStage.strongTree:
        final canopyPaint = Paint()..color = leafColor.withOpacity(0.5);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, stemTop.dy + 10), width: 56, height: 38),
          canopyPaint,
        );
        final midPaint = Paint()..color = leafColor.withOpacity(0.38);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - 6, stemTop.dy + 2), width: 36, height: 26),
          midPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + 8, stemTop.dy - 4), width: 28, height: 20),
          midPaint,
        );
        final topPaint = Paint()..color = leafColor.withOpacity(0.3);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, stemTop.dy - 10), width: 20, height: 14),
          topPaint,
        );
      case PlantStage.bigTree:
        final canopyPaint = Paint()..color = leafColor.withOpacity(0.48);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, stemTop.dy + 12), width: 64, height: 42),
          canopyPaint,
        );
        final midPaint = Paint()..color = leafColor.withOpacity(0.36);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - 8, stemTop.dy + 2), width: 40, height: 28),
          midPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + 10, stemTop.dy - 4), width: 32, height: 22),
          midPaint,
        );
        final topPaint = Paint()..color = leafColor.withOpacity(0.28);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + 2, stemTop.dy - 12), width: 24, height: 16),
          topPaint,
        );
      case PlantStage.quietTree:
        // Full layered canopy — the final quiet tree
        final canopyPaint = Paint()..color = leafColor.withOpacity(0.5);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, stemTop.dy + 14), width: 72, height: 46),
          canopyPaint,
        );
        final midPaint = Paint()..color = leafColor.withOpacity(0.38);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - 10, stemTop.dy + 4), width: 44, height: 30),
          midPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + 12, stemTop.dy - 2), width: 36, height: 24),
          midPaint,
        );
        final topPaint = Paint()..color = leafColor.withOpacity(0.3);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, stemTop.dy - 10), width: 28, height: 18),
          topPaint,
        );
        final peakPaint = Paint()..color = leafColor.withOpacity(0.22);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + 3, stemTop.dy - 18), width: 18, height: 12),
          peakPaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _GardenPainter oldDelegate) =>
      oldDelegate.stage != stage;
}
