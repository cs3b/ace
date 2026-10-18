# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
