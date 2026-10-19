# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Reviewer role (8xg.t.sbz.4.1 / L5.2): shipped preset
  `.ace-defaults/coworker/roles/reviewer.yml` and the self-contained
  `wfi://coworker/reviewer` workflow. The reviewer is independent of the
  worker, fixes confirmed defects itself inside its own single assignment
  (steps added via `ace-assign add`), checks each fix diff, and returns to
  full review rounds under the 3/2/10 convergence rule (stated, not yet
  deterministically enforced — that is 8xg.t.sbz.4.2). No effective fix or a
  needed product decision is escalated via an `ace-hitl` decision question;
  unresolved High/Critical is never marked as success.
- `ace-review` declared as a runtime dependency: the reviewer role's primary
  function drives the `ace-review`/`ace-review-feedback` CLIs, matching the
  gemspec's stated policy of declaring runtime CLI requirements.

### Fixed

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
