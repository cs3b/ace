# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
