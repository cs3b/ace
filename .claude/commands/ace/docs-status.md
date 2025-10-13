---
description: Show documentation status
allowed-tools: Bash
argument-hint: "[--needs-update|--type TYPE|--freshness STATUS]"
last_modified: '2025-10-13'
source: ace-docs
---

Show status of managed documentation files.

Usage: /ace:docs-status [options]

Options:
- --needs-update: Show only documents needing updates
- --type TYPE: Filter by document type (context|guide|workflow|api)
- --freshness STATUS: Filter by freshness (current|stale|outdated)

Execute `ace-docs status [arguments]`
