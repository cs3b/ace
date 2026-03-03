---
id: 8q0pia
title: Task 150 Subtask Numbering Convention Issue
type: standard
tags: []
created_at: '2026-01-05 16:31:17'
status: done
source: legacy
migrated_from: ".ace-taskflow/v.0.9.0/retros/reflection-task-150-subtask-numbering-conventions.md"
---

# Reflection: Task 150 Subtask Numbering Convention Issue

**Date:** 2026-01-04
**Context:** Task 150 orchestrator and subtask creation
**Issue:** Manually created subtasks used incorrect naming convention

## Problem Discovery

Task 150 subtasks were created manually with single-digit suffixes (150.0, 150.1, etc.) instead of the two-digit format required by ace-taskflow's task loader patterns. This caused `ace-taskflow task 150` to not display subtasks.

### Root Cause Analysis

1. **Manual Task Creation**: Subtasks were created by hand rather than using `ace-taskflow task create --child-of`
2. **Convention Unawareness**: The two-digit subtask convention wasn't followed
3. **Pattern Mismatch**: Files like `150.1-*.s.md` didn't match the expected patterns in `task_loader.rb`:
   - `ORCHESTRATOR_PATTERN = /^(\d+)\.00-.*\.s\.md$/`
   - `SUBTASK_PATTERN = /^(\d+)\.(\d{2})-.*\.s\.md$/`

## Technical Details

### The Problem

```
# Created manually (WRONG):
150-parameter-conf.s.md      # Orchestrator without .00
150.0-config-summary.s.md    # Single-digit suffix
150.1-ace-git-commit.s.md    # Single-digit suffix
...
150.9-ace-test-runner.s.md   # Single-digit suffix

# Expected by ace-taskflow (CORRECT):
150.00-parameter-conf.s.md   # Orchestrator with .00
150.01-config-summary.s.md   # Two-digit suffix
150.02-ace-git-commit.s.md   # Two-digit suffix
...
150.10-ace-test-runner.s.md  # Two-digit suffix
```

### The Fix

Renamed all files and updated:
- Frontmatter IDs: `v.0.9.0+task.150.1` → `v.0.9.0+task.150.01`
- Task titles: `# 150.1:` → `# 150.01:`
- Orchestrator subtasks list
- Inline references in orchestrator document

## Lessons Learned

### Use ace-taskflow Commands for Task Creation

**Key Insight**: Manual task file creation bypasses conventions that ace-taskflow enforces automatically.

The `ace-taskflow task create --child-of PARENT` command:
- Applies correct two-digit numbering
- Sets proper frontmatter (id, parent, status)
- Updates orchestrator's subtasks list
- Follows all naming conventions

### Current Skill Gap

The `/ace:draft-task` and related skills don't adequately guide subtask creation. Missing:
- Explicit subtask creation workflow via ace-taskflow
- Convention documentation for hierarchical tasks
- Validation step to verify naming patterns

### Proposed Improvements

1. **Enhanced Subtask Skill**: Create `/ace:create-subtask` that:
   - Uses `ace-taskflow task create --child-of` internally
   - Validates parent exists before creation
   - Shows created subtask structure

2. **Convention Documentation**: Add to ace-taskflow docs:
   - Orchestrator pattern: `NNN.00-slug.s.md`
   - Subtask pattern: `NNN.NN-slug.s.md` (two-digit)
   - ID format: `v.X.Y.Z+task.NNN.NN`

3. **Validation Command**: Add `ace-taskflow doctor --subtasks` to:
   - Check naming convention compliance
   - Detect orphaned subtasks
   - Verify parent-child consistency

## Prevention Strategies

### For Agents

- Always use `ace-taskflow task create` for task creation
- Use `--child-of` flag for subtasks, never create manually
- Run `ace-taskflow task PARENT` after subtask creation to verify display

### For Skills/Workflows

- Update `/ace:plan-tasks` to use ace-taskflow for subtask creation
- Add validation step in task planning workflows
- Include convention reminders in task creation prompts

## Impact

### Immediate

- Fixed: `ace-taskflow task 150` now shows all 10 subtasks correctly
- 11 files renamed with proper two-digit convention

### Long-term

- Identified gap in agent skills for task creation
- Highlighted need for better convention documentation
- Motivation for enhanced validation tooling

## Summary

This issue arose from manual task creation bypassing ace-taskflow's built-in conventions. The fix was straightforward (file renames + content updates), but the root cause reveals a need for:

1. **Better skills** that use ace-taskflow commands directly
2. **Convention documentation** for hierarchical tasks
3. **Validation tooling** to catch convention violations early

**Key Takeaway**: Always use `ace-taskflow task create --child-of` for subtasks. Manual creation risks convention violations that break tool functionality.