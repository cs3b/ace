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
   - `pending` - Waiting to be executed
   - `failed` - Failed and preserved as history

5. **File-Based Storage**: Each step is a separate markdown file with frontmatter. This provides:
   - Corruption isolation (one file fails, others survive)
   - Git-friendly diffs and merges
   - Natural subtask injection via hierarchical numbering
   - Human-readable history aligned with ACE patterns

### Interface Contract

```bash
# Start a new session from YAML config
ace-coworker start --config job.yaml
# Output:
# Session: foobar-gem-session (8or5kx)
# Created: .cache/ace-coworker/8or5kx/
# Step 010: init-project [in_progress]
#
# Instructions:
# Create a minimal Ruby project structure...

# Check current queue status
ace-coworker status
# Output:
# QUEUE - Session: foobar-gem-session (8or5kx)
# FILE                           STATUS       NAME
# 010-init-project.md            done         init-project
# 020-write-tests.md             done         write-tests
# 030-implement-foobar.md        in_progress  implement-foobar
# 040-run-tests.md               pending      run-tests
# 050-report-status.md           pending      report-status

# Complete current step with a report file
ace-coworker report impl-report.md
# Output:
# Step 030 (implement-foobar) completed
# Report appended to: jobs/030-implement-foobar.md
# Advancing to step 040: run-tests
# Instructions: ...

# Mark current step as failed
ace-coworker fail --message "2 tests failed: test_greet, test_shout"
# Output:
# Step 040 (run-tests) marked as failed
# Updated: jobs/040-run-tests.md
# Error: 2 tests failed: test_greet, test_shout

# Add new step dynamically
ace-coworker add "fix-implementation" --instructions "Fix the FooBar bug"
# Output:
# Created: jobs/041-fix-implementation.md
# Status: in_progress

# Retry a failed step (creates NEW queue item)
ace-coworker retry 040
# Output:
# Created: jobs/042-run-tests.md (retry of 040)
# Step 041 (fix-implementation) must complete first
```

**Error Handling:**
- No active session: "Error: No active session. Use 'ace-coworker start' to begin."
- Missing config file: "Error: Config file not found: job.yaml"
- Missing report file: "Error: Report file not found: report.md"
- Invalid step reference: "Error: Step 99 not found in queue"

**Edge Cases:**
- Starting session when one exists: Warn and offer to resume or create new
- Adding step: If `in_progress` exists → insert after it; else → insert after last `done` step
- Retry of already-completed step: Create new step anyway (re-verification)

### Success Criteria

- [ ] `ace-coworker start --config job.yaml` creates session folder with `session.yaml` and `jobs/` subfolder
- [ ] `ace-coworker status` displays full queue from `jobs/*.md` files (done/in_progress/pending/failed)
- [ ] `ace-coworker report <file>` appends report to current step's `.md` file and advances queue
- [ ] `ace-coworker fail --message "..."` updates frontmatter status=failed, preserves file
- [ ] `ace-coworker add "step-name"` creates new `.md` file with next available number
- [ ] `ace-coworker retry <step-id>` creates new `.md` file with `added_by: retry_of:NNN`
- [ ] Queue history shows complete execution path (all files remain, including failed)
- [ ] Session state persists as files (can resume after interruption)

### Validation Questions

- [x] **Queue Position**: Where should dynamically added steps be inserted? → After current `in_progress` step (or after last `done` if none in progress)
- [x] **Retry Semantics**: Should retry overwrite or preserve? → PRESERVE (create new item)
- [x] **Status Display**: Show all items or filter by state? → Show ALL (queue is history)
- [x] **Concurrent Sessions**: Allow multiple sessions per directory? → Deferred to later task (out of scope for MVP)
- [x] **Storage Model**: Single JSON or file-based? → FILE-BASED (hierarchical markdown files)

### File-Based Storage Model

```
.cache/ace-coworker/<session-id>/
├── session.yaml                   # Session metadata
└── jobs/                          # Work queue files (lexicographic order)
    ├── 010-init-project.md        # Main task
    ├── 010.01-setup-dirs.md       # Subtask of 010 (optional)
    ├── 010.01.01-create-lib.md    # Sub-subtask (3 levels max)
    ├── 020-write-tests.md
    ├── 030-implement-foobar.md
    ├── 040-run-tests.md           # [failed]
    ├── 041-fix-implementation.md  # Injected after failure
    ├── 042-run-tests.md           # Retry of 040
    └── 050-report-status.md
```

**Numbering Rules:**
- Main tasks: `010`, `020`, `030` (10-step gaps for injection room)
- Subtasks: `.01`, `.02` (2-digit padding)
- Sub-subtasks: `.01.01`, `.01.02` (3 levels max)
- Dynamic injection: next available number (`041` after `040`)

**Queue Reconstruction:** Scan `jobs/*.md`, sort lexicographically, parse frontmatter for status.

## Objective

Create a simplified ace-coworker gem that manages workflow sessions using a work queue model. This replaces the complex 234.01-234.08 subtask breakdown with a focused MVP that:
- Tracks work as a queue (history + pending)
- Preserves failed steps (no overwriting)
- Allows dynamic work addition
- Shows complete execution history

## Scope of Work

- **User Experience Scope**: CLI commands for session lifecycle (start, status, report, fail, add, retry)
- **System Behavior Scope**: Work queue management with history preservation
- **Interface Scope**: YAML input (job.yaml), file-based state (session.yaml + jobs/*.md), CLI commands

### Deliverables

#### Behavioral Specifications
- Complete CLI command interface with expected inputs/outputs
- Work queue state model with status transitions
- Session persistence format (session.yaml + jobs/*.md schemas)
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

- Plan file: (session-local, not persisted)
- Related task: v.0.9.0+task.234 (parent orchestrator)
- Existing specs (reference only): 234.01-234.08 subtasks
