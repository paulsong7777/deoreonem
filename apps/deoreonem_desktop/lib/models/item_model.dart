class ItemModel {
  final String itemId;
  final String sessionId;
  final String content;
  final String? category;
  final bool isFirstAction;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemModel({
    required this.itemId,
    required this.sessionId,
    required this.content,
    this.category,
    required this.isFirstAction,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
        itemId: json['itemId'],
        sessionId: json['sessionId'],
        content: json['content'],
        category: json['category'],
        isFirstAction: json['isFirstAction'] ?? false,
        sortOrder: json['sortOrder'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'sessionId': sessionId,
        'content': content,
        'category': category,
        'isFirstAction': isFirstAction,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  ItemModel copyWith({String? category, bool? isFirstAction}) => ItemModel(
        itemId: itemId,
        sessionId: sessionId,
        content: content,
        category: category ?? this.category,
        isFirstAction: isFirstAction ?? this.isFirstAction,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
