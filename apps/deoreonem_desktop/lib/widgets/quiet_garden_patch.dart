import 'package:flutter/material.dart';
import '../services/plant_stage_helper.dart';
import '../theme.dart';

/// A small calm garden visual that represents the plant stage.
/// Uses simple CustomPaint for a ground patch with a sprout/tree.
class QuietGardenPatch extends StatelessWidget {
  final int totalNutrients;

  const QuietGardenPatch({super.key, required this.totalNutrients});

  @override
  Widget build(BuildContext context) {
    final stage = getPlantStage(totalNutrients);

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
          // Simple visual based on stage
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _GardenPainter(stage: stage),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getGardenMessage(totalNutrients),
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

  String _getGardenMessage(int nutrients) {
    return getPotSignalMessage(nutrients);
  }
}

class _GardenPainter extends CustomPainter {
  final PlantStage stage;

  _GardenPainter({required this.stage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);

    // Ground mound
    final groundPaint = Paint()
      ..color = const Color(0xFF8B7355).withValues(alpha: 0.3);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx, size.height - 5), width: 60, height: 14),
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
      // Two tiny leaves
      canvas.drawCircle(Offset(stemTop.dx - 4, stemTop.dy + 2), 4, leafPaint);
      canvas.drawCircle(Offset(stemTop.dx + 4, stemTop.dy + 2), 4, leafPaint);
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
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(stemTop.dx, stemTop.dy + 4), width: 36, height: 28),
        leafPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GardenPainter oldDelegate) =>
      oldDelegate.stage != stage;
}
