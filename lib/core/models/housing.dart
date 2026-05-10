import 'address.dart';
import 'user_role.dart';

class Housing {
  final String id;
  final String name;
  final String city;
  final List<Address> addresses;
  final DateTime createdAt;

  const Housing({
    required this.id,
    required this.name,
    required this.city,
    required this.addresses,
    required this.createdAt,
  });

  Housing copyWith({
    String? id,
    String? name,
    String? city,
    List<Address>? addresses,
    DateTime? createdAt,
  }) {
    return Housing(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Housing.fromJson(Map<String, dynamic> json) {
    return Housing(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      addresses: (json['addresses'] as List<dynamic>? ?? [])
          .map((a) => Address.fromJson(a as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'addresses': addresses.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class StaffUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final List<String> accessibleHousingIds;
  final DateTime createdAt;

  const StaffUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.accessibleHousingIds,
    required this.createdAt,
  });

  StaffUser copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    List<String>? accessibleHousingIds,
    DateTime? createdAt,
  }) {
    return StaffUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      accessibleHousingIds: accessibleHousingIds ?? this.accessibleHousingIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.admin,
      ),
      accessibleHousingIds:
          List<String>.from(json['accessibleHousingIds'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.name,
        'accessibleHousingIds': accessibleHousingIds,
        'createdAt': createdAt.toIso8601String(),
      };
}
