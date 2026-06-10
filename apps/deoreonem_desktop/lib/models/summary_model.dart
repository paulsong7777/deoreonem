import 'item_model.dart';

class SummaryModel {
  final String sessionId;
  final String status;
  final int totalItems;
  final ItemModel? firstActionItem;
  final Map<String, List<ItemModel>> itemsByCategory;

  SummaryModel({
    required this.sessionId,
    required this.status,
    required this.totalItems,
    this.firstActionItem,
    required this.itemsByCategory,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    final categoriesJson = json['itemsByCategory'] as Map<String, dynamic>;
    final itemsByCategory = categoriesJson.map((key, value) => MapEntry(
        key, (value as List).map((e) => ItemModel.fromJson(e)).toList()));

    ItemModel? firstAction;
    if (json['firstActionItem'] != null) {
      firstAction = ItemModel.fromJson(json['firstActionItem']);
    }

    return SummaryModel(
      sessionId: json['sessionId'],
      status: json['status'],
      totalItems: json['totalItems'],
      firstActionItem: firstAction,
      itemsByCategory: itemsByCategory,
    );
  }
}
