---
title: "Meta: Update Handbook Documentation"
command: "meta-update-handbook-docs"
description: "Update and maintain handbook documentation and README files"
author: "handbook"
tools_restricted: true
tools_allowed: Read, Write, Edit, MultiEdit, Glob, LS, Bash, TodoWrite
model_preference: claude-3-5-sonnet-latest
version: "1.0.0"
---

# Meta: Update Handbook Documentation

Update and maintain handbook documentation, including README files and indexes.

## Usage

Type `/as-handbook-update-docs [section]` where:
- `section` is optional - specific section to update (e.g., "guides", "workflows", "agents")

## What This Does

This meta workflow helps you:
1. Update main handbook README with current content
2. Maintain section indexes and catalogs
3. Update cross-references and links
4. Ensure documentation reflects current state
5. Generate documentation from code/config

## Process

The workflow will:
1. Scan handbook structure for changes
2. Update README with current listings
3. Regenerate section indexes
4. Update navigation and cross-references
5. Validate all documentation links

## Examples

```
/as-handbook-update-docs
/as-handbook-update-docs guides
/as-handbook-update-docs workflows
```

## Full Workflow

For detailed instructions, see: @ace-handbook/handbook/workflow-instructions/update-handbook-docs.wf.md