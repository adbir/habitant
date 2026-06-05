# Habitant — task backlog

Status markers: `[ ]` todo · `[~]` in progress · `[x]` done · `[-]` deferred

---

## Housing detail — scale for 275 units / 1000 issues

Current screen dumps everything into one list. Needs tabs + server-side
filtering + pagination before it hits real data.

- [ ] **Add TabBar to HousingDetailScreen** — split existing list into two
  tabs: "Units" (addresses + invitations) and "Issues" (open issues).
  Existing `_AddressRow` and `_IssueTile` widgets move into tab bodies
  unchanged. No VM or API changes.

- [ ] **Server-side issue status filter** — add optional `IssueStatus? status`
  param to `ApiClient.getHousingIssues()`. Update `FakeApiClient` to filter
  by it. Update `HousingDetailViewModel.load()` to pass
  `status: IssueStatus.open` (or equivalent set). Removes client-side filter.

- [ ] **Paginate getHousingIssues** — extend the method signature with
  `int page` and `int pageSize` (default 25). `FakeApiClient` slices the list.
  New `HousingIssuesViewModel` tracks `_issues`, `_page`, `_hasMore`,
  `_isLoadingMore`.

- [ ] **Scroll-to-load-more on Issues tab** — `NotificationListener` on the
  issues `ListView.builder` that triggers `loadMore()` when the user is within
  ~200 px of the bottom. Show a small spinner at the list tail while loading.

- [ ] **Widget tests for HousingIssuesViewModel** — load, load-more, error,
  refresh, status filter. Follow existing VM test pattern in
  `test/features/staff/`.

- [-] **Decouple Housing.addresses from list fetch** — `getHousings()` should
  return summary counts, not full address lists. Needs a `HousingSummary`
  model and a separate `getHousingAddresses(id, page)` endpoint. Blocked on
  the backend swagger. Revisit when the REST API spec lands.

---

## Known gaps elsewhere

- [ ] **Tenant issue detail screen** — tenant taps an issue card and sees the
  full description, photos, and any *public* comments. Staff-only (private)
  comments must be hidden. Route `/tenant/issues/:id` exists; screen
  `TenantIssueDetailScreen` is a stub.

- [ ] **Join flow router timing bug** — an already-authenticated user who
  opens an invitation link is momentarily redirected to `/tenant` before
  `joinInProgress` is set, losing the token. Needs a fix in
  `computeAuthRedirect` or the `JoinScreen` entry path.
  See memory: `project_join_flow_bugs.md`.

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
