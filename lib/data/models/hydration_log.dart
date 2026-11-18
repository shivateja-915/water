class HydrationLog {
  final String id;
  final String userId;
  final String? drinkTypeId;
  final int amountMl;
  final int hydratedMl;
  final DateTime loggedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined fields (not stored, populated from drink_types)
  final String? drinkTypeName;
  final String? drinkTypeIcon;
  final String? drinkTypeColor;

  const HydrationLog({
    required this.id,
    required this.userId,
    this.drinkTypeId,
    required this.amountMl,
    required this.hydratedMl,
    required this.loggedAt,
    this.createdAt,
    this.updatedAt,
    this.drinkTypeName,
    this.drinkTypeIcon,
    this.drinkTypeColor,
  });

  factory HydrationLog.fromJson(Map<String, dynamic> json) {
    // Handle nested drink_types join
    final drinkType = json['drink_types'] as Map<String, dynamic>?;

    return HydrationLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      drinkTypeId: json['drink_type_id'] as String?,
      amountMl: json['amount_ml'] as int,
      hydratedMl: json['hydrated_ml'] as int,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      drinkTypeName: drinkType?['name'] as String?,
      drinkTypeIcon: drinkType?['icon'] as String?,
      drinkTypeColor: drinkType?['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'drink_type_id': drinkTypeId,
      'amount_ml': amountMl,
      'hydrated_ml': hydratedMl,
      'logged_at': loggedAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  HydrationLog copyWith({
    String? id,
    String? userId,
    String? drinkTypeId,
    int? amountMl,
    int? hydratedMl,
    DateTime? loggedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? drinkTypeName,
    String? drinkTypeIcon,
    String? drinkTypeColor,
  }) {
    return HydrationLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      drinkTypeId: drinkTypeId ?? this.drinkTypeId,
      amountMl: amountMl ?? this.amountMl,
      hydratedMl: hydratedMl ?? this.hydratedMl,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      drinkTypeName: drinkTypeName ?? this.drinkTypeName,
      drinkTypeIcon: drinkTypeIcon ?? this.drinkTypeIcon,
      drinkTypeColor: drinkTypeColor ?? this.drinkTypeColor,
    );
  }
}
