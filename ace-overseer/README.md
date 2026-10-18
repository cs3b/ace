<div align="center">
  <h1> ACE - Overseer </h1>

  Local task worktrees, assignments, and cleanup in one command surface.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-overseer"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-overseer.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

> **State owner:** the private, gitignored overseer task list in
> `.ace-tasks/_overseer/`, a normal task folder reached through
> `ace-task --in _overseer …` (see [docs/lab-flow.md](../docs/lab-flow.md)).
> Task worktrees live in `.ace-wt/`; assignment plans and steps stay in
> `.ace-local/assign/` (ace-assign) and are never copied into the overseer
> list.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

Starting task work means creating a worktree, opening a terminal, and preparing
an assignment. ace-overseer collapses that into one command, shows what runs
where, and cleans up finished worktrees so nothing lingers.

## How It Works

1. Resolve task refs and create a scoped worktree under `.ace-wt/`.
2. Prepare an assignment through `ace-assign create --task ...`; the plan and
   its steps live in `.ace-local/assign/`.
3. Open a terminal (tmux or Herdr) mapped to the worktree and point the agent
   at `/as-assign-drive`.

tmux and Herdr are transports only. They do not own task, assignment, or HITL
state. The old protected execution path (`--project/--agent`, protected
status/review/stop/prompt/prune) and the installed ordinary launcher
(`ace-overseer ordinary`, native journal/attempt-handoff preparation and
launch) are removed (L1) and are not normal paths. Prune and status read local
assignment, task, worktree and Git state only.

## Use Cases

**Kick off task work** - provisions an isolated worktree via
[ace-git-worktree](../ace-git-worktree), opens a dedicated terminal, and
prepares an [ace-assign](../ace-assign) assignment. Draft tasks are blocked
until reviewed.

```bash
ace-overseer work-on --task 8q4 --preset work-on-task
```

**Bundle related tasks** - pass multiple task refs or a task with subtasks and
they land in a single worktree. The refs are expanded and forwarded to the
assignment preset, so every step is prepared in one assignment.

**Monitor active work** - `ace-overseer status` shows task worktrees with
assignment progress and git state. Add `--watch` for a live-refreshing view.

```bash
ace-overseer status --watch
```

**Clean up finished work** - `ace-overseer prune` removes completed worktrees
safely after assignment completion, task completion, and a clean working tree.
Use `--dry-run` to preview candidates, `--yes` to skip confirmation, or
`--assignment` to prune a single assignment.

**Customize the workflow** - the assignment preset controls which steps run and
in what order; each step references a workflow instruction that defines how it
executes. Browse [available presets](../ace-assign/.ace-defaults/assign/presets/)
or create your own.

## Planned waves

> **Planned (L4):** planner role that prepares the worktree and the whole
> assignment sequence -- not available yet.
>
> **L6 (partial):** the private overseer queue is coordinated through the
> gitignored `.ace-tasks/_overseer/` list (`ace-task --in _overseer`):
> managing tasks with lifecycle subtasks (prepare, implement, review,
> integrate), integration-gated dependencies, and one active executor per
> worktree. See the
> [Overseer Queue Workflow](handbook/workflow-instructions/overseer/queue.wf.md)
> (`ace-bundle wfi://overseer/queue`). Role dispatch and report-driven
> continuation land with the remaining L6 leaves.
>
> **Planned (L7):** aggregated status and pi continuation of already delegated
> work -- not available yet.

## Testing

- `bin/ace-test ace-overseer all` runs deterministic package coverage.
- `bin/ace-test-e2e ace-overseer` runs retained workflow scenarios.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
