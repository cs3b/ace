---
description: Validate documents
allowed-tools: Bash
argument-hint: "[FILE|PATTERN]"
last_modified: '2025-10-13'
source: ace-docs
---

Validate documents against configured rules.

Usage: /ace:docs-validate [file-or-pattern]

Checks:
- Required frontmatter fields
- Max line limits
- Required sections
- Syntax errors (if linter available)

Execute `ace-docs validate [arguments]`
