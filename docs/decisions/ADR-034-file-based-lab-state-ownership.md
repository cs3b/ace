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
| Private overseer task list | `.ace-tasks/_overseer/` (untracked via `.gitignore`) | the owning overseer, via `ace-task --in _overseer` |
| Assignment execution plan and step reports | `.ace-local/assign/` | `ace-assign`; steps are not copied elsewhere |
| Coworker run configuration (reserved for L3) | `.ace-local/coworker/` | `ace-coworker` in L3: role, instruction source, start prompt, task, assignment reference, overseer address, reporting and error rules |
| HITL agent events | `.ace-local/hitl/` | `ace-hitl`; reports need no answer, questions are answered on the exact case |
| Project task worktree | `.ace-wt/<task>/` | `ace-git-worktree`; one worktree per project task |

### Private `_overseer` folder

- `.ace-tasks/_overseer/` is an ordinary special folder under the task root and
  is listed in `.gitignore`, so its tasks never enter commits.
- `ace-task create "..." --in _overseer` creates the folder when missing and
  `list --in _overseer` narrows the scope. The default `ace-task list` is the
  shared view of project root tasks plus `_overseer` tasks; `_maybe`,
  `_archive`, and other special folders stay hidden by default.
- `show`, `update`, subtasks, dependencies, `status`, and `plan` handle
  `_overseer` refs like any other task; `update --move-to overseer` and
  `--move-to next` move tasks in and out of the folder. `--git-commit` is
  rejected for `_overseer` tasks because the folder is untracked.
- Prohibition: no worktree is created for an `_overseer` task and it cannot be
  used as a project implementation assignment (`ace-git-worktree create --task`
  rejects it; `ace-assign create --task` applies the same rule). The management
  task stays with the overseer, and a separate project task carries the
  implementation. Subagents may still be delegated planning, analysis,
  verification, or dependency analysis; the overseer approves their results and
  updates its own task tree.

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

- The shared `ace-task list` shows project root tasks and `_overseer` tasks
  together, and `--in _overseer` narrows the scope; the private folder stays
  untracked and never enters commits.
- Worktree and implementation-assignment guards keep management tasks with the
  overseer, while subagent delegation for planning, analysis, and verification
  remains allowed.
- Each package reads and writes only its own location; no consumer mirrors
  assignment steps or the overseer queue.
- L2-L10 planned waves (HITL interface, coworker, planner, roles, private
  overseer queue, status/continuation, installer, acceptance, release) build on
  this map without introducing another state store.
- No compatibility layer is kept for the removed lab mechanisms (ADR-024).
- Old worktrees, branches, reports, and archives are not deleted by this
  decision.
