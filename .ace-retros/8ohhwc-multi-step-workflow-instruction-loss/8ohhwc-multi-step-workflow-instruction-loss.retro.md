---
id: 8ohhwc
title: Multi-Step Workflow Instruction Loss
type: conversation-analysis
tags: []
created_at: "2026-01-18 11:55:55"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8ohhwc-multi-step-workflow-instruction-loss.md
---
# Reflection: Multi-Step Workflow Instruction Loss

**Date**: 2026-01-18
**Context**: Agent failed to track and execute a numbered multi-step workflow assignment, completing only the first step
**Author**: Claude (self-reflection prompted by user)
**Type**: Conversation Analysis

## What Went Well

- The implementation work itself (task 215.03) was completed successfully
- Code quality was good - all 116 tests passed
- Individual skill invocations (/ace:commit, /ace-release) worked correctly when prompted

## What Could Be Improved

- Agent did not use TodoWrite to track the full 8-step assignment at the start
- Agent treated the detailed implementation plan as the "primary instruction" instead of recognizing it as step 1 of 8
- No checkpoint or return mechanism to the higher-order workflow after completing step 1
- User had to manually invoke /ace-release rather than agent continuing the workflow

## Key Learnings

- **Competing instruction signals**: When a message contains both a numbered workflow (15 lines) and a detailed implementation plan (100+ lines), the agent weighted the detailed plan higher
- **Persistence requires externalization**: Multi-step workflows must be externalized (todo list, plan file) BEFORE starting work, or they get lost during complex implementation
- **Context compaction risk**: As conversations grow, earlier instructions get summarized - workflow steps in the opening message are vulnerable to being "forgotten"

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Workflow Instruction Loss**: Agent completed step 1 of 8, then stopped
  - Occurrences: 1 (but this pattern is likely systemic)
  - Impact: User had to manually track and prompt remaining steps; potential for incomplete workflows
  - Root Cause: No persistent anchor for the multi-step assignment; detailed implementation plan overshadowed the workflow structure

#### Medium Impact Issues

- **Todo Tool Not Used Proactively**: User explicitly requested "use todo tool to track progress" but agent used it only for implementation details, not the session assignment
  - Occurrences: 1
  - Impact: Lost visibility into the full workflow; agent couldn't self-correct
  - Root Cause: Agent interpreted "track progress" as tracking implementation tasks, not the meta-level assignment

### Improvement Proposals

#### Process Improvements

- **Workflow Anchoring Protocol**: When user provides numbered multi-step instructions, IMMEDIATELY create a todo list or plan file BEFORE reading any detailed content
- **Session Assignment Recognition**: Recognize patterns like numbered lists with skill invocations as "session assignments" requiring persistent tracking
- **Checkpoint Discipline**: After completing any step, explicitly check: "What step am I on? What's next?"

#### Tool Enhancements

- **Session Assignment Skill**: Create a `/ace:session-assignment` skill that:
  - Parses multi-step instructions
  - Creates persistent todo list
  - Prompts agent to return to list after each step completion

#### Communication Protocols

- **Acknowledge Full Scope First**: Before diving into step 1, agent should acknowledge: "I see an 8-step workflow. Let me create a todo list to track all steps."
- **Explicit Completion Signals**: After each step, agent should state: "Step N complete. Moving to step N+1: [description]"

## Action Items

### Stop Doing

- Treating detailed implementation plans as the "whole assignment" when they're nested within a larger workflow
- Starting implementation before externalizing the full task list

### Continue Doing

- Using TodoWrite for tracking implementation subtasks (this worked well for the 13 implementation phases)
- Executing skills correctly when invoked

### Start Doing

- **Parse session instructions first**: Before any implementation, scan for numbered lists, skill invocations, and workflow markers
- **Create meta-todo immediately**: First action for multi-step workflows should be TodoWrite with ALL steps
- **Use plan files for session assignments**: Write the full workflow to a plan file that persists across context compaction

## Recommended Instruction Format

For users wanting to ensure multi-step workflows are respected:

```markdown
## SESSION ASSIGNMENT - CREATE TODO LIST FIRST

Before starting ANY work, use TodoWrite to create tasks for each step below.
Only proceed to step 1 after the todo list is created.

### Steps:
1. /ace:work-on-task 215.03
   - commit all changes
   - release modified packages
   - mark task done, push to remote
2. /ace:create-pr
3. /ace:review-pr
...

---

### Step 1 Details:
[detailed implementation plan here]
```

## Additional Context

- Task: 215.03 Multi-Validator Architecture for ace-lint
- Session started with clear 8-step workflow but only step 1 was autonomously executed
- User intervention required at step 1c (release) and to identify the issue
