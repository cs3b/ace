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
| Per-role executor start configs (L4.3) | `.ace-local/coworker/prepare/<role>.yml` in the task worktree | `ace-coworker` (the planner, via `ace-coworker prepare`); one leg config per planned sequence role, written through the `commission` primitive so `start --config` accepts it; `commission` stays the single writer of the default `config.yml` target |
| Review-round history per reviewer assignment | `.ace-local/coworker/review-rounds/` | `ace-coworker` (the coworker reviewer role, via `ace-coworker rounds record`); the 3/2/10 convergence evidence — one JSON file per assignment |
| HITL agent events | `.ace-local/hitl/` | `ace-hitl`; a report needs no answer, a question is answered on the exact case |
| Project task worktree | `.ace-wt/<task>/` | `ace-git-worktree`; one worktree per project task |

Task progress that must survive between turns is written inside that task's own
folder under `.ace-tasks/`, not in a separate journal.

### Private `_overseer` folder

The private overseer task list is the ordinary folder `.ace-tasks/_overseer/`.
The lab prepares the folder (for example `mkdir -p .ace-tasks/_overseer`) and
its `.gitignore` entry; `ace-task` itself is folder-name agnostic and handles it
like any other existing folder. When a rule depends on Git tracking, `ace-task`
asks Git about the actual task path — never about the folder's name.

- `ace-task create "..." --in _overseer` places a task in the prepared folder
  (a custom `--in` destination must already exist).
- `ace-task list --in _overseer` lists private management tasks; the default
  `ace-task list` is the ordinary root view.
- `show`, `update`, subtasks, dependencies, `status`, and `plan` work for
  `_overseer` tasks like for any other task; Git tracking does not change the
  task model.
- `--git-commit` is rejected whenever the task path is Git-ignored — the task
  folder, its children, its spec file, or a destination a relocation would
  create — on create, subtask creation, update, and move, because Git would not
  stage it.
- Completing a private task (or the last subtask of a private family) does not
  auto-archive it, does not create a private archive folder, and `ace-task
  doctor` neither reports the missing archive nor moves the task with
  `--auto-fix`; a move into an ignored archive destination is skipped too. The
  overseer decides when obsolete private history is deleted.
- `ace-assign` and `ace-git-worktree` are role- and folder-name-agnostic: they
  do not classify management tasks and do not inspect `.gitignore`. The overseer
  decides which tasks it delegates and where the executor starts; preparing a
  correct delegation (including a task present in the requested worktree) is the
  requester's responsibility.
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
implementation step below points at the task the overseer selects. Delegation
tools do not classify tasks by folder or tracking state: the overseer decides
which tasks it delegates and where the executor starts. If a requested worktree
does not contain the named task, the executor reports the missing task.

1. **Write the project task** — `ace-task create "..."` (writes `.ace-tasks/`).
2. **Plan the work** — `ace-task plan <ref>` (ephemeral plan cache under the project root; the task stays in `.ace-tasks/`).
3. **Provision the worktree** — `ace-git-worktree create --task <ref>` (writes `.ace-wt/<task>/`).
4. **Create the assignment** — `ace-assign create --task <ref> --preset work-on-task` (writes `.ace-local/assign/`).
5. **Drive it** — `/as-assign-drive` in the agent session; the steps execute and report under `.ace-local/assign/`.
6. **Verify** — run package tests and review; results are recorded in the task folder or assignment reports.
7. **Escalate blockers** — `ace-hitl create`, `ace-hitl list`, `ace-hitl update`, `ace-hitl wait` (writes `.ace-local/hitl/`; the overseer interprets the report/question and updates its own task in `.ace-tasks/_overseer/`).
8. **Ship** — commit with `ace-git-commit`, then open a PR with `ace-git pr create` (a private `_overseer` task is never committed because the folder is gitignored).
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
| L4 | Planner accepts work, provides the worktree, and prepares the assignment sequence | Partially shipped — `ace-coworker prepare` (L4.1) ensures the worktree, composes the whole role-sequence assignments (L4.2), writes per-role start configs (L4.3), and reports readiness/gaps to the overseer via ace-hitl (L4.4) |
| L5 | Worker/reviewer/integrator/spec roles and unambiguous completion rules (3-10 review rounds) | Shipped — worker/spec/reviewer/integrator role presets; the deterministic 3/2/10 round rule (`ace-coworker rounds record`) and the pre-merge integration gate (`ace-coworker gate`) enforce the completion rules |
| L6 | Private overseer queue: execute unblocked steps, hand off the worktree, process reports | Partially shipped — `ace-overseer work-on` (L6.3) starts only unblocked steps, `ace-overseer handoff` (L6.4) passes the worktree to the next role, and `ace-overseer process-reports` (L6.5) interprets incoming ace-hitl reports and continues the queue; automatic queue wakeup and closing the managing task remain with the overseer role |
| L7 | Overseer status plus pi continuation for already-delegated work | Shipped — `ace-overseer status` aggregates configurable sources (L7.2: worktrees, forge PRs, project/`_overseer` tasks, Herdr, coworker progress) and opens with a derived attention section (L7.4) that separates blockers (unsatisfied dependencies with reasons), failures (source errors, failed/stalled assignments, pending ace-hitl escalations) and missing data (disabled sources, unknown states) from healthy progress; the pi `/continue-work` resume prompt with report-wake wiring continues commissioned work after a message or restart (L7.3) |
| L8 | Installer and `project add`: prepare accounts, directories, permissions, keys, and a ready project | Partially shipped — `ace-lab prepare` (L8.1) converges accounts, directories, keys, and roles from the trusted install manifest; `project add` and the full installer remain planned |
| L9 | Full-flow and failure acceptance scenarios on one candidate | Planned |
| L10 | Release gems and verify the full flow on a fresh lab from RubyGems | Planned |

`_overseer` can already be used as a private task list, and the L6.3-L6.5
gates (`work-on`, `handoff`, `process-reports`) execute the private queue on
demand; the queue is not yet woken automatically and the managing task is
closed by the overseer role, not by the tooling.
