# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
