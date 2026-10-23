# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.2] - 2026-10-23

### Added

- Formal reviewer-owned, exact-head provider approval and read-only approval verification through the forge-neutral review flow; comments do not substitute for approval.


## [0.6.1] - 2026-10-20

### Fixed
- Honor `ACE_TOOLCHAIN=installed` for published-gem execution and context propagation without source-runtime fallback; retain default auto development behavior.


## [0.6.0] - 2026-10-20

### Fixed

- Trust-posture parity with `ace-lab verify`: the instruction resolver
  never executes the repository-controlled `bin/ace-nav` binstub under
  a privileged (root) run — only the PATH-installed resolver is used.

- `ace-coworker prepare` no longer reports readiness for a protocol
  instruction URI (`wfi://`, `prompt://`, `tmpl://`) that the ace-nav
  resolver rejects in the prepared worktree. Protocol sources now resolve
  through the SAME `InstructionResolver`/ace-nav path that `start` uses,
  BEFORE readiness is claimed; a resolver that runs and fails is a
  `role_instructions` gap (never ready), while a missing ace-nav CLI
  (`InstructionResolver::NavUnavailableError`, ENOENT) stays a
  non-blocking unknown consistent with lab verify's posture toward an
  absent checker.

### Added

- Readiness / gap reporting to the overseer in `ace-coworker prepare`
  (8xg.t.sbz.3.3 / L4.4): every SUCCESSFUL preparation ends with a
  READINESS report through ace-hitl (`--type report --result success`,
  title `Preparation ready - <task>/<worktree-dir>`; a report expects
  no reply) carrying the complete set to run the first step — worktree
  (path/branch/disposition), every sequence leg, every start config,
  and the exact first command (`ace-coworker start --config
  .ace-local/coworker/prepare/<first-role>.yml` in the worktree) — so
  the overseer never composes ace-assign details itself. Gaps never
  pass as ready: role errors (unknown role, missing process
  definition) become a `role_sequence` conflict and a missing overseer
  address becomes a `missing_overseer` conflict — both exit 1, write
  no start configs, and escalate to the overseer as a decision
  question (the existing conflict path; question = a decision is
  needed) with the concrete reasons: what is prepared, what is
  missing, and the decision needed. The previous hard error `cannot
  prepare start configs: no overseer address` is replaced by the
  structured `missing_overseer` gap. The prepare result JSON/table
  gained a `report` field (`{"kind": "readiness", "event": <id>,
  "delivered": …}`, or the create/delivery failure under `error`); a
  report delivery failure never undoes the preparation — the event id
  stays available for an `ace-hitl send` retry. `--dry-run` reports
  nothing (zero effects includes ace-hitl events). No new state owner:
  events live with ace-hitl, helper state is none (ADR-034).
