class TenantProfile {
  final String id;
  final String email;

  /// Full name, populated from housing company records.
  final String? name;

  /// Primary contact phone number supplied during signup.
  final String? phoneNumber;

  /// Secondary phone number (e.g. landline vs mobile from housing records).
  final String? phoneNumberSecondary;

  /// Null until the tenant selects a housing after first login.
  final String? currentHousingId;

  /// Null until the tenant selects an address within their housing.
  final String? currentAddressId;

  /// Opaque identifier from the housing company's own system (e.g. "18" in
  /// the AAB scheme "1-25-1-18"). Null if the company has no such system.
  final String? customerTenantIdentifier;

  final DateTime createdAt;

  const TenantProfile({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.phoneNumberSecondary,
    this.currentHousingId,
    this.currentAddressId,
    this.customerTenantIdentifier,
    required this.createdAt,
  });

  /// Whether the tenant has completed onboarding (housing + address selected).
  bool get isOnboarded =>
      currentHousingId != null && currentAddressId != null;

  TenantProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? phoneNumberSecondary,
    String? currentHousingId,
    String? currentAddressId,
    String? customerTenantIdentifier,
    DateTime? createdAt,
  }) {
    return TenantProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneNumberSecondary: phoneNumberSecondary ?? this.phoneNumberSecondary,
      currentHousingId: currentHousingId ?? this.currentHousingId,
      currentAddressId: currentAddressId ?? this.currentAddressId,
      customerTenantIdentifier:
          customerTenantIdentifier ?? this.customerTenantIdentifier,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TenantProfile.fromJson(Map<String, dynamic> json) {
    return TenantProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      phoneNumberSecondary: json['phoneNumberSecondary'] as String?,
      currentHousingId: json['currentHousingId'] as String?,
      currentAddressId: json['currentAddressId'] as String?,
      customerTenantIdentifier: json['customerTenantIdentifier'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'phoneNumberSecondary': phoneNumberSecondary,
        'currentHousingId': currentHousingId,
        'currentAddressId': currentAddressId,
        'customerTenantIdentifier': customerTenantIdentifier,
        'createdAt': createdAt.toIso8601String(),
      };
}
