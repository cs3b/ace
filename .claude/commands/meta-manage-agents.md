---
title: 'Meta: Manage Agents'
command: meta-manage-agents
description: Create, update, and maintain agent definitions following standardized
  guide
author: handbook
tools_restricted: true
tools_allowed: Read, Write, Edit, MultiEdit, Glob, LS, Bash, TodoWrite
model_preference: claude-3-5-sonnet-latest
version: 1.0.0
last_modified: '2025-08-23 23:18:44'
source: custom
---

# Meta: Manage Agents

Create, update, and maintain agent definitions following the standardized agent definition guide.

## Usage

Type `/meta-manage-agents [agent-name] [action]` where:
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
/meta-manage-agents task-finder create
/meta-manage-agents git-commit update
/meta-manage-agents release-navigator review
```

## Full Workflow

For detailed instructions, see: @dev-handbook/.meta/wfi/manage-agents.wf.md