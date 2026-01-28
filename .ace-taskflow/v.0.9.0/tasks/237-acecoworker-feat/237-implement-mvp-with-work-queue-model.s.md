---
id: v.0.9.0+task.237
status: draft
priority: high
estimate: 6h
dependencies: []
parent: v.0.9.0+task.234
---

# ace-coworker MVP with Work Queue Model

## Behavioral Specification

### User Experience

- **Input**: YAML configuration file (job.yaml) defining session name and steps with instructions
- **Process**:
  - User starts session with `ace-coworker start --config job.yaml`
  - System creates session, displays first step instructions
  - User (or agent) completes work, reports with `ace-coworker report <file>`
  - System advances queue, shows next step
  - User can add work dynamically with `ace-coworker add`
  - Failed steps preserved in queue as history; retry creates NEW queue item
- **Output**: Complete work queue showing all items (done, in_progress, in_queue, failed) with history preserved

### Expected Behavior

The ace-coworker gem manages workflow sessions using a **work queue model** where:

1. **Queue as History**: The queue represents both pending work AND execution history. Failed steps are NOT overwritten - they remain visible showing what happened.

2. **Dynamic Work**: Steps can be added to a running session at any time. This enables agents to insert fix steps, verification steps, or additional work as needed.

3. **Retry as New Item**: When retrying a failed step, a NEW queue item is created. The original failed item remains in the queue, showing:
   - Original step #4: failed (error message preserved)
   - Retry step #6: in_progress or done (linked to original)

4. **Status States**: Queue items have four states:
   - `done` - Completed successfully
   - `in_progress` - Currently being worked on (only one at a time)
   - `in_queue` - Waiting to be executed
   - `failed` - Failed and preserved as history

### Interface Contract

```bash
# Start a new session from YAML config
ace-coworker start --config job.yaml
# Output:
# Session: foobar-gem-session (8or5kx)
# Step 1/5: init-project [in_progress]
#
# Instructions:
# Create a minimal Ruby project structure...

# Check current queue status
ace-coworker status
# Output:
# QUEUE - Session: foobar-gem-session
# #  STATUS       NAME
# 1  done         init-project
# 2  done         write-tests
# 3  in_progress  implement-foobar
# 4  in_queue     run-tests
# 5  in_queue     report-status

# Complete current step with a report file
ace-coworker report impl-report.md
# Output:
# Step 3/5 (implement-foobar) completed
# Advancing to step 4/5: run-tests
# Instructions: ...

# Mark current step as failed
ace-coworker fail --message "2 tests failed: test_greet, test_shout"
# Output:
# Step 4 (run-tests) marked as failed
# Error: 2 tests failed: test_greet, test_shout

# Add new step dynamically
ace-coworker add "fix-implementation" --instructions "Fix the FooBar bug"
# Output:
# Added step: fix-implementation (in_progress)

# Retry a failed step (creates NEW queue item)
ace-coworker retry 4
# Output:
# Added retry of step 4 (run-tests) as step 6
# Step 5 (fix-implementation) must complete first
```

**Error Handling:**
- No active session: "Error: No active session. Use 'ace-coworker start' to begin."
- Missing config file: "Error: Config file not found: job.yaml"
- Missing report file: "Error: Report file not found: report.md"
- Invalid step reference: "Error: Step 99 not found in queue"

**Edge Cases:**
- Starting session when one exists: Warn and offer to resume or create new
- Adding step when none in_progress: Insert after last done step
- Retry of already-completed step: Create new step anyway (re-verification)

### Success Criteria

- [ ] `ace-coworker start --config job.yaml` creates session and shows first step
- [ ] `ace-coworker status` displays full queue with all states (done/in_progress/in_queue/failed)
- [ ] `ace-coworker report <file>` completes current step and advances queue
- [ ] `ace-coworker fail --message "..."` marks step as failed (preserved in queue)
- [ ] `ace-coworker add "step-name"` inserts new step dynamically
- [ ] `ace-coworker retry <step-id>` creates new queue item, preserves original failed
- [ ] Queue history shows complete execution path including all failures and retries
- [ ] Session state persists in job.json (can resume after interruption)

### Validation Questions

- [x] **Queue Position**: Where should dynamically added steps be inserted? → After current in_progress step
- [x] **Retry Semantics**: Should retry overwrite or preserve? → PRESERVE (create new item)
- [x] **Status Display**: Show all items or filter by state? → Show ALL (queue is history)
- [ ] **Concurrent Sessions**: Allow multiple sessions per directory? → Defer to later task

## Objective

Create a simplified ace-coworker gem that manages workflow sessions using a work queue model. This replaces the complex 234.01-234.08 subtask breakdown with a focused MVP that:
- Tracks work as a queue (history + pending)
- Preserves failed steps (no overwriting)
- Allows dynamic work addition
- Shows complete execution history

## Scope of Work

- **User Experience Scope**: CLI commands for session lifecycle (start, status, report, fail, add, retry)
- **System Behavior Scope**: Work queue management with history preservation
- **Interface Scope**: YAML input (job.yaml), JSON state (job.json), CLI commands

### Deliverables

#### Behavioral Specifications
- Complete CLI command interface with expected inputs/outputs
- Work queue state model with status transitions
- Session persistence format (job.json schema)
- E2E test scenario validating queue behavior

#### Validation Artifacts
- E2E test case: MT-COWORKER-001 (Work Queue Session Lifecycle)
- Real-world example: FooBar gem creation workflow
- Success criteria checklist

## Out of Scope

- ❌ **Implementation Details**: File structures, code organization, ATOM architecture decisions
- ❌ **Complex Features**: Subagent spawning, human gates, frontmatter schema (defer to later tasks)
- ❌ **Multi-Session**: Concurrent sessions in same directory (future enhancement)
- ❌ **Verifications**: Automatic verification command execution (separate task)

## References

- Plan file: `/Users/mc/.claude/plans/expressive-napping-allen.md`
- Related task: v.0.9.0+task.234 (parent orchestrator)
- Existing specs (reference only): 234.01-234.08 subtasks
