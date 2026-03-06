---
title: "Meta: Manage Workflow Instructions"
command: "meta-manage-workflow-instructions"
description: "Create, update, and maintain workflow instruction files"
author: "handbook"
tools_restricted: true
tools_allowed: Read, Write, Edit, MultiEdit, Glob, LS, Bash, TodoWrite
model_preference: claude-3-5-sonnet-latest
version: "1.0.0"
---

# Meta: Manage Workflow Instructions

Create, update, and maintain workflow instruction files (.wf.md).

## Usage

Type `/as-handbook-manage-workflows [workflow-name] [action]` where:
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
/as-handbook-manage-workflows deploy-feature create
/as-handbook-manage-workflows fix-bug update
/as-handbook-manage-workflows code-review review
```

## Full Workflow

For detailed instructions, see: @ace-handbook/handbook/workflow-instructions/manage-workflow-instructions.wf.md