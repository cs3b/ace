# Candidate batch limits and deadline — evidence

Date: 2026-10-16/17 (Atlantic/Canary). Worktree `codex/ei9-program-integration`
at `214dfbb81` plus this WIP. Real-project fixture: candidate `c25960c30`
(82,809,675-byte bundle, 9,203 entries, 71,583,200 expanded bytes) compared
against reviewed main `2e9005f39` (82,066,639 bytes, 8,834 entries). Manifest:
`.ace-local/ei9-candidate-readiness/manifest.json`.

## 1. Deadline explanation (closes handoff item 1)

`CandidateTransfer::DEADLINE` is one wall budget for the whole
`with_head_comparison` operation: both full bundle admits (write bundle →
verify → fetch into empty quarantine → `fsck --full --strict` → re-bundle),
the reviewed-head fetch, and the complete comparison context build.

RED `assign/7993070e-b250-4f26-9a25-d9dcdc58e451` (2026-10-16 22:01):
`EvidenceUnavailable: head comparison deadline expired` at `ReadView#context`
after 50.60s total test time. The host was concurrently running the Pi review
session 86282 (recorded in the handoff); this is legitimate bounded work under
load, not a hang — every subprocess runs under `Herdr::BoundedProcess` with a
hard kill at the deadline (fail-closed).

Measurements (probe: `.ace-local/ei9-deadline-probe/probe.rb`, receipts
`deadline-probe-2.txt` in this directory and the session log of the first run):

| Measurement | Comparison wall | Notes |
|---|---|---|
| PASS `961d15dc` (earlier agent) | 22.43s | metrics JSON in report |
| RED `7993070e` | > 30s | expired mid-context under loadavg ≈ 11 |
| Probe run 1 (loadavg 7–10) | 22.93s | admits ≈ 14.1s |
| Probe run 2 (receipt) | 23.81s | admits ≈ 15.5s; identical context sha256 |
| GREEN `5799bed9` (after fix) | 27.01s | passing run, only 3s under the old 30s |

Per-label breakdown (probe run 2): `fsck` 2× ≈ 7.9s, admit fetches 2× ≈ 6.1s,
`cat-file --batch-check` 141 calls ≈ 5.3s, content `--batch` 20 calls ≈ 1.2s,
diffs ≈ 0.4s. A passing run at 27.01s proves the old 30s budget had no
real-world margin; the RED is the same work under heavier load.

Decision (explicit, per handoff "do not raise without measurement"):
`DEADLINE` 30 → 60. Worst measured legitimate need 27s; 60s gives ≥ 2.2×
headroom while remaining a finite secondary guard. Primary bounds are
unchanged and independent of wall clock: 128MiB wire/expansion ceilings,
20,000 objects per tree inventory and across the comparison's unique-blob
union (`CandidateBlobBatch::MAX_OBJECTS` guards both the per-inventory entry
count and the `candidate_blob_sizes` selector), 8MiB/512-object batch chunks,
4,096-byte path bound. No timeout was weakened for `BoundedProcess`; the RED
report is retained unedited.

Not taken (recorded options, not required): splitting admit/context budgets
(changes the one-bound-per-operation contract); enlarging the 64-oid
batch-check slices (141 spawns ≈ 5.3s — reducible, but out of scope for this
increment).

## 2. Path bounds (closes handoff item 2)

Dynamic-agent flag: possible quadratic/linear-in-path-length cost when a very
long tree path (e.g. 4096/255 bytes) reaches inventory construction or
filesystem prefix creation. Explicit decision: adopt PATH_MAX/NAME_MAX-sized
finite bounds — total path ≤ 4096 bytes, component ≤ 255 bytes (component
count is then implicitly ≤ 2048).

Implementation (`Atoms::CandidateLimits::PATH_BYTES/PATH_COMPONENT_BYTES`):

- `CandidateTransfer#materialize` — total-bytes bound checked before the
  component split; component bound inside the existing traversal-safety scan;
  both precede any `mkdir_p`/file creation.
- `CandidateTransfer#prepared_files` — same two bounds before building the
  path→content inventory.
- `PreparedWork` file-path validation — same bounds for `export_prepared`'s
  prefix creation.
- `CandidateHeadComparison#head_comparison_inventory` — total-bytes bound
  before JSON inventory encoding (components are never used there; delta
  paths are a subset of already-bounded tree paths).

Negative proofs (macOS git 2.54.0 refuses `/` inside `mktree` names, so deep
fixtures are built as bottom-up nested trees; `bundle create` needs a named
ref): `test_materialization_refuses_unbounded_component_and_total_path_lengths`,
`test_head_comparison_refuses_unbounded_inventory_paths`,
`test_prepared_files_refuse_unbounded_paths_before_any_prefix_work`.

## 3. Review dependency (handoff item 4, release-time action)

