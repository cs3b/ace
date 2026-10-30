---
doc-type: user
title: ace-overseer Usage
purpose: CLI reference for local overseer worktrees, assignments, and cleanup.
ace-docs:
  last-updated: 2026-10-17
  last-checked: 2026-10-17
---

# Usage

> **State owner:** `.ace-tasks/_overseer/` (private, gitignored task folder
> reached via `ace-task --in _overseer`) and `.ace-wt/` (one worktree per
> project task). Assignment plans live in `.ace-local/assign/` and are not
> copied here. See [docs/lab-flow.md](../../docs/lab-flow.md).

## Command Surface

Local work uses six primary commands (`projects` lists configured lab projects):

- `ace-overseer start` - start or reuse the project overseer session from configuration.
- `ace-overseer work-on` - prepare a worktree, assignment, and terminal.
- `ace-overseer handoff` - hand the task worktree to the next role in the prepared sequence.
- `ace-overseer process-reports` - interpret ace-hitl reports and continue the queue.
- `ace-overseer status` - show active task worktrees and assignment progress.
- `ace-overseer prune` - remove completed task worktrees safely.

`--project`/`--agent` protected execution and the installed `ordinary`
launcher are removed in L1 and are not normal paths. Status and prune read
local assignment/task/worktree/Git state only; there is no journal, attempt or
authority execution model. tmux and Herdr are transports, never state owners.

## `ace-overseer start`

Start or reuse the PROJECT overseer session from the directory's own
configuration (task 8xs.t.pu0.1). The start contract is explicit — nothing is
guessed and no interim default model applies:

```yaml
# .ace/overseer/config.yml (project tier of the cascade)
start:
  scope: project            # project | lab (lab: not implemented yet)
  profile: overseer-default # reference into the profiles map below
  instructions: wfi://overseer/start  # handbook source (or absolute file path)
profiles:
  overseer-default:
    harness: pi
    model: zai/glm-5.3-flash
    thinking: high
```

| Option | Purpose |
|--------|---------|
| `--dry-run` | Show the start plan; no session, no sync, no model call |
| `--format` | `table` (default) or `json` |

Behavior:

- The project root is canonical: a subdirectory, a symlinked checkout, and a
  linked worktree of one repository resolve to the SAME owner, so one project
  never runs two whole-project overseers.
- Session identity is Herdr's: the tab/pane label `overseer-<project>` on the
  caller's herdr workspace. A live owner pane is REUSED (`status: reused`); a
  live pane whose cwd resolves elsewhere is a conflict (`status: blocked`,
  never taken over); a dead owner pane is replaced and the new identity is
  reported (`replaced_pane`).
- The guide resolves through the normal handbook chain (`wfi://` sources via
  the project's `ace-nav`; absolute paths verbatim) and boots the harness
  agent as standing instructions with the configured profile.
- The report carries `status` (`started|reused|blocked|dry_run`), `scope`,
  `root`, `label`, `workspace`, `pane`, `agent`, `profile`, `instructions`
  (`source` + resolved `path`) and a `message`. Exit 0 only for a ready
  start/reuse (dry-run included); a blocked start is a CLI error naming the
  missing configuration.
- The started overseer coordinates and delegates (guide:
  `wfi://overseer/start`); it never substitutes for a missing coworker.

## `ace-overseer observe`

Read-only standing observation the started overseer's eyes poll (task
8xs.t.pu0.3). The projection merges the six local source classes, each read
from its state owner — never a second task/assignment state:

- HITL events (semantic revisions; reports/questions toward this owner),
- project tasks and private `_overseer` tasks (`ace-task`),
- worktrees (`ace-git-worktree`),
- coworker availability and assignment progress (`ace-coworker` probe over the
  `ace-assign` inventory; live/stale judged by existing run identifiers —
  commissioned assignment ids — never pane names).

Every row carries a stable `key` and a `revision` that changes only when the
owner's data changes: identical state projects identical revisions (healthy
silence consumes zero model turns), and a real change wakes the observer once.
A failing source degrades ONLY itself — it contributes a `source-health` row
whose revision is keyed by the failure class (an identical repeated failure
never re-wakes; a new failure mode wakes once) while the healthy sources keep
projecting. `sources` maps each source to `ok`/`degraded`. After a restart,
pending revisions reconcile before new work is chosen, so a report that
arrived during the overseer's absence is recognized exactly once.

## `ace-overseer work-on`

Create or reuse local worktrees and prepare one assignment.

