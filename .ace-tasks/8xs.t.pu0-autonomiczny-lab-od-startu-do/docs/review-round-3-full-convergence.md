# PR #398 — review round 3: full-delta convergence (2026-10-30)

The two earlier prepared packets mis-described coverage (77 changed files
skipped). This round reviewed the ENTIRE PR delta exactly once, as seven
consecutive git-range segments (each within the packet budget):

| Segment | Range | Session | Draft findings |
|---|---|---|---|
| 1 | 7a1b1d9d2..46fe4c289 | review-8xtgnr | 9 |
| 2 | 46fe4c289..74dd561a0 | review-8xtgv8 | 15 |
| 3 | 74dd561a0..e867b5796 | review-8xth39 | 12 |
| 4 | e867b5796..025dbff92 | review-8xthaf | 18 |
| 5 | 025dbff92..7c5787e26 | review-8xthiv | 17 |
| 6 | 7c5787e26..839e1b093 | review-8xthrl | 5 |
| 7 | 839e1b093..HEAD | review-8xti23 | 8 |
| | | total | 84 |

Provider: `pi / zai/glm-5.3`, role:review-default + review-synthesizer —
every segment completed successfully.

## Triage (verified at HEAD by three independent verifiers)

- 14 already fixed by the round-2 commits (resolved as done)
- 1 invalid (Ruby `system(env, *argv)` merges, does not replace, the env)
- 6 skipped with reasons (2 design, 2 reviewer-deferred live-acceptance QA,
  1 belt-and-braces guard, 1 tracked lab-acceptance gate)
- **63 valid → all fixed in round 3** (20 from the pre-fix segments were
  round-2 duplicates already counted; the remaining items are new fixes)

## Round-3 fixes (all verified by green suites at the final state)

- **ace-lab auth**: provider/capability resolved BEFORE any record exists;
  empty repo intersection and non-positive TTL refused; per-correlation
  flock against the double-mint TOCTOU; deadline-aware find_live (expired
  grants never "live"); real child exit codes through runner+CLI;
  removed-profile degrade; revoke --force forced-terminal; exec
  credential-presence refusal; Authorization secrets moved to 0600
  ephemeral header files (never in argv); GitHub permission orientation
  bug fixed ({"repository"=>"write"}); dead code/token_ref output removed.
- **ace-lab installer/verify**: shared ExtensionProjection molecule with
  symlink-escape validate_destination! before any write/verify; dry-run
  predicts would_project; duplicate extension paths rejected; chmod/chown
  convergence + declared-account readability; receipt read errors
  degrade; parse_versions validates via Gem::Version (platform suffixes
  fail closed); closure_failures tuple unified; required fields stripped.
- **ace-overseer**: herdr failures surface as blocked (project + lab
  paths); first prompt separated from agent_start (prompt failure never
  strands an idle agent as "not started"); dig_workspace aligned to
  herdr keys; root-uid binstub guard restored; lab space title
  namespaced lab-overseer (no basename collision); nested lab scope
  refused; topology rescue narrowed; malformed observe.remote entries
  degrade to per-source health markers; start.wf.md boundaries updated.
- **ace-hitl**: crash-atomic case writes (tmp+rename under the lock);
  sweep guards (ENOENT/non-object JSON); terminal-case rule extended to
  lessons; dangling decision: ref guarded; duplicate timestamp removed
  and internals made private; lifecycle receipts 'recorded' for reports;
  Answer extraction centralized on body_section; collision test reworked
  to actually exercise the cross-worktree ambiguity (regression: the
  original passed vacuously); history table/quiet real.
- **ace-coworker**: gate rejects anonymous formal approvals.
- **ace-wake/handbook/pi**: pi acceptance test runs against the real
  extension layout (12/12); unresolvable extensions_package raises
  instead of silently pruning projections; import-hygiene guard restored;
  NODE_BIN + ENOENT handling; stale layout references fixed; extension
  path centralized (Ace::Wake.extension_root); latent watch-subscription
  ENOENT crash fixed; idempotence asserts zero updated/removed.

## Test evidence (final state, executed via bin/ace-test)

ace-lab 663 · ace-handbook 68 · ace-overseer 416 · ace-herdr 616 ·
ace-hitl 401 · ace-coworker 405 · ace-wake JS wrapper (node --test) ·
ace-handbook-integration-pi 9 + feat 12/12 — all 0 failures.
Pre-existing unrelated failures (ace-hitl-hermes macOS origin validation)
verified identical at HEAD before this round; not caused by this branch.

## Gate status

The gate verdict must be re-bound to the final HEAD of this round
(endgame-status.md updated accordingly). Formal approval + merge remain
external gates, unchanged.

## Round 3b — gate-delta review of the round-3 fixes (same day)

The round-3 delta itself (40e8f19a2..) was reviewed as one more segment
(session review-8xtj7y, 19 findings). Fixed: the flock+rename lost-update
race in HITL case writes (sidecar `<case>.lock` + tmp+rename data file,
fsync before rename), the doubled auth-exec report + typed exit code, the
pi acceptance package-root depth, fsync-before-rename, typed
UnresolvableExtensionsPackageError, position-based segment check in
extension projection, degraded markers for non-Hash observe entries,
malformed GitHub scope guard, token_ref consistency comment, and the
completed private-def migration. 8 low refactor/hygiene items skipped
with recorded reasons. All suites re-verified green at the final head;
post-fix probes 9/9.

## Round 3c — closing the loop on the 3b fixes

The 3b delta was itself reviewed (session review-8xtjsg, 9 findings): every
remaining unlocked HITL writer path now holds the sidecar lock (field-only
updates, the double answer application in `update`, resume notes); the
misleading auth `--format` option dropped; regression test added;
CHANGELOGs updated for all changed packages. 3 low items skipped with
recorded reasons. **Final reviewed head: 2c65811c6** — the gate verdict
binds here.

## Re-review round (2026-10-30 evening) — R1–R8 closed, two clean rounds

The independent re-review of `ea3a01734` (readiness report
`.ace-local/review/pr398-rereview/readiness.md`) returned REQUEST CHANGES
with seven P1s; all were fixed and verified:

- R1 Forgejo wire contract → token-authenticated ADMIN endpoints
  (`/api/v1/admin/users/{account}/tokens`), RepoTargetOption repo targets,
  ownerless scoping refused pre-request, response-scope validated,
  404=already_invalid settlement.
- R2 HITL field-write atomicity → `Molecules::CaseFileWriter` (sidecar lock
  + fsynced tmp + rename) used by manager AND sender; SIGKILL + inode
  regressions; the reviewer's two truncate-injection probes fail their own
  precondition because the boundary no longer exists — the adapted
  rename-boundary probes (`.ace-local/review/pr398-rereview/flow_test_post_rereview.rb`)
  pass 2/2, and 7/9 of the reviewer's originals pass.
- R3 lease durability → atomic record writes under a stable write lock;
  corrupt records surface as visible recovery errors, never skipped.
- R4 killed issuer → records born `preparing`; `issued` only after a
  complete handoff; recovery distinguishes never-delivered from active.
- R5 no blind re-mint → deterministic `token_ref_for` identity recorded at
  creation; retries settle the unresolved predecessor inside the
  correlation lock or refuse.
- R6 env isolation → allowlisted child env via `env -i`; a REAL spawned
  child proves ambient credential overrides never leak.
- R7 false ready → first-turn delivery confirmed through herdr's activity
  gate (`agent prompt --wait --timeout`); readiness requires confirmed
  initialization; reuse repairs idle/done sessions through the existing
  session state.
- R8 GitHub scope schema → subjects validated against real installation
  permission names; docs corrected.

Review rounds after the fixes (rule: two consecutive rounds without
confirmed P0/P1, evidence bound to the exact HEAD):
- Round A `ea3a01734..4f7732b0e` (review-8xtu7i): 14 findings, ZERO P0/P1
  (1 medium blank-line accumulation + lows) — all addressed or skipped
  with reasons.
- Round B `4f7732b0e..c1cb56472` (review-8xtun7): 8 findings, ZERO P0/P1
  (2 mediums: transition-rebuild accumulation + compounding test) — fixed.
- Micro-round `c1cb56472..6b46382c6` (review-8xtute): hardening only
  (0600 tmp/creation perms, Psych::Exception alignment) — fixed at
  `e45dbbc05`.
- Suites at `e45dbbc05`: ace-lab 676, ace-overseer 421, ace-hitl 405,
  ace-coworker 405, ace-handbook 68, ace-support-items 344, pi 9 + feat
  12/12, wake wrapper — 0 failures. ace-herdr's bounded-process timing
  tests are load-flaky in this environment (reproduced identical on a
  clean tree).

**Gate binding: the review evidence covers the complete delta up to and
including `e45dbbc05` (docs-only commits after a code HEAD get an explicit
no-op refresh per wfi://review/pr).** The release set at
docs/release-artifacts-sha256.md is superseded — fresh build/install
rehearsal recorded in /tmp/pu0-gem-build-r4 (digests below).

Remaining external gates: formal approval (lane account), integrator merge
with expected-head, publication (OTP), Hermes→reply transport + host
revoke scheduler, cold-cycle acceptance on the lab.
