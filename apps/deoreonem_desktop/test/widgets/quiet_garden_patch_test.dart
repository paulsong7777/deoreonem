import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/widgets/quiet_garden_patch.dart';

void main() {
  group('QuietGardenPatch', () {
    for (final n in [0, 1, 4, 7, 11, 16, 22, 30, 40]) {
      testWidgets('builds for $n nutrients', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: QuietGardenPatch(totalNutrients: n)),
        );
        await tester.pump();
        expect(find.byType(QuietGardenPatch), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      });
    }

    testWidgets('messages do not contain game-like terms', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: QuietGardenPatch(totalNutrients: 5)),
      );
      await tester.pump();
      expect(find.textContaining('레벨'), findsNothing);
      expect(find.textContaining('보상'), findsNothing);
      expect(find.textContaining('퀘스트'), findsNothing);
    });

    testWidgets('animation controller initializes without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: QuietGardenPatch(totalNutrients: 10)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(QuietGardenPatch), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('hover interaction via MouseRegion', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: QuietGardenPatch(totalNutrients: 20)),
      );
      await tester.pump();
      expect(find.byType(MouseRegion), findsWidgets);
    });
  });
}
