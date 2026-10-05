# 8wr.t.qjl — Implementation Report (2026-09-28)

Implemented in worktree `.ace-wt/8wr-t-qjl-persist-assignment-attempts` (branch `8wr-t-qjl-persist-assignment-attempts`, 8 commits, one per plan step). Task left `in-progress`; final delivery owns `done`/archive.

## What landed

- **Models/atoms** — `AttemptBinding`, `Attempt`, `ExecutionReceipt`, `EvidenceEvent` (digest-chained, non-secret), `AttemptStateMachine` (reserved→running→succeeded/failed/stopped/uncertain; reconcile resolves uncertain→succeeded/failed), `EvidenceDigest` (canonical JSON + SHA-256), `AssignmentScope` (canonical step/subtree keys). New `AttemptErrors` family exits with code 5.
- **AttemptStore** — durable records + atomic active-attempt ownership pointers under `<cache>/<assignment>/attempts/`, flock serialization, deterministic listing.
- **EvidenceJournal** — append-only `execution/<assignment-id>/events/` commits on `refs/ace/execution` via isolated detached audit checkout, checkout-root flock, and expected-old-value `git update-ref` CAS with conflict replay. Candidate branch HEAD proven unchanged.
- **Authority** — `ExecutionIdentityResolver` (local OS-login coordinator or service-executor env identity; unknown fails closed), `ReceiptVerifier` (binding, stale-head, artifact digest, checks, reviewer independence, forbidden-field rejection; worker identity cannot accept succeeded), `AttemptCoordinator` (sole authority for start/finish/reconcile/status; base_head captured once; candidate_head pinned on acceptance and invalidated on change).
- **EvidenceCalculator** — now derives review/release receipt currency, feedback state, and merge authorization exclusively from accepted current-head journal/store receipts; `report-only` and hardcoded `terminal` are gone.
- **AttemptReconciler** — classifies interruptions (stopped before process start; running only for verifiably live processes; uncertain otherwise) and resolves uncertainty only via boundary-attributed verified receipts. Never replays merge/publish/deploy.
- **CLI** — `ace-assign attempt start|status|finish|reconcile` registered as a nested command namespace; JSON projections carry state/binding/refs/digests only. `ace-assign status` (JSON and compact) now shows attempt, base_head, candidate_head, evidence_git_ref, journal_commit, unresolved effects.
- **Docs** — drive.wf.md sections 4–5 rewritten attempt-first; usage.md "Attempt Evidence" section (Git-backed vs `local_only` recovery); exit-codes.md code 5; CHANGELOG breaking entries.

## Plan deviations (spec wins, plan is HOW)

1. Test layout: plan's `test/{models,atoms,...}` paths adapted to this package's existing `test/fast/{models,atoms,molecules,organisms,commands}/` convention.
2. Attempt command files: four command classes plus a shared `attempt/base.rb` helper module (package pattern is one file per command class).
3. Attempt IDs are generated before reservation so journal start events carry the attempt ID (spec requires records link to the attempt).
4. Assignment metadata carries task/project attachment only; active-attempt references are read through AttemptStore/AttemptCoordinator (single authority), keeping attempt history out of mutable assignment metadata.

## Verification

- `ace-test ace-assign all`: 700 tests, 2553 assertions, 0 failures/errors.
- SC1–SC4 covered: accepted receipt leaves candidate HEAD unchanged (unit + journal ref inspection), stale-head rejection incl. task-only edits, concurrent claim single-winner, restart classification matrix (intent-only/dead pid/live pid), uncertain never resolves without boundary-attributed receipt, self-approval/report-only/digest-mismatch rejection, public CLI recovery scenario, crash/reload (checkout loss + fresh store instances).
- `ace-lint` clean on drive.wf.md and usage.md (only pre-existing warnings remain).

## Follow-ups (non-blocking)

- `docs/exit-codes.md` and README could surface attempt commands in additional languages/demos.
- Version bump + publish (0.58.0 minor, breaking changelog already recorded) belongs to the release step.

## Independent review (PR #346, codex:astra:high × 4 rounds, 2026-09-28)

Converged after four review rounds: 40 findings total — 27 fixed with regression tests, 7 marked not-this-PR (Lab CLI / subprocess-env findings about other packages), 6 recorded as design boundaries on the ADR-028 service-executor surface (worker-pid checkpoints, cross-cache state arbitration, execution-bound role attribution). Sessions: review-8wru20, review-8wruko, review-8wruy3, review-8wrvlj.

Highlights of what review caught and fixed:
- Critical: attempt-ID collisions (1.85s B36ts resolution) — lock-scoped allocation + cross-assignment `.attempt-ids` registry + journal-known IDs.
- Concurrency: finish/reconcile now hold the assignment lock and consult journal-authoritative state; CAS-conflict stderr was misclassified as fatal so the retry loop never actually retried (fixed + unit tested).
- Ownership: hierarchical scope-overlap rejection, journal-derived attempts block writers after local cache loss, post-append ownership revalidation records a stopped transition for race losers.
- Authority: succeeded verdicts need executed checks; review receipts need a reviewer verdict; supplied digests verified against canonical payloads; different actors cannot adopt an existing attempt.
- Recovery: journal-first reconciliation without cached metadata (assignment IDs discovered from the evidence ref); terminal journal states project over stale local records.

Suite: `ace-test ace-assign all` — 726 tests, 2635 assertions, 0 failures (up from 618 before this task).

Deferred design boundaries (ADR-028 service-executor surface, for a follow-up task):
- Worker-owned process checkpoints (pid recorded at the actual execution boundary).
- Cross-cache attempt-state arbitration inside the journal transaction.
- Producer/reviewer claims bound to independently recorded executions.
