-- Development seed data.
-- UUIDs match FakeApiClient so local dev and Supabase data are consistent.
--
-- Staff and tenant accounts are NOT seeded here because they require matching
-- rows in auth.users. Create them via the Supabase dashboard:
--   Authentication → Users → Add user
-- Then insert matching rows in staff_user / tenant using the UUID Supabase assigns.

-- ============================================================
-- housing
-- ============================================================

INSERT INTO housing (housing_id, name, city, created, modified) VALUES
  ('6ba7b810-9dad-41d1-80b4-00c04fd430c1', 'AAB Nørrebro',      'København NV', NOW(), NOW()),
  ('6ba7b810-9dad-41d1-80b4-00c04fd430c2', 'KAB Frederiksberg',  'Frederiksberg', NOW(), NOW())
ON CONFLICT (housing_id) DO NOTHING;

-- ============================================================
-- address
-- ============================================================

INSERT INTO address (address_id, street, number, floor, side, postal_code, city, housing_id, address_flags) VALUES
  -- AAB Nørrebro
  ('a3bb189e-8bf9-4888-9912-ace4e6543001', 'Rentemestervej', '23',  '1',  'tv', '2400', 'København NV', '6ba7b810-9dad-41d1-80b4-00c04fd430c1', 1),
  ('a3bb189e-8bf9-4888-9912-ace4e6543002', 'Rentemestervej', '23',  '1',  'th', '2400', 'København NV', '6ba7b810-9dad-41d1-80b4-00c04fd430c1', 1),
  ('a3bb189e-8bf9-4888-9912-ace4e6543003', 'Tomsgårdsvej',   '157', 'st', 'tv', '2400', 'København NV', '6ba7b810-9dad-41d1-80b4-00c04fd430c1', 0),
  ('a3bb189e-8bf9-4888-9912-ace4e6543004', 'Tomsgårdsvej',   '157', '2',  'th', '2400', 'København NV', '6ba7b810-9dad-41d1-80b4-00c04fd430c1', 0),
  -- KAB Frederiksberg
  ('a3bb189e-8bf9-4888-9912-ace4e6543005', 'Falkoner Allé',  '20',  'st', 'th', '2000', 'Frederiksberg', '6ba7b810-9dad-41d1-80b4-00c04fd430c2', 0),
  ('a3bb189e-8bf9-4888-9912-ace4e6543006', 'Falkoner Allé',  '20',  '1',  'tv', '2000', 'Frederiksberg', '6ba7b810-9dad-41d1-80b4-00c04fd430c2', 0)
ON CONFLICT (address_id) DO NOTHING;
