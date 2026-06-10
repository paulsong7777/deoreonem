import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/models/session_model.dart';

void main() {
  group('SessionModel', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        'sessionId': '550e8400-e29b-41d4-a716-446655440000',
        'status': 'IN_PROGRESS',
        'firstActionItemId': null,
        'createdAt': '2026-06-09T18:30:00Z',
        'updatedAt': '2026-06-09T18:30:00Z',
      };

      final model = SessionModel.fromJson(json);

      expect(model.sessionId, '550e8400-e29b-41d4-a716-446655440000');
      expect(model.status, 'IN_PROGRESS');
      expect(model.firstActionItemId, isNull);
      expect(model.createdAt, DateTime.utc(2026, 6, 9, 18, 30, 0));
      expect(model.updatedAt, DateTime.utc(2026, 6, 9, 18, 30, 0));
    });

    test('fromJson parses with firstActionItemId', () {
      final json = {
        'sessionId': '550e8400-e29b-41d4-a716-446655440000',
        'status': 'COMPLETED',
        'firstActionItemId': '661e8400-e29b-41d4-a716-446655440001',
        'createdAt': '2026-06-09T18:30:00Z',
        'updatedAt': '2026-06-09T18:45:00Z',
      };

      final model = SessionModel.fromJson(json);

      expect(model.firstActionItemId, '661e8400-e29b-41d4-a716-446655440001');
      expect(model.status, 'COMPLETED');
    });

    test('copyWith creates new instance with updated fields', () {
      final model = SessionModel(
        sessionId: 'abc',
        status: 'IN_PROGRESS',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final updated = model.copyWith(status: 'COMPLETED');

      expect(updated.status, 'COMPLETED');
      expect(updated.sessionId, 'abc');
    });
  });
}
