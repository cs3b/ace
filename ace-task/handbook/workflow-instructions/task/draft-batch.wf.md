---
name: task/draft-batch
allowed-tools: Bash, Read, Task
description: Create multiple draft tasks from idea files in sequence
argument-hint: "[idea-pattern]"
doc-type: workflow
purpose: draft-tasks workflow instruction
update:
  frequency: on-change
  last-updated: '2025-10-02'
---

# Draft Multiple Tasks Workflow

## Goal

Process multiple idea files and create draft tasks for each one in sequence, with comprehensive error handling and progress reporting.

## Prerequisites

- Idea files exist in maybe folder (discoverable via `ace-idea list --in maybe`)
- Access to `draft-task` singular workflow via `ace-bundle wfi://task/draft`
- Understanding of ace-task commands

## Variables

- `$idea_pattern`: Optional pattern or list to filter idea files (from argument)

## Process Steps

### Step 0: Detect Task Structure

Before discovering idea files, check whether the argument requests an orchestrator structure:

| Argument pattern | Structure |
|-----------------|-----------|
| "one task with N subtasks" | Single orchestrator + N subtasks |
| "one task with one subtask per phase" | Single orchestrator + one subtask per phase |
| "group under one task" / "single parent" | Single orchestrator + N subtasks |
| (default — no structural hint) | One standalone task per idea file |

**If orchestrator pattern detected:**
1. Create ONE parent task first: `ace-task create "Parent" --status draft`
2. Create each subtask with `--child-of PARENT_ID` (this auto-converts parent to orchestrator)
3. Do NOT create multiple separate parent tasks
* When reorganizing via `ace-task move --child-of <parent>`, the parent conversion also runs automatically so the same `--child-of` workflow applies.

**If flat pattern (default):**
Proceed to Step 1 and create one standalone task per idea.

### Step 1: Discover Idea Files

**If no idea pattern provided:**
```bash
# Discover all ideas in maybe folder
ace-idea list --in maybe
```

**If idea pattern provided:**
- Use the provided pattern/list to filter ideas
- Support specific idea references or file patterns

**Output:**
- List of idea file paths to process
- Total count of ideas found

### Step 2: Process Each Idea File Sequentially

For each idea file in the list:

**2.1 Start Processing:**
- Report: "Processing idea N of M: [idea-reference]"
- Record original idea file path

**2.2 Execute Draft Task Workflow:**

Use Task tool to delegate to singular workflow:

**Task tool prompt:**
```
Execute draft-task workflow for idea: [idea-file-path]

ARGUMENTS: [idea-file-path]

Follow the complete draft-task workflow:
1. Read and execute: ace-bundle wfi://task/draft
2. Create draft task with status: draft
3. Follow all workflow steps exactly
4. Report task ID and path when complete

Expected output:
- Draft task ID created
- Draft task file path
- Task title
- Any issues encountered
```

**Subagent type:** general-purpose

**2.3 Handle Idea File Cleanup:**

After task creation succeeds:
```bash
# Extract task number from created task path
TASK_NUM=$(echo "$TASK_PATH" | grep -oE '[0-9]+' | tail -1)

# Move idea file to archive and mark as done
ace-idea move [idea-id] --to archive
ace-idea update [idea-id] --set status=done
```

**Note:** These commands:
- Move the idea file to the `_archive/` folder
- Update idea frontmatter with completion status

**2.4 Error Handling:**

If task creation fails:
- Log the failure with idea file and error details
- Add to failures list
- Continue to next idea file (don't stop batch)

If idea cleanup fails:
- Report warning but don't fail the batch
- Add to warnings list
- Include in final summary

**2.5 Progress Update:**
- Brief summary of task created
- Current success/failure count
- Move to next idea

### Step 3: Generate Final Summary

After all idea files processed:

**3.1 Run Documentation Validation:**
```bash
bin/lint
```
- Ensure all documentation passes quality checks
- Fix any linting issues found

**3.2 Create Summary Report:**

Provide comprehensive summary including:

**Statistics:**
- Total idea files processed: X
- Draft tasks created successfully: Y
- Failures: Z
- Warnings: W

**Created Tasks:**
| Task ID | Title | Path | Status |
|---------|-------|------|--------|
| v.X.Y+NNN | ... | ... | draft |

**Failures (if any):**
- Idea file: [path]
- Error: [description]
- Action needed: [recommendation]

**Warnings (if any):**
- Issue: [description]
- Context: [details]

**Recommendations:**
- Next steps (e.g., run ace-review-run-task to validate and promote drafts)
- Any follow-up actions needed

## Error Handling Strategies

### Idea Discovery Failure
- **Symptom:** `ace-idea list --in maybe` returns no results or errors
- **Action:** Report issue, check if maybe directory exists, exit gracefully

### Task Creation Failure
- **Symptom:** Draft task workflow fails or returns error
- **Action:** Log failure, skip to next idea, include in final summary

### Idea Cleanup Failure
- **Symptom:** `ace-idea move` or `ace-idea update` fails
- **Action:** Warn user, task still created, manual cleanup may be needed

### Validation Failure
- **Symptom:** `bin/lint` fails after task creation
- **Action:** Attempt auto-fix, report issues, don't fail entire batch

## Output / Success Criteria

- All idea files processed (or failures documented)
- Draft tasks created with `status: draft`
- Idea files marked as done and moved to _archive/ (or warnings issued)
- Comprehensive summary report generated
- Documentation validation passes (or issues reported)
- Clear next steps provided

## Usage Examples

```bash
# Process all backlog ideas
/ace-task-drafts

# Process specific idea pattern (if supported)
/ace-task-drafts [pattern]

# Process specific ideas by reference
/ace-task-drafts [idea-ref-1] [idea-ref-2]
```

## Important Notes

- Execute ideas sequentially (no parallel processing)
- Each idea gets full draft-task workflow treatment
- Use Task tool to delegate to singular workflow
- Never skip idea file cleanup step
- Maintain detailed progress logs
- Continue on failure (collect all results)
- Always provide comprehensive final summary
- Use `ace-idea move <id> --to archive` + `ace-idea update <id> --set status=done` for idea cleanup (not manual git mv)
