---
id: v.0.9.0+task.046
status: in-progress
priority: high
estimate: 4h
dependencies: []
---

# Migrate batch operations to ace-taskflow

## Behavioral Specification

### User Experience
- **Input**: Slash commands for batch task operations (draft-tasks, plan-tasks, work-on-tasks, review-tasks)
- **Process**: Users execute batch commands that process multiple tasks in sequence
- **Output**: Multiple tasks created/planned/executed/reviewed with comprehensive summaries

### Expected Behavior

Users should be able to execute batch operations on tasks through intuitive slash commands. Each command processes multiple tasks following the same pattern as its singular counterpart but with aggregated reporting.

**Commands to migrate:**
- `draft-tasks.md` - Create multiple draft tasks from idea files or descriptions
- `plan-tasks.md` - Plan implementation for multiple draft tasks
- `work-on-tasks.md` - Execute work on multiple planned tasks
- `review-tasks.md` - Review and aggregate findings from multiple completed tasks

### Interface Contract

```bash
# Batch task drafting
/ace:draft-tasks [idea-pattern or task-descriptions]
# Output: List of created task IDs with titles and status

# Batch task planning
/ace:plan-tasks [task-id-list or pattern]
# Output: Planning summary for each task with status transitions

# Batch task execution
/ace:work-on-tasks [task-id-list or pattern]
# Output: Work progress and completion status for each task

# Batch task review
/ace:review-tasks [task-id-list or pattern]
# Output: Aggregated review findings and recommendations
```

**Error Handling:**
- Missing task IDs: Prompt user to specify tasks or patterns
- Invalid task status: Skip task with warning, continue with others
- Partial failures: Report which tasks succeeded/failed with reasons

### Success Criteria

- [ ] **Batch Commands Available**: All 4 batch commands accessible via /ace: prefix
- [ ] **Sequential Processing**: Each command processes tasks one at a time with clear progress
- [ ] **Comprehensive Reporting**: Final summary includes all processed tasks with status and outcomes
- [ ] **Error Resilience**: Failures in one task don't block processing of remaining tasks
- [ ] **wfi:// Protocol Support**: Commands use ace-nav wfi:// protocol for workflow discovery

### Validation Questions

- [ ] **Pattern Matching**: How should task-id patterns be specified (glob, regex, range)?
- [ ] **Progress Feedback**: Should users see real-time progress or only final summary?
- [ ] **Failure Handling**: Should batch stop on first failure or always process all tasks?

## Objective

Enable efficient batch processing of tasks to reduce repetitive command execution and improve workflow velocity when managing multiple related tasks.

## Scope of Work

### Commands to Migrate
1. `.claude/commands/draft-tasks.md` → `ace-taskflow/handbook/workflow-instructions/draft-tasks.wf.md`
2. `.claude/commands/plan-tasks.md` → `ace-taskflow/handbook/workflow-instructions/plan-tasks.wf.md`
3. `.claude/commands/work-on-tasks.md` → `ace-taskflow/handbook/workflow-instructions/work-on-tasks.wf.md`
4. `.claude/commands/review-tasks.md` → `ace-taskflow/handbook/workflow-instructions/review-tasks.wf.md`

### Migration Steps
1. Move workflow files from dev-handbook to ace-taskflow/handbook/workflow-instructions/
2. Create command files in .claude/commands/ace/ using wfi:// protocol pattern
3. Add `source: ace-taskflow` metadata to command frontmatter
4. Test each command with ace-nav wfi:// resolution
5. Update documentation and CLAUDE.md references

## Out of Scope

- ❌ Parallel task processing (sequential only for v1)
- ❌ Interactive task selection UI
- ❌ Advanced pattern matching beyond simple globs
- ❌ Real-time progress bars (text summaries only)

## References

- Singular command patterns: capture-idea, draft-task, plan-task, work-on-task, review-task
- ace-nav wfi:// protocol documentation
- ace-taskflow command structure examples

## Technical Approach

### Architecture Pattern

This migration follows the established ace-taskflow command migration pattern:
- **Workflow files** stored in `ace-taskflow/handbook/workflow-instructions/` with `.wf.md` extension
- **Command files** in `.claude/commands/ace/` use `ace-nav wfi://` protocol for workflow discovery
- **Source metadata** includes `source: ace-taskflow` to indicate ownership
- **Delegation pattern** uses Task tool with general-purpose agent for sequential processing

### Key Design Decisions

**1. Sequential vs Parallel Processing**
- **Decision**: Sequential processing only (no parallelization)
- **Rationale**: Simpler error handling, clearer progress tracking, easier debugging
- **Trade-off**: Slower for large batches, but acceptable for typical use cases

