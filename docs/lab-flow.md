---
doc-type: bundle
title: Lab State Owners and Local Flow
purpose: Canonical state ownership map and executable local flow for the ACE lab
ace-docs:
  last-updated: '2026-10-17'
---

# Lab State Owners and Local Flow

The lab is file-based: active ACE commands and instructions describe one local
flow, and every piece of persisted information has exactly one write location
and one owner. This document is the canonical map. Package docs and workflows
point here instead of defining a second queue, journal, cache, or state service.

## One Write Location Per Information

| Information | Write location | Owner |
|---|---|---|
| Project task specs and their progress | `.ace-tasks/` (tracked) | `ace-task`; one project task per folder |
| Private overseer task list | `.ace-tasks/_overseer/` (untracked via `.gitignore`) | the overseer that owns it, via `ace-task --in _overseer` |
| Assignment execution plan and step reports | `.ace-local/assign/` | `ace-assign`; steps are not copied into another queue or config |
| Coworker run configuration (L3) | `.ace-local/coworker/` | reserved in L3: role, instruction source, start prompt, task, assignment reference, overseer address, reporting and error rules |
| HITL agent events | `.ace-local/hitl/` | `ace-hitl`; a report needs no answer, a question is answered on the exact case |
| Project task worktree | `.ace-wt/<task>/` | `ace-git-worktree`; one worktree per project task |

Task progress that must survive between turns is written inside that task's own
folder under `.ace-tasks/`, not in a separate journal.

### Private `_overseer` folder

The private overseer task list is an ordinary special folder in the task tree:
`.ace-tasks/_overseer/`. It is gitignored, so it never enters commits, while
`ace-task` treats it like any other special folder.

- `ace-task create "..." --in _overseer` creates the folder when missing.
- `ace-task list --in _overseer` narrows the shared list to private tasks.
- The default `ace-task list` is the shared view: project root tasks and
  `_overseer` tasks together. `_maybe`, `_archive`, and other special folders
  stay hidden unless `--in all` (or their folder) is used.
- `show`, `update`, subtasks, dependencies, `status`, and `plan` resolve
  `_overseer` refs the same way as any other task; `update --move-to overseer`
  and `--move-to next` move tasks in and out of the folder.
- `--git-commit` is rejected for `_overseer` tasks because the folder is
  untracked.
- No worktree is created for an `_overseer` task, and it cannot be used as a
  project implementation assignment: the management task stays with the
  overseer, and a separate project task is used for implementation. Subagents may
  still be delegated planning, analysis, verification, or dependency analysis;
  the overseer approves their results and updates its own task tree.
- `ace-task status` includes `_overseer` tasks in the shared totals and
  recently-done list; up-next remains project-root tasks, like other special
  folders. `ace-task plan` resolves `_overseer` refs and writes its plan cache
  under the project root, also when run from a subdirectory.
- A missing owner configuration is reported as not ready by the owning role
  path; the L3 coworker start/status path reports an absent
  `.ace-local/coworker/` configuration as not ready rather than guessing one.

## Explicit Non-Owners

The lab does not add a journal, authority/admission layer, listener/daemon,
topology registry, queue engine, extra state cache, or mutation authorization
broker. Permissions belong to the existing accounts and files. See
[ADR-034](decisions/ADR-034-file-based-lab-state-ownership.md).

## Executable Local Flow After L1

The flow below runs locally with the files above; each step writes only to its
owner's location.

The overseer's own coordination tasks live in `.ace-tasks/_overseer/`; every
implementation step below points at a separate project task (`.ace-tasks/`).
Worktrees and implementation assignments are rejected for `_overseer` tasks,
while subagents remain available for planning, analysis, verification, and
dependency analysis.

1. **Write the project task** — `ace-task create "..."` (writes `.ace-tasks/`).
2. **Plan the work** — `ace-task plan <ref>` (ephemeral plan cache under the project root; the task stays in `.ace-tasks/`).
3. **Provision the worktree** — `ace-git-worktree create --task <ref>` (writes `.ace-wt/<task>/`; project tasks only).
4. **Create the assignment** — `ace-assign create --task <ref> --preset work-on-task` (writes `.ace-local/assign/`; project tasks only).
5. **Drive it** — `/as-assign-drive` in the agent session; the steps execute and report under `.ace-local/assign/`.
6. **Verify** — run package tests and review; results are recorded in the task folder or assignment reports.
7. **Escalate blockers** — `ace-hitl create`, `ace-hitl list`, `ace-hitl update`, `ace-hitl wait` (writes `.ace-local/hitl/`; the overseer interprets the report/question and updates its own task in `.ace-tasks/_overseer/`).
8. **Ship** — commit with `ace-git-commit`, then open a PR with `ace-git pr create` (project tasks only; `_overseer` tasks are never committed).
9. **Close** — mark the project task done with `ace-task update <ref> --set status=done` (archive when the family is terminal).

`ace-overseer work-on` / `status` / `prune` is local convenience over the same
files: it does not introduce another state owner.

## Planned Waves L2-L10 (not available yet)

These waves are planned, not implemented in the current local flow. A wave is
available only after its subtasks are integrated; this table is not a runtime
queue.

| Wave | Planned capability | Status |
|---|---|---|
| L2 | One HITL interface for reports, questions, and replies, with configurable adapters | Planned |
| L3 | `ace-coworker` starts from prepared config, drives its assignment, reports, and resumes | Planned |
| L4 | Planner accepts work, provides the worktree, and prepares the assignment sequence | Planned |
| L5 | Worker/reviewer/integrator/spec roles and unambiguous completion rules (3-10 review rounds) | Planned |
| L6 | Private overseer queue: execute unblocked steps, hand off the worktree, process reports | Planned |
| L7 | Overseer status plus pi continuation for already-delegated work | Planned |
| L8 | Installer and `project add`: prepare accounts, directories, permissions, keys, and a ready project | Planned |
| L9 | Full-flow and failure acceptance scenarios on one candidate | Planned |
| L10 | Release gems and verify the full flow on a fresh lab from RubyGems | Planned |

`_overseer` can already be used as a private task list; the automated L6 queue
behavior is not available yet.
