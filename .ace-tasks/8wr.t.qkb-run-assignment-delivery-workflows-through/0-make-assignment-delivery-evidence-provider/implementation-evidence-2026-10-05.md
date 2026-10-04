# qkb.0 source candidate — 2026-10-05

Own worktree: `/Users/mc/Ps/ace/.ace-wt/wave4-delivery`, branch
`codex/wave4-delivery`, initial base `ce7e39228cbaa558122a2447861cdcf75abad83f`.
Task remains in progress. This is source preparation for independent review.

## Implemented boundary

DeliveryCoordinator uses the existing qjl managed attempt, lifecycle exclusion and
evidence Git ref. It resolves explicit named/default/remote forge selection, freezes
identity at the first actual delivery action, validates explicit canonical/fork
provenance and actual pushed candidate, journals intent before mutation and exact
outcome afterward. Status and review do not append evidence. Candidate projection
comes from the authoritative journal; journal commits do not advance HEAD.

Lost create, update and readiness responses reconcile exact remote outcome. Zero
create matches remain unknown; multiple matches conflict. Readiness reconciliation
revalidates original intent references without requiring new caller references.
Current readiness requires accepted executed test and independent review receipts;
red remote CI stays visible and advisory. Worker boundary identity is rejected.
Merge only consumes a completed, verified existing qjx service receipt and observed
exact merged PR; the actual authorized executor calls the neutral merge primitive.
No second ledger, grant dialect, credential authority or publication path is added.

CLI, task creation delivery mapping, remote preset parameters, neutral source wfi
and skill entrypoints, catalog consumption and preparation-only release steps are
included. Companion producer/consumer requirements are in
`../1-align-canonical-delivery-workflows-with/delivery-service-adoption.md`.

## Executed verification

- `bin/ace-test ace-assign test/feat/delivery_coordinator_test.rb`: 12 tests,
  223 assertions, zero failures/errors; receipt `8x3z0f`. Real temporary Git and
  bare source refs with controlled provider IO cover GitHub/remote, Forgejo/default
  and Forgejo/named, both canonical and fork provenance; unknown effects, crash
  before receipt persistence, stale/forged evidence, identity changes, read-only
  status, red CI and verified merge consumption/tampered evidence are exercised.
- `bin/ace-test ace-git all`: 575 tests, 1425 assertions, zero failures/errors;
  receipt `8x3z09`, including qk1 explicit repository/pinned identity/reconciliation.
- CLI and parameter focused group: 20/72 green, receipt `8x3yyr`.
- Catalog/materialization/CLI focused group: 28/132 green, receipt `8x3z1l`.
- Final create/delivery command group: 15/59 green, receipt `8x3z32`.
- First `ace-assign all` stopped at 547 tests with two obsolete GitHub skill
  assertions and one fixture containing publication source after preparation source
  adoption (`8x3z1d`). Those consumer fixtures were corrected; rerun recorded below.
- Source `bin/ace-bundle` resolved `wfi://git/pr/create` and
  `skill://as-git-pr-create` to the new package source assets.
- `git diff --check` clean.

## Remaining gates

Recovery source is not yet independently accepted/integrated. Rebase on its reviewed
commit and rerun affected consumers before integration. Execute the separate provider
package suites and default monorepo suite after that rebase, then obtain independent
exact-head implementation review. No claim of those gates passing is made here.

qkb.0/qkb.1 installed vocabulary adoption is atomic: old source names remain pending
qkb.1 removal and normal projection updates. Do not publish this intermediate source
candidate. Fresh installed outside-checkout resolution and the actual configured
qjx/gad.b merge producer/grants/native evidence path remain companion acceptance
gates. Controlled provider/service fixtures do not establish live installed acceptance.
