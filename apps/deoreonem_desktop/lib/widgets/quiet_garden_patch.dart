import 'package:flutter/material.dart';
import '../services/plant_stage_helper.dart';
import '../theme.dart';

/// A small calm garden visual representing the plant stage.
/// Visual metaphor: 내려놓은 걱정이 작은 자리에 스며들어 조용히 나무가 자란다.
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
  late final AnimationController _controller;
  late final AnimationController _glowController;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0), weight: 70),
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
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = getPlantStage(widget.totalNutrients);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF7F3ED), // warm sky
            Color(0xFFF0EAE0), // warm ground transition
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: 100,
                height: 90,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final angle = stage == PlantStage.seed
                        ? 0.0
                        : (_controller.value - 0.5) * 0.04; // ~2.3 degrees max
                    return Transform.rotate(
                      angle: angle,
                      alignment: Alignment.bottomCenter,
                      child: CustomPaint(
                        size: const Size(100, 90),
                        painter: _GardenPainter(stage: stage),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(flex: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  getPotSignalMessage(widget.totalNutrients),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.secondaryText.withValues(alpha: 0.8),
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          // Subtle warm glow around ground area when nutrients increase
          Positioned(
            bottom: 30,
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
                    width: 90,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(45),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8D5B7)
                              .withValues(alpha: _glowOpacity.value),
                          blurRadius: 24,
                          spreadRadius: 8,
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
    );
  }
}

class _GardenPainter extends CustomPainter {
  final PlantStage stage;

  _GardenPainter({required this.stage});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final groundY = size.height - 8;

    // --- Ground layers ---
    // Soft shadow under ground
    final shadowPaint = Paint()
      ..color = const Color(0xFF8B7355).withValues(alpha: 0.12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY + 3), width: 72, height: 10),
      shadowPaint,
    );

    // Main ground mound
    final groundPaint = Paint()
      ..color = const Color(0xFFB5A48B).withValues(alpha: 0.5);
    final groundWidth = stage == PlantStage.quietTree ? 74.0 : 64.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY), width: groundWidth, height: 16),
      groundPaint,
    );

    // Darker soil center
    final soilPaint = Paint()
      ..color = const Color(0xFF8B7355).withValues(alpha: 0.25);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY), width: groundWidth * 0.6, height: 10),
      soilPaint,
    );

    // Tiny grass hints (small lines around mound)
    if (stage != PlantStage.seed) {
      final grassPaint = Paint()
        ..color = const Color(0xFF8FAF8F).withValues(alpha: 0.4)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - 20, groundY - 4), Offset(cx - 22, groundY - 8), grassPaint);
      canvas.drawLine(Offset(cx + 18, groundY - 3), Offset(cx + 20, groundY - 7), grassPaint);
      canvas.drawLine(Offset(cx - 12, groundY - 5), Offset(cx - 11, groundY - 9), grassPaint);
    }

    if (stage == PlantStage.seed) {
      // Small seed mark
      final seedPaint = Paint()
        ..color = const Color(0xFF8B7355).withValues(alpha: 0.4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, groundY - 2), width: 6, height: 4),
        seedPaint,
      );
      return;
    }

    // --- Stem ---
    double stemHeight;
    double stemWidth;
    switch (stage) {
      case PlantStage.seed:
        stemHeight = 0; stemWidth = 1.5;
      case PlantStage.sprout:
        stemHeight = 18; stemWidth = 2.0;
      case PlantStage.smallLeaf:
        stemHeight = 28; stemWidth = 2.2;
      case PlantStage.youngPlant:
        stemHeight = 38; stemWidth = 2.8;
      case PlantStage.quietTree:
        stemHeight = 48; stemWidth = 3.2;
    }

    final stemBottom = Offset(cx, groundY - 4);
    final stemTop = Offset(cx, groundY - 4 - stemHeight);

    // Trunk (darker at base for tree stages)
    final stemPaint = Paint()
      ..color = stage == PlantStage.quietTree
          ? const Color(0xFF6B5B4B)
          : const Color(0xFF6B8E6B)
      ..strokeWidth = stemWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(stemBottom, stemTop, stemPaint);

    // --- Leaves / Canopy ---
    final leafColor = const Color(0xFF7B9E87);

    if (stage == PlantStage.sprout) {
      final leafPaint = Paint()..color = leafColor.withValues(alpha: 0.7);
      // Two small elliptical leaves
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 5, stemTop.dy + 3), width: 10, height: 7),
        leafPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 5, stemTop.dy + 3), width: 10, height: 7),
        leafPaint,
      );
    } else if (stage == PlantStage.smallLeaf) {
      final leafPaint = Paint()..color = leafColor.withValues(alpha: 0.65);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 7, stemTop.dy + 4), width: 12, height: 9),
        leafPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 7, stemTop.dy + 4), width: 12, height: 9),
        leafPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, stemTop.dy), width: 10, height: 8),
        leafPaint,
      );
    } else if (stage == PlantStage.youngPlant) {
      final leafPaint = Paint()..color = leafColor.withValues(alpha: 0.6);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, stemTop.dy + 3), width: 26, height: 20),
        leafPaint,
      );
      // Small highlight
      final highlightPaint = Paint()..color = leafColor.withValues(alpha: 0.35);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 3, stemTop.dy - 2), width: 14, height: 10),
        highlightPaint,
      );
    } else if (stage == PlantStage.quietTree) {
      // Main canopy — soft layered
      final canopyPaint = Paint()..color = leafColor.withValues(alpha: 0.55);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, stemTop.dy + 6), width: 40, height: 30),
        canopyPaint,
      );
      // Upper layer
      final upperPaint = Paint()..color = leafColor.withValues(alpha: 0.4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, stemTop.dy - 2), width: 28, height: 20),
        upperPaint,
      );
      // Top accent
      final topPaint = Paint()..color = leafColor.withValues(alpha: 0.3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 2, stemTop.dy - 8), width: 16, height: 12),
        topPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GardenPainter oldDelegate) =>
      oldDelegate.stage != stage;
}
