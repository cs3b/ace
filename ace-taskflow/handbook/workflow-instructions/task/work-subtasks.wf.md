---
name: task/work-subtasks
allowed-tools: Bash, Read, Task, AskUserQuestion, TodoWrite
description: Execute orchestrator task by delegating subtasks to worktrees
argument-hint: "[orchestrator-task-id]"
doc-type: workflow
purpose: work-on-subtasks workflow instruction for orchestrator tasks
update:
  frequency: on-change
  last-updated: '2025-12-26'
---

# Work on Subtasks Workflow Instruction

**Goal:** Execute an orchestrator task by processing its subtasks sequentially, each in an isolated worktree with subagent delegation, PR creation, and review cycles.

## Prerequisites

- Orchestrator task selected (has `subtasks:` in frontmatter or subtask files `NNN.NN-*.s.md` in same directory)
- Access to ace-git-worktree for worktree management (see `ace-git-worktree/docs/usage.md`)
- Understanding of the parent-subtask relationship

## Critical: Worktree Isolation

**ALL implementation work MUST happen in the subtask worktree, NOT the orchestrator worktree.**

### Use ace-git-worktree

```bash
# Create worktree (handles everything automatically)
ace-git-worktree create --task 140.03
```

This command:
1. Marks task `in-progress` (commits to orchestrator branch, pushes)
2. Creates worktree at sibling path (e.g., `../ace-task.140.03/`)
3. Creates subtask branch from orchestrator
4. Outputs the worktree path

**After creation, ALL work happens in the worktree path.**

### What happens where:

| Action | Location | Handled by |
|--------|----------|------------|
| Mark task in-progress | Orchestrator | `ace-git-worktree create` |
| Implementation work | **Worktree** | Subagent |
| Commits | **Worktree** | Subagent |
| Create PR | Worktree | Orchestrator agent |

### Anti-patterns

```bash
# ❌ WRONG - Subagent working in orchestrator directory
cd /path/to/ace-task.140      # orchestrator - WRONG
vim ace-review/lib/...         # changes here go to wrong branch!

# ✅ CORRECT - Subagent working in worktree
cd /path/to/ace-task.140.03   # worktree from tool output
vim ace-review/lib/...         # changes on subtask branch
```

## Critical: Branch Management

**DO NOT merge between subtask branches.** The workflow handles dependencies automatically:

1. Each subtask PR targets the orchestrator branch
2. When a PR is merged, the orchestrator branch has those changes
3. New worktrees created via `ace-git-worktree create` branch from the orchestrator
4. Therefore, new worktrees automatically include all previously merged subtask work

**Anti-pattern to avoid:**
```bash
# WRONG - Do not do this!
git merge 140.01-branch into 140.02-branch
```

**Correct flow:**
1. Complete subtask 140.01, create PR, merge to orchestrator branch
2. Create worktree for 140.02 - it already has 140.01 changes
3. No manual merging needed

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

## Quick Start

For experienced users, here's the condensed workflow:

1. **Load orchestrator** - Get orchestrator task and list pending subtasks
2. **For each pending subtask:**
   - Create worktree: `ace-git-worktree create --task {id}` (creates `../ace-task.{id}/`)
   - **Switch to worktree** for all implementation work
   - Launch subagent with **explicit worktree path** in prompt
   - Verify commits are on subtask branch (not orchestrator)
   - Create PR targeting orchestrator branch
   - Run review cycle (x2 max)
   - User validates manually
   - Run tests
   - Merge PR with rebase: `gh pr merge <number> --rebase`
   - Pull changes and mark subtask done
3. **Summarize progress** after each subtask
4. **Wait for user feedback** between subtasks

**Remember:** Worktree creation marks task in-progress on orchestrator branch. All other work happens in the worktree.

## Detailed Process Steps

### Step 1: Load Orchestrator Task

```bash
# Get orchestrator task details
ace-task show <orchestrator-id>

# Example: ace-task show 122
# Returns: orchestrator path, subtasks list
```

**Extract from frontmatter:**
```yaml
subtasks:
- v.0.9.0+task.122.01
- v.0.9.0+task.122.02
- v.0.9.0+task.122.03
- v.0.9.0+task.122.04
```

