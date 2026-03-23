---
doc-type: package-readme
title: ace-support-models
purpose: Shared model metadata and pricing helpers for ACE provider tooling
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-support-models

> Shared model metadata infrastructure used by ACE tools that reason about providers and models.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-models` normalizes provider/model metadata and pricing helpers for consistent ACE behavior.

## How It Works

1. Provider and model data is loaded into shared model structures.
2. Metadata lookups are surfaced through helper APIs and validators.
3. Tooling uses shared pricing and compatibility insights from one canonical source.

## Use Cases

**Resolve model metadata consistently** - avoid duplicated model catalogs across ACE features.

**Calculate usage expectations** - support stable cost and compatibility assumptions during tool workflows.

**Share validation rules** - apply one metadata model for provider and model checks.

## What It Provides

- Canonical model and provider metadata helpers.
- Validation utilities and compatibility lookup support.
- Shared pricing/capability primitives for higher-level packages.

## Part of ACE

`ace-support-models` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
