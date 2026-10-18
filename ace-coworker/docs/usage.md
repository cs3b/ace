---
doc-type: usage
title: ace-coworker Usage
purpose: full command reference and the start-config contract
ace-docs:
  last-updated: 2026-10-18
  last-checked: 2026-10-18
---

# ace-coworker Usage

`ace-coworker` is the prepared executor of the file-based lab. The planner
(L4) writes the run configuration; `ace-coworker` reads, validates, and
renders what the executor agent must drive. This document is the single
source for the start-config format.

## Start config — `.ace-local/coworker/config.yml`

```yaml
role: worker                          # required, non-empty role name
instructions: "roles/worker.md"       # required: file path relative to the
                                      # project root, or wfi:// prompt:// tmpl://
start_prompt: "Drive assignment <id> for task <ref> as worker."
                                      # required (or start_prompt_file: path
                                      # relative to the project root, whose
                                      # content becomes the prompt; the two
                                      # are mutually exclusive)
task: "8xg.t.sbz.2"                   # required: task ref that must resolve
                                      # in this worktree
assignment: "abc123"                  # required: assignment id that must exist
                                      # under .ace-local/assign/ and whose
                                      # task_id matches `task`
overseer: "overseer@machine"          # required: reporting address (opaque
                                      # string until the L2 addressing scheme
                                      # is integrated)
reporting:
  channel: hitl                       # optional, default hitl
errors:
  on_failure: report                  # optional: report | stop (default report)
```

Validation is field-specific: every missing or invalid field produces its own
error, and no substitute commission is guessed. The config never copies
assignment steps — the plan stays solely with `ace-assign`.

## Commands

### `ace-coworker start`

```
ace-coworker start [--config PATH] [--format table|json] [-q] [-d]
```

Reads the config (default `.ace-local/coworker/config.yml`), then:

1. resolves the task ref in this worktree via `ace-task`;
2. verifies the assignment exists under `.ace-local/assign/` and its
   `task_id` matches the config task;
3. reads assignment truth from `ace-assign status --assignment <id> --format json`;
4. resolves the instruction source (file relative to the project root, or
   protocol URI via `ace-nav resolve`);
5. prints the executor brief: role, resolved instruction source, start
   prompt, task ref + path, the pinned `--assignment <id>` drive target,
   overseer address, error rules, and current assignment state.

`start` writes nothing. Exit codes: `0` ready; `1` with a specific message
(`not ready: …`, `invalid config …: …`, `task '<ref>' not found in this
worktree`, `assignment '<id>' not found …`, `assignment '<id>' belongs to task
'<other>', not '<ref>'`, `instruction file '<path>' not found in this
worktree`).

### `ace-coworker status`

```
ace-coworker status [--config PATH] [--assignment ID] [--format table|json] [-q] [-d]
```

Readiness query — always exit `0`. Absent config renders
`not ready: .ace-local/coworker/config.yml not found`. Otherwise renders the
resolved role/task/assignment/overseer, the assignment progress, and the
completion verdict with remaining-work reasons (empty plan, failed steps,
pending/active steps).

The completion verdict is deterministic: `complete` iff the assignment state
is `completed`, the step plan is non-empty, and every step is `done`. Process
or session end never implies completion.

## Exit codes

| Command | 0 | 1 |
|---|---|---|
| `start` | config valid, task+assignment verified, brief rendered | missing/invalid/mismatched input |
| `status` | query rendered any state (including not-ready) | — |

## Boundaries

- `.ace-local/coworker/` is owned by `ace-coworker`; `.ace-local/assign/` by
  `ace-assign`; `.ace-local/hitl/` by `ace-hitl`; `.ace-tasks/` by `ace-task`.
- No journal, queue, daemon, or second plan store (ADR-034).
- Delegation to `ace-assign` / `ace-nav` uses argv subprocess calls with an
  explicit working directory (ADR-031).
- Reporting via `ace-hitl` and resume-after-interruption arrive with leaves
  8xg.t.sbz.2.2 / 8xg.t.sbz.2.3.
