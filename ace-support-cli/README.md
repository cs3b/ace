---
doc-type: package-readme
title: ace-support-cli
purpose: Shared CLI framework and command primitives for ACE packages
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-support-cli

> Shared command primitives for consistent ACE CLI behavior.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-cli` is the foundation layer for ACE commands, providing metadata-driven command definitions, parser behavior, and execution orchestration.

## How It Works

1. Package commands extend shared `Command` base classes and define arguments/options declaratively.
2. Parsers normalize argv into structured Ruby types and route to a registry.
3. Runners execute command objects with consistent help, error, and exit semantics.

## Use Cases

**Build a new ACE CLI in minutes** - reuse shared conventions for command declaration and execution.

**Standardize command behavior across packages** - enforce predictable option parsing, help text, and exit codes.

**Keep agent invocations safe** - preserve a stable CLI contract in mixed human/agent workflows.

## Provides

- Shared command DSL and parser helpers.
- Registry and module-level command registration utilities.
- Runner and standard option helpers for consistent terminal behavior.

## Documentation

- API package docs at the code level under `lib/ace/support/cli`.

## Part of ACE

`ace-support-cli` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