**2. Workflow Delegation Strategy**
- **Decision**: Use Task tool with general-purpose agent to execute singular workflows
- **Rationale**: Reuses existing singular workflows, maintains consistency
- **Pattern**: Batch command → Task tool → Singular workflow execution

**3. Error Handling Approach**
- **Decision**: Continue processing on failure, aggregate errors in final report
- **Rationale**: Partial success better than complete failure
- **Implementation**: Try-catch per task, collect failures, report at end

**4. Progress Reporting**
- **Decision**: Text-based incremental progress (not real-time progress bars)
- **Rationale**: Compatible with Claude Code interface, simpler implementation
- **Format**: "Processing task N of M: [task-id] [title]..."

### File Modifications

#### Create

**New workflow files in ace-taskflow/handbook/workflow-instructions/:**

1. `draft-tasks.wf.md`
   - Purpose: Batch workflow for creating multiple draft tasks from ideas
   - Key components: Idea discovery via `ace-taskflow ideas --backlog`, sequential Task tool invocation, `ace-taskflow idea done` for cleanup
   - Dependencies: `draft-task.wf.md`, `ace-taskflow ideas`, `ace-taskflow idea done`

2. `plan-tasks.wf.md`
   - Purpose: Batch workflow for planning multiple draft tasks
   - Key components: Draft task discovery, sequential planning execution, status transition tracking
   - Dependencies: `plan-task.wf.md`, `ace-taskflow tasks --status draft`

3. `work-on-tasks.wf.md`
   - Purpose: Batch workflow for executing work on multiple tasks
   - Key components: Pending task discovery, sequential work execution, git tagging
   - Dependencies: `work-on-task.wf.md`, `ace-taskflow tasks --status pending`

4. `review-tasks.wf.md`
   - Purpose: Batch workflow for reviewing multiple tasks
   - Key components: Task discovery, sequential review execution, question aggregation
   - Dependencies: `review-task.wf.md`, `ace-taskflow tasks` with various filters

**New command files in .claude/commands/ace/:**

1. `draft-tasks.md`
   - Command: `/ace:draft-tasks [idea-pattern]`
   - Invokes: `ace-nav wfi://draft-tasks`
   - Metadata: `source: ace-taskflow`

2. `plan-tasks.md`
   - Command: `/ace:plan-tasks [task-id-pattern]`
   - Invokes: `ace-nav wfi://plan-tasks`
   - Metadata: `source: ace-taskflow`

3. `work-on-tasks.md`
   - Command: `/ace:work-on-tasks [task-id-pattern]`
   - Invokes: `ace-nav wfi://work-on-tasks`
   - Metadata: `source: ace-taskflow`

4. `review-tasks.md`
   - Command: `/ace:review-tasks [task-id-pattern]`
   - Invokes: `ace-nav wfi://review-tasks`
   - Metadata: `source: ace-taskflow`

#### Delete

**Legacy command files (after migration and testing):**

1. `.claude/commands/draft-tasks.md`
   - Reason: Replaced by `/ace:draft-tasks` command
   - Migration: Content transformed into workflow file
   - Dependencies: None (standalone command)

2. `.claude/commands/plan-tasks.md`
   - Reason: Replaced by `/ace:plan-tasks` command
   - Migration: Content transformed into workflow file
   - Dependencies: None (standalone command)

3. `.claude/commands/work-on-tasks.md`
   - Reason: Replaced by `/ace:work-on-tasks` command
   - Migration: Content transformed into workflow file
   - Dependencies: None (standalone command)

4. `.claude/commands/review-tasks.md`
   - Reason: Replaced by `/ace:review-tasks` command
   - Migration: Content transformed into workflow file
   - Dependencies: None (standalone command)

### Implementation Strategy

**Phase 1: Create Workflow Files**
- Extract core logic from legacy commands
- Transform into self-contained workflow instructions
- Add proper metadata and structure
- Embed any required templates

**Phase 2: Create Command Wrappers**
- Create minimal command files using wfi:// protocol
- Test ace-nav resolution for each workflow
- Verify metadata is correct

**Phase 3: Validation and Testing**
- Test each batch command end-to-end
- Verify error handling works correctly
- Confirm workflow discovery via ace-nav
- Check that singular workflows are invoked correctly

**Phase 4: Legacy Cleanup**
- Remove old command files
- Update any documentation references
- Verify no dependencies on old commands

## Risk Assessment

### Technical Risks

