---
title: 'Meta: Manage Guides'
command: meta-manage-guides
description: Create, update, and maintain development guides
author: handbook
tools_restricted: true
tools_allowed: Read, Write, Edit, MultiEdit, Glob, LS, Bash, TodoWrite
model_preference: claude-3-5-sonnet-latest
version: 1.0.0
last_modified: '2025-08-23 23:18:44'
source: custom
---

# Meta: Manage Guides

Create, update, and maintain development guides in the handbook.

## Usage

Type `/meta-manage-guides [guide-name] [action]` where:
- `guide-name` is the name of the guide to manage
- `action` is either "create", "update", or "review"

## What This Does

This meta workflow helps you:
1. Create new development guides with proper structure
2. Update existing guides to maintain consistency
3. Ensure guides follow handbook standards
4. Maintain guide index and cross-references
5. Keep guides synchronized with actual implementation

## Process

The workflow will:
1. Determine guide type and location
2. Create/update guide with proper formatting
3. Update guide index if needed
4. Ensure cross-references are valid
5. Verify examples are current

## Examples

```
/meta-manage-guides testing-strategy create
/meta-manage-guides code-review update
/meta-manage-guides security-practices review
```

## Full Workflow

For detailed instructions, see: @dev-handbook/.meta/wfi/manage-guides.wf.md