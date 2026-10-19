# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

## [0.5.0] - 2026-10-18

### Added

- Worker and spec roles as configuration and instructions (L5.1): shipped
  role presets (`.ace-defaults/coworker/roles/worker.yml`, `spec.yml`) with
  role name, `wfi://coworker/<role>` instruction sources, start-prompt
  templates (`{{task}}`, `{{assignment}}`, `{{role}}`, `{{overseer}}`
  placeholders), and reporting/error rules; projects override or extend the
  catalog via `.ace/coworker/roles/*.yml` (project wins over gem defaults).
- `ace-coworker roles` — list the preset catalog (name, source, description,
  instruction source) as a table or JSON; exit 0 for any valid catalog state
  (an empty catalog renders an explicit empty state); an invalid preset file
  fails with a specific error.
- `ace-coworker commission` — the role-instantiation primitive consumed by
  the planner (L4.2/L4.3 seam): expand a role preset plus the commission
  identity (`--role NAME --task REF --assignment ID --overseer ADDR`) into
  the documented `.ace-local/coworker/config.yml`. Renders the preset's
  start-prompt template (an explicit `--start-prompt` wins), performs the
  same identity checks as `start` (task resolves in this worktree;
  assignment exists and its `task_id` matches), validates the assembled
  config through the start-grade schema, and writes atomically — overwrite
  refused without `--force`, `--dry-run` resolves and renders without
  writing. No sequencing, no active-driver detection, no role policies
  (those belong to the planner); any role string remains valid config
  (ADR-034).
- Self-contained role instruction workflows addressable as
  `wfi://coworker/worker` and `wfi://coworker/spec`
  (`handbook/workflow-instructions/coworker/`): the worker drives its
  pinned assignment via ace-assign and treats failed required tests as a
  hard completion blocker (fail the step, never a false done; the report
  outcome stays derived from the assignment verdict); the spec delivers a
  complete behavior-first specification and escalates significant unresolved
  requirement gaps as `ace-hitl` questions to the overseer instead of
  guessing.
- wfi-source registration (gem defaults plus the tracked project mirror
  `.ace/nav/protocols/wfi-sources/ace-coworker.yml`); `ace-support-nav ~> 0.28`
  is a new runtime dependency so `wfi://` instruction sources resolve on
  fresh installs.

### Fixed

- Review follow-ups on the 0.5.0 roles & commission feature (M1-M3, L4-L7):
  - preset merge is keyed by filename (as documented), not by the `name`
    field: the loader now also validates that a preset's `name` matches the
    file's basename, so a project `worker.yml` declaring `name: builder`
    fails loudly instead of silently skipping the override (M1);
  - start-prompt template interpolation uses gsub's block form, so identity
    values containing backslash escapes (`\1`, `\0`, `\&`, `\\`) render
    literally instead of being mangled or crashing (M2);
  - `commission --config` refuses targets that resolve outside the project
    root (`config path '<path>' escapes the project root`) and refuses a
    directory target even with `--force` (`--config` must name a file)
    (M3, L6);
  - `roles` exit-code documentation now matches the actual behavior: exit 0
    for any valid catalog state including empty; invalid preset files fail
    with a specific error (non-zero exit) (L4);
  - the overwrite refusal's TOCTOU window (exist? → mv) is documented in
    code as an accepted single-planner assumption (L7).

## [0.4.0] - 2026-10-18

### Added

- `ace-coworker prepare` (planner commission acceptance, L4.1): accepts a
  preparation commission (`--task REF --roles worker,reviewer [--to ADDR]`)
  and deterministically finds or prepares exactly one proper worktree for
  the task via `ace-git-worktree` (association-aware switch, idempotent
  create, stale-metadata prune/recreate recovery). Re-preparation reuses the
  existing worktree with zero writes; an active executor (a commissioned
  assignment that is not completed, or an uncommissioned running/stalled
  assignment) or a mismatched worktree escalates a decision-type `ace-hitl`
  question to the overseer instead of overwriting work. `--dry-run` performs
  the full resolution and conflict detection with zero effects; the result
  is rendered as a table or the JSON preparation contract (worktree
  path/branch/disposition, assignments, active-executor evidence, conflict)
  consumable by the next role or tool. New runtime dependency:
  `ace-git-worktree ~> 0.27`.