**Risk 1: Workflow Resolution Failure**
- **Probability**: Low
- **Impact**: High (commands won't work)
- **Mitigation**: Test ace-nav resolution before deployment, verify wfi:// paths
- **Rollback**: Keep legacy commands until new ones are validated

**Risk 2: Task Tool Delegation Issues**
- **Probability**: Medium
- **Impact**: Medium (batch processing fails)
- **Mitigation**: Test Task tool invocation patterns, validate general-purpose agent availability
- **Rollback**: Fall back to inline execution if delegation fails

**Risk 3: Error Handling Edge Cases**
- **Probability**: Medium
- **Impact**: Low (some tasks may be skipped)
- **Mitigation**: Comprehensive error logging, clear failure reporting
- **Monitoring**: Review batch command logs for unexpected failures

### Integration Risks

**Risk 1: ace-taskflow Command Changes**
- **Probability**: Low
- **Impact**: Medium (task discovery may fail)
- **Mitigation**: Use stable ace-taskflow CLI patterns, document command dependencies
- **Monitoring**: Test with actual ace-taskflow output

**Risk 2: Singular Workflow Changes**
- **Probability**: Medium
- **Impact**: High (batch commands may break)
- **Mitigation**: Use wfi:// protocol for dynamic resolution, version check workflows
- **Monitoring**: Validate singular workflows exist and are compatible

## Implementation Plan

### Planning Steps

* [ ] Review existing batch command logic and identify core patterns
* [ ] Analyze singular workflow structure to ensure compatibility
* [ ] Design workflow file structure and metadata schema
* [ ] Plan error aggregation and reporting format
* [ ] Design test strategy for each batch command

### Execution Steps

#### Step 1: Create draft-tasks Workflow

- [ ] Create `ace-taskflow/handbook/workflow-instructions/draft-tasks.wf.md`
  - Extract logic from `.claude/commands/draft-tasks.md`
  - Add self-contained workflow instructions
  - Use `ace-taskflow ideas --backlog` for idea discovery
  - Add Task tool delegation pattern for each idea
  - Use `ace-taskflow idea done <reference>` instead of `git mv` for idea cleanup
  - Include aggregated reporting structure
  - Add error handling per idea file
  > TEST: Workflow Content Validation
  > Type: Pre-condition Check
  > Assert: Workflow file contains all required sections (Goal, Prerequisites, Process Steps, Output)
  > Command: grep -q "## Goal" ace-taskflow/handbook/workflow-instructions/draft-tasks.wf.md && grep -q "## Process Steps" ace-taskflow/handbook/workflow-instructions/draft-tasks.wf.md

- [ ] Create `.claude/commands/ace/draft-tasks.md`
  - Use wfi:// protocol pattern
  - Add `source: ace-taskflow` metadata
  - Include argument hints
  - Set allowed-tools appropriately
  > TEST: Command Resolution
  > Type: Action Validation
  > Assert: ace-nav can resolve the workflow
  > Command: ace-nav wfi://draft-tasks --verbose | grep -q "draft-tasks.wf.md"

#### Step 2: Create plan-tasks Workflow

- [ ] Create `ace-taskflow/handbook/workflow-instructions/plan-tasks.wf.md`
  - Extract logic from `.claude/commands/plan-tasks.md`
  - Add self-contained workflow instructions
  - Include draft task discovery using `ace-taskflow tasks --status draft`
  - Add Task tool delegation for each draft task
  - Include status transition tracking (draft → pending)
  - Add aggregated reporting structure
  > TEST: Workflow Structure
  > Type: Pre-condition Check
  > Assert: Workflow includes task discovery and delegation patterns
  > Command: grep -q "ace-taskflow tasks" ace-taskflow/handbook/workflow-instructions/plan-tasks.wf.md

- [ ] Create `.claude/commands/ace/plan-tasks.md`
  - Use wfi:// protocol pattern
  - Add `source: ace-taskflow` metadata
  > TEST: Command Resolution
  > Type: Action Validation
  > Assert: ace-nav can resolve the workflow
  > Command: ace-nav wfi://plan-tasks | grep -q "plan-tasks.wf.md"

#### Step 3: Create work-on-tasks Workflow

- [ ] Create `ace-taskflow/handbook/workflow-instructions/work-on-tasks.wf.md`
  - Extract logic from `.claude/commands/work-on-tasks.md`
  - Add self-contained workflow instructions
  - Include pending task discovery using `ace-taskflow tasks --status pending`
  - Add Task tool delegation for each pending task
  - Include git tagging logic per task
  - Add work progress tracking
  > TEST: Workflow Git Operations
  > Type: Pre-condition Check
  > Assert: Workflow includes git tagging instructions
  > Command: grep -q "git.*tag" ace-taskflow/handbook/workflow-instructions/work-on-tasks.wf.md

- [ ] Create `.claude/commands/ace/work-on-tasks.md`
  - Use wfi:// protocol pattern
  - Add `source: ace-taskflow` metadata
  > TEST: Command Resolution
  > Type: Action Validation
  > Assert: ace-nav can resolve the workflow
  > Command: ace-nav wfi://work-on-tasks | grep -q "work-on-tasks.wf.md"

#### Step 4: Create review-tasks Workflow

- [ ] Create `ace-taskflow/handbook/workflow-instructions/review-tasks.wf.md`
  - Extract logic from `.claude/commands/review-tasks.md`
  - Add self-contained workflow instructions
  - Include flexible task discovery (multiple filter options)
  - Add Task tool delegation for each task
  - Include question aggregation by priority
  - Add needs_review flag tracking
  > TEST: Workflow Flexibility
  > Type: Pre-condition Check
  > Assert: Workflow supports multiple task selection patterns
  > Command: grep -q "filter" ace-taskflow/handbook/workflow-instructions/review-tasks.wf.md

- [ ] Create `.claude/commands/ace/review-tasks.md`
  - Use wfi:// protocol pattern
  - Add `source: ace-taskflow` metadata
  > TEST: Command Resolution
  > Type: Action Validation
  > Assert: ace-nav can resolve the workflow
  > Command: ace-nav wfi://review-tasks | grep -q "review-tasks.wf.md"

#### Step 5: Integration Testing

- [ ] Test `/ace:draft-tasks` end-to-end
  - Create test idea file
  - Run command
  - Verify draft task created
  - Verify idea file moved
  - Check error handling
  > TEST: End-to-End Draft Tasks
  > Type: Integration Test
  > Assert: Command successfully processes idea file and creates draft task
  > Command: # Manual test - create test idea, run /ace:draft-tasks, verify task created

- [ ] Test `/ace:plan-tasks` end-to-end
  - Use draft task from previous test
  - Run command
  - Verify status changed to pending
  - Check implementation plan added
  > TEST: End-to-End Plan Tasks
  > Type: Integration Test
  > Assert: Command successfully plans draft task and updates status
  > Command: # Manual test - use draft task, run /ace:plan-tasks, verify status:pending

- [ ] Test `/ace:work-on-tasks` end-to-end
  - Use pending task from previous test
  - Run command in safe environment
  - Verify work executed
  - Check git tags created
  > TEST: End-to-End Work Tasks
  > Type: Integration Test
  > Assert: Command successfully executes task and creates git tags
  > Command: # Manual test - use pending task, run /ace:work-on-tasks, verify completion

- [ ] Test `/ace:review-tasks` end-to-end
  - Use various task statuses
  - Run command with different filters
  - Verify questions generated
  - Check aggregated report
  > TEST: End-to-End Review Tasks
  > Type: Integration Test
  > Assert: Command successfully reviews tasks and aggregates findings
  > Command: # Manual test - run /ace:review-tasks with filters, verify report

#### Step 6: Error Handling Validation

- [ ] Test error resilience for each command
  - Simulate missing task files
  - Test invalid task IDs
  - Verify partial failure handling
  - Check error reporting format
  > TEST: Error Handling
  > Type: Edge Case Validation
  > Assert: Commands handle errors gracefully and continue processing
  > Command: # Manual test - provide invalid inputs, verify graceful degradation

#### Step 7: Documentation and Cleanup

- [ ] Update CLAUDE.md references
  - Document new /ace: batch commands
  - Remove references to legacy commands
  - Add usage examples

- [ ] Remove legacy command files
  - Delete `.claude/commands/draft-tasks.md`
  - Delete `.claude/commands/plan-tasks.md`
  - Delete `.claude/commands/work-on-tasks.md`
  - Delete `.claude/commands/review-tasks.md`
  > TEST: Legacy Cleanup
  > Type: Action Validation
  > Assert: Legacy command files no longer exist
  > Command: ! test -f .claude/commands/draft-tasks.md && ! test -f .claude/commands/plan-tasks.md

- [ ] Final validation
  - Run `ace-nav 'wfi://*tasks*' --list` to verify all workflows discoverable
  - Test each /ace: command one more time
  - Verify no broken references
  > TEST: Final Integration
  > Type: System Validation
  > Assert: All batch commands discoverable and functional
  > Command: ace-nav 'wfi://*tasks' --list | grep -E "(draft-tasks|plan-tasks|work-on-tasks|review-tasks)"

## Acceptance Criteria

- [ ] **All Batch Commands Functional**: `/ace:draft-tasks`, `/ace:plan-tasks`, `/ace:work-on-tasks`, `/ace:review-tasks` all work correctly
- [ ] **Workflow Discovery**: All workflows resolvable via `ace-nav wfi://` protocol
- [ ] **Sequential Processing**: Commands process tasks one at a time with clear progress updates
- [ ] **Error Resilience**: Failures in individual tasks don't stop batch processing
- [ ] **Comprehensive Reporting**: Final summaries include task counts, statuses, and any errors
- [ ] **Legacy Cleanup**: Old command files removed and no broken references remain
- [ ] **Documentation Updated**: CLAUDE.md reflects new command structure
