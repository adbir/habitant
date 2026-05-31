import 'address.dart';

/// An invitation that grants one or more tenants the right to sign up for
/// a specific address without going through the open housing/address picker.
///
/// A single invitation token is tied to an [Address]. All residents of the
/// same apartment share the same token link — each registers with their own
/// email and password.
class Invitation {
  final String id;
  final String token;
  final String addressId;
  final DateTime expiresAt;

  /// The pre-assigned address, populated when fetched with a joined query.
  final Address? address;

  /// The housing name, populated from the nested housing join.
  final String? housingName;

  const Invitation({
    required this.id,
    required this.token,
    required this.addressId,
    required this.expiresAt,
    this.address,
    this.housingName,
  });

  /// Whether the invitation has passed its expiry date.
  bool get isExpired => expiresAt.isBefore(DateTime.now().toUtc());

  factory Invitation.fromRow(Map<String, dynamic> row) {
    final addressRow = row['address'] as Map<String, dynamic>?;
    final housingRow = addressRow?['housing'] as Map<String, dynamic>?;

    Address? address;
    if (addressRow != null) {
      final flags = addressRow['address_flags'] as int? ?? 0;
      address = Address(
        id: addressRow['address_id'] as String,
        housingId: addressRow['housing_id'] as String,
        street: addressRow['street'] as String,
        number: addressRow['number'] as String,
        floor: addressRow['floor'] as String?,
        side: addressRow['side'] as String?,
        postalCode: addressRow['postal_code'] as String,
        city: addressRow['city'] as String,
        isOccupied: (flags & 1) == 1,
        history: const [],
      );
    }

    return Invitation(
      id: row['invitation_id'] as String,
      token: row['token'] as String,
      addressId: row['address_id'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String),
      address: address,
      housingName: housingRow?['name'] as String?,
    );
  }
}