- Per-role executor start configs in `ace-coworker prepare`
  (8xg.t.sbz.3.2 / L4.3): after composing the role-sequence assignments,
  the planner also writes ONE start config per sequence leg into the
  prepared worktree at `.ace-local/coworker/prepare/<role>.yml` — role,
  instruction source, start prompt, task, assignment reference, overseer
  address, and reporting/error rules — so `ace-coworker start --config
  .ace-local/coworker/prepare/<role>.yml` (run inside the worktree)
  begins a leg with zero ad-hoc setup. Ownership split stays one writer
  per file: `prepare` owns `prepare/<role>.yml`, expanded through the
  SAME commission primitive that writes the default `config.yml`, so the
  round-trip guarantee ("what commission writes, start accepts") holds by
  construction; `commission` remains the single writer of the default
  config target. The leg configs require an overseer address (`--to`, or
  the coworker config's `overseer` read leniently): a missing address
  ends the preparation as a `missing_overseer` gap (see the L4.4 entry
  above) instead of writing an incomplete config. Writing leg
  configs never touches an active driver: the existing
  active-executor/mismatched-worktree conflicts run first, and the
  default `config.yml` is never written by prepare. Writes are
  idempotent: identical leg configs are reported as `reused` without a
  write, changed content as `updated`; `--dry-run` reports them as
  `planned` with zero writes. New organism
  `Ace::Coworker::Organisms::StartConfigWriter`; the prepare result
  JSON/table gained a `start_configs` list (role, assignment, path,
  disposition `created`/`reused`/`updated`/`planned`).
- Role-sequence assignment composition in `ace-coworker prepare`
  (8xg.t.sbz.3.1 / L4.2): after finding or preparing the task worktree,
  the planner composes the assignments for the WHOLE known role sequence in
  one go — one `ace-assign` assignment per role in dependency order, stored
  by ace-assign in the worktree's `.ace-local/assign/` (no second queue;
  ADR-034) — so after start the roles hand off sequentially without the
  overseer re-commissioning preparation per step. Each assignment records
  the task id, its sequence position (`sequence N/M`), the expected outcome
  of the leg, and — for every leg after the first — an explicit entry
  condition naming the predecessor assignment and role. Per-role processes
  come from new shipped sequence definitions overridable per project
  (`.ace-defaults/coworker/sequences/<role>.yml`, project override
  `.ace/coworker/sequences/<role>.yml`): worker (implementation plus
  per-package `bin/ace-test` verification), spec (material requirement gaps
  become `ace-hitl` questions, never guesses), reviewer (embeds the 3/2/10
  round rule via `ace-coworker rounds record`: min 3 completed full rounds,
  last 2 consecutive clean, no unresolved earlier High/Critical, max 10
  then escalation), and integrator (runs the `ace-coworker gate` checks
  before any merge; withholding is a legitimate outcome). A role without a
  preset or without its own process definition is reported with exit 1 and
  nothing is composed (all-or-nothing) — another role's process is never
  substituted. Composition is idempotent: re-preparation reuses
  already-composed assignments (matched by `<task>-<role>` name plus
  recorded task_id) without writes; `--dry-run` composes nothing. New
  molecule `Ace::Coworker::Molecules::RoleSequenceComposer`; the prepare
  result JSON/table gained an ordered `assignments` list (role, position,
  assignment id, disposition `created`/`existing`, step count, expected
  outcome).

- Integrator role (8xg.t.sbz.4.3 / L5.2): the fourth coworker role preset
  `integrator` (shipped in `.ace-defaults/coworker/roles/integrator.yml`,
  workflow `wfi://coworker/integrator`). It performs the project-defined
  integration: before merging it checks (a) dependencies are integrated
  predecessors (an open PR or "work done" message never substitutes), (b)
  the candidate head still matches the reviewed head (no drift), (c) tests
  were executed and passed (real evidence; CI stays advisory), and (d) a
  fresh independent review verdict accepts the EXACT candidate head. A
  stale review after a candidate change, an unsatisfied dependency, or
  missing test evidence WITHHOLDS the merge and escalates to the overseer
  via `ace-hitl`; an uncertain operation outcome (merge/push) is verified
  against the real state, never retried blind. A merge that changes the
  candidate (conflict resolution) renews the checks and the review before
  the result counts as integrated. The role drives git/ace-git; no merge
  is performed in code. No new persisted artifact kind: integration
  decisions persist in the assignment's existing report state.
- `ace-coworker gate`: deterministic pre-merge gate surface for the
  integrator role over the new pure atom
  `Ace::Coworker::Atoms::IntegrationGate`. `ace-coworker gate
  --candidate-head <sha> --review-head <sha> --review-verdict
  accept|continue|escalate --tests executed,passed
  --dep <leaf>=integrated|missing [...]` evaluates the four checks and
  prints `ready` or `blocked` with per-check reasons (dependencies,
  candidate drift, stale/missing review evidence, executed+passing tests).
  Unknown facts (omitted heads, missing sections) block with an explicit
  verify-instead-of-guess reason rather than being assumed. `blocked` is a
  legitimate gate outcome (exit 0); only malformed input fails - an invalid
  `--dep` pair (missing `=`), a duplicate `--dep` name, or an unknown
  `--tests` token (expected: executed, passed). Heads are recorded and
  compared as full lowercase SHAs (case drift is tolerated, length mismatch
  is not). Stateless: readiness only, no writes, no merges.

