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

## Independent review P1 repair after recovery integration

Repair worktree `/Users/mc/Ps/ace/.ace-wt/codex-wave4-delivery-integrated`, branch
`codex/wave4-delivery-integrated`, base `ac940ce60` includes accepted recovery from
main `394d816dc`. Original candidate was rejected for filtering delivery context to
one scoped attempt: closing create030 lost the PR for later steps, and unknown
create030 could be repeated by fresh scoped attempt031.

Ported regressions failed before correction: receipt `8x3zn5`, 14 tests/245
assertions, one duplicate-create failure and one cross-step context error. The
successful path closes scoped create030, runs read-only review145, closes it,
updates147, closes it, and readies148 with current accepted evidence. Unknown
create retains zero-match uncertainty in a new scoped attempt, then adopts the
single exact result without another write and records original intent attribution.

The repair derives assignment-wide identity, PR and pending intents exclusively
from the existing qjl evidence events. Results remain owned by the current scoped
attempt and link their original intent digest and attempt. Settlement is determined
by digest links, not cross-attempt array chronology (journal ordering follows each
attempt's chain). Status history exposes each event's owning attempt and digest.
No attempt must remain active across the recipe; no new ledger is introduced.
The recovery-based Git suite passed 575/1425, receipt `8x3zmx`.

Final repair-focused run passed 15 tests/277 assertions in 4m3s, receipt
`8x3zxz`. It also proves recovery of an older create cannot report success for a
requested readiness operation: the caller receives an explicit remaining-step
error, closes the original create attempt, then executes readiness on its own
current scoped attempt with valid evidence. No timeout settings were changed.
The intermediate 14-case repair passed 14/257 in 3m51s, receipt `8x3zsj`.

Full `bin/ace-test ace-assign all` repair verification is still running at candidate
freeze: its first run predates the final differing-operation completion guard;
the second run includes the final guard and test. Both cleared all fast targets;
feature outcomes must be recorded before claiming the full package gate. Neither
those pending results nor the atomic installed companion gates are claimed green.