`CandidateTransfer::MAX_REVIEW_BYTES` now reads
`Ace::Review::Atoms::CampaignContract::MAX_HEAD_CONTEXT_BYTES` (128MiB).
ace-assign's gemspec still pins `ace-review ~> 0.60.3`, which predates the
constant. At release the floor must be raised to the version that ships it;
no fallback to installed Review 0.60.3 is permitted. Source-side, the
monorepo resolves Review from this checkout. The Linux source-only fixture
must pin five packages: Lab/Assign/Runtime/Herdr/Review (handoff "Lab i
granice operacyjne").

## 4. Executed receipts (this session, bin/ace-test)

| Report | Scope | Result |
|---|---|---|
| `assign/1ef4d5c4-a487-43be-b8e2-9741bbabdf2d` | candidate_transfer feat (21 tests incl. 3 new negative) | PASS 416 assertions |
| `assign/5799bed9-81a8-4e1d-9a68-8da93f64847f` | real-project readiness | PASS 16 assertions, 52.65s |
| `assign/dc61d4da-ad2e-4037-b181-9aed5158824e` | transfer_codec | PASS 17/98 |
| `assign/b03ab581-8ce0-4aba-a720-20709cb4f875` | git_blob_batch atom | PASS 4/22 |
| `assign/23e1f50c-c08c-475d-ac38-88935e89341f` | journal_mutation | PASS 14/170 |
| `assign/26d5314a-6636-47c2-bbea-546cc271d76c` | canonical_journal_initialization | PASS 2/15 |
| `assign/832ffde9-effa-4164-b9b5-6e55520c444f` | installed_journal_read | PASS 4/23 |
| `assign/6bc230ec-f5f3-45fd-9e87-89a5aaca983c` | prepared_work_transfer | PASS 4/47 |
| `assign/e6a6a42c-daf7-4031-a485-63b7b852f9ee` | prepared_work_builder | PASS 9/46 |
| `review/627f63c3-929f-4e71-9e49-ae73c7461972` | campaign_head_assessments | PASS 7/54 |

Earlier WIP receipts retained unedited: `b3cb606e` (68/620), `2ae7db50`
(Review 7/54), `961d15dc` (readiness 1/14), RED `7993070e`, RED diagnostics
`93517815`, `e8182d79`, `1ceb3135`.

## 5. Independent review verdict and dispositions

Configured reviewer ran `code-valid` on `diff:214dfbb81..HEAD`
(session `.ace-local/review/candidate-batch-limits/`, report
`review-report-review-default.md`). Security assessment: attack vectors
closed; no high/medium vulnerabilities. Actionable findings and dispositions:

1. **[High] gemspec floor vs load-time constant** — verified and sequenced,
   not applied in this WIP: an in-branch bump (`ace-review` 0.61.0 +
   ace-assign floor `~> 0.61.0`) was attempted and reverted. Reason: every
   monorepo consumer must move together — `ace-overseer` also pins
   `ace-review ~> 0.60.3`, Bundler enforces the constraint across path gems,
   and the coordinated move including `Gemfile.lock` (read-only for agents,
   see blueprint) is the established dedicated release-commit pattern
   (`42195850a`). Required release-time actions, blocking any publish of
   ace-assign built from this source: bump `ace-review` to 0.61.0 (ships
   `MAX_HEAD_CONTEXT_BYTES`), raise ace-assign floor to `~> 0.61.0`, raise
   ace-overseer's ace-review floor to accept 0.61, regenerate the lock, add
   changelog release sections. No fallback to installed Review 0.60.3 is
   permitted anywhere. Until that release, the constant resolves from source
   in this checkout (all executed receipts above ran that way).
2. **[Medium] documented 20k bound semantics** — accepted: evidence and
   changelog now state the bound applies per tree inventory and to the
   comparison's unique-blob union (`CandidateBlobBatch::MAX_OBJECTS`).
3. **[Low] readiness wall-clock asserts are load-sensitive** — considered and
   deliberately kept: `elapsed <= DEADLINE` asserts the production contract
   itself (the same constant fails closed in production); a softer multiple
   would hide deadline regressions. Real times are additionally recorded in
   the emitted metrics JSON.
4. **[Low] selector/batch-oversize negative test gaps** — accepted: added
   `test_blob_size_selector_rejects_oversized_or_malformed_oid_sets_before_git`
   (rejects before any Git invocation) and
   `test_batched_materialization_carries_an_oversized_single_blob_alone`
   (single blob larger than `BATCH_BYTES` roundtrips in its own batch).
5. **[Low] `review_snapshot` stays at 64MiB** — retained deliberately per the
   handoff contract (prepared-source and review-snapshot purposes keep 64MiB;
   full-candidate review input now flows through the 128MiB head-comparison
   context). No lib caller of `CandidateTransfer#review_snapshot` exists; its
   removal or alignment is tracked for the .8 campaign composition rather
   than this transport change.
6. Refactor suggestion (shared ls-tree parser for the three bounded sites) —
   recorded, not taken: the three parsers differ deliberately (inventory has
   no component tier; prepared is 100644-only); a parameterized shared parser
   would add indirection without removing a real defect.

Not established by this evidence: canonical execution of the comparison path,
full-suite rerun on the final state, publication or installed acceptance.
The merge gate (executed tests + independent review) is satisfied for this
delta by the receipts above plus the session-1 review round; the full default
suite receipt for the final commit state is recorded in the delivery map.
