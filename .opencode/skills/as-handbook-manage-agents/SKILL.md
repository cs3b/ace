---
name: as-handbook-manage-agents
description: Create, update, and maintain agent definitions following standardized
  guide
user-invocable: true
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
last_modified: 2026-01-10
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://handbook/manage-agents
---

read and run `ace-bundle wfi://handbook/manage-agents`
