---
id: 8olqpc
title: "Retro: ace-draft-task Skill Workflow Issues"
type: conversation-analysis
tags: []
created_at: "2026-01-22 17:48:08"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8olqpc-ace-draft-task-skill-issues.md
---
# Retro: ace-draft-task Skill Workflow Issues

**Date**: 2026-01-22
**Context**: Creating task 227 (ace-test package) as subtask of 218 using /ace:draft-task skill
**Author**: Claude Code Agent
**Type**: Conversation Analysis

## What Went Well

- User caught the error: recognized that `ace-taskflow task move --child-of` wasn't used
- Plan mode prevented accidental incorrect file modifications
- Behavioral specification was properly created in task 227 following draft-task template
- User identified the need for a retro to capture learnings

## What Could Be Improved

- Skill name confusion: tried `ace_create-task` but actual skill is `ace_draft-task`
- Missed proper ace-taskflow command for parent-child relationship
- Manual file edit instead of using proper workflow command
- No validation that task was properly linked to parent

## Key Learnings

- **Skill names use underscores**: `ace_draft-task` not `ace-create-task`
- **ace-taskflow has proper commands**: `ace-taskflow task move <id> --child-of <parent>` establishes structural relationship
- **Manual edits ≠ proper workflow**: Editing parent task file only adds text reference, not structural relationship
- **The `--child-of` command does multiple things**: moves file to subdirectory, updates metadata, maintains tracking

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Skill Name Mismatch**: Attempted `Skill("ace-create-task")` but actual skill name is `ace_draft-task`
  - Occurrences: 2 (first attempt, second after realizing error)
  - Impact: Delayed task creation, caused user frustration
  - Root Cause: No easy way to discover available skill names; assumption that CLI pattern maps to skill pattern

- **Missed ace-taskflow Command**: Created task but didn't establish parent-child relationship properly
  - Occurrences: 1
  - Impact: Task 227 not structurally linked to parent task 218; only manual text reference added
  - Root Cause: Draft-task workflow doesn't explicitly include the `ace-taskflow task move --child-of` step; agent assumed manual edit was sufficient

#### Medium Impact Issues

- **Ambiguous Workflow Instructions**: Skill shows "read and run `ace-bundle wfi://draft-task`" but doesn't execute workflow
  - Occurrences: 1
  - Impact: Agent read workflow but didn't follow all steps properly
  - Root Cause: Skill instructions could be clearer about executing vs. reading

### Improvement Proposals

#### Process Improvements

- **Add skill discovery command**: `ace-nav skill:///` to list all available skills
- **Update draft-task workflow**: Explicitly include `ace-taskflow task move <id> --child-of <parent>` step
- **Add validation step**: After creating task, verify parent relationship with `ace-taskflow task show <id>`

#### Tool Enhancements

- **Skill name aliases**: Support both `ace-create-task` and `ace_draft-task` for discoverability
- **Task creation with parent**: Add `--parent` flag to `ace-taskflow task create` to establish relationship during creation
- **Relationship validation**: `ace-taskflow task create` could warn if creating a subtask without parent reference

#### Communication Protocols

- **Explicit skill invocation**: When user says "/ace:command", agent should verify skill exists before attempting
- **Workflow completion checklist**: After running workflow, confirm all steps completed (especially parent linking)

## Action Items

### Stop Doing

- Manually editing parent task files to add subtask references
- Assuming skill names follow CLI patterns without verification
- Skipping ace-taskflow commands for task relationships

### Continue Doing

- Creating behavioral specifications in draft tasks (template worked well)
- Catching errors in plan mode before executing
- Using retros to capture workflow learnings

### Start Doing

- **Verify skill names before invocation**: Use `ace-nav skill:///` or check `.claude/skills/` directory
- **Use proper ace-taskflow commands**: `ace-taskflow task move <id> --child-of <parent>` for parent relationships
- **Add validation steps**: After task creation, verify relationship established
- **Document skill naming conventions**: Clarify underscore vs. hyphen patterns

## Technical Details

**Proper workflow for creating subtask:**
```bash
# 1. Create draft task
ace-taskflow task create --title "Task Title" --status draft --estimate "TBD"

# 2. Move to parent directory (establishes structural relationship)
ace-taskflow task move <task-id> --child-of <parent-task-id>

# 3. Populate with behavioral specification
# Edit the task file with content from draft-task template
```

**What `--child-of` actually does:**
- Moves task file to parent's subdirectory: `.ace-taskflow/v.0.9.0/tasks/<parent-slug>/<task-id>-<slug>.md`
- Updates task metadata with parent relationship
- Maintains ace-taskflow's internal tracking/index

**Skill naming convention:**
- Skills use underscores: `ace_draft-task`, `ace_create-retro`
- CLI commands use hyphens: `ace-taskflow task create`, `ace-nav guide://`
- This inconsistency causes confusion

## Additional Context

- **Related Tasks**: v.0.9.0+task.227 (Create ace-test package), v.0.9.0+task.218 (Docs Audit - parent)
- **Related Skills**: ace_draft-task, ace_create-retro, ace_plan-task
- **Plan File**: `/Users/mc/.claude/plans/starry-orbiting-glacier.md`
- **Implementation Plan**: Detailed plan for ace-test package creation