| Option | Purpose |
|--------|---------|
| `--task`, `-t` | Task ref(s); repeatable and comma-separated |
| `--preset`, `-p` | Assignment preset name (default `work-on-task`) |
| `--runtime` | Terminal backend: `auto`, `tmux` or `herdr` |
| `--quiet`, `-q` | Suppress non-essential output |
| `--debug`, `-d` | Show debug output |

```bash
ace-overseer work-on --task 8q4
ace-overseer work-on --task t.123,t.124 --preset work-on-task --runtime herdr
```

Work-on is idempotent: rerunning with the same task refs reuses the existing
worktree and assignment instead of creating duplicates. Draft tasks are
blocked until reviewed.

Work-on only starts steps whose recorded `dependencies` are satisfied by real
task-tree state: every predecessor must have status `done` (accepted *and*
integrated result). A finished worker, "work done" message, or open PR does
not unlock a dependent step -- model merge requirements by depending on the
predecessor's integration step. Cancelled, skipped, missing, or cyclic
predecessors block the start with explicit reasons, before any worktree or
assignment side effect. For a manager task with active subtasks, BOTH the
manager's own `dependencies` and each active subtask's `dependencies` are
gated. Two intentional edges: re-attaching to an already-started step whose
dependencies are (now) unsatisfied is refused like any other start -- open
the existing window directly instead of `work-on`; and the gate is strictly
`done`, whereas `ace-task list --sort smart` also treats an archived
predecessor as satisfied -- with normal auto-archive the two agree, but on
archived-non-terminal dirty data `list` may say ready while `work-on`
blocks (work-on is the authority for starting).

> Planner preparation of a worktree and a whole role-sequence (one
> assignment and start config per role) is delivered by `ace-coworker
> prepare`; `ace-overseer handoff` walks that sequence leg by leg.

## `ace-overseer handoff`

Hand the SAME task worktree to the next role in the prepared role sequence
(L6.4). The gate reads only real state: the worktree's role-sequence
assignments (ace-assign files, in composition order), their current states,
the per-leg start configs (`ace-coworker prepare`), and the worktree's
executor truth via the coworker active-executor rule. Nothing is re-prepared;
the next role starts from the existing start config.

| Option | Purpose |
|--------|---------|
| `--task`, `-t` | Task ref whose worktree receives the next role |
| `--runtime` | Terminal backend: `auto`, `tmux` or `herdr` |
| `--dry-run` | Check handoff readiness without opening a window |
| `--quiet`, `-q` | Suppress non-essential output |
| `--debug`, `-d` | Show debug output |

```bash
ace-overseer handoff --task 8q4                 # worker finished -> reviewer
ace-overseer handoff --task 8q4 --dry-run       # check only
```

Rules enforced mechanically: the handoff is ready only when every earlier leg
reached ace-assign state `completed` (a failed, in-flight, stalled, paused
predecessor, or an unknown/unreadable state refuses with reasons); no executor
may hold the worktree (commissioned, in-flight, or unparseable config all
block -- a busy worktree never gets a second executor and unknown state is
never a free resource); the next leg must have its existing start config. On
success a terminal window opens in the worktree and the exact start command
is printed (`ace-coworker start --config .ace-local/coworker/prepare/<role>.yml`).
When every leg is completed the command reports the sequence complete and
opens nothing. Handoff never creates a worktree; two different tasks hand off
independently in their own worktrees.

## `ace-overseer process-reports`

Process incoming ace-hitl reports/questions and continue the overseer queue
(L6.5). Every event is matched against the private `_overseer` tree, the
outcome is recorded through the existing `ace-task update` surface, and the
queue continues by reusing the existing gates — no new state, no dedup table.

| Option | Purpose |
|--------|---------|
| `--dry-run` | Interpret events without writes or continuation |
| `--quiet`, `-q` | Suppress non-essential output |
| `--debug`, `-d` | Show debug output |

```bash
ace-overseer process-reports            # interpret, record, continue
ace-overseer process-reports --dry-run  # what would happen, zero effects
```

Matching and outcome rules (enforced mechanically):

- A report matches the current order by the `assignment` recorded on a step.
  An explicit assignment that matches no step is `unmatched` — there is no
  task-only fallback, so a stale report for a different assignment never
  completes whichever step happens to remain. A report WITHOUT an assignment
  (a planner readiness report) matches only the preparation role: the
  managing task's `project_task` plus exactly one non-terminal step whose
  own assignment is blank. A report fitting no open allocation is reported
  as `unmatched` and kept for clarification — never treated as success.
