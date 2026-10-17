# ADR-034: File-Based Lab State Ownership

## Status

Accepted
Date: 2026-10-17

## Context

The earlier lab model spread execution state across a protected authority,
journals, queue machinery, and listener processes. The approved ACE lab program
replaces that model with file-based operations: existing `ace-task`,
`ace-assign`, `ace-hitl`, `ace-git-worktree`, and `ace-overseer` act on local
files. L1 must therefore make the owner and the single write location of every
piece of persisted state explicit, and must make the private overseer task list
reachable without tracking it in Git.

Without a single owner map, consumers duplicate state (a second queue, an extra
cache, a journal mirror), and private overseer work risks leaking into project
scope or into version control.

## Decision

### One write location per information

| Information | Write location | Owner |
|---|---|---|
| Project task specs and progress | `.ace-tasks/` | `ace-task` |
| Private overseer task list | `.ace-local/overseer/tasks/` (untracked) | the owning overseer, via `ace-task --in _overseer` |
| Assignment execution plan and step reports | `.ace-local/assign/` | `ace-assign`; steps are not copied elsewhere |
| Coworker run configuration (reserved for L3) | `.ace-local/coworker/` | `ace-coworker` in L3: role, instruction source, start prompt, task, assignment reference, overseer address, reporting and error rules |
| HITL agent events | `.ace-local/hitl/` | `ace-hitl`; reports need no answer, questions are answered on the exact case |
| Project task worktree | `.ace-wt/<task>/` | `ace-git-worktree`; one worktree per project task |

### Private `_overseer` store

- `task.stores` in `.ace/task/config.yml` maps store names to task roots;
  `ace-task/.ace-defaults/task/config.yml` ships
  `_overseer: .ace-local/overseer/tasks`. Paths are relative to the project root
  unless absolute.
- A store root becomes the task manager root, so it is resolved before create
  destination validation. `create` creates the store root when missing.
- `create`, `list`, `show`, and `update` accept `--in <store>` as the store
  selector; `next`, `maybe`, `anytime`, `archive`, and custom folders keep
  their special-folder meaning. `status` and `plan` remain project-scoped.
- Because the store lives under `.ace-local/` it is untracked and is never
  scanned by the project task list. `--git-commit` is rejected for store tasks.

### Canonical owner document

`docs/lab-flow.md` (`doc-type: bundle`) is the canonical owner map and local
flow. It is loaded by the `project` bundle preset and linked from `AGENTS.md`,
the root `README.md`, and `docs/quick-start.md`.

### Explicit non-owners

The lab does not add a journal, authority/admission layer, listener/daemon,
topology registry, queue engine, extra state cache, or mutation authorization
broker. Permissions belong to the existing accounts and files, and adapters are
built in L2 rather than as a new shared state service.

## Consequences

- Project `ace-task list`, `show`, and the directory scanner cannot see the
  private store; overseer tasks require an explicit `--in _overseer`.
- Each package reads and writes only its own location; no consumer mirrors
  assignment steps or the overseer queue.
- L2-L10 planned waves (HITL interface, coworker, planner, roles, private
  overseer queue, status/continuation, installer, acceptance, release) build on
  this map without introducing another state store.
- No compatibility layer is kept for the removed lab mechanisms (ADR-024).
- Old worktrees, branches, reports, and archives are not deleted by this
  decision.