### Step 2: Identify Pending Subtasks

```bash
# List subtasks with status
ace-task list --filter "122.*" --filter status:pending
```

**Filter for actionable subtasks:**
- Status: `pending` (ready to start)
- Dependencies satisfied (all deps are `done`)
- Skip: `in-progress`, `done`, `blocked`

### Step 3: Process Each Subtask Sequentially

For each pending subtask (e.g., `122.01`):

#### 3.1 Create Worktree

Use `ace-git-worktree` to create the worktree. Run from orchestrator:

```bash
ace-git-worktree create --task 122.01
```

**This automatically:**
1. Marks task as `in-progress` (commits to orchestrator branch)
2. Pushes status change to origin
3. Creates worktree with subtask branch
4. Outputs the worktree path

**Capture the worktree path** from output:
```
Worktree path: <WORKTREE_PATH>  # e.g., /path/to/ace-task.122.01
```

**If worktree exists:** The tool will report it. Reuse existing worktree (don't recreate).

#### 3.2 Delegate to Subagent

**CRITICAL: Subagent MUST work in the worktree.**

Use Task tool with the **exact worktree path** from step 3.1:

```markdown
Execute work-on-task workflow for subtask 122.01

## CRITICAL: Worktree Location

**Worktree path:** <WORKTREE_PATH>

ALL work MUST happen in this directory. Before ANY file operations:
1. Run: `cd <WORKTREE_PATH>`
2. Verify: `pwd` shows the worktree path
3. Verify: `git branch` shows the subtask branch (122.01-*)

❌ DO NOT work in <ORCHESTRATOR_PATH> (orchestrator)
✅ ALL changes in <WORKTREE_PATH> (worktree)

## Steps

1. `cd <WORKTREE_PATH>`
2. Read parent task for context: `ace-task 122`
3. Read your subtask: `ace-task 122.01`
4. Implement changes per subtask file
5. Run tests: `ace-test`
6. Commit on subtask branch
7. Return: changes made, files modified, test results
```

The parent task provides the why and overall scope boundaries.
The subtask provides the specific implementation requirements.
If parent context cannot be loaded, continue with the subtask spec only.
If your subtask appears to conflict with parent intent, flag it in your return summary instead of guessing.

**Verification:** After subagent returns, check commits are on subtask branch:
```bash
git -C <WORKTREE_PATH> log --oneline -3
```

#### 3.3 Create Pull Request

After subagent completes successfully:

```bash
# From worktree directory
cd <WORKTREE_PATH>

# Create PR targeting parent branch
gh pr create \
  --base {parent-branch-name} \
  --head 122.01-{slug} \
  --title "122.01: {subtask-title}" \
  --body "$(cat <<'EOF'
## Summary
{subagent summary of changes}

## Test Plan
- [ ] All existing tests pass
- [ ] New functionality tests pass
- [ ] Manual CLI validation

---
Parent task: #122

Generated by ACE agent
EOF
)"
```

**PR targeting:**
- Base: parent branch (derived from orchestrator task's `branch:` field, e.g., `122-subtask-workflow-support`)
- Head: subtask branch (`122.01-hierarchical-parser`)

#### 3.4 Review Cycle

```
For each PR:
  1. Get PR number from `ace-git status` (Current PR section)
  2. Verify target branch is orchestrator (not main)
  3. Run: `ace-review --preset code --pr <number> --auto-execute`
  4. If approved -> continue to validation
  5. If feedback:
     a. Delegate to subagent: apply review feedback
     b. Re-run ace-review with same --pr flag
     c. Repeat up to 2 times (max_review_cycles)
  6. If still not approved after 2 cycles:
     a. Summarize issues
     b. Ask user how to proceed
```

**Review command:**
```bash
# In worktree directory - get PR info from ace-git status
ace-git status
# Look for "Current PR" section:
#   #88 [OPEN] 140.04: Update ace-prep to use ace-git
#     Target: 140-enhance-ace-bundle-with-dynamic-git-branch-and-pr-information

# Review the PR (compares against PR's target branch)
ace-review --preset code --pr 88 --auto-execute
```

**Why --pr is required:** Without `--pr`, ace-review compares against main branch. Subtask PRs target the orchestrator branch, so `--pr` ensures the review only covers the subtask's changes.

**Review delegation prompt:**
```markdown
Apply review feedback to subtask 122.01

Working directory: <WORKTREE_PATH>

Review feedback to address:
{review feedback here}

Actions:
1. Apply all feedback items
2. Run tests: ace-test
3. Commit changes
4. Report what was changed
```

#### 3.5 Manual Validation

After review approval, prompt user:

```markdown
**Subtask 122.01 implementation is complete.**

Please validate manually:
1. Test the CLI: `ace-task show 121.01`
2. Verify new functionality works as expected
3. Run: `ace-test test/atoms/task_reference_parser_test.rb`

Is the implementation working correctly?
- [ ] Yes, proceed to next subtask
- [ ] No, need fixes (describe issues)
```

Use `AskUserQuestion` tool for this validation step.

#### 3.6 Test Validation

```bash
# In worktree directory
cd <WORKTREE_PATH>
ace-test

# If failures:
#   1. Delegate to subagent: fix failing tests
#   2. Re-run tests
#   3. Repeat until pass or max_test_retries (default: 3)
```

**Test fix delegation:**
```markdown
Fix failing tests in subtask 122.01

Working directory: <WORKTREE_PATH>

Failing tests:
{test output here}

Actions:
1. Analyze test failures
2. Fix implementation or test as appropriate
3. Re-run: ace-test
4. Report results
```

#### 3.7 Commit Subtask Changes

**IMPORTANT:** Commit after each subtask completes, before moving to the next.

```bash
# In worktree directory (or main repo if not using worktrees)
git add -A
git commit -m "feat(component): Implement [subtask-title]

Completes subtask [subtask-id] of orchestrator [orchestrator-id]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Rationale:**
- Each subtask's changes are isolated in their own commit
- Enables granular review and rollback per subtask
- If later subtasks fail, earlier work is preserved
- Makes PR reviews more manageable

#### 3.8 Merge PR (Rebase)

After user validation passes, merge the PR using **rebase merge** to preserve commit history:

```bash
# Merge PR with rebase (preserves individual commits)
gh pr merge <pr-number> --rebase

# Pull merged changes to orchestrator branch
git pull --rebase origin {orchestrator-branch}
```

**Why rebase merge:**
- Preserves granular commit history from subtask branch
- Each logical change remains a separate commit
- Easier to review, bisect, and revert individual changes
- Maintains clean linear history on orchestrator branch

**Avoid:**
- `--squash` - Loses commit granularity (subagent prepared commits well)
- `--merge` - Creates merge commits that clutter history

#### 3.9 Mark Subtask Complete

After PR is merged:

```bash
# Mark subtask as done
ace-task done 122.01
```

#### 3.10 Architecture Drift Check

After completing each subtask, briefly assess:
- Did implementation reveal that concepts from EARLIER subtasks are now unnecessary?
- Did the approach change in ways that affect LATER subtask specs?

If drift detected:
1. Document the drift in the orchestrator task file
2. Flag affected sibling subtasks with `needs_review: true`
3. Ask user: "Subtask N revealed [finding]. Should we update subtask specs M, O, P before continuing?"

**Why**: Implementation learnings in subtask 3 may invalidate assumptions in subtasks 1-2 (backward)
or require spec updates in subtasks 4-5 (forward). Catching drift early prevents wasted work.

### Step 4: Progress Summary

After each subtask completion, provide summary:

```markdown
## Subtask 122.01 Complete

**Status:** Done
**Changes:** {key changes}
**PR:** #{pr-number}
**Review cycles:** {count}/2

**Next:** 122.02 - Task Scanner Enhancement
**Remaining:** 3 subtasks pending

Continue to next subtask?
```

### Step 5: Repeat for Remaining Subtasks

Continue with next pending subtask:
- Check dependencies are satisfied
- Follow steps 3.1-3.9
- Summarize progress

### Step 6: Final Orchestrator Summary

When all subtasks are done:

```markdown
## Orchestrator Task 122 Complete

**All Subtasks:**
| Subtask | Title | Status | PR |
|---------|-------|--------|-----|
| 122.01 | Hierarchical Parser | Done | #X |
| 122.02 | Task Scanner | Done | #Y |
| 122.03 | CLI Integration | Done | #Z |
| 122.04 | Orchestration Workflow | Done | #W |

**Final Validation:**
- [ ] All subtask PRs merged to parent branch
- [ ] Full test suite passes: ace-test
- [ ] Parent task validation criteria met

**Next Steps:**
- Merge parent branch to main
- Mark orchestrator as done
```

## Configuration

```yaml
# .ace/taskflow/config.yml
taskflow:
  orchestration:
    max_review_cycles: 2        # Review retries before asking user
    max_test_retries: 3         # Test fix retries before asking user
    cleanup_worktrees: false    # Remove worktrees after completion
    auto_merge_subtasks: false  # Auto-merge PRs (vs manual)
```

## Edge Cases

### Subtask Already In Progress

```
If subtask status == in-progress:
  - Report: "Subtask 122.01 already in progress"
  - Check if worktree exists
  - Ask user: resume or skip?
```

### Subtask Already Done

```
If subtask status == done:
  - Skip subtask
  - Report: "Subtask 122.01 already complete"
```

### Worktree Already Exists

```
If worktree path exists:
  - Report: "Resuming work in existing worktree: <WORKTREE_PATH>"
  - Do NOT cleanup/recreate (prevents data loss)
  - Continue with subagent delegation
```

### Subagent Fails Repeatedly

```
If subagent fails > 2 times:
  - Capture error details
  - Ask user: retry, skip, or abort?
```

### Tests Never Pass

```
If tests fail after max_test_retries:
  - Capture test output
  - Ask user: fix manually, skip, or abort?
```

### PR Merge Conflicts

```
If PR has conflicts:
  - Report conflict details
  - Ask user to resolve manually
  - Resume after user confirms resolution
```

### Dependencies Not Satisfied

```
If subtask has unmet dependencies:
  - Skip subtask
  - Report: "Skipping 122.02 - dependency 122.01 not complete"
  - Continue with next subtask that has met dependencies
```

## Error Handling

### Worktree Creation Failure

**Symptoms:**
- `ace-git-worktree create` fails
- Path already exists with conflicts
- Branch already exists

**Recovery:**
1. Check existing worktrees: `ace-git-worktree list`
2. Try with different path: `ace-git-worktree create --task 122.01 --path custom/path`
3. Clean up orphaned worktrees: `ace-git-worktree prune`
4. Ask user for resolution

### Subagent Timeout

**Symptoms:**
- Subagent takes too long
- No response from Task tool

**Recovery:**
1. Check worktree status manually
2. Review partial work completed
3. Resume with new subagent or manual completion

### PR Creation Failure

**Symptoms:**
- `gh pr create` fails
- Authentication issues
- Branch not pushed

**Recovery:**
1. Ensure branch is pushed: `git push -u origin 122.01-{slug}`
2. Check gh authentication: `gh auth status`
3. Retry PR creation
4. Manual PR creation as fallback

## Output / Success Criteria

- All pending subtasks processed
- Each subtask has:
  - Worktree created/reused
  - Implementation completed by subagent
  - **Changes committed** (one commit per subtask)
  - PR created targeting parent branch
  - Review cycle completed (max 2)
  - User validation passed
  - Tests passed
  - Status marked `done`
- Progress summarized after each subtask
- Final orchestrator summary provided
- **Git history shows one commit per subtask** (not batched)

## Usage Example

```
User: "Work on orchestrator task 122"

1. Load task 122, detect orchestrator (has subtasks)
2. Redirect to work-on-subtasks workflow
3. Process subtask 122.01:
   - Create worktree (e.g., ../ace-task.122.01/)
   - Delegate to subagent with worktree path
   - Create PR 122.01-* -> 122-*
   - Review cycle
   - User validates
   - Mark done
4. Summary: "122.01 done, 3 remaining"
5. Continue with 122.02...
```

---

This workflow enables systematic execution of complex tasks broken into subtasks, with isolation, review, and validation at each step.
