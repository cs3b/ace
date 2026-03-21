# ace-task

Manage development tasks with unique IDs, subtask trees, and AI-generated plans.

![ace-task demo](docs/demo/ace-task-getting-started.gif)

## Why ace-task

`ace-task` gives you lightweight task specs that are easy to track in git and easy for AI agents to execute. Every task gets a compact B36TS-based ID, and subtasks let you split work without losing context.

When a spec is ready, `ace-task plan` generates an implementation plan you can execute step by step. `ace-task doctor` keeps task structure healthy across refactors and long-running branches.

## Quick Start

Run:


```bash
gem install ace-task
ace-task create "Rewrite README"
ace-task show <task-ref>
```

## Features

- B36TS IDs: short, unique task references that work well in commits and chat
- Subtask trees: break large work into manageable slices
- AI-generated plans: convert behavior specs into actionable implementation checklists
- Doctor checks: detect and fix common task structure issues

## Documentation

- [Getting Started](docs/getting-started.md)
- Runtime help: `ace-task --help`

## Common Commands


```bash
ace-task create "Add health checks"
ace-task show <task-ref> --tree
ace-task plan <task-ref>
ace-task doctor --check
```

## Part of ACE

`ace-task` is part of ACE (Agentic Coding Environment), a CLI-first toolkit for agent-assisted development.
