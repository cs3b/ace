---
doc-type: workflow
title: Perform Delivery Workflow
purpose: Coordinate complete task delivery across implementation, review, release, and review cycles.
ace-docs:
  last-updated: 2026-03-12
  last-checked: 2026-03-21
---

# Perform Delivery Workflow

## Goal

Execute complete delivery workflow for a task with automatic step tracking, ensuring no steps are lost during complex multi-step execution.

## Prerequisites

* Task reference (e.g., `215.03`) OR detailed inline instructions
* Clean git working directory (or staged changes ready for commit)
* Understanding of the standard delivery workflow steps
* Access to the relevant ACE CLI tools and workflows

## Project Context Loading

* Load task context via `ace-task show <ref>` if task reference provided
* Load git status: `git status`
* Load PR status: `gh pr view` (if PR exists)

## High-Level Execution Plan

### Phase 0: Externalize Workflow (CRITICAL - DO FIRST)

* [ ] Parse input to identify delivery scope
* [ ] Create TodoWrite entry for EVERY delivery step BEFORE starting work
* [ ] Confirm todo list is complete before proceeding

### Phase 1: Implementation

* [ ] Enter plan mode if implementation required
* [ ] Execute implementation via `ace-bundle wfi://task/work` or inline instructions
* [ ] Commit all changes (`ace-git-commit`)
* [ ] Release modified packages (`ace-bundle wfi://release/publish` if applicable)
* [ ] Mark task done and push to remote

### Phase 2: PR & Initial Review

* [ ] Create or update PR (`ace-bundle wfi://github/pr/create`)
* [ ] Run initial review (`ace-bundle wfi://review/pr`)
* [ ] Implement HIGH/CRITICAL feedback immediately

### Phase 3: Deep Review Cycle

* [ ] Run deep code review (`ace-bundle wfi://review/pr`, using the `code-deep` preset)
* [ ] Implement MEDIUM+ severity feedback
* [ ] Run test suite (`ace-test-suite`)
* [ ] Commit fixes (`ace-git-commit`)
* [ ] Repeat review cycle if needed

## Process Steps

### Phase 0: Externalize Workflow (CRITICAL - DO FIRST)

**BEFORE reading any detailed content or starting implementation:**

1. **Parse Input:**
   * Identify if input is a task reference (e.g., `215.03`) or inline instructions
   * Determine scope: full delivery vs. partial (implementation only, review only, etc.)

2. **Create Session Todo List IMMEDIATELY:**
   * Use TodoWrite to create entries for ALL delivery steps
   * This MUST be the FIRST action before any other work
   * Do not read implementation details until todo list is created

   **Standard Delivery Steps to Add:**

   ```
   1. Implement task (via `ace-bundle wfi://task/work` or inline)
   2. Commit all changes (`ace-git-commit`)
   3. Release modified packages (`ace-bundle wfi://release/publish`)
   4. Mark task done and push to remote
   5. Create/update PR (`ace-bundle wfi://github/pr/create`)
   6. Initial review (`ace-bundle wfi://review/pr`)
   7. Implement HIGH/CRITICAL feedback
   8. Deep review (`ace-bundle wfi://review/pr` with `code-deep`)
   9. Implement MEDIUM+ feedback
   10. Run test suite and commit fixes
   ```

3. **Confirm Before Proceeding:**
   * Output: "Session todo list created with N delivery steps"
   * Only proceed to Phase 1 after todo list is confirmed

### Phase 1: Implementation

1. **Load Task Context (if task reference provided):**
   * Load `ace-bundle wfi://task/work`, then follow it with the task reference
   * If inline instructions provided, use those directly

2. **Enter Plan Mode (if implementation required):**
   * Prepare detailed implementation plan
   * Get user approval before proceeding

3. **Execute Implementation:**
   * Follow the implementation plan
   * Track progress using TodoWrite for sub-tasks

4. **Commit Changes:**
   * Run `ace-git-commit` to commit all changes
   * Use descriptive commit message

5. **Release Packages (if applicable):**
   * Load `ace-bundle wfi://release/publish` when a release is required
   * Follow versioning conventions

