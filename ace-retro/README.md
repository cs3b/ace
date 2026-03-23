# ace-retro

Structured retrospective management for ACE workflows, from capture to archive.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-retro demo](docs/demo/ace-retro-getting-started.gif)

`ace-retro` helps teams capture learning while context is still fresh, keep retros connected to tasks, and maintain a searchable archive for follow-up improvements.

## Use Cases

**Capture retros quickly** - Create a new retrospective from templates for standard, conversation-analysis, or self-review flows.

**Keep retros connected to delivery work** - Link retros to task references so findings stay tied to concrete changes.

**Review and maintain retro metadata** - List, show, and update retros with tags and status metadata.

**Archive completed retros without losing history** - Move completed retros into archive locations while preserving searchability.

**Run health checks before sharing** - Use `ace-retro doctor` to validate environment and workflow readiness.

## Works With

- `ace-task` for linking retros to task references.
- `ace-assign` for assignment retros and follow-up actions.
- `ace-b36ts` for compact, sortable IDs.

## Agent Skills

Package-owned canonical skills:

- `as-retro-create`
- `as-retro-synthesize`
- `as-handbook-selfimprove`

## Features

- Fast create, show, list, and update workflow for daily retrospective work.
- Type-aware templates for different reflection styles.
- Metadata updates with tags, status, and folder moves.
- Health checks via `ace-retro doctor`.

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Guide](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-retro --help`

## Part of ACE

`ace-retro` is part of [ACE](../README.md) (Agentic Coding Environment).
