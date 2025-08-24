---
description: Draft Task
allowed-tools: Read, Write, TodoWrite, Bash
last_modified: '2025-08-24 00:17:47'
source: generated
---

# Draft Task with Idea File Movement

## Step 1: Detect Input Type
First, determine if the input is an idea file:
- Check if input file path contains "backlog/ideas/"
- If YES: Set IDEA_FILE_MODE=true and record the original path
- If NO: Set IDEA_FILE_MODE=false

## Step 2: Execute Workflow
Read whole file and follow @dev-handbook/workflow-instructions/draft-task.wf.md

## Step 3: CRITICAL - Idea File Movement (if IDEA_FILE_MODE=true)
**MANDATORY when drafting from idea files:**

After task creation is complete, you MUST:
1. Extract task number from the created task path
2. Get current release path using `release-manager current`
3. Create destination directory: `$RELEASE_PATH/docs/ideas/`
4. Move idea file: `git-mv "original-idea-path" "$RELEASE_PATH/docs/ideas/$TASK_NUM-original-filename"`
5. Update task file references to point to new location
6. Commit the movement with message: "Move idea file to current release for task $TASK_NUM"

## Step 4: Validation Checklist
If IDEA_FILE_MODE=true, verify ALL of the following:
- [ ] Original idea file NO LONGER exists in backlog/ideas/
- [ ] Idea file NOW exists in current-release/docs/ideas/ with task number prefix
- [ ] Task file references the NEW location of the idea file
- [ ] Git commit includes the file movement

## Step 5: Report Status
- If idea file was moved: Report "✓ Idea file successfully moved to release"
- If movement failed: Report "✗ ERROR: Idea file movement failed - manual intervention required"

## Step 6: Commit Changes
Read and run @.claude/commands/commit.md