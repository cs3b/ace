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

- `.ace-tasks/_overseer/` is an ordinary folder under the task root that the lab
  prepares together with its `.gitignore` entry, so its tasks never enter
  commits. `ace-task` stays folder-name agnostic: it has no overseer-specific
  constants, create destinations, listing view, archive relocation, doctor
  exception, or commit block.
- `ace-task create "..." --in _overseer` places a task in the prepared folder
  and `ace-task list --in _overseer` lists it; the default `ace-task list` is
  the ordinary root view. A custom `--in` destination must already exist.
- Rules that depend on Git tracking ask Git about the actual task path
  (`git check-ignore`), from any working directory and with a custom task root:
  `--git-commit` is rejected for an ignored task folder, child, spec file, or
  relocation destination (create, subtask, update, move); completing an ignored
  task or family does not auto-archive it, and `ace-task doctor` neither
  reports the missing archive nor moves it with `--auto-fix` (including into an
  ignored archive destination). No private archive folder or retention
  mechanism exists; the overseer decides when obsolete private history is
  deleted.
- `show`, `update`, subtasks, dependencies, `status`, and `plan` handle
  `_overseer` refs like any other task; Git tracking does not change the task
  model.
- The universal tools stay role- and folder-name agnostic. `ace-assign` and
  `ace-git-worktree` do not classify management tasks and do not inspect
  `.gitignore`; the overseer decides which tasks it delegates and where the
  executor starts, and preparing a correct delegation (including a task present
  in the requested worktree) is the requester's responsibility. A missing task
  in a worktree is reported by the executor.

### Canonical owner document

`docs/lab-flow.md` (`doc-type: bundle`) is the canonical owner map and local
flow. It is loaded by the `project` bundle preset and linked from `AGENTS.md`,
the root `README.md`, and `docs/quick-start.md`.

### Explicit non-owners

The lab does not add a journal, authority/admission layer, listener/daemon,
topology registry, queue engine, extra state cache, or mutation authorization
broker. Permissions belong to the existing accounts and files, and adapters are
built in L2 rather than as a new shared state service. Role-specific policy does
not live in the universal tools or runtime: the old Root Overseer reverse-address
channel and systemd unit-name role check were removed, and no replacement role
policy or queue is added.

## Consequences

- The default `ace-task list` stays the ordinary root view; the lab prepares
  `.ace-tasks/_overseer/` and its ignore entry, `--in _overseer` reaches it, and
  `ace-task` derives tracking behavior from Git's ignore rules for the actual
  path rather than from folder names.
- A Git-ignored task keeps its plain task semantics but is never committed,
  auto-archived, or moved by `doctor --auto-fix`; its owner decides when to
  delete obsolete history.
- Worktree and assignment tools do not keep state about roles: the overseer
  decides which tasks it delegates and where the executor starts, and a missing
  task in a requested worktree is reported by the executor.
- Each package reads and writes only its own location; no consumer mirrors
  assignment steps or the overseer queue.
- L2-L10 planned waves (HITL interface, coworker, planner, roles, private
  overseer queue, status/continuation, installer, acceptance, release) build on
  this map without introducing another state store.
- No compatibility layer is kept for the removed lab mechanisms (ADR-024).
- Old worktrees, branches, reports, and archives are not deleted by this
  decision.
