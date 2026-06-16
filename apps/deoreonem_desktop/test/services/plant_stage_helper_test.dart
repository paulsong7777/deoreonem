import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/services/plant_stage_helper.dart';

void main() {
  group('Plant stage helper — 9-stage growth system', () {
    test('0 nutrients → seed', () {
      expect(getPlantStage(0), PlantStage.seed);
    });

    test('1 nutrient → sprout', () {
      expect(getPlantStage(1), PlantStage.sprout);
    });

    test('3 nutrients → sprout', () {
      expect(getPlantStage(3), PlantStage.sprout);
    });

    test('4 nutrients → youngTree', () {
      expect(getPlantStage(4), PlantStage.youngTree);
    });

    test('6 nutrients → youngTree', () {
      expect(getPlantStage(6), PlantStage.youngTree);
    });

    test('7 nutrients → youngTreePlus', () {
      expect(getPlantStage(7), PlantStage.youngTreePlus);
    });

    test('10 nutrients → youngTreePlus', () {
      expect(getPlantStage(10), PlantStage.youngTreePlus);
    });

    test('11 nutrients → greenTree', () {
      expect(getPlantStage(11), PlantStage.greenTree);
    });

    test('15 nutrients → greenTree', () {
      expect(getPlantStage(15), PlantStage.greenTree);
    });

    test('16 nutrients → growingTree', () {
      expect(getPlantStage(16), PlantStage.growingTree);
    });

    test('21 nutrients → growingTree', () {
      expect(getPlantStage(21), PlantStage.growingTree);
    });

    test('22 nutrients → strongTree', () {
      expect(getPlantStage(22), PlantStage.strongTree);
    });

    test('29 nutrients → strongTree', () {
      expect(getPlantStage(29), PlantStage.strongTree);
    });

    test('30 nutrients → bigTree', () {
      expect(getPlantStage(30), PlantStage.bigTree);
    });

    test('39 nutrients → bigTree', () {
      expect(getPlantStage(39), PlantStage.bigTree);
    });

    test('40 nutrients → quietTree', () {
      expect(getPlantStage(40), PlantStage.quietTree);
    });

    test('100 nutrients → quietTree', () {
      expect(getPlantStage(100), PlantStage.quietTree);
    });

    test('pot signal message for seed', () {
      expect(getPotSignalMessage(0), '아직 내려놓은 걱정은 없습니다.');
    });

    test('pot signal message for sprout', () {
      expect(getPotSignalMessage(1), '조용한 나무가 싹을 틔우고 있어요.');
    });

    test('pot signal message for youngTree', () {
      expect(getPotSignalMessage(5), '조용한 나무가 조금씩 자라고 있어요.');
    });

    test('pot signal message for youngTreePlus', () {
      expect(getPotSignalMessage(8), '조용한 나무가 기반을 다지고 있어요.');
    });

    test('pot signal message for greenTree', () {
      expect(getPotSignalMessage(12), '조용한 나무가 풍성해지고 있어요.');
    });

    test('pot signal message for growingTree', () {
      expect(getPotSignalMessage(18), '조용한 나무가 넓어지고 있어요.');
    });

    test('pot signal message for strongTree', () {
      expect(getPotSignalMessage(25), '조용한 나무가 깊어지고 있어요.');
    });

    test('pot signal message for bigTree', () {
      expect(getPotSignalMessage(35), '조용한 나무가 따뜻해지고 있어요.');
    });

    test('pot signal message for quietTree', () {
      expect(getPotSignalMessage(50), '내려놓은 걱정들이 조용한 나무가 되었어요.');
    });

    test('messages do not contain game-like terms', () {
      for (int i = 0; i <= 50; i++) {
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
