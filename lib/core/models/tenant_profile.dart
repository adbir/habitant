class TenantProfile {
  final String id;
  final String email;

  /// Contact phone number supplied during signup. Optional.
  final String? phoneNumber;

  /// Null until the tenant selects a housing after first login.
  final String? currentHousingId;

  /// Null until the tenant selects an address within their housing.
  final String? currentAddressId;

  final DateTime createdAt;

  const TenantProfile({
    required this.id,
    required this.email,
    this.phoneNumber,
    this.currentHousingId,
    this.currentAddressId,
    required this.createdAt,
  });

  /// Whether the tenant has completed onboarding (housing + address selected).
  bool get isOnboarded =>
      currentHousingId != null && currentAddressId != null;

  TenantProfile copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? currentHousingId,
    String? currentAddressId,
    DateTime? createdAt,
  }) {
    return TenantProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      currentHousingId: currentHousingId ?? this.currentHousingId,
      currentAddressId: currentAddressId ?? this.currentAddressId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TenantProfile.fromJson(Map<String, dynamic> json) {
    return TenantProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      currentHousingId: json['currentHousingId'] as String?,
      currentAddressId: json['currentAddressId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phoneNumber': phoneNumber,
        'currentHousingId': currentHousingId,
        'currentAddressId': currentAddressId,
        'createdAt': createdAt.toIso8601String(),
      };
}
