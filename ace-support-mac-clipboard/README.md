---
doc-type: package-readme
title: ace-support-mac-clipboard
purpose: Rich macOS clipboard integration for ACE tooling
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-support-mac-clipboard

> macOS clipboard support for text, files, and image payloads used by ACE tools.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-mac-clipboard` integrates with macOS `NSPasteboard` so ACE can consume richer clipboard inputs than plain text.

## How It Works

1. Reader utilities ingest clipboard payloads from macOS pasteboard.
2. Content parsers convert platform types into consistent Ruby structures.
3. Callers consume normalized output without re-implementing platform glue.

## Use Cases

**Attach image/context content from clipboard** - support screenshot and file-based workflows in ACE tools.

**Handle Finder selections and formatted text** - process files and rich content without manual conversion.

**Keep platform details isolated** - let one package encapsulate macOS-specific behavior.

## What It Provides

- macOS-focused clipboard readers and parsers.
- Unified attachment and content representations.
- Stable interface for downstream packages that need native content capture.

## Part of ACE

`ace-support-mac-clipboard` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT

