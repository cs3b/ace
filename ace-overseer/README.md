<div align="center">
  <h1> ACE - Overseer </h1>

  One command to provision a worktree, open a tmux window, and start working on a task.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-overseer"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-overseer.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-overseer demo](docs/demo/ace-overseer-getting-started.gif)

Starting task work means creating a worktree, opening a tmux window, and preparing an assignment - three manual steps before you even begin coding. ace-overseer collapses that into a single command, tracks what is running where, and cleans up finished worktrees so nothing lingers. You can jump straight to a focused worktree any time with a single invocation.

## How It Works

1. Resolve task refs and create a scoped worktree.
2. Route assignment creation through `ace-assign create --task ...`, which expands the assignment preset into concrete steps under `.ace-local/assign/`, then open a dedicated tmux window mapped to that worktree.
3. Instruct the agent inside the tmux window to act as an orchestrator and drive the assignment step-by-step.

## Use Cases

**Kick off task work** - provisions an isolated worktree via [ace-git-worktree](../ace-git-worktree), opens a dedicated [ace-tmux](../ace-tmux) window, and prepares an [ace-assign](../ace-assign) assignment - all in one shot. Supports regular tasks and subtask trees. Draft tasks are blocked until reviewed. Use `/as-overseer` or from the CLI:

```bash
ace-overseer work-on --task 8q4 --preset work-on-task
```

**Bundle related tasks** - pass multiple task refs or a task with subtasks and they all land in a single worktree. The refs are expanded and forwarded to the assignment preset, so every step for every task is prepared in one assignment. Drive through them with `/as-assign-drive`.

**Monitor active work** - [`ace-overseer status`](docs/usage.md#ace-overseer-status) shows a dashboard of all task worktrees with assignment progress, git state, and PR links. Add `--watch` for a live-refreshing view that updates assignments every 15 seconds and git status every 5 minutes.

```bash
ace-overseer status --watch
```

**Clean up finished work** - [`ace-overseer prune`](docs/usage.md#ace-overseer-prune) removes completed worktrees safely. It checks three conditions before removing: assignment completed, task marked done, and git working tree clean. Use `--dry-run` to preview what would be pruned, `--force` for worktrees that fail safety checks, or `--assignment` to prune a single stale assignment.

**Customize the workflow** - the full pipeline is defined in two layers: the [assignment preset](../ace-assign/.ace-defaults/assign/presets/work-on-task.yml) controls which steps run and in what order (onboard, implement, test, release, review, PR), while each step references a [workflow instruction](../ace-task/handbook/workflow-instructions/task/work.wf.md) that defines how it executes. Browse [available presets](../ace-assign/.ace-defaults/assign/presets/) or create your own to tailor the pipeline to your project.

## Testing

- `ace-test ace-overseer` runs deterministic fast coverage from `test/fast/`.
- `ace-test ace-overseer feat` runs deterministic feature coverage from `test/feat/` when present.
- `ace-test ace-overseer all` runs fast + feat deterministic coverage.
- `ace-test-e2e ace-overseer` runs retained workflow scenarios from `test/e2e/`.

The package no longer uses deterministic `*_test.rb` files under `test/e2e/` and
does not use `ace-test ace-overseer e2e` as a deterministic test path.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