- Success records `processed_report`/`report_result` on the step and marks
  it `done`, then continues with the next unblocked step (same
  `DependencyReadiness` gate as `work-on`): `ace-overseer handoff` for the
  next role when the family records a worktree, otherwise the `work-on`
  gate. A refused continuation is reported as blocked with reasons. The
  handoff outcome carries the actionable start command (the same one the
  Handoff CLI prints); the window is ensured, the agent runs the command.
- A repeated delivery of an already-processed report is `duplicate`: the
  recorded result and existing allocation answer it; nothing re-runs
  (delivery repetition is never work repetition). A duplicate whose
  recorded result is success still re-checks the continuation from current
  task/assignment state — the report result is persisted BEFORE dispatch,
  so a failed handoff (or a crash between the write and the dispatch) must
  not suppress the next role forever. Duplicate starts stay impossible: the
  gates read real allocation state.
- An `error` result records the cause on the step but keeps it open; a
  question surfaces its `ace-hitl update <id> --answer` path. Neither
  advances a step nor triggers a continuation.

## `ace-overseer status`

Show the overseer's one-view status: every configured source is collected
live, read-only, into one table or JSON payload. Nothing is persisted — the
view is always computed from the source owners' current state.

```bash
ace-overseer status
ace-overseer status --format json
ace-overseer status --watch
```

| Option | Purpose |
|--------|---------|
| `--format` | `table` (default) or `json` |
| `--watch`, `-w` | Auto-refresh the worktree dashboard |
| `--runtime` | Terminal backend used for pane checks |
| `--quiet`, `-q` | Suppress non-essential output |
| `--debug`, `-d` | Show debug output |

### Sources

Sources are configured under `status_sources` in the overseer config
(`.ace/overseer/config.yml`; defaults in the gem's
`.ace-defaults/overseer/config.yml`). Each key is one source; setting
`enabled: false` disables it.

| Source | Information | Owner interface used |
|--------|-------------|----------------------|
| `worktrees` | worktrees with assignment progress and git state | `ace-git-worktree` WorktreeManager + worktree assignment context |
| `forge` | recent forge pull requests and issues (explicit unavailable marker when the provider has no issue-listing API) | `ace-git` Providers `recent_pull_requests` / `recent_issues` (forge-neutral) |
| `project_tasks` | project task ids, statuses, dependencies (full descendant tree) | `ace-task` TaskManager (`.ace-tasks/`) |
| `overseer_tree` | private overseer tasks including lifecycle steps and their recorded reports | `ace-task` TaskManager (`.ace-tasks/_overseer/`) |
| `herdr` | live workspaces/tabs/panes | `ace-herdr` ControlSurface + StatusComposer (read-only) |
| `coworkers` | per-worktree executor truth | `ace-coworker` WorktreeExecutorProbe + ActiveExecutorRule |

`forge` is disabled by default (`enabled: false`). Enable it in project or
user config when the forge server is configured; with no server, a missing
provider CLI, or no network it degrades to a per-source error entry, never
to "no open pull requests".

### Attention: blockers, failures, missing data

The same one-shot view opens with a derived `-- attention` section that
splits what needs the overseer's decision from healthy progress. It is
computed live from the collected sources plus the read-only ace-hitl
inbox — no new fetchers, no second dashboard, nothing persisted
(`Organisms::StatusAttention`):

- **BLOCKER** — a startable task (`pending` in the project or `_overseer`
  tree) whose dependencies are not satisfied, or a task explicitly
  `blocked`, with the concrete reason per dependency
  (`Atoms::DependencyReadiness`: predecessor status, missing or cyclic
  dependency) and the next action.
- **FAILURE** — a source `error` (with origin), a `failed`/`stalled`
  assignment, a per-worktree executor probe error, an escalation: a
  pending ace-hitl `question` awaiting an answer, or an unprocessed
  incoming ace-hitl `report` (next action: run
  `ace-overseer process-reports`).
- **MISSING DATA** — a disabled source, unknown `status_sources` keys,
  an unreadable task tree (dependency readiness unverified), an
  unrecognized task status, an unknown executor state (`unknown`/
  `unparseable` — the worktree cannot be treated as free), or an
  unreachable hitl inbox.

Every row carries a `next_action`. Absence of data is never success: a
disabled or errored source confirms neither a free worktree nor a
finished task (program contract). When nothing needs attention the
section says so explicitly (`-- attention: none`).

### JSON contract