- `ace-coworker rounds record --assignment <id> --type full|delta --status
  completed|aborted [--confirmed id:sev,...] [--resolved id,...]`: CLI
  surface for the 3/2/10 enforcement (8xg.t.sbz.4.2) used by the reviewer
  workflow. Appends one finished round to the coworker-owned history at
  `.ace-local/coworker/review-rounds/<assignment>.json`
  (`Molecules::ReviewRoundStore#record!`, validated at the boundary by
  `Atoms::RoundRecordSchema`) and prints the resulting verdict with its
  counters. A corrupt or non-array history file fails with `corrupt round
  history at <path>` instead of silently resetting the round counters, and
  the 10-round cap is terminal: a rule-satisfying state at round 11+
  escalates instead of accepting.
- Review-round convergence enforcement (8xg.t.sbz.4.2 / L5.2): the 3/2/10
  rule is now working code. `Ace::Coworker::Atoms::RoundRule` is a pure
  evaluator over round records (type full|delta, status
  completed|aborted, confirmed severities, resolved references) returning
  an explicit verdict `:continue | :accept | :escalate` plus derived
  counters (full rounds, completed full rounds, consecutive clean,
  unresolved High/Critical). Minimum 3 full rounds with the last 2
  consecutive clean and no unresolved earlier High/Critical accepts
  (so clean/clean/clean and error/clean/clean both finish at round 3);
  no acceptance after 10 full rounds escalates as an outcome, never an
  exception. Delta/fix-diff rounds never advance the counters;
  interrupted/aborted rounds are not clean and a confirmed High/Critical
  resets the streak. `Molecules::ReviewRoundStore` persists the round
  history per assignment in
  `.ace-local/coworker/review-rounds/<assignment>.json` (the
  coworker-owned location, following `ReportStateStore`), so a restart
  reloads the counters and findings history instead of resetting them.
- Reviewer role (8xg.t.sbz.4.1 / L5.2): shipped preset
  `.ace-defaults/coworker/roles/reviewer.yml` and the self-contained
  `wfi://coworker/reviewer` workflow. The reviewer is independent of the
  worker, fixes confirmed defects itself inside its own single assignment
  (steps added via `ace-assign add`), checks each fix diff, and returns to
  full review rounds under the 3/2/10 convergence rule (deterministic
  enforcement landed as 8xg.t.sbz.4.2, see above). No effective fix or a
  needed product decision is escalated via an `ace-hitl` decision question;
  unresolved High/Critical is never marked as success.
- `ace-review` declared as a runtime dependency: the reviewer role's primary
  function drives the `ace-review`/`ace-review-feedback` CLIs, matching the
  gemspec's stated policy of declaring runtime CLI requirements.

### Fixed

