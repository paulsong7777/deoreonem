import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/garden_overlay.dart';

void main() {
  group('isValidOverlayPosition', () {
    test('rejects negative x', () {
      expect(isValidOverlayPosition(-1, 100), isFalse);
    });

    test('rejects negative y', () {
      expect(isValidOverlayPosition(100, -1), isFalse);
    });

    test('rejects both negative', () {
      expect(isValidOverlayPosition(-10, -20), isFalse);
    });

    test('rejects x exceeding upper bound', () {
      expect(isValidOverlayPosition(4001, 100), isFalse);
    });

    test('rejects y exceeding upper bound', () {
      expect(isValidOverlayPosition(100, 3001), isFalse);
    });

    test('accepts valid position at origin', () {
      expect(isValidOverlayPosition(0, 0), isTrue);
    });

    test('accepts valid mid-screen position', () {
      expect(isValidOverlayPosition(500, 300), isTrue);
    });

    test('accepts position at upper bounds', () {
      expect(isValidOverlayPosition(4000, 3000), isTrue);
    });
  });
}
