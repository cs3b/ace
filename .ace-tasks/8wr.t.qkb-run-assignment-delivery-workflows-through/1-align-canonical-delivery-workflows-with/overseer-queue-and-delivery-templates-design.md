# Design: overseer high-level delivery queue + project-adaptable assign templates (gad.2-informed)

Status: DESIGN / SPEC-ONLY — no implementation authorized. Supersedes the
earlier "lifecycle-completion" framing (which extended the worker template
toward merge/publish); per Captain correction 2026-10-11 the worker/reviewer
pipeline ending at **PR READY is the CORRECT completion** of a
work-on-task-style plan. Parent task line: 8wr.t.qkb (blocked) → this slice
8wr.t.qkb.1 (draft, needs_review). Role-charter counterpart: 8wr.t.qk0.

## 0. Problem statement (evidence: gad.2, 2026-10-10/11)

gad.2 proved the worker+reviewer pipeline (work-on-task → PR-ready) and the
AGit/forge-neutral delivery route work, but exposed the MISSING LAYER above
workers: nothing owns the DELIVERY QUEUE. Multiple deliverables became ready
(PR35/PR36/PR37) with no dependency-aware selection, no integration-order
decision record, and head-moving operations (rebase) requiring ad-hoc
renewed-evidence orders injected by the coordinator. Ordering deviations
inside the worker flow (155 deferred, 190 N/A, 130/140 superseded-by-AGit)
were misdiagnosed at first as worker-template defects; the Captain's
correction locates them correctly: they are QUEUE-LEVEL concerns, not worker
template changes.

## 1. Requirement — overseer-level HIGH-LEVEL QUEUE as Assign plans

The project overseer maintains a HIGH-LEVEL DELIVERY QUEUE defined as an
ace-assign parent plan (canonical batch-parent semantics) over SEVERAL
ready workers:

- several workers may be PR-ready/ready at any time; the queue does not
  assume one worker → one release;
- selection of what integrates next is DEPENDENCY-AWARE and follows an
  INTEGRATION ORDER decision — NOT completion FIFO;
- the queue lives entirely in canonical assign state (parent/child plans,
  steps, attempt ledger). NO second orchestration engine/journal/cache;
- the overseer operates the queue through existing public CLIs
  (select/start/finish/status/attempt) exactly as exercised in gad.2.

Implementation-task completion NEVER auto-completes a delivery/release
parent: PR-ready workers become queue ENTRIES; integration, release-cutting
and closure remain explicit queue-owner decisions recorded in the parent
plan.

### 1b. Integration selection decision record and WAIT/BLOCKED transitions (R2 F2 precision)

**Per-entry eligibility inputs, evaluated at each integration decision:**
dependency state (per the project guide), exact candidate head sha, fresh
test/review evidence refs bound to that head, required authority/transport
provisions for the intended effect, and grouping constraints (release/demo/
production batch membership).

**Canonical decision record (parent-plan step report/evidence, all fields
mandatory):** the ordered ELIGIBLE set; the SELECTED next entry;
skipped/DEFERRED entries each with reason; decision actor and timestamp;
the evidence revision (policy/plan revision + evidence refs) used. Order is
NEVER derived from completion timestamps.

**Re-evaluation triggers:** any dependency state change, candidate head
movement, evidence supersession, or authorization/transport change voids
the prior decision; the queue owner re-records a fresh decision before the
next effect.

**State transitions (canonical Assign state is the sole record):**

- required result channel/authority absent → `BLOCKED(provision, owner)`;
- authorized request issued WITH a durable correlation/reference and a
  defined poll/reconcile path → `WAIT(reference, next-check)`;
- uncertain or lost response WITHOUT a durable path → remains
  `BLOCKED(M2-provision, host)` — never `WAIT` by assertion, never blind
  retry of the effect.

## 2. Requirement — delegation of rebase + REQUIRED RENEWED EVIDENCE

Any operation that moves a deliverable's head AFTER exact-head evidence was
produced (rebase onto a moved base, union-conflict resolutions, extra
cherry-picks) REQUIRES renewed evidence at the new head before integration
eligibility:

- generalized from the PR36 discipline: R1 APPROVED at ba31afa7 → rebase →
  R2 supplementary re-verification at 1a8fa820 (range-diff content-identity,
  suite re-execution, verdict-stands note) before STOP-for-integration;
- the queue owner (overseer) DELEGATES the rebase and the renewed
  review/verification as queue steps — reviewer identity independent of the
  executor; callbacks verified per standing protocol;
- exact-head validity rule: evidence is bound to one head sha; a moved head
  voids eligibility until renewed evidence lands;
- supplementary re-verification is scoped: prove content-identity of the
  replay + re-run the correctness gate; it does not reopen the full review
  unless content changed beyond the declared delta.

## 3. Requirement — SEVERAL project-adaptable assign templates + decision guides

Deliverable shape: a SMALL SET of composable, project-adaptable assign
templates (presets/parent-plan shapes) + decision guides — explicitly NOT a
rigid one-worker→one-release pipeline. Candidate template families (to be
finalized in implementation planning, gated on spec approval):

