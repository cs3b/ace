# ace-task

Draft, organize, and tackle tasks — for you and your agents.

![ace-task demo](docs/demo/ace-task-getting-started.gif)

## Why ace-task

Lightweight behavioral specs tracked in git, with compact IDs that work in commits, branches, and chat. Break work into subtask trees, generate AI-powered implementation plans on demand, and keep everything healthy with automated doctor checks.

Built for both human developers and coding agents — same CLI, same task specs, same workflow.

## Features

- **Behavioral specs in git** — tasks are markdown files versioned alongside code, not locked in a SaaS tool
- **Compact B36TS IDs** — short, unique references like `8q4.t.abc` that fit in commit messages and branch names
- **Subtask trees** — break large goals into trackable slices without losing parent context
- **AI-generated plans** — convert specs into step-by-step implementation checklists on demand
- **Health checks** — detect and auto-fix structural issues across task trees with `doctor`
- **Folder organization** — next, maybe, archive folders for workflow stages
- **Status dashboard** — see up-next tasks and recent completions at a glance

## Works with

- **[ace-idea](../ace-idea)** — ideas flow into tasks: capture with ace-idea, then draft into ace-task specs via `as-task-draft`
- **[ace-overseer](../ace-overseer)** — orchestrate parallel task execution across isolated worktrees
- **[ace-git-worktree](../ace-git-worktree)** — create per-task worktrees for branch isolation, tracked in task metadata
- **[ace-assign](../ace-assign)** — tasks become steps in automated assignment pipelines for end-to-end execution

## Agent Skills

ace-task ships 21 skills for agent-assisted workflows, covering the full development lifecycle:

- **Task lifecycle:** `draft` → `review` → `plan` → `work` → `manage-status`
- **Discovery:** `finder`, `reorganize`, `review-questions`, `improve-coverage`
- **Bugs:** `analyze` → `fix`
- **Ideas:** `capture` → `prioritize` → `draft`
- **Quality:** `test-create-cases`, `test-fix`, `document-unplanned`
- **Docs & retros:** `update-roadmap`, `update-usage`, `retro-create`, `retro-synthesize`

See [Handbook Reference](docs/handbook.md) for the complete skill catalog, workflow instructions, guides, and templates.

## Documentation

- [Getting Started](docs/getting-started.md) — end-to-end tutorial
- [Usage Guide](docs/usage.md) — full command reference
- [Handbook Reference](docs/handbook.md) — skills, workflows, guides, templates
- Runtime help: `ace-task --help`

## Part of ACE

`ace-task` is part of [ACE](../README.md) (Agentic Coding Environment), a CLI-first toolkit for agent-assisted development.
