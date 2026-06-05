# Habitant — task backlog

Status markers: `[ ]` todo · `[~]` in progress · `[x]` done · `[-]` deferred

---

## Housing detail — scale for 275 units / 1000 issues

Current screen dumps everything into one list. Needs tabs + server-side
filtering + pagination before it hits real data.

- [x] **Add TabBar to HousingDetailScreen** — `DefaultTabController(length:2)`,
  city + `TabBar` in AppBar bottom, `TabBarView` with `_UnitsTab` and
  `_IssuesTab`. `_SectionHeader` removed.

- [x] **Server-side issue status filter + pagination** — `getHousingIssues`
  now takes `{Set<IssueStatus>? statuses, int page, int pageSize}` and returns
  `PagedResult<Issue>`. `FakeApiClient` filters and slices. `PagedResult<T>`
  model added at `lib/core/models/paged_result.dart`.

- [x] **HousingIssuesViewModel** — `load()`, `loadMore()`, `refresh()`,
  concurrent-guard on `loadMore()`. Issues tab wired to this VM;
  `HousingDetailViewModel` now only manages invitations.

- [x] **Scroll-to-load-more on Issues tab** — `NotificationListener` fires
  `loadMore()` within 200 px of bottom; spinner appended as last list item
  while `hasMore` is true.

- [x] **Widget tests for HousingIssuesViewModel** — 9 tests: load, load-more,
  error, loading-guard, refresh. All 89 project tests pass.

- [-] **Decouple Housing.addresses from list fetch** — `getHousings()` should
  return summary counts, not full address lists. Needs a `HousingSummary`
  model and a separate `getHousingAddresses(id, page)` endpoint. Blocked on
  the backend swagger. Revisit when the REST API spec lands.

---

## Address detail + tenancy history (done 2026-06-05)

Admin can drill from the housing overview into a single address, see current
tenants / invitation status, and browse the full tenancy history with issues.

- [x] **AddressDetailScreen + AddressDetailViewModel** — loads tenants,
  invitations, and history profiles in parallel. Status enum (occupied /
  invitationPending / vacant) drives the status section. Create / cancel
  invitation actions with in-flight spinners. Route:
  `/admin/housing/:housingId/address/:addressId` (extra: `Address`).

- [x] **TenancyIssuesScreen** — shows issue cards (status chip, 2-line
  description, creation date, "Handled by {name}") for a specific tenancy
  period. Tapping a card pushes to the existing `IssueDetailScreen`.
  Route: `/admin/housing/:housingId/address/:addressId/tenancy-issues`
  (extra: `TenancyIssuesArgs`).

- [x] **Shared address widgets** — `AddressStatusChip`, `TenantTile`,
  `LinkBox` extracted to `address_widgets.dart` and reused across
  `HousingDetailScreen` and `AddressDetailScreen`.

- [x] **Info peek button on address rows** — `Icons.info_outline` `IconButton`
  in each `_AddressRow`; tapping the card body navigates to
  `AddressDetailScreen`.

- [x] **DESIGN.md** — project-level design document: navigation hierarchy,
  sheet-usage rules (confirmation + ≤4-field info only), GoRouter `extra`
  convention, state management, adaptive breakpoints, code conventions.

- [x] **Tests** — 16 VM unit tests (`address_detail_view_model_test.dart`),
  6 widget tests (`tenancy_issues_screen_test.dart`), 4 integration tests
  (`integration_test/address_detail_flow_test.dart`).

---

## Known gaps elsewhere

- [x] **Join flow router timing bug** — router fix was `if (location == '/join') return null;`
  in `computeAuthRedirect` (unconditional, all authenticated users). Root-cause fix
  (2026-06-05): moved `_claimInvitation()` DB write from direct Supabase call into
  `ApiClient.claimInvitation()`; skipped VM test now passes. Rules documented in
  `DESIGN.md` § Routing rules.

- [x] **Tenant issue detail screen** — `TenantIssueDetailScreen` at
  `/tenant/issues/:id` shows description, photos, location, and public
  comments only (`!c.isPrivate` filter). No comment input. 17 widget tests
  in `test/features/tenant/tenant_issue_detail_screen_test.dart`.

- [ ] **Profile / housing switcher** — tenant profile page where a user can
  see their current address and claim a new invitation link to move housing.
  Not started.

---

## Infrastructure / quality

- [ ] **Restore integration_test setup for full login flow** — the
  `integration_test/` and `test_driver/` directories were removed when
  switching to widget tests. A real end-to-end test (launch app in Chrome,
  log in as `lars@example.com`, verify navigation shell) still needs the
  `flutter drive` + ChromeDriver path wired up.

- [ ] **Real ApiClient implementations** — `getHousingInvitations`,
  `createInvitation`, `cancelInvitation` all `throw UnimplementedError()` in
  the real `ApiClient`. Will need wiring once the backend swagger arrives.
