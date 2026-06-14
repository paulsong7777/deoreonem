import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/services/plant_stage_helper.dart';

void main() {
  group('Plant stage helper', () {
    test('0 nutrients → seed', () {
      expect(getPlantStage(0), PlantStage.seed);
    });

    test('1 nutrient → sprout', () {
      expect(getPlantStage(1), PlantStage.sprout);
    });

    test('2 nutrients → sprout', () {
      expect(getPlantStage(2), PlantStage.sprout);
    });

    test('3 nutrients → smallLeaf', () {
      expect(getPlantStage(3), PlantStage.smallLeaf);
    });

    test('6 nutrients → smallLeaf', () {
      expect(getPlantStage(6), PlantStage.smallLeaf);
    });

    test('7 nutrients → youngPlant', () {
      expect(getPlantStage(7), PlantStage.youngPlant);
    });

    test('14 nutrients → youngPlant', () {
      expect(getPlantStage(14), PlantStage.youngPlant);
    });

    test('15 nutrients → quietTree', () {
      expect(getPlantStage(15), PlantStage.quietTree);
    });

    test('100 nutrients → quietTree', () {
      expect(getPlantStage(100), PlantStage.quietTree);
    });

    test('pot signal message for seed', () {
      expect(getPotSignalMessage(0), '아직 내려놓은 걱정은 없습니다.');
    });

    test('pot signal message for sprout', () {
      expect(getPotSignalMessage(1), '내려놓은 걱정이 작은 자리에 스며들고 있어요.');
    });

    test('pot signal message for smallLeaf', () {
      expect(getPotSignalMessage(5), '작은 싹이 조용히 자라고 있어요.');
    });

    test('pot signal message for youngPlant', () {
      expect(getPotSignalMessage(10), '조용한 잎이 조금씩 자라고 있어요.');
    });

    test('pot signal message for quietTree', () {
      expect(getPotSignalMessage(20), '내려놓은 걱정들이 조용한 나무가 되고 있어요.');
    });

    test('messages do not contain game-like terms', () {
      for (int i = 0; i <= 20; i++) {
        final msg = getPotSignalMessage(i);
        expect(msg.contains('레벨'), false);
        expect(msg.contains('Level'), false);
        expect(msg.contains('EXP'), false);
        expect(msg.contains('보상'), false);
        expect(msg.contains('퀘스트'), false);
        expect(msg.contains('업적'), false);
        expect(msg.contains('스트릭'), false);
      }
    });
  });
}
