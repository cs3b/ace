---
description: Update document frontmatter
allowed-tools: Bash
argument-hint: "[FILE] --set KEY=VALUE"
last_modified: '2025-10-13'
source: ace-docs
---

Update frontmatter metadata for documents.

Usage: /ace:docs-update [file] --set KEY=VALUE

Examples:
- Update last-updated date: /ace:docs-update docs/api.md --set last-updated=today
- Update version: /ace:docs-update README.md --set version=2.0

Execute `ace-docs update [file] [options]`
