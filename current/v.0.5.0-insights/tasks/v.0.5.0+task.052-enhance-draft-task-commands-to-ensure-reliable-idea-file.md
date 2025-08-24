---
id: v.0.5.0+task.052
status: done
priority: high
estimate: 1h
dependencies: []
---

# Enhance draft-task commands to ensure reliable idea file movement

## Behavioral Context

**Issue**: The `/draft-task` and `/draft-tasks` commands were not reliably moving idea files to the current release's `docs/ideas/` directory with task number prefixes, despite this being a required step (Step 8) in the workflow. This led to idea files remaining in the backlog after tasks were created.

**Key Behavioral Requirements**:
- When drafting tasks from idea files, the original idea files MUST be moved to the current release
- Files must be renamed with task number prefixes for traceability
- The movement must be validated and reported to the user
- Failures must be clearly indicated requiring manual intervention

## Objective

Enhanced both `/draft-task` and `/draft-tasks` commands to explicitly detect idea files, enforce their movement to the release directory, and validate the operation completed successfully.

## Scope of Work

- Added explicit idea file detection at the start of `/draft-task` command
- Added mandatory Step 3 for idea file movement with detailed instructions
- Enhanced `/draft-tasks` Task tool prompt to emphasize Step 8 requirement
- Added post-execution verification to ensure files were actually moved
- Updated both Claude commands and source files in dev-handbook

### Deliverables

#### Modify
- `.claude/commands/draft-task.md` - Added 6-step process with explicit idea file handling
- `.claude/commands/draft-tasks.md` - Enhanced Task tool prompt with mandatory movement section
- `dev-handbook/.integrations/claude/commands/_generated/draft-task.md` - Synchronized with main command
- `dev-handbook/.integrations/claude/commands/_custom/draft-tasks.md` - Enhanced with verification

## Implementation Summary

### What Was Done

- **Problem Identification**: User reported that even when using `/draft-task` directly, idea files weren't being moved despite Step 8 being in the workflow
- **Investigation**: Found that Step 8 was buried late in workflow, conditional requirement was easy to miss, and commands didn't explicitly check for idea files
- **Solution**: Made idea file detection explicit at start, added mandatory movement step with validation, and enhanced Task tool prompts to emphasize requirement
- **Validation**: Verified that existing idea files in the repository had been moved to current release (showing as deleted from backlog and present in release)

### Technical Details

The enhanced `/draft-task` command now includes:
1. Step 1: Detect if input is an idea file (check for "backlog/ideas/" in path)
2. Step 2: Execute workflow
3. Step 3: CRITICAL - Mandatory idea file movement if IDEA_FILE_MODE=true
4. Step 4: Validation checklist
5. Step 5: Report status
6. Step 6: Commit changes

The `/draft-tasks` command Task tool prompt now explicitly states:
- "CRITICAL: This is an IDEA FILE from backlog/ideas/ - Step 8 of the workflow is MANDATORY!"
- Includes mandatory movement section with detailed steps
- Adds validation requirements
- Includes post-execution verification

### Testing/Validation

```bash
# Checked git status to verify files were moved
git-status --short

# Verified idea files were moved from backlog to release
# Deleted from: dev-taskflow/backlog/ideas/
# Present in: dev-taskflow/current/v.0.5.0-insights/docs/ideas/
```

**Results**: Confirmed that idea files were successfully moved with proper task number prefixes

## References

- Commits: "Enhance draft-task commands to ensure idea file movement" 
- Related issue: `dev-taskflow/backlog/ideas/20250812-0033-draft-tasks-input-error.md`
- Documentation: Updated workflow commands in both `.claude/commands/` and `dev-handbook/.integrations/claude/commands/`
- Follow-up needed: Monitor future `/draft-task` usage to ensure reliability