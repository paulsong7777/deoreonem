/// Quiet plant stage derived from total worry nutrients.
/// This is not a game system. The pot/tree is a calm emotional reflection.
/// Full widget, graphics, and decorations are deferred.

enum PlantStage { seed, sprout, smallLeaf, youngPlant, quietTree }

PlantStage getPlantStage(int totalNutrients) {
  if (totalNutrients >= 15) return PlantStage.quietTree;
  if (totalNutrients >= 7) return PlantStage.youngPlant;
  if (totalNutrients >= 3) return PlantStage.smallLeaf;
  if (totalNutrients >= 1) return PlantStage.sprout;
  return PlantStage.seed;
}

String getPotSignalMessage(int totalNutrients) {
  final stage = getPlantStage(totalNutrients);
  switch (stage) {
    case PlantStage.seed:
      return '아직 내려놓은 걱정은 없습니다.';
    case PlantStage.sprout:
      return '작은 화분에 양분이 조용히 쌓이고 있어요.';
    case PlantStage.smallLeaf:
      return '내려놓은 걱정들이 작은 싹을 틔우고 있어요.';
    case PlantStage.youngPlant:
      return '조용한 잎이 조금씩 자라고 있어요.';
    case PlantStage.quietTree:
      return '내려놓은 걱정들이 조용한 나무가 되고 있어요.';
  }
}
