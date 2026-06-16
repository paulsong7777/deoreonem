/// 9-stage quiet plant growth system derived from total worry nutrients.
/// This is not a game system. The pot/tree is a calm emotional reflection.

enum PlantStage {
  seed,        // 1. 씨앗 - 작은 씨앗
  sprout,      // 2. 새싹 - 첫 생명의 기운
  youngTree,   // 3. 어린 나무 - 조용히 자라는 시간
  youngTreePlus, // 4. 어린 나무+ - 기반을 다지는 단계
  greenTree,   // 5. 푸른 나무 - 자연스럽게 풍성해짐
  growingTree, // 6. 자라나는 나무 - 가지와 잎이 넓어짐
  strongTree,  // 7. 튼튼한 나무 - 미세한 연속이 깊어짐
  bigTree,     // 8. 큰 나무 - 더 넓은 따뜻함
  quietTree,   // 9. 조용한 나무 - 완성된 반응 특색
}

PlantStage getPlantStage(int totalNutrients) {
  if (totalNutrients >= 40) return PlantStage.quietTree;
  if (totalNutrients >= 30) return PlantStage.bigTree;
  if (totalNutrients >= 22) return PlantStage.strongTree;
  if (totalNutrients >= 16) return PlantStage.growingTree;
  if (totalNutrients >= 11) return PlantStage.greenTree;
  if (totalNutrients >= 7) return PlantStage.youngTreePlus;
  if (totalNutrients >= 4) return PlantStage.youngTree;
  if (totalNutrients >= 1) return PlantStage.sprout;
  return PlantStage.seed;
}

String getPotSignalMessage(int totalNutrients) {
  final stage = getPlantStage(totalNutrients);
  switch (stage) {
    case PlantStage.seed:
      return '아직 내려놓은 걱정은 없습니다.';
    case PlantStage.sprout:
      return '조용한 나무가 싹을 틔우고 있어요.';
    case PlantStage.youngTree:
      return '조용한 나무가 조금씩 자라고 있어요.';
    case PlantStage.youngTreePlus:
      return '조용한 나무가 기반을 다지고 있어요.';
    case PlantStage.greenTree:
      return '조용한 나무가 풍성해지고 있어요.';
    case PlantStage.growingTree:
      return '조용한 나무가 넓어지고 있어요.';
    case PlantStage.strongTree:
      return '조용한 나무가 깊어지고 있어요.';
    case PlantStage.bigTree:
      return '조용한 나무가 따뜻해지고 있어요.';
    case PlantStage.quietTree:
      return '내려놓은 걱정들이 조용한 나무가 되었어요.';
  }
}
