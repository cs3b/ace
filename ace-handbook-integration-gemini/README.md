---
doc-type: package-readme
title: ace-handbook-integration-gemini
purpose: Gemini-specific provider integration for ACE handbook skills
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-handbook-integration-gemini

> Provider manifest package for Gemini-native handbook workflow integration.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-handbook-integration-gemini` projects canonical ACE handbook skills into Gemini-native manifest assets.

## How It Works

1. Canonical skill definitions stay in shared handbook sources.
2. This package turns those definitions into Gemini-specific integration artifacts.
3. Gemini-compatible workflows run using the same project-level skill semantics.

## Use Cases

**Run ACE skill workflows in Gemini-native stacks** - preserve behavior while using Gemini-native projection format.

**Centralize skill updates** - keep shared definitions and avoid provider-specific drift.

**Ship lean provider packs** - support only provider shims and manifests in this package.

## What It Provides

- Gemini provider manifests for ACE handbook skills.
- Gemini-native projection assets for ACE workflows.
- Alignment with canonical skill contracts managed by `ace-handbook`.

## Part of ACE

`ace-handbook-integration-gemini` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
