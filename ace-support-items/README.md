---
doc-type: package-readme
title: ace-support-items
purpose: Shared item-management infrastructure for ACE task and idea stores
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-support-items

> Shared primitives for scanning, resolving, and sanitizing ACE item stores.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-items` standardizes directory scanning, shortcut resolution, and slug handling for ACE item workflows.

## How It Works

1. Directory scanners discover item payloads across ACE store conventions.
2. Resolvers map short IDs to canonical b36ts identifiers.
3. Parsers and validators keep item metadata safe and deterministic.

## Use Cases

**Parse and resolve ACE task/idea shortcuts** - map compact IDs to canonical item paths.

**Handle special item directories consistently** - support shared folder conventions across tools.

**Normalize metadata safely** - sanitize slugs and arguments before persistence.

## What It Provides

- Directory scanning and item result modeling.
- Shortcut resolver for compact ID lookups.
- Slug sanitization and CLI argument parsing helpers.

## Part of ACE

`ace-support-items` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
