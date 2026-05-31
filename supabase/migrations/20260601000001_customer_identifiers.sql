-- Opaque string identifiers from the housing company's own system.
-- Both are nullable since not all companies use such identifiers,
-- and existing rows are back-filled manually.

ALTER TABLE address
  ADD COLUMN customer_apartment_identifier VARCHAR(64);

ALTER TABLE tenant
  ADD COLUMN name                       TEXT,
  ADD COLUMN phone_number_secondary     VARCHAR(32),
  ADD COLUMN customer_tenant_identifier VARCHAR(64);
