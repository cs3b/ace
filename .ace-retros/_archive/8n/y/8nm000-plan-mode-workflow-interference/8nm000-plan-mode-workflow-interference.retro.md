---
id: 8nm000
title: Plan Mode vs Workflow Instruction Interference
type: conversation-analysis
tags: []
created_at: '2025-12-23 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8nm000-plan-mode-workflow-interference.md"
---

# Reflection: Plan Mode vs Workflow Instruction Interference

**Date**: 2025-12-23
**Context**: Agent misinterpreted `/ace:plan-task` workflow as triggering Claude's built-in plan mode, leading to code implementation instead of task planning
**Author**: Claude (Opus 4.5) + User
**Type**: Conversation Analysis

## What Went Well

- User caught the error quickly before significant code was written
- Code changes were easily reverted with `git checkout`
- The correct workflow was executed successfully after clarification
- Task 140.10 was properly planned with full technical specification

## What Could Be Improved

- Agent confused project's `/ace:plan-task` workflow with Claude Code's built-in "plan mode"
- When plan mode exited with "approved", agent interpreted this as approval to implement code
- The term "plan" appears in both contexts with different meanings:
  - **ace:plan-task**: Write implementation plan TO the task file, update status draft→pending
  - **Claude plan mode**: Research and design approach, write to Claude's plan file

## Key Learnings

- Workflow names that overlap with Claude Code system features can cause semantic confusion
- The `/ace:plan-task` workflow is about **documenting** a plan, not **executing** it
- "Plan mode" in Claude Code context means "don't make changes yet, research first"
- "plan-task" in ace-taskflow context means "write the HOW to the task file"

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Semantic Collision**: `/ace:plan-task` workflow name collided with Claude's "plan mode" concept
  - Occurrences: 1 (but potential for recurrence is high)
  - Impact: Agent wrote code changes instead of updating task file; required user intervention and rollback
  - Root Cause: Both "plan" and "plan mode" exist in different contexts with different meanings. Agent's system prompt entered "plan mode" which has specific behaviors (write to plan file, exit when done), but the workflow instruction says to write to the task file.

#### Medium Impact Issues

- **Exit Signal Misinterpretation**: When Claude's plan mode said "approved", agent started implementing
  - Occurrences: 1
  - Impact: Wasted time writing code that needed reverting
  - Root Cause: The ExitPlanMode approval was about the plan file content, not permission to implement

### Improvement Proposals

#### Process Improvements

1. **Workflow Naming Convention**: Consider renaming workflows that conflict with Claude Code system terminology
   - `plan-task` → `spec-task` or `detail-task` or `prepare-task`
   - Avoids semantic collision with Claude's "plan mode"

2. **Explicit Output Clarification**: Workflows should explicitly state:
   - "This workflow ONLY modifies the task file"
   - "Do NOT write code or make implementation changes"
   - "Output is documentation, not implementation"

3. **Workflow Category Headers**: Add category to workflow frontmatter:
   ```yaml
   category: documentation  # vs implementation, review, etc.
   modifies: task-file-only
   ```

#### Tool Enhancements

1. **ace-taskflow plan-task command**: Create a CLI command that:
   - Takes task ID as argument
   - Outputs explicit instructions: "Update task file at X, change status to pending"
   - Makes the expected action unambiguous

2. **Workflow Execution Guard**: Add check in skill execution:
   - If in Claude plan mode AND workflow is documentation-only → warn about conflict

#### Communication Protocols

1. **Workflow Intent Declaration**: At start of workflow execution, agent should state:
   - "This workflow will modify: [specific files]"
   - "This workflow will NOT: [write code, make commits, etc.]"

2. **User Confirmation for Ambiguous Cases**: When workflow name overlaps with system concepts:
   - "I see `/ace:plan-task` - this updates the task file with implementation details, not actual code. Proceeding?"

### Token Limit & Truncation Issues

- **Large Output Instances**: None
- **Truncation Impact**: N/A
- **Mitigation Applied**: N/A
- **Prevention Strategy**: N/A

## Action Items

### Stop Doing

- Assuming "plan" in workflow names means Claude's plan mode behavior
- Interpreting "plan mode exit/approval" as permission to implement code
- Starting implementation without explicit user request

### Continue Doing

- Reading workflow instructions before execution
- Using `ace-nav wfi://` to load workflow content
- Following commit workflow after task updates

### Start Doing

- State explicitly what files will be modified before starting workflow
- Distinguish between "planning documentation" and "implementation execution"
- When workflow name overlaps with system concepts, clarify intent first
- Consider workflow names from the perspective of potential semantic collision

## Technical Details

**The Collision Point:**
```
User: /ace:plan-task 140.10
       ↓
Claude Code: Enters "plan mode" (system behavior)
       ↓
Workflow: Says "write plan to task file"
       ↓
Agent: Wrote to Claude's plan file instead
       ↓
Plan mode exits: "approved"
       ↓
Agent: Interpreted as "implement now"
       ↓
Result: Started writing code (WRONG)
```

**Correct Flow:**
```
User: /ace:plan-task 140.10
       ↓
Agent: Read workflow instruction
       ↓
Agent: Write implementation plan to TASK FILE
       ↓
Agent: Update task status draft → pending
       ↓
Agent: Commit the task file changes
       ↓
Result: Task documented, ready for implementation (CORRECT)
```

## Additional Context

- Task: 140.10 - Enhance ace-git context with PR activity awareness
- Workflow: `ace-taskflow/handbook/workflow-instructions/plan-task.wf.md`
- The workflow's purpose is clear in its content, but the name created confusion with Claude's system feature