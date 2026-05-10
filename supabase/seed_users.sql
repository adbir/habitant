-- ============================================================
-- staff_user
-- ============================================================

INSERT INTO staff_user (staff_user_id, email, name, first_name, role) VALUES
  ('550e8400-e29b-41d4-a716-446655441001', 'admin@aab.dk', 'Admin',    'Anna',   'admin'),
  ('550e8400-e29b-41d4-a716-446655441002', 'tech@aab.dk',  'Tekniker', 'Thomas', 'maintenance_staff')
ON CONFLICT (staff_user_id) DO NOTHING;

-- ============================================================
-- staff_housing_access  (both staff members access both housings)
-- ============================================================

INSERT INTO staff_housing_access (staff_user_id, housing_id) VALUES
  ('550e8400-e29b-41d4-a716-446655441001', '6ba7b810-9dad-41d1-80b4-00c04fd430c1'),
  ('550e8400-e29b-41d4-a716-446655441001', '6ba7b810-9dad-41d1-80b4-00c04fd430c2'),
  ('550e8400-e29b-41d4-a716-446655441002', '6ba7b810-9dad-41d1-80b4-00c04fd430c1'),
  ('550e8400-e29b-41d4-a716-446655441002', '6ba7b810-9dad-41d1-80b4-00c04fd430c2')
ON CONFLICT DO NOTHING;

-- ============================================================
-- tenant
-- ============================================================

INSERT INTO tenant (tenant_id, email, current_housing_id, current_address_id, tenant_flags, created) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'lars@example.com',  '6ba7b810-9dad-41d1-80b4-00c04fd430c1', 'a3bb189e-8bf9-4888-9912-ace4e6543001', 1, '2023-03-01'),
  ('550e8400-e29b-41d4-a716-446655440002', 'maria@example.com', '6ba7b810-9dad-41d1-80b4-00c04fd430c1', 'a3bb189e-8bf9-4888-9912-ace4e6543002', 1, '2022-09-15'),
  ('550e8400-e29b-41d4-a716-446655440003', 'peter@example.com', NULL, NULL, 0, '2024-01-10')
ON CONFLICT (tenant_id) DO NOTHING;

-- ============================================================
-- issue
-- ============================================================

INSERT INTO issue (issue_id, tenant_id, address_id, description, status, issue_flags, maintenance_staff_id, created, modified) VALUES
  -- Radiator leak — in_progress, assigned to Thomas
  ('f47ac10b-58cc-4372-a567-0e02b2c3d101',
   '550e8400-e29b-41d4-a716-446655440001',
   'a3bb189e-8bf9-4888-9912-ace4e6543001',
   'Radiator i soveværelset lækker vand ned langs væggen. Det har stået på i ca. en uge.',
   'in_progress', 0, '550e8400-e29b-41d4-a716-446655441002',
   '2024-11-01', '2024-11-03'),

  -- Mold — pending, needs_assistance
  ('f47ac10b-58cc-4372-a567-0e02b2c3d102',
   '550e8400-e29b-41d4-a716-446655440001',
   'a3bb189e-8bf9-4888-9912-ace4e6543001',
   'Kraftig skimmelsvamp i badeværelsets loft og bag toilettet. Lugter kraftigt.',
   'pending', 1, NULL,
   '2024-11-10', '2024-11-10'),

  -- Window handle — completed
  ('f47ac10b-58cc-4372-a567-0e02b2c3d103',
   '550e8400-e29b-41d4-a716-446655440001',
   'a3bb189e-8bf9-4888-9912-ace4e6543001',
   'Håndtag på køkkenvindue er knækket af og kan ikke lukkes ordentligt.',
   'completed', 0, '550e8400-e29b-41d4-a716-446655441002',
   '2024-10-18', '2024-10-22'),

  -- Hood — assigned
  ('f47ac10b-58cc-4372-a567-0e02b2c3d104',
   '550e8400-e29b-41d4-a716-446655440002',
   'a3bb189e-8bf9-4888-9912-ace4e6543002',
   'Emhætten over komfuret er defekt – motoren laver høj støj og suger ikke ordentligt.',
   'assigned', 0, '550e8400-e29b-41d4-a716-446655441002',
   '2024-11-08', '2024-11-08')
ON CONFLICT (issue_id) DO NOTHING;

-- ============================================================
-- maintenance_update
-- ============================================================

INSERT INTO maintenance_update (maintenance_update_id, issue_id, maintenance_staff_id, description, completed_at) VALUES
  ('b14a7b8c-d47b-4734-b301-9e1a2f5c1001',
   'f47ac10b-58cc-4372-a567-0e02b2c3d101',
   '550e8400-e29b-41d4-a716-446655441002',
   'Tilsyn udført. Pakning er slidt og skal udskiftes. Bestiller reservedel.',
   '2024-11-03'),

  ('b14a7b8c-d47b-4734-b301-9e1a2f5c1002',
   'f47ac10b-58cc-4372-a567-0e02b2c3d103',
   '550e8400-e29b-41d4-a716-446655441002',
   'Udskiftet håndtag på alle vinduer i køkkenet med nye beslagsdele.',
   '2024-10-22')
ON CONFLICT (maintenance_update_id) DO NOTHING;

-- ============================================================
-- issue_comment
-- ============================================================

INSERT INTO issue_comment (issue_comment_id, issue_id, author_id, body, issue_comment_flags, created) VALUES
  -- Radiator comments (private then public)
  ('cc000001-0000-0000-0000-000000000001',
   'f47ac10b-58cc-4372-a567-0e02b2c3d101',
   '550e8400-e29b-41d4-a716-446655441002',
   'Bestilt reservedel – forventes leveret fredag.',
   1, '2024-11-04'),

  ('cc000001-0000-0000-0000-000000000002',
   'f47ac10b-58cc-4372-a567-0e02b2c3d101',
   '550e8400-e29b-41d4-a716-446655441002',
   'Hej Lars! Vi har bestilt en ny pakning og forventer at komme forbi fredag den 8. november mellem kl. 10–12.',
   0, '2024-11-04'),

  -- Mold comment (private admin note)
  ('cc000001-0000-0000-0000-000000000003',
   'f47ac10b-58cc-4372-a567-0e02b2c3d102',
   '550e8400-e29b-41d4-a716-446655441001',
   'Dette kræver professionel skimmelbehandling. Hvem kan vi kontakte?',
   1, '2024-11-11'),

  -- Hood comment (private)
  ('cc000001-0000-0000-0000-000000000004',
   'f47ac10b-58cc-4372-a567-0e02b2c3d104',
   '550e8400-e29b-41d4-a716-446655441002',
   'Kigger på det mandag. Skal muligvis bestilles ny motor.',
   1, '2024-11-09')
ON CONFLICT (issue_comment_id) DO NOTHING;
