import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/widgets/quiet_garden_patch.dart';

void main() {
  group('QuietGardenPatch', () {
    for (final n in [0, 1, 3, 7, 15]) {
      testWidgets('builds for $n nutrients', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: QuietGardenPatch(totalNutrients: n)),
        );
        expect(find.byType(QuietGardenPatch), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      });
    }

    testWidgets('messages do not contain game-like terms', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: QuietGardenPatch(totalNutrients: 5)),
      );
      // Should not find game terms
      expect(find.textContaining('레벨'), findsNothing);
      expect(find.textContaining('보상'), findsNothing);
      expect(find.textContaining('퀘스트'), findsNothing);
    });
  });
}
