class ContainerPreset {
  final String id;
  final String userId;
  final String name;
  final int amountMl;
  final DateTime? createdAt;

  const ContainerPreset({
    required this.id,
    required this.userId,
    required this.name,
    required this.amountMl,
    this.createdAt,
  });

  factory ContainerPreset.fromJson(Map<String, dynamic> json) {
    return ContainerPreset(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      amountMl: json['amount_ml'] as int,
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
      'amount_ml': amountMl,
    };
  }

  ContainerPreset copyWith({
    String? id,
    String? userId,
    String? name,
    int? amountMl,
  }) {
    return ContainerPreset(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amountMl: amountMl ?? this.amountMl,
    );
  }
}
