---
id: v.0.9.0+task.046
status: draft
priority: high
estimate: TBD
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
