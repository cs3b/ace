---
doc-type: package-readme
title: ace-handbook-integration-codex
purpose: Codex-specific provider integration for ACE handbook skills
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-handbook-integration-codex

> Provider manifest package for Codex-native handbook workflow integration.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-handbook-integration-codex` maps canonical ACE handbook skills into Codex-compatible projection assets.

## How It Works

1. Canonical skill definitions stay in the canonical ACE handbook sources.
2. This package produces Codex-focused manifests and skill wiring.
3. Codex agents consume those assets while keeping semantics unchanged.

## Use Cases

**Run handbook workflows in Codex contexts** - keep same behavior while using Codex-native execution entrypoints.

**Avoid duplication across providers** - update canonical skill definitions once and generate provider-specific projections.

**Keep integration delivery minimal** - maintain a tiny provider shim layer with focused assets.

## What It Provides

- Codex-specific provider manifests for ACE handbook skills.
- Projection assets that keep canonical behavior portable.
- Alignment with canonical skill contracts managed by `ace-handbook`.

## Part of ACE

`ace-handbook-integration-codex` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
