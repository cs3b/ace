---
description: Analyze document changes
allowed-tools: Bash
argument-hint: "[FILE] [--needs-update|--all|--since DATE]"
last_modified: '2025-10-13'
source: ace-docs
---

Analyze git changes relevant to documentation.

Usage: /ace:docs-diff [file-or-options]

Options:
- FILE: Analyze specific document
- --needs-update: Analyze documents needing updates
- --all: Analyze all managed documents
- --since DATE: Analyze from specific date/commit
- --exclude-renames: Skip renamed files
- --exclude-moves: Skip moved files

Execute `ace-docs diff [arguments]`
