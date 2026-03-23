# ace-handbook

Standardized workflows for creating and managing guides, workflow instructions, and agent definitions.

[Getting Started](docs/getting-started.md) | [Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-handbook demo](docs/demo/ace-handbook-getting-started.gif)

`ace-handbook` gives ACE teams a shared way to author, review, and maintain handbook assets with consistent quality gates and repeatable delivery workflows.

## Use Cases

**Author handbook assets with consistent structure** - create and update guides (`.g.md`), workflow instructions (`.wf.md`), and agents (`.ag.md`) using package workflows.

**Review handbook content before publishing** - run review workflows to catch clarity, formatting, and process issues before updates propagate to integrations.

**Coordinate larger handbook deliveries** - use orchestration and research workflows to plan, execute, and synthesize multi-step documentation changes.

## Works With

- `ace-nav` for workflow and resource discovery.
- `ace-bundle` for loading complete workflow instructions.
- Provider integrations (`ace-integration-*`) that project canonical handbook skills into provider-native folders.

## Features

- Standardized authoring and review workflows for guides (`.g.md`), workflows (`.wf.md`), and agents (`.ag.md`).
- Consistent handbook quality gates for structure, clarity, and maintainability.
- Multi-agent research and synthesis workflows for deeper documentation discovery.
- Delivery orchestration workflow for coordinated handbook updates.

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-handbook --help`

## Agent Skills

Package-owned canonical skills:

- `as-handbook-manage-guides`
- `as-handbook-manage-workflows`
- `as-handbook-manage-agents`
- `as-handbook-review-guides`
- `as-handbook-review-workflows`
- `as-handbook-update-docs`

## Part of ACE

`ace-handbook` is part of [ACE](../README.md) (Agentic Coding Environment).
