---
name: ace-handbook-manage-guides
title: "Meta: Manage Guides"
command: meta-manage-guides
description: Create, update, and maintain development guides
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
argument-hint: "[guide-name] [action: create|update|review]"
---

# Meta: Manage Guides

Create, update, and maintain development guides in the handbook.

## Usage

Type `/ace-handbook-manage-guides [guide-name] [action]` where:
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
/ace-handbook-manage-guides testing-strategy create
/ace-handbook-manage-guides code-review update
/ace-handbook-manage-guides security-practices review
```

## Full Workflow

read and run ace-bundle wfi://handbook/manage-guides