6. **Complete Task:**
   * Mark task as done: `ace-taskflow done <ref>`
   * Push to remote: `git push`

### Phase 2: PR & Initial Review

1. **Create or Update PR:**
   * Load `ace-bundle wfi://github/pr/create` to prepare the pull request flow
   * Include task reference and summary

2. **Run Initial Review:**
   * Load `ace-bundle wfi://review/pr`
   * Review the feedback output

3. **Implement Critical Feedback:**
   * Address all HIGH and CRITICAL severity items
   * Commit fixes with descriptive messages

### Phase 3: Deep Review Cycle

1. **Run Deep Code Review:**
   * Load `ace-bundle wfi://review/pr` and use the `code-deep` preset
   * This provides more thorough analysis

2. **Implement Feedback:**
   * Address MEDIUM severity and above items
   * Consider LOW severity items for future improvements

3. **Run Test Suite:**
   * Run `ace-test-suite` to verify all tests pass
   * Fix any failing tests

4. **Commit Fixes:**
   * Run `ace-git-commit` to commit all fixes

5. **Repeat Review Cycle (if needed):**
   * If significant changes were made, run another review
   * Continue until no HIGH/CRITICAL items remain

## Checkpoint Protocol

**After completing EACH numbered todo item:**

1. Mark the todo as COMPLETED using TodoWrite
2. Output checkpoint message:

   ```
   ✓ Step N complete: [step description]
   → Next: Step N+1 - [next step description]
   ```

3. Read todo list to confirm next step
4. Continue IMMEDIATELY to next step (no user prompt needed unless blocked)

**On Failure:**

1. Mark the current todo as blocked (keep as in_progress)
2. Output failure message:

   ```
   ✗ Step N failed: [step description]
   → Error: [error description]
   → Action needed: [what user needs to do]
   ```

3. Ask user for guidance using AskUserQuestion
4. Resume workflow after issue is resolved

## Auto-Continue Protocol

**CRITICAL:** This workflow should AUTO-CONTINUE between steps without waiting for user input.

The only times to pause and ask the user:

* Plan mode approval (Phase 1)
* Step failure requiring user intervention
* Ambiguous instructions requiring clarification
* External blockers (CI failures, merge conflicts, etc.)

For all other transitions, immediately proceed to the next step after checkpoint.

## Scope Variations

### Full Delivery (default)

All steps from implementation through review cycles. Load `ace-bundle wfi://handbook/perform-delivery`.

### Implementation Only

Skip PR and review phases (useful for WIP branches). Load `ace-bundle wfi://handbook/perform-delivery`.

### Review Only

Skip implementation, start from PR creation. Load `ace-bundle wfi://handbook/perform-delivery`.

### Custom Instructions

Provide inline instructions instead of task reference. Load `ace-bundle wfi://handbook/perform-delivery`.

## Success Criteria

* All todo items marked as completed
* No skipped or forgotten steps
* All commits pushed to remote
* PR created (if applicable)
* All HIGH/CRITICAL review feedback addressed
* Test suite passing
* Task marked as done in taskflow

## Error Handling

**Step Fails to Complete:**

* Keep todo item as in_progress
* Log the error with context
* Ask user for guidance
* Resume from failed step after resolution

**User Interruption:**

* Save current state (which step is in progress)
* Allow resume from interruption point
* Maintain todo list across session

**External Tool Failure:**

* Report which tool failed and the error
* Suggest manual alternatives if available
* Wait for user guidance before proceeding

## Usage Examples

### Full Task Delivery

> "Perform delivery for task 215.03"

This will:
1. Load task context
2. Implement the task
3. Commit, release, mark done
4. Create PR
5. Review and iterate

### Review Cycle Only

> "Perform delivery for task 215.03 --scope review"

This will:
1. Create/update PR
2. Review and implement feedback
3. Run test suite
4. Iterate until clean

### Custom Workflow

> "Perform delivery: implement the dark mode feature, commit, create PR, and run one review cycle"

This will parse the custom instructions and create a todo list matching the requested steps.
