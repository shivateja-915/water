class DrinkType {
  final String id;
  final String? userId;
  final String name;
  final String icon;
  final String color;
  final double hydrationMultiplier;
  final bool isDefault;
  final bool isActive;
  final DateTime? createdAt;

  const DrinkType({
    required this.id,
    this.userId,
    required this.name,
    this.icon = 'water_drop',
    this.color = '#004ac6',
    this.hydrationMultiplier = 1.0,
    this.isDefault = false,
    this.isActive = true,
    this.createdAt,
  });

  factory DrinkType.fromJson(Map<String, dynamic> json) {
    return DrinkType(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'water_drop',
      color: json['color'] as String? ?? '#004ac6',
      hydrationMultiplier:
          (json['hydration_multiplier'] as num?)?.toDouble() ?? 1.0,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'hydration_multiplier': hydrationMultiplier,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }

  DrinkType copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    double? hydrationMultiplier,
    bool? isDefault,
    bool? isActive,
  }) {
    return DrinkType(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      hydrationMultiplier: hydrationMultiplier ?? this.hydrationMultiplier,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }
}