### Fixed

- Review follow-ups on `prepare` (M1/M2/L1-L4):
  - stale-metadata detection is real: the owner's `switch` never resolves a
    missing directory, so a failed switch is cross-checked against the
    association inventory — a registration for this task pointing at a
    missing directory reports `would_recover` under `--dry-run` (matching
    the real run) and recovers via prune + recreate, reattaching the
    surviving branch so its committed work is never orphaned behind a
    freshly minted branch (previously the reattach tripped over the
    surviving branch and errored) (M1);
  - a completed commissioned assignment no longer short-circuits the
    uncommissioned in-flight scan — other running/stalled assignments still
    block as an `active_executor` conflict (M2);
  - `active_executor` in the result JSON carries the rule evidence
    (`assignment`, `state`, `source`) on an `active_executor` conflict
    instead of always rendering null (L1);
  - the overseer fallback reads the config's `overseer` field leniently, so
    a partial planner-side config still names its recipient; a config that
    fails full validation without any overseer surfaces the load error in
    the conflict detail instead of a silent "no overseer address" (L2);
  - a missing `ace-hitl` binary during conflict escalation folds the error
    into the conflict detail (event id null) so the structured conflict
    result still renders (L3);
  - `WorktreeExecutorProbe#probe` docstring matches the actual return
    contract (failures raise; no `error:` key) (L4).
- Round-2 review follow-ups on `prepare` (all low severity):
  - the branch-reattach fallback now also works on the
    `create_with_verification` recovery sub-path (the known branch is
    passed through instead of dropped);
  - an occupied expected directory after prune classifies as
    `mismatched_worktree` (same rule as the miss path) instead of an
    operational `error`, and a failed prune surfaces its error instead
    of being ignored;
  - the recovery error hint no longer suggests re-running
    `ace-git-worktree prune` (it already ran in this method); the
    `--roles` option example and the prepare table's disposition row
    alignment are fixed.

## [0.3.2] - 2026-10-18

### Changed

- Round-9 review follow-ups (L1/L4/L5 + QA gap):
  - `Models::Config#with(assignment:)` owns the identity copy for the
    `--assignment` override (single place, no field-drift between the
    config assignment and the override); the report orchestrator now
    calls it instead of copying fields itself (L1).
  - `resume` says "reporting the outcome" when the delegated report run
    created a NEW event (the F2 error→success path) and reserves
    "redelivering the report" for true resends of the same event (L4).
  - end-to-end regression: reporting a success after a DELIVERED error
    report creates a new event through the orchestrator (F2 orchestrator
    path; previously only the atom was covered).
  - test cleanup: removed dead HITL event-file scaffolding left over
    from the pre-F7 glob-based existence check (L5).

## [0.3.1] - 2026-10-18

### Fixed

- Report/resume correctness after PR #383 audit (F2/F3/F4/F7/F8/F9):
  - `resume`: a completed assignment whose earlier DELIVERED report was an
    error (later fixed) no longer resolves to `complete` — only a delivered
    SUCCESS report matches a completed assignment, so resume reports the
    success instead of leaving the overseer with the stale error (F2).
  - `report`: the created HITL event ID is persisted to helper state
    BEFORE the send effect, so an interrupt/crash during send (after the
    message may already be delivered) never orphans the event; a rerun
    reuses the same ID instead of minting a duplicate (F3).
  - `report --assignment B` now threads B's identity consistently through
    the durable record, evidence paths, and the HITL message — previously
    B's result was reported under the config assignment's ID (F4).
  - the existing-event check on reruns goes through the ace-hitl CLI
    (`show <id> --path`) instead of globbing the constant `.ace-local/hitl`
    path, so events stored under a custom `hitl.root_dir` are reused, not
    duplicated (F7).
  - report records serialize the delivery value, so a normal delivery
    failure (`delivery: failed: <free-form cause>`) no longer breaks the
    frontmatter for `YAML.safe_load` (F8).
  - `start` and `status` no longer swallow `Interrupt` into a success
    return; the exe wrapper's exit(130) handles Ctrl-C again (F9).

## [0.3.0] - 2026-10-18

### Added

