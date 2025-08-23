---
title: 'Meta: Update Claude Integration'
command: meta-update-integration-claude
description: Maintain Claude Code integration and synchronize commands
author: handbook
tools_restricted: true
tools_allowed: Read, Write, Edit, MultiEdit, Glob, LS, Bash, TodoWrite
model_preference: claude-3-5-sonnet-latest
version: 1.0.0
last_modified: '2025-08-24 00:17:47'
source: custom
---

# Meta: Update Claude Integration

Maintain Claude Code integration using unified handbook CLI commands.

## Usage

Type `/meta-update-integration-claude [options]` where options can be:
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
/meta-update-integration-claude
/meta-update-integration-claude full
/meta-update-integration-claude meta
```

## Full Workflow

For detailed instructions, see: @dev-handbook/.meta/wfi/update-integration-claude.wf.md