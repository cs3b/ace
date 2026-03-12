---
name: update-claude
description: Synchronize Claude-native skill projections from canonical handbook skills
allowed-tools: Bash, Read, Write, Edit, Glob
argument-hint: "[full|skills|agents|meta]"
doc-type: workflow
purpose: claude integration sync workflow
---

# Update Claude Integration Workflow

## Instructions

1. Enumerate canonical skills from package `handbook/skills/`.
2. Project Claude-native wrappers into `.claude/skills/`.
3. Sync any Claude-specific agents or templates owned by this package.
4. Validate the generated Claude tree against canonical source metadata.
