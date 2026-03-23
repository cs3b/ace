---
doc-type: package-readme
title: ace-support-fs
purpose: Filesystem utilities for ACE package discovery and path resolution
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-support-fs

> File system primitives for ACE path resolution and project root discovery.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-fs` provides reusable filesystem helpers for path expansion, root detection, and directory traversal.

## How It Works

1. Context-aware path expansion normalizes CLI and environment-driven paths.
2. Project root discovery identifies workspace boundaries from marker files.
3. Directory traversal collects config directories in deterministic order.

## Use Cases

**Resolve paths safely** - use consistent path expansion for tools that move across subdirectories.

**Detect workspace boundaries** - infer project root without shell-specific assumptions.

**Build config scans** - discover and rank candidate configuration directories during resolution.

## What It Provides

- Path expansion and protocol-aware path handling.
- Project root and directory traversal utilities.
- Thread-safe helpers for filesystem-heavy operations.

## Part of ACE

`ace-support-fs` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

See LICENSE
