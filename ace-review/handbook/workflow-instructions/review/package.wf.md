---
name: review-package
description: Review a package across code quality, docs, UX, DX, and tests
allowed-tools: Bash, Read, Glob, Grep, Write, Edit, TodoWrite
argument-hint: "[package-name]"
doc-type: workflow
purpose: package review workflow
---

# Review Package Workflow

## Instructions

1. Load package context with `ace-bundle <package-name>/project` when available.
2. Review library structure, public CLI/API surface, documentation, and tests.
3. Produce prioritized findings and concrete follow-up recommendations.
