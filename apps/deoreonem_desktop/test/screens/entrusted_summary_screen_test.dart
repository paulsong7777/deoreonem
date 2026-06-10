import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/screens/entrusted_summary_screen.dart';

void main() {
  testWidgets(
      'EntrustedSummaryScreen shows title, total count, and complete button',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: EntrustedSummaryScreen()));

    expect(find.text('오늘의 덜어냄'), findsOneWidget);
    expect(find.textContaining('맡겼습니다'), findsOneWidget);
    expect(find.text('완료하기'), findsOneWidget);
  });
}
