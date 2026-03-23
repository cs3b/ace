---
doc-type: package-readme
title: ace-support-config
purpose: Reusable configuration cascade helpers for ACE Ruby tooling
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-support-config

> Shared configuration cascade primitives for ACE libraries and tools.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Usage Guide](docs/usage.md)

`ace-support-config` provides layered configuration loading and merging for ACE, including `.ace`, user, and gem-default layers.

## How It Works

1. A resolver builds a configuration cascade from the nearest `.ace` up to defaults.
2. Resolved values are merged using configurable merge strategies.
3. Consumers access resolved config by namespace, file path, and direct lookup.

## Use Cases

**Load layered configuration safely** - combine project, user, and default values with deterministic precedence.

**Support project-specific overrides** - place `.ace` files near the execution context and keep defaults stable.

**Resolve namespaces consistently** - access configuration across tools using shared resolver methods.

## What It Provides

- Configuration resolvers with `.ace`, home, and gem default resolution.
- Namespace and file-based resolution APIs.
- Merge utilities and path expanders used throughout the ACE toolchain.

## Documentation

- [Usage Guide](docs/usage.md)

## Part of ACE

`ace-support-config` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
