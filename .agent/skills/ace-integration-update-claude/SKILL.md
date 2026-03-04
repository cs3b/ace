---
name: ace-integration-update-claude
title: "Update Claude Integration"
command: ace-integration-update-claude
description: Maintain Claude Code integration and synchronize commands
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
argument-hint: [full|commands|agents|meta]
---

# Meta: Update Claude Integration

Maintain Claude Code integration using unified handbook CLI commands.

## Usage

Type `/ace-integration-update-claude [options]` where options can be:
- `full` - Complete integration update
- `commands` - Update commands only
- `agents` - Update agents only
- `meta` - Include meta workflows

## What This Does

This meta workflow helps you:
1. Generate missing Claude commands from workflows
2. Update existing commands to match workflows
3. Maintain command registry
4. Install commands to .claude/ directory
5. Handle both regular and meta workflows

## Process

The workflow will:
1. Check current integration status
2. Generate missing commands (regular and meta)
3. Update command registry
4. Install to project .claude/ directory
5. Verify installation and validate

## Examples

```
/ace-integration-update-claude
/ace-integration-update-claude full
/ace-integration-update-claude meta
```

## Full Workflow

For detailed instructions, see: ace-bundle wfi://integration/update-claude
