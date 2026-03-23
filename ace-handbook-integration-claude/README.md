---
doc-type: package-readme
title: ace-handbook-integration-claude
purpose: Claude-specific provider integration for ACE handbook skills
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-handbook-integration-claude

> Provider manifest package for Claude-native handbook workflow integration.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-handbook-integration-claude` hosts Claude-specific manifests that let ACE route canonical handbook skills to Claude-native runtime assets.

## How It Works

1. Canonical ACE skills stay owned in canonical `handbook/skills` trees.
2. This package projects those definitions into Claude-specific provider formats.
3. Claude-specific integrations consume those projections during skill invocation.

## Use Cases

**Run ACE workflows from Claude-native entrypoints** - load canonical skill semantics with Claude-specific packaging.

**Keep provider integration changes isolated** - update manifests and projections without altering canonical handbook definitions.

**Standardize cross-provider behavior** - preserve shared conventions while adapting to provider-specific command surfaces.

## What It Provides

- Claude manifest generation and projection assets for ACE handbook skills.
- Provider-specific runtime glue that preserves canonical intent.
- Alignment with canonical skill contracts managed by `ace-handbook`.

## Part of ACE

`ace-handbook-integration-claude` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
