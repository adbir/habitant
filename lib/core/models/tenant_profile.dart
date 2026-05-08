import 'tenant_address.dart';

class TenantProfile {
  final String id;
  final String email;
  final String currentHousingId;
  final String currentFavoriteAddressId;
  final List<TenantAddress> addressHistory;
  final DateTime createdAt;

  const TenantProfile({
    required this.id,
    required this.email,
    required this.currentHousingId,
    required this.currentFavoriteAddressId,
    required this.addressHistory,
    required this.createdAt,
  });

  TenantProfile copyWith({
    String? id,
    String? email,
    String? currentHousingId,
    String? currentFavoriteAddressId,
    List<TenantAddress>? addressHistory,
    DateTime? createdAt,
  }) {
    return TenantProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      currentHousingId: currentHousingId ?? this.currentHousingId,
      currentFavoriteAddressId:
          currentFavoriteAddressId ?? this.currentFavoriteAddressId,
      addressHistory: addressHistory ?? this.addressHistory,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  TenantAddress get currentFavoriteAddress =>
      addressHistory.firstWhere(
        (addr) => addr.id == currentFavoriteAddressId,
        orElse: () => throw StateError('Current address not found'),
      );

  factory TenantProfile.fromJson(Map<String, dynamic> json) {
    return TenantProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      currentHousingId: json['currentHousingId'] as String,
      currentFavoriteAddressId: json['currentFavoriteAddressId'] as String,
      addressHistory: (json['addressHistory'] as List<dynamic>)
          .map(
            (addr) => TenantAddress.fromJson(addr as Map<String, dynamic>),
          )
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'currentHousingId': currentHousingId,
        'currentFavoriteAddressId': currentFavoriteAddressId,
        'addressHistory': addressHistory.map((addr) => addr.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}
