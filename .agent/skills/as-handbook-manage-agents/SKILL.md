---
name: as-handbook-manage-agents
title: "Meta: Manage Agents"
command: meta-manage-agents
description: Create, update, and maintain agent definitions following standardized guide
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
argument-hint: "[agent-name] [action: create|update|review]"
---

# Meta: Manage Agents

Create, update, and maintain agent definitions following the standardized agent definition guide.

## Usage

Type `/ace-handbook-manage-agents [agent-name] [action]` where:
- `agent-name` is the name of the agent to manage
- `action` is either "create", "update", or "review"

## What This Does

This meta workflow helps you:
1. Create new agent definitions with proper structure
2. Update existing agents to follow standards
3. Maintain agent symlinks and integration
4. Update CLAUDE.md agent documentation
5. Ensure single-purpose design and proper response formats

## Process

The workflow will:
1. Determine if creating new agent or updating existing
2. Ensure single-purpose design with clear action keywords
3. Create/update agent file with .ag.md extension
4. Update symlinks in .claude/agents/
5. Update CLAUDE.md and settings.json as needed

## Examples

```
/ace-handbook-manage-agents task-finder create
/ace-handbook-manage-agents git-commit update
/ace-handbook-manage-agents release-navigator review
```

## Full Workflow

For detailed instructions, see: ace-bundle wfi://handbook/manage-agents
