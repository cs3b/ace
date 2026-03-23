---
doc-type: package-readme
title: ace-handbook-integration-pi
purpose: PI-specific provider integration for ACE handbook skills
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-handbook-integration-pi

> Provider manifest package for PI-native handbook workflow integration.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-handbook-integration-pi` translates canonical ACE handbook skills into PI provider assets.

## How It Works

1. Canonical skill definitions remain in the shared handbook source.
2. This package emits PI-specific integration artifacts and command wiring.
3. PI execution paths consume those artifacts without changing ACE intent.

## Use Cases

**Consume canonical skills from PI tooling** - keep provider-specific behavior while preserving shared semantics.

**Keep provider updates constrained** - update projection assets inside this package, not canonical definitions.

**Enable incremental provider onboarding** - add PI support independently of core ACE changes.

## What It Provides

- PI provider manifests for handbook skills.
- PI-native projection and sync assets.
- Alignment with canonical skill contracts managed by `ace-handbook`.

## Part of ACE

`ace-handbook-integration-pi` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