- `ace-coworker resume` (8xg.t.sbz.2.3 / L3.4): after an interruption,
  reads the existing assignment, task, and the REAL state of the same
  worktree, and renders the resume path. Dispositions: `continue`
  (preserved done steps, remaining work, in-flight step with its recorded
  cause/report and verify-before-repeat guidance, preserved local changes —
  never reset; effect caution for merge/publish/deploy/release/push steps:
  check actual state with existing tools or report a blocker, never blind
  replay, never a new task/worktree), `report` (assignment complete but
  delivery missing — delegates to the existing report flow, resending the
  SAME HITL event ID; retrying delivery never retries the assignment), and
  `complete` (informational). `--dry-run` derives the plan with zero writes;
  resume itself writes nothing on the continue path and never drives
  assignment steps. No journal/checkpoint store — the worktree git state,
  ace-assign step files, and report state ARE the checkpoint (ADR-034).

## [0.2.0] - 2026-10-18

### Added

- `ace-coworker report` (8xg.t.sbz.2.2 / L3.3): records the assignment
  outcome and reports it through the ace-hitl interface. The outcome is
  derived from the ace-assign verdict (a `--result success` on an incomplete
  assignment is refused before anything is written; an error outcome carries
  a cause — explicit `--message` or the failed step's recorded error — and
  the unfinished step, never a false work done). The durable record is
  written FIRST into the task's own folder (`<task>/coworker/<assignment>.md`);
  helper state lives under `.ace-local/coworker/reports/`; the report event
  goes through `ace-hitl create --type report --to <overseer>` and
  `ace-hitl send`. Outcome and delivery are strictly separated: an
  undelivered report keeps the recorded outcome and exits 1 with an explicit
  delivery error, and a rerun resends the same event instead of duplicating
  it (retrying delivery never retries the assignment). `--no-send` creates
  the event without delivering; `--dry-run` derives the outcome with zero
  writes; `errors.on_failure: stop` records errors locally without any HITL
  subprocess. `ace-hitl ~> 0.22` is now a runtime dependency.

## [0.1.0] - 2026-10-18

### Added

- `ace-coworker` gem: prepared executor for the file-based lab, owner of
  `.ace-local/coworker/` (ADR-034).
- `start` command: loads and validates the prepared run config (role,
  instructions, start prompt, task, assignment, overseer, error rules) with
  field-specific errors, resolves the task in the worktree, verifies the
  assignment↔task match, resolves the instruction source (file or
  `wfi://`/`prompt://`/`tmpl://` via `ace-nav`), and renders the executor
  brief pinning `--assignment <id>`. Writes nothing; never guesses a
  substitute commission.
- `status` command: readiness query (absent config renders `not ready: …`,
  exit 0), assignment progress from `ace-assign status --format json`, and a
  deterministic completion verdict with remaining-work reasons.
- Documented start-config contract consumed by the L4 planner
  (`docs/usage.md`).

### Fixed (review PR #383, round 3)

- `start_prompt_file` is containment-checked against the project root (same
  rule as the instruction source): absolute paths and `..` traversal are
  rejected instead of read.
- Assignment ids are validated (`letters/digits/dot/dash/underscore`) before
  path joining, closing a `..` traversal in the metadata reader.
- The `status` table labels probe failures `assignment error:` (matching the
  JSON key) instead of duplicating the `assignment:` row.

### Fixed (review PR #383, round 1)

- `start_prompt_file` content is now actually read: the loader resolves the
  file relative to the project root, rejects missing/empty files with specific
  errors, and uses the file contents as the start prompt (the filename is no
  longer printed as the prompt).
- Relative `--config` paths resolve against the project root in `status` too,
  not the process working directory.
- `status --assignment <override>` reports the effective (queried) assignment
  identity in table and JSON output, not the configured one.
- Malformed YAML and scalar nested sections (`reporting: hitl`,
  `errors: stop`) render as documented invalid/not-ready results instead of
  raising Psych/TypeError through the CLI.
- `ace-assign` is declared as a runtime dependency (fresh installs get the
  required CLI); missing subprocess binaries (`ace-assign`, `ace-nav`) fail
  with explicit actionable errors instead of `Errno::ENOENT` crashes.
