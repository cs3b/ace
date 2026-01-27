---
name: meta-update-tools-docs
title: "Meta: Update Tools Documentation"
command: meta-update-tools-docs
description: Update ace-* package documentation from implementation and tests
# context: no-fork
# agent: general-purpose
user-invocable: true
author: handbook
model_preference: claude-3-5-sonnet-latest
version: 1.0.0
last_modified: 2026-01-10
source: custom
allowed-tools:
  - Bash(ace-handbook:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
  - MultiEdit
  - Glob
  - Grep
  - LS
  - TodoWrite
argument-hint: [component]
---

# Meta: Update Tools Documentation

Update ace-* package documentation to reflect current implementation.

## Usage

Type `/meta-update-tools-docs [component]` where:
- `component` is optional - specific tool or command to document

## What This Does

This meta workflow helps you:
1. Generate documentation from Ruby implementation
2. Update CLI command documentation
3. Maintain tool usage examples
4. Document configuration options
5. Keep API documentation current

## Process

The workflow will:
1. Analyze ace-* Ruby implementation
2. Extract command signatures and options
3. Update documentation files
4. Generate usage examples from tests
5. Validate documentation completeness

## Examples

```
/meta-update-tools-docs
/meta-update-tools-docs context
/meta-update-tools-docs handbook
```

## Full Workflow

For detailed instructions, see: ace-bundle wfi://update-tools-docs