```json
{
  "sources": {
    "worktrees": {"status": "ok", "origin": "...", "data": {"worktrees": [...]}},
    "forge": {"status": "disabled"},
    "herdr": {"status": "error", "origin": "...", "error": "..."}
  },
  "unknown_keys": ["forg"],
  "attention": {
    "blockers": [
      {"kind": "dependency", "tree": "project", "task_id": "8x1",
       "title": "...", "reasons": ["8x0: predecessor not integrated yet (status: running)"],
       "next_action": "unblock the predecessor(s), then start or continue 8x1"}
    ],
    "failures": [
      {"kind": "escalation", "subject": "q7", "task": "8x1", "assignment": "asg1",
       "detail": "Which branch?", "next_action": "answer question q7 via ace-hitl"}
    ],
    "missing_data": [
      {"kind": "source_disabled", "subject": "forge",
       "detail": "source disabled: absence of its data does not confirm a free worktree or a finished task",
       "next_action": "enable 'forge' under status_sources or accept that its view stays unknown"}
    ]
  }
}
```

Every entry carries `status` (`ok` | `disabled` | `error`); `ok` entries
add `origin` (explicit provenance) and `data`; `error` entries add `origin`
and `error`. A failing or disabled source is rendered next to the healthy
results — missing data never reads as a free worktree or a finished task.
In the `coworkers` data an unknown or unparseable commission reports
`active: true` with state `unknown`/`unparseable` (never free).

`--watch` keeps refreshing the worktree dashboard (the quick-refresh
section); the full source view is the one-shot `status` run.

## `ace-overseer prune`

Remove completed task worktrees. A candidate is removed only when the
assignment is complete, the task is marked done, and the git working tree is
clean. `--force`/`--yes` never override those blocks.

```bash
ace-overseer prune --dry-run
ace-overseer prune --yes
ace-overseer prune 8q4 --dry-run
ace-overseer prune --assignment abc123
```

| Option | Purpose |
|--------|---------|
| `TARGETS` | Task refs or folder names to prune |
| `--assignment`, `-a` | Prune a specific assignment by ID |
| `--dry-run` | Show candidates only; no cleanup side effects |
| `--yes`, `-y` | Skip the confirmation prompt |
| `--force`, `-f` | Skip confirmation for already-safe candidates; never bypasses safety blocks |
| `--preservation FILE` | YAML manifest declaring verified cross-repository destinations |
| `--quiet`, `-q` | Suppress progress output |
| `--debug`, `-d` | Show debug output |

Dry-run exits 0 even when it lists blocked candidates. Apply exits non-zero
when any selected candidate is blocked or removal fails; independent safe
candidates still complete. Unmatched explicit targets are errors.

> **Planned (L6):** private queue and worktree handoff between roles -- not
> available yet.

## Terminal runtime configuration

Work-on opens the task terminal and prune closes its window through the
runtime-neutral [ace-runtime](../ace-runtime) contract. Select the backend in
`.ace/overseer/config.yml`:

```yaml
# tmux | herdr | auto (default): auto detects tmux first, then herdr.
# ACE_RUNTIME wins over this key; nothing detected fails explicitly.
runtime: auto
window_presets:
  "work-on-task": "work-on-task"
```

## Private overseer queue (L6)

The overseer role coordinates delegated work in its own gitignored list,
separate from project tasks. No queue engine is added: order, dependencies,
and allocations live in ordinary task files under `.ace-tasks/_overseer/`
(see ADR-034 and `docs/lab-flow.md`).

```bash
mkdir -p .ace-tasks/_overseer          # prepared once by project config
ace-task list --in _overseer            # the overseer's own view
ace-task create "Manage: <scope>" --in _overseer
ace-task create "Integrate <scope>" --child-of <manager-ref>
ace-task update <B-step> --set dependencies=<A-integrate-ref>
```

Binding rules: cross-task merge requirements depend on the integration step
(never on worker completion); one active executor per task worktree across
roles (`ace-overseer handoff` enforces the role-sequence handoff in the same
worktree mechanically); implementation completion does not close a managing
task while review or integration remains; coworker reports arrive via ace-hitl
and only the overseer writes its list (`ace-overseer process-reports`
interprets them mechanically and continues the queue through the work-on and
handoff gates).

Full procedure: `ace-bundle wfi://overseer/queue`.

## Example flows

Start task work and check the dashboard:

```bash
ace-overseer work-on --task t.123
ace-overseer status --format json
```

Preview and prune finished work:

```bash
ace-task update t.123 --set status=done
ace-overseer prune --dry-run
ace-overseer prune --yes
ace-overseer prune --dry-run
```
