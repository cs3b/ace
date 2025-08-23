---
title: 'Meta: Review Workflows'
command: meta-review-workflows
description: Review and validate workflow instructions for quality and consistency
author: handbook
tools_restricted: true
tools_allowed: Read, Glob, LS, Bash, TodoWrite
model_preference: claude-3-5-sonnet-latest
version: 1.0.0
last_modified: '2025-08-23 23:18:44'
source: custom
---

# Meta: Review Workflows

Review and validate workflow instructions for quality and consistency.

## Usage

Type `/meta-review-workflows [workflow-name]` where:
- `workflow-name` is optional - if not provided, reviews all workflows

## What This Does

This meta workflow helps you:
1. Review workflows for completeness and clarity
2. Check consistency across related workflows
3. Validate prerequisites and dependencies
4. Ensure workflows follow standard template
5. Identify missing or outdated steps

## Process

The workflow will:
1. Load and analyze specified workflow(s)
2. Check structure against template
3. Validate prerequisites are clear
4. Review process steps for completeness
5. Generate review report with improvements

## Examples

```
/meta-review-workflows
/meta-review-workflows commit
/meta-review-workflows fix-tests
```

## Full Workflow

For detailed instructions, see: @dev-handbook/.meta/wfi/review-workflows.wf.md