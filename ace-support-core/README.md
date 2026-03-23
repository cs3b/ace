---
doc-type: package-readme
title: ace-support-core
purpose: Core infrastructure for config, env, and runtime helpers across ACE
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-support-core

> Core infrastructure primitives shared by ACE support gems.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-core` centralizes configuration loading, environment handling, and shared runtime behavior used by support libraries.

## How It Works

1. Config resolution is delegated through `ace-support-config` with predictable cascade precedence.
2. Shared environment and filesystem helpers are reused across ACE libraries.
3. Core modules expose stable orchestration points for package-level tooling.

## Use Cases

**Create consistent package startup behavior** - initialize config, env, and shared context once with shared primitives.

**Avoid duplicate configuration logic** - reuse one configuration and environment model across many gems.

**Keep support libraries composable** - build package-specific features on top of stable core contracts.

## What It Provides

- Core configuration and environment utilities for ACE packages.
- Shared support interfaces used across `ace-support-*` gems.
- Reusable orchestration patterns for command and runtime behavior.

## Documentation

- [Configuration overview](docs/config.md)

## Part of ACE

`ace-support-core` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
