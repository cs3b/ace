---
doc-type: package-readme
title: ace-support-markdown
purpose: Safe markdown and frontmatter editing primitives for ACE
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-support-markdown

> Safe, composable markdown editing tools for ACE libraries and docs.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-markdown` provides atomic document editing with frontmatter and section-level updates while preserving document integrity.

## How It Works

1. Load markdown content and frontmatter through model-driven editing interfaces.
2. Apply section and metadata updates through atomic write operations.
3. Persist changes with optional validation and backup/rollback support.

## Use Cases

**Safely update task and docs content** - avoid accidental corruption during metadata and section edits.

**Generate documents programmatically** - use builder-like APIs for reproducible document creation.

**Preserve history during edits** - maintain backup and rollback safety for write-heavy operations.

## What It Provides

- Frontmatter and section editing primitives.
- Atomic write utilities with backup and validation support.
- Document builder APIs for generated and generated content.

## Part of ACE

`ace-support-markdown` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

[MIT License](https://opensource.org/licenses/MIT)
