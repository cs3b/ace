---
doc-type: package-readme
title: ace-handbook-integration-opencode
purpose: OpenCode-specific provider integration for ACE handbook skills
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-handbook-integration-opencode

> Provider manifest package for OpenCode-native handbook workflow integration.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-handbook-integration-opencode` provides OpenCode-focused handbook manifests and projection artifacts.

## How It Works

1. Canonical skills remain in the ACE handbook canonical source.
2. OpenCode-specific assets are generated from that canonical contract.
3. OpenCode runtime uses these assets to expose the same skills in local formats.

## Use Cases

**Run ACE workflows from OpenCode integrations** - keep canonical skill intent while targeting OpenCode entrypoints.

**Adapt quickly to provider-specific layouts** - update projections instead of rewriting handbook logic.

**Keep provider layers small** - isolate integration glue from core handbook behavior.

## What It Provides

- OpenCode provider manifests for handbook skills.
- OpenCode workflow and projection assets.
- Alignment with canonical skill contracts managed by `ace-handbook`.

## Part of ACE

`ace-handbook-integration-opencode` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
