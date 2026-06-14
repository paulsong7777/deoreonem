import 'package:flutter/material.dart';
import '../services/plant_stage_helper.dart';
import '../theme.dart';

/// A small calm garden visual that represents the plant stage.
/// Uses simple CustomPaint for a ground patch with a sprout/tree.
/// Includes a very subtle idle sway animation (seed stage is static).
class QuietGardenPatch extends StatefulWidget {
  final int totalNutrients;

  const QuietGardenPatch({super.key, required this.totalNutrients});

  @override
  State<QuietGardenPatch> createState() => _QuietGardenPatchState();
}

class _QuietGardenPatchState extends State<QuietGardenPatch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = getPlantStage(widget.totalNutrients);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Subtle lean: max ±~2.8 degrees (0.05 radians)
                final angle = stage == PlantStage.seed
                    ? 0.0
                    : (_controller.value - 0.5) * 0.05;
                return Transform.rotate(
                  angle: angle,
                  alignment: Alignment.bottomCenter,
                  child: CustomPaint(
                    painter: _GardenPainter(stage: stage),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            getPotSignalMessage(widget.totalNutrients),
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.secondaryText,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
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
    final center = Offset(size.width / 2, size.height);

    // Ground mound — wider for quietTree
    final groundWidth = stage == PlantStage.quietTree ? 70.0 : 60.0;
    final groundPaint = Paint()
      ..color = const Color(0xFF8B7355).withValues(alpha: 0.3);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx, size.height - 5),
          width: groundWidth,
          height: 14),
      groundPaint,
    );

    if (stage == PlantStage.seed) return;

    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF6B8E6B)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    double stemHeight;
    switch (stage) {
      case PlantStage.seed:
        stemHeight = 0;
      case PlantStage.sprout:
        stemHeight = 15;
      case PlantStage.smallLeaf:
        stemHeight = 25;
      case PlantStage.youngPlant:
        stemHeight = 35;
      case PlantStage.quietTree:
        stemHeight = 45;
    }

    final stemBottom = Offset(center.dx, size.height - 10);
    final stemTop = Offset(center.dx, size.height - 10 - stemHeight);
    canvas.drawLine(stemBottom, stemTop, stemPaint);

    // Leaves / canopy
    final leafPaint = Paint()
      ..color = const Color(0xFF7B9E87).withValues(alpha: 0.7);

    if (stage == PlantStage.sprout) {
      // Two tiny elliptical leaves
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(stemTop.dx - 4, stemTop.dy + 2),
            width: 9,
            height: 7),
        leafPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(stemTop.dx + 4, stemTop.dy + 2),
            width: 9,
            height: 7),
        leafPaint,
      );
    } else if (stage == PlantStage.smallLeaf) {
      canvas.drawCircle(Offset(stemTop.dx - 6, stemTop.dy + 3), 6, leafPaint);
      canvas.drawCircle(Offset(stemTop.dx + 6, stemTop.dy + 3), 6, leafPaint);
      canvas.drawCircle(stemTop, 5, leafPaint);
    } else if (stage == PlantStage.youngPlant) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(stemTop.dx, stemTop.dy + 2), width: 24, height: 18),
        leafPaint,
      );
    } else if (stage == PlantStage.quietTree) {
      // Main canopy
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(stemTop.dx, stemTop.dy + 4), width: 36, height: 28),
        leafPaint,
      );
      // Secondary smaller canopy for fullness
      final upperLeafPaint = Paint()
        ..color = const Color(0xFF7B9E87).withValues(alpha: 0.5);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(stemTop.dx, stemTop.dy - 4), width: 22, height: 16),
        upperLeafPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GardenPainter oldDelegate) =>
      oldDelegate.stage != stage;
}