- **records-closure** (proven by gad.2 closure PR37): archival replays +
  closure/RC documents via records PR;
- **docs-only delivery**: work-on-task minus code/release steps;
- **code + release-preparation delivery**: worker pipeline to PR-ready +
  release-prep records (publication always separate authority);
- **integration-wait/queue-entry**: parent-side step shapes for awaiting
  host integrator results with attributable BLOCKED states.

Decision guides (role-charter material, owned by 8wr.t.qk0 — the queue
owner IS the overseer):

- **integrate-more-then-cut-release vs deploy demo/production**: criteria
  (dependency coupling, release-train policy, demo/production risk windows,
  evidence freshness at chosen heads);
- **when renewed evidence is required** (any head move — §2);
- **BLOCKED vs WAIT attribution** (missing authority/transport = BLOCKED
  with named provision; awaiting host result = WAIT with durable polling).

## 4. Standing constraints (unchanged)

- Reuse assign canonical state (catalog/presets/parent-child/attempt
  ledger); NO second orchestration engine/journal.
- Design/spec-first; implementation gated until Captain/host approval of
  the spec; no generic rollout.
- No publication; rubygems-publish remains a separate authority; RC records
  are preparation-only.
- Completion-callback delivery protocol + coordinator JSON verification.
- Preserve all running work (PR37 loop, drills).

## 5. CURRENT-CAPABILITY vs MISSING-PROVISIONING audit (gad.2 inputs)

Current capabilities (proven):

- C1 assign parent/child plans + attempt ledger + fork-run dispatch (herdr
  launch, workspace by calling pane); C2 authenticated role chains
  (codex/pi/agy) with agent-executed overseer callbacks + coordinator JSON
  verification; C3 AGit refs/for route (branch push denied, refs/for
  accepted) with push-option title/description; C4 repaired task-aware
  worktree create proven on real Lab (PR37 records); C5 durable evidence
  conventions; C6 rebase+renewed-evidence discipline proven (PR36 R1→R2).

Missing provisioning (attributable BLOCKED inputs; owners named):

- M1 forge push identity split (fj-stored token denied; managed
  git-credential-lab works; no mapping provision) — owner host/lab-config.
- M2 integrator/host-adapter result path: coordinator-relay only; no
  durable pollable integration-result record — owner host.
- M3 HITL topology gap → gad.8; 16-hour proposal anchor stands meanwhile —
  owner gad.8.
- M4 login-gated identities (interactive claude unusable; identity pools
  must record availability) — owner host/lab-config.
- M5 AGit journal gap: AGit PRs do not populate the managed PR journal
  field; route+URL recorded in step reports — owner ace-assign/
  ace-git-forgejo backlog.
- M6 ace-git-worktree remove --task misresolves assignment journal
  checkout — owner ace-git-worktree backlog.
- M7 forge push flag semantics (ace-git-worktree backlog; corrected per
  lifecycle R2 + PR37 review F1). EXACT FACTS: the closure demonstration was
  invoked WITH `--no-push --no-pr --no-bootstrap --no-auto-navigate`; its
  evidence log contains BOTH `Failed to push task changes` (emitter gated by
  `--no-push`, task_worktree_orchestrator.rb:152-166) AND `Failed to setup
  upstream` (gated by `--no-upstream`); `--dry-run --no-push` (reproduced
  independently twice) still plans `push to origin` + `setup upstream
  tracking`. Current source confirms `no_push` IS parsed and threaded
  (create_command.rb → WorktreeManager#create_task → gate at :152), so the
  combined observation is NOT explained by broken threading — the runtime
  cause of the task-changes push warning in that specific run is UNRESOLVED
  (candidate: `option :no_push, type: :boolean, aliases: ["--no-push"]`
  alias/parsing behavior). Attributable gaps: (a) `--no-push` vs
  `--no-upstream` semantic split confuses operators — the PR36-era record
  “push despite --no-push” was the upstream push (misconeption corrected
  here and in host records per PR37 review F4); (b) dry-run planning
  contradicts the flag. Owner: ace-git-worktree backlog; investigation+fix
  gated on spec-approved implementation.

## Related task refs

8wr.t.qkb (blocked parent), 8wr.t.qkb.0 (evidence provider, delivered),
8wr.t.qk0 (role charter: queue-owner decision guides home), 8wr.t.qjx /
8wr.t.qjz (role services / second-commander proposals), 8x3.t.xz9
(protected authority), 8x3.t.3zi (forgejo transport hygiene), 8x0.t.ig3
(review loop ownership), gad.2 evidence tasks 8wj.t.vle / 8x9.t.x3o /
8xa.t.ega (PR35/36/37), gad.8 (HITL topology).

## Non-goals

No implementation in this pass; no new orchestration store; no worker
template extension toward merge/publish/deploy; no publication; no standing
authorization exercised; no change to Captain-host integration authority
boundaries.