- `prepare --dry-run` is now zero-write on EXISTING worktrees too
  (PR #393 audit): `PrepareOrchestrator` passes `dry_run` through to
  `RoleSequenceComposer`, which resolves the whole sequence read-only —
  already-composed legs are reported as `existing`, missing legs as
  `planned` with no assignment id — and `StartConfigWriter` plans such
  legs without commissioning them (a real run still requires a composed
  assignment per leg). Previously a dry-run reuse/extension of an
  existing worktree created real ace-assign assignments (e.g. a real
  reviewer `assignment.yaml` after extending `--roles worker` to
  `--roles worker,reviewer --dry-run`), mutating execution state during
  a preview.
- `prepare` never reports readiness when a leg's instruction source does
  not resolve (never-ready-on-missing-context, 8xg.t.sbz.3.2/.3.3):
  before any start config is written or readiness reported, the
  instruction source of EVERY leg is resolved through the existing
  loader in the prepared worktree (file-path sources in-process; protocol
  URIs stay delegated to ace-nav at start time). A missing source (e.g.
  `instructions: roles/nonexistent.md`) is a new `role_instructions`
  conflict — exit 1, no leg config written, escalated to the overseer as
  a decision question — instead of a success whose emitted first-leg
  start command fails immediately with "instruction file not found".
- `RoundRule` (3/2/10 review convergence): a completed delta round that
  CONFIRMS a High/Critical finding now invalidates the prior clean
  streak — even when the same delta (or a separate fix delta) resolves
  the finding — so renewed clean full-round evidence is required before
  `accept`. Previously three clean full rounds followed by a
  High-confirmed delta (even resolved) still yielded `accept` with a
  stale `consecutive_clean: 3`. Full-round counting (3/2/10 cap) is
  unchanged; deltas without a confirmed High/Critical stay transparent.
- `RoleSequenceComposer` raises the actionable
  `invalid assignment process` `Ace::Coworker::Error` for malformed
  sequence step entries (e.g. a project override
  `.ace/coworker/sequences/worker.yml` with `steps: [42]` or
  `steps: [null]`) instead of a raw `TypeError`/`NoMethodError`, so
  malformed user process data flows through the intended `role_sequence`
  gap/HITL escalation in `prepare` instead of crashing it.
- `WorktreeExecutorProbe` cascade (8xi1p4z2): an unparseable nearest
  cascade layer (e.g. unresolved merge-conflict markers in the
  worktree's own `coworker/config.yml`) is now skipped per-layer,
  exactly like a non-mapping layer, instead of discarding the whole
  merge and silently reverting the probe to the default config
  location — a commissioned executor at a cascade-overridden
  `config_path` stays detected. The user-tier (`~/.ace`) override is
  covered by a stubbed-HOME test (8xi1p4z8).
- `WorktreeExecutorProbe` cascade (8xi16mz3): a non-mapping cascade
  layer (e.g. a `coworker/config.yml` containing a YAML list) is now
  skipped instead of wiping the already-merged farther tiers, so valid
  configuration (including a `config_path` override) from other tiers
  survives. The probe's deliberate read-only asymmetry — following the
  cascade-resolved `config_path` without the orchestrator's
  project-root containment, since it only reads what the worktree's
  loader process would read anyway — is now documented in the code
  (8xi16mz4).
- Render start-prompt placeholders in a single pass derived from `PromptTemplate::PLACEHOLDERS`, so substituted values shaped like a later placeholder are never re-expanded.
- Raise a specific `invalid role preset` error for malformed YAML preset files (all `Psych::Exception` load failures), instead of a raw backtrace.
- Correct the spec role workflow's escalation command to the required `ace-hitl create "<title>" --type question ... --question "..."` form.
- `prepare` reads the target worktree's coworker config through the coworker
  config cascade anchored at that worktree (project `.ace` tiers plus the
  user tier), so a commission written under a configured `config_path`
  (e.g. `.ace-local/coworker/worker.yml`) is detected as an active
  executor instead of being missed because of the hard-coded default
  location.
- `commission` canonicalizes the task identity before the assignment match
  and the config write: a short task ref of the recorded task (e.g. `ccc`
  for `8xh.t.ccc`) is accepted and the config stores the resolved full id,
  while an assignment genuinely belonging to another task stays rejected.
- Reviewer workflow instruction (`wfi://coworker/reviewer`): newly named
  fix steps are added via `ace-assign add --yaml <file> --assignment <id>`
  (top-level `steps:` array with `name`/`instructions`, example included);
  `--step` is documented as selecting an existing preset-catalog step
  definition only — it cannot mint a new step name.

