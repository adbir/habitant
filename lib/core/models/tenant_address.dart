class TenantAddress {
  final String id;
  final String addressLine;
  final String housingId;
  final bool isMovedOut;
  final DateTime? movedOutAt;
  final DateTime createdAt;

  const TenantAddress({
    required this.id,
    required this.addressLine,
    required this.housingId,
    required this.isMovedOut,
    this.movedOutAt,
    required this.createdAt,
  });

  TenantAddress copyWith({
    String? id,
    String? addressLine,
    String? housingId,
    bool? isMovedOut,
    DateTime? movedOutAt,
    DateTime? createdAt,
  }) {
    return TenantAddress(
      id: id ?? this.id,
      addressLine: addressLine ?? this.addressLine,
      housingId: housingId ?? this.housingId,
      isMovedOut: isMovedOut ?? this.isMovedOut,
      movedOutAt: movedOutAt ?? this.movedOutAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TenantAddress.fromJson(Map<String, dynamic> json) {
    return TenantAddress(
      id: json['id'] as String,
      addressLine: json['addressLine'] as String,
      housingId: json['housingId'] as String,
      isMovedOut: json['isMovedOut'] as bool? ?? false,
      movedOutAt: json['movedOutAt'] != null
          ? DateTime.parse(json['movedOutAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'addressLine': addressLine,
        'housingId': housingId,
        'isMovedOut': isMovedOut,
        'movedOutAt': movedOutAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
