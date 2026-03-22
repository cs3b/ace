---
doc-type: user
title: ACE Handbook
purpose: Landing page for handbook workflows and documentation standards
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ACE Handbook

Standardized workflows for creating and managing guides, workflow instructions, and agent definitions.

![ace-handbook demo](docs/demo/ace-handbook-getting-started.gif)

## Why

`ace-handbook` gives ACE teams a shared way to author and maintain documentation assets with consistent quality.
It provides repeatable workflows for handbook content so documentation stays structured, reviewable, and current.

## Works With

- `ace-nav` for workflow and resource discovery.
- `ace-bundle` for loading complete workflow instructions.
- Provider integrations (`ace-integration-*`) that project canonical handbook skills into provider-native folders.

## Agent Skills

Package-owned skills live in `handbook/skills/` and map to handbook workflows used by provider agents and assignment runners.
Common skills include:

- `as-handbook-manage-guides`
- `as-handbook-manage-workflows`
- `as-handbook-manage-agents`
- `as-handbook-review-guides`
- `as-handbook-review-workflows`
- `as-handbook-update-docs`

## Features

- Standardized authoring and review workflows for guides (`.g.md`), workflows (`.wf.md`), and agents (`.ag.md`).
- Consistent handbook quality gates for structure, clarity, and maintainability.
- Multi-agent research and synthesis workflows for deeper documentation discovery.
- Delivery orchestration workflow for coordinated handbook updates.

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)

## Part of ACE

`ace-handbook` is part of ACE (Agentic Coding Environment), a modular CLI ecosystem for developer and AI-agent collaboration.
