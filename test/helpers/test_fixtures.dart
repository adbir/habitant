import 'package:beboer_app/core/models/address.dart';
import 'package:beboer_app/core/models/invitation.dart';

/// A valid [Address] for use in tests.
final testAddress = Address(
  id: 'address-1',
  housingId: 'housing-1',
  street: 'Rentemestervej',
  number: '23',
  floor: '1',
  side: 'tv',
  postalCode: '2400',
  city: 'København NV',
  isOccupied: false,
  history: const [],
);

/// A valid, non-expired [Invitation] for use in tests.
final testInvitation = Invitation(
  id: 'inv-1',
  token: 'test-token-uuid',
  addressId: testAddress.id,
  expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
  address: testAddress,
  housingName: 'AAB Afdeling 25',
);

/// An expired [Invitation] for use in tests.
final expiredInvitation = Invitation(
  id: 'inv-expired',
  token: 'expired-token',
  addressId: testAddress.id,
  expiresAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
  address: testAddress,
  housingName: 'AAB Afdeling 25',
);
