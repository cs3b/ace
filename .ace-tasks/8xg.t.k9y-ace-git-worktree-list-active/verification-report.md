# Verification Report — 8xg.t.k9y `ace-git-worktree list` active worktree table

Executed during work-on-task on 2026-10-17. All commands were run against this
checkout (`bin/` binstubs) with Ruby 3.4.8.

## Plan provenance

`bin/ace-task plan 8xg.t.k9y` stalled for >5 minutes with no output (planner role
dispatch, network-bound; no plan path was produced). Per the plan-retrieval
guard, the fallback JIT plan `implementation-plan.md` in this folder was authored
and used as the implementation checklist.

## Deterministic package tests

| Command | Result |
|---------|--------|
| `bin/ace-test ace-git-worktree` | 670 tests, 2099 assertions, 0 failures, 0 errors, 16 skipped |
| `bin/ace-test ace-overseer` | 288 tests, 1425 assertions, 0 failures, 0 errors |

New/changed fast coverage includes: duration parsing, relative age formatting,
text truncation, task index build/queries, task association precedence and
ambiguity, PR three-tier matching and cell mapping, recent-branch counting,
probe payloads against a real repo, forked probe runner (order, 16-child cap,
5s-timeout process-group kill, sequential fallback, discarded child output),
width/truncation policy with pinned `COLUMNS`, footer/header counts, report
pipeline (empty states, filters, JSON schema, quiet, determinism), the list CLI
flag contract (including `--show-tasks` rejection), and a full integration run
against a real multi-worktree repository with the real fork probe runner.

## CLI acceptance evidence

Fixture repo: 91 worktrees (1 primary + 90 linked), 30 worktrees with commits
inside 18h, task file changed in an opaque-named worktree.

| Check | Evidence |
|-------|----------|
| Compact default shape | `Active worktrees (last 18h) -- 31 of 91:` + 31 enriched rows + two-line footer; header/footer counts correct |
| Wall clock (success criterion 5) | `real 2.99s` for 91 worktrees with forked bounded probing (<=10s required) |
| `COLUMNS=120` width | max line length 120 chars, 0 lines over |
| `COLUMNS=80` width | max line length 80 chars, 0 lines over |
| `COLUMNS=60` | `Path` column dropped, remaining columns aligned; only the footer counts line exceeds 60 (width rule applies to the table; criterion 8 requires Path drop + alignment at 60) |
| `--full` | 91 rows, absolute untruncated paths, `Inactive: 60` |
| `--format json` | valid top-level array, 91 rows, keys include `task_id`, `task_id_source`, `task_ids`, `active_within_window`, `last_commit`, `uncommitted`, `pr` |
| `--active-within 2d` | header reads `last 2d`, reclassifies between 18h and 48h |
| No forge configured | every PR cell `-`, exit 0 |
| Name-independent association | opaque `codex/opaque` worktree resolved `task_id: ega`, `task_id_source: task_files` |
| `--active-within abc` | `Error: invalid duration 'abc'. Use forms like 30m, 18h, 2d, or bare hours.` exit 1 |
| `--compact --full` | `Error: --compact and --full are mutually exclusive` exit 1 |
| `--show-tasks` | unknown-option error, exit 1 |
| outside a git repository | `Failed to list worktrees: fatal: not a git repository...`, exit 1 |
| `list --help` | documents view/output/filtering flags plus DESCRIPTION with column semantics, task/PR inference, width behavior, and probe isolation; no `--show-tasks` |

## E2E scenario TS-WORKTREE-001 (success criterion 10)

Agent-driven runner: `bin/ace-test-e2e ace-git-worktree TS-WORKTREE-001`.

- Deterministic preflight tests: 4/4 pass.
- Scenario execution: blocked by an environment limitation, not by this change —
  no LLM provider is available in this environment (`pi` CLI not installed;
  `agy` rejected temperature through ace-llm; `claude` invocation exits non-zero).
  A first attempt additionally hit a host `mise` shim/ruby mismatch during
  sandbox bundle install, worked around by pinning PATH to the real Ruby 3.4.8
  bin directory.

Proxy evidence for the same goals (scripted exactly as the scenario commands
against a fresh sandbox-style repo with `feature/test-worktree` and
`bugfix/test-fix` branches):

| Goal | Command | Result |
|------|---------|--------|
| TC-002 list before | `ace-git-worktree list` | exit 0; main worktree only; header `1 of 1` |
| TC-002 create existing branch | `ace-git-worktree create feature/test-worktree` | exit 0, worktree created |
| TC-002 create new branch | `ace-git-worktree create --from main bugfix/test-fix` | exit 0, worktree created |
| TC-002 list after | `ace-git-worktree list` | exit 0; header `3 of 3`; both created worktrees present |
| TC-003 switch | `ace-git-worktree switch feature/test-worktree` | exit 0, prints worktree path |
| TC-003 formats | `list --format json/simple/table` | JSON parses (3 rows); simple and table non-empty with exit 0 |
| TC-004 dry run | `ace-git-worktree create bugfix/third --dry-run` | exit 0, "Dry run - no changes made" |

The independent LLM verifier pass could not run for the same provider
availability reason; the scenario assertions above were checked directly.

## Follow-ups / caveats

- `ace-task plan` stalled in this environment (planner dispatch); plan produced
  by fallback.
- E2E agent execution needs an available LLM provider (pi/agy/claude) and a
  sane mise shim `bundle` resolution in the host PATH.
