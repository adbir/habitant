/// A historical record of a single tenancy at an [Address].
///
/// Used by administrators to track who lived at an address and what issues
/// were reported during their stay — making it possible to verify whether
/// problems were resolved before a new tenant moved in.
class TenancyRecord {
  final String tenantId;
  final DateTime movedInAt;
  final DateTime? movedOutAt;

  /// IDs of issues reported by the tenant during this tenancy.
  final List<String> issueIds;

  const TenancyRecord({
    required this.tenantId,
    required this.movedInAt,
    this.movedOutAt,
    required this.issueIds,
  });

  /// Whether this tenancy is currently active.
  bool get isActive => movedOutAt == null;

  TenancyRecord copyWith({
    String? tenantId,
    DateTime? movedInAt,
    DateTime? movedOutAt,
    List<String>? issueIds,
  }) {
    return TenancyRecord(
      tenantId: tenantId ?? this.tenantId,
      movedInAt: movedInAt ?? this.movedInAt,
      movedOutAt: movedOutAt ?? this.movedOutAt,
      issueIds: issueIds ?? this.issueIds,
    );
  }

  factory TenancyRecord.fromJson(Map<String, dynamic> json) {
    return TenancyRecord(
      tenantId: json['tenantId'] as String,
      movedInAt: DateTime.parse(json['movedInAt'] as String),
      movedOutAt: json['movedOutAt'] != null
          ? DateTime.parse(json['movedOutAt'] as String)
          : null,
      issueIds: List<String>.from(json['issueIds'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenantId': tenantId,
        'movedInAt': movedInAt.toIso8601String(),
        'movedOutAt': movedOutAt?.toIso8601String(),
        'issueIds': issueIds,
      };
}

/// A physical dwelling unit within a [Housing].
///
/// Models the Danish address format, e.g.:
/// - Rentemestervej 23, 1 tv, 2400 København NV
/// - Tomsgårdsvej 157, st tv, 2400 København NV
///
/// [floor] uses Danish conventions: "st" (stuen/ground), "kl"
/// (kælder/basement), or a floor number. [side] is "tv" (venstre/left),
/// "th" (højre/right), or "mf" (midterfor/middle).
class Address {
  final String id;
  final String housingId;
  final String street;
  final String number;
  final String? floor;
  final String? side;
  final String postalCode;
  final String city;
  final bool isOccupied;

  /// Full tenancy history, visible to administrators only.
  final List<TenancyRecord> history;

  const Address({
    required this.id,
    required this.housingId,
    required this.street,
    required this.number,
    this.floor,
    this.side,
    required this.postalCode,
    required this.city,
    required this.isOccupied,
    required this.history,
  });

  /// The full formatted Danish address string including postal code and city.
  String get displayAddress {
    final base = '$street $number';
    final apartment = [floor, side].whereType<String>().join(' ');
    final location = '$postalCode $city';
    return apartment.isEmpty
        ? '$base, $location'
        : '$base, $apartment, $location';
  }

  /// Street, number, and apartment only — use when the housing context
  /// is already shown (e.g. "Rentemestervej 23, st tv").
  String get shortDisplayAddress {
    final base = '$street $number';
    final apartment = [floor, side].whereType<String>().join(' ');
    return apartment.isEmpty ? base : '$base, $apartment';
  }

  Address copyWith({
    String? id,
    String? housingId,
    String? street,
    String? number,
    String? floor,
    String? side,
    String? postalCode,
    String? city,
    bool? isOccupied,
    List<TenancyRecord>? history,
  }) {
    return Address(
      id: id ?? this.id,
      housingId: housingId ?? this.housingId,
      street: street ?? this.street,
      number: number ?? this.number,
      floor: floor ?? this.floor,
      side: side ?? this.side,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      isOccupied: isOccupied ?? this.isOccupied,
      history: history ?? this.history,
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      housingId: json['housingId'] as String,
      street: json['street'] as String,
      number: json['number'] as String,
      floor: json['floor'] as String?,
      side: json['side'] as String?,
      postalCode: json['postalCode'] as String,
      city: json['city'] as String,
      isOccupied: json['isOccupied'] as bool? ?? false,
      history: (json['history'] as List<dynamic>? ?? [])
          .map((r) => TenancyRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'housingId': housingId,
        'street': street,
        'number': number,
        'floor': floor,
        'side': side,
        'postalCode': postalCode,
        'city': city,
        'isOccupied': isOccupied,
        'history': history.map((r) => r.toJson()).toList(),
      };
}
