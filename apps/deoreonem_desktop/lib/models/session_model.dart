class SessionModel {
  final String sessionId;
  final String status;
  final String? firstActionItemId;
  final DateTime createdAt;
  final DateTime updatedAt;

  SessionModel({
    required this.sessionId,
    required this.status,
    this.firstActionItemId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        sessionId: json['sessionId'],
        status: json['status'],
        firstActionItemId: json['firstActionItemId'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  SessionModel copyWith({
    String? sessionId,
    String? status,
    String? firstActionItemId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SessionModel(
        sessionId: sessionId ?? this.sessionId,
        status: status ?? this.status,
        firstActionItemId: firstActionItemId ?? this.firstActionItemId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
