<div align="center">
  <h1> ACE - Task </h1>

  Draft, organize, and tackle tasks (specs) - for you and your agents.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-task"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-task.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)
![ace-task demo](docs/demo/ace-task-getting-started.gif)

Tasks are markdown specs living in git - attached to branches and worktrees, not trapped in a SaaS dashboard. A task can contain subtasks, prototypes, research notes, and UX specs. Compact B36TS IDs like `8q4` are timestamp-derived, so they stay unique across branches without a central sequence - parallel worktrees rarely conflict.

## How It Works

1. Task specs are created and tracked as markdown files.
2. Review and planning workflows refine scope before implementation.
3. Oversee execution through worktrees and assignments until ship-ready.

## Use Cases

**Draft and structure work** - create a task, split it into subtasks, add new subtasks as work reveals scope. Use `/as-task-draft` to draft from an earlier captured [idea](../ace-idea) or short note, or [`ace-task create`](docs/usage.md#ace-task-create-title) from the CLI.

**Review before building** - validate specs with `/as-task-review` before committing to implementation. The agent can ask you clarification questions to surface missing acceptance criteria, unclear scope, or architectural risks early. Use `/as-task-review-questions` to go through pending reviews across tasks.

**Plan the work** - generate a step-by-step implementation plan with `/as-task-plan` or `ace-task plan`. Define subtasks, configure which agent handles execution, and break scope into assignable units. The plan lives in the task spec so any agent can pick it up.

**Run as dark factory** - hand a task to [ace-overseer](../ace-overseer) and it provisions a worktree, opens a tmux window, creates an assignment, and drives execution through the full lifecycle - onboard, implement, verify, create PR, review, ship. One command kicks it off:

```bash
ace-overseer work-on --task t.tt6 --preset work-on-task
```

Under the hood this chains [ace-git-worktree](../ace-git-worktree) (isolated branch) -> [ace-tmux](../ace-tmux) (dedicated window and panes layout) -> [ace-assign](../ace-assign) (step-by-step execution). Switch to the tmux window and run `/as-assign-drive` to walk through each step.

**Track progress** - `ace-task list` shows tasks by status - what is next, what is in progress, and what was recently completed. `ace-task status` gives a focused view of the current task with subtask progress.

**Keep it healthy** - with flexible folder structures and work spread across multiple branches, things can drift. `ace-task doctor` detects structural issues - orphaned subtasks, broken references, inconsistent status. Run it with `--fix` for automatic repairs, or `--fix-with-agent` to let an agent resolve issues that need judgment.

**Organize** - move a task to a folder and it is created automatically. Special folders like `_maybe` and `_anytime` group tasks by intent. `_archive` partitions completed tasks by date so they stay browsable as the project grows. Sort by priority, creation date, or pin position manually.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
