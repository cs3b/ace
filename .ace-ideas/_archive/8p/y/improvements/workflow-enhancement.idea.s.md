---
id: improv
status: done
title: 'Workflow Enhancement: Explicit Commit Instructions'
tags: []
created_at: '2026-02-28 20:24:51'
---

# Workflow Enhancement: Explicit Commit Instructions

## Issue Identified
Date: 2025-08-13
Context: During execution of 6 tasks (v.0.5.0+task.031 through v.0.5.0+task.037)

### Problem
Sub-agents executing tasks via the Task tool completed all implementation work but did not commit changes to git. This resulted in uncommitted changes accumulating across multiple tasks.

### Root Cause
The `work-on-task.wf.md` workflow instruction does not include explicit git commit steps. While the parent `/work-on-tasks` command mentions commits, the actual workflow file that sub-agents follow only mentions:
- "Save the updated task file"
- "Work is complete and ready for review"
- No explicit `git add` or `git commit` instructions

## Proposed Solutions

### 1. Update work-on-task.wf.md

Add a new section after step 6 (Follow Coding Standards) and before step 7 (Final Review & Completion):

```markdown
## 6.5. Commit Implementation Changes
   * Stage all modified and new files:
     ```bash
     git add -A
     ```
   
   * Review staged changes:
     ```bash
     git status
     ```
   
   * Commit with descriptive message:
     ```bash
     git commit -m "feat(task-id): implement [brief description]
     
     - Key changes made
     - Files added/modified
     - Tests passed
     
     Task: [task-id]"
     ```
   
   * Verify commit was successful:
     ```bash
     git log --oneline -1
     ```
   
   * Note: If working in submodules, commit those first before main repo
```

### 2. Update work-on-tasks.md Sub-agent Instructions

Modify the Task tool prompt template to explicitly include:

```markdown
- [ ] **Commit Implementation:**
  - Stage all new and modified files with git add
  - Create descriptive commit message with task ID
  - Commit changes to version control
  - Verify commit was successful
```

### 3. Add Verification Between Tasks

In work-on-tasks.md, add between-task verification:

```markdown
## Between Tasks

After completing one task and before starting the next:
- [ ] Verify previous task changes were committed
- [ ] Run `git status` to ensure clean working directory
- [ ] If uncommitted changes exist, investigate and resolve
- [ ] Document any commit issues in task summary
```

### 4. Enhanced Error Recovery

Add to both workflows:

```markdown
## Git State Management

If git operations fail:
1. Check current branch: `git branch`
2. Verify remote configuration: `git remote -v`
3. Check for merge conflicts: `git status`
4. If unable to commit, document issue and continue with CAUTION flag
5. Never leave uncommitted work without documentation
```

## Benefits

1. **Traceability**: Each task's changes are committed with reference to task ID
2. **Atomicity**: Changes for each task are grouped in logical commits
3. **Recovery**: Easier to rollback or cherry-pick individual task implementations
4. **Review**: Clear commit history for code review and auditing
5. **Automation**: Sub-agents will handle commits automatically

## Implementation Priority

**HIGH** - This change should be implemented immediately to prevent future accumulation of uncommitted changes across task executions.

## Validation

After implementing these changes:
1. Test with a single task execution
2. Verify commits are created automatically
3. Test with multiple task execution
4. Verify each task gets its own commit
5. Test error scenarios (merge conflicts, etc.)