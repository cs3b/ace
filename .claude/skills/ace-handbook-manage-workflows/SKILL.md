---
name: ace-handbook-manage-workflows
title: "Meta: Manage Workflow Instructions"
command: meta-manage-workflow-instructions
description: Create, update, and maintain workflow instruction files
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
  - LS
  - TodoWrite
argument-hint: "[workflow-name] [action: create|update|review]"
---

# Meta: Manage Workflow Instructions

Create, update, and maintain workflow instruction files (.wf.md).

## Usage

Type `/ace-handbook-manage-workflows [workflow-name] [action]` where:
- `workflow-name` is the name of the workflow to manage
- `action` is either "create", "update", or "review"

## What This Does

This meta workflow helps you:
1. Create new workflow instructions with standard template
2. Update existing workflows to maintain consistency
3. Ensure workflows have proper goal, prerequisites, and steps
4. Maintain workflow catalog and cross-references
5. Generate corresponding Claude commands

## Process

The workflow will:
1. Determine if creating new or updating existing workflow
2. Use standard workflow template structure
3. Ensure clear goal and prerequisites
4. Document process steps clearly
5. Update Claude integration if needed

## Examples

```
/ace-handbook-manage-workflows deploy-feature create
/ace-handbook-manage-workflows fix-bug update
/ace-handbook-manage-workflows code-review review
```

## Full Workflow

For detailed instructions, see: ace-bundle wfi://handbook/manage-workflows
