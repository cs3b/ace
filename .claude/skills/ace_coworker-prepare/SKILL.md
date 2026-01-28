---
name: ace:coworker-prepare
description: Prepare job.yaml from preset or informal instructions
user-invocable: true
allowed-tools:
  - Bash(ls:*)
  - Bash(cat:*)
  - Read
  - Write
  - AskUserQuestion
argument-hint: "[preset-name] [--taskref value] [--output path]"
last_modified: 2026-01-28
source: ace-coworker
---

read and run `ace-bundle wfi://coworker-prepare-job`

## Quick Reference

**Available Presets:**
- `work-on-task` - Simple task implementation with commit
- `work-on-task-with-pr` - Full workflow with PR and 3 review cycles

**Parameters:**
- `--taskref <id>` - Task reference (required for task presets)
- `--output <path>` - Custom output path (default: job.yaml)

**Examples:**
```
/ace:coworker-prepare work-on-task --taskref 123
/ace:coworker-prepare work-on-task-with-pr --taskref 148
/ace:coworker-prepare "implement task 148, create pr, review twice"
```
