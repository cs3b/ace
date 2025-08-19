---
title: 'Meta: Update Tools Documentation'
command: meta-update-tools-docs
description: Update dev-tools documentation from implementation and tests
author: handbook
tools_restricted: true
tools_allowed: Read, Write, Edit, MultiEdit, Glob, Grep, LS, Bash, TodoWrite
model_preference: claude-3-5-sonnet-latest
version: 1.0.0
last_modified: '2025-08-19 14:15:07'
source: custom
---

# Meta: Update Tools Documentation

Update dev-tools documentation to reflect current implementation.

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
1. Analyze dev-tools Ruby implementation
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

For detailed instructions, see: @dev-handbook/.meta/wfi/update-tools-docs.wf.md