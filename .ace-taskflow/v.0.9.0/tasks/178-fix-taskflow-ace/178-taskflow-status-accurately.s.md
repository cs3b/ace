---
id: v.0.9.0+task.178
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Fix ace-taskflow status to accurately report recently completed tasks

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-taskflow status` from terminal
- **Process**: System loads current release tasks, identifies completed tasks, sorts by completion time, displays most recent
- **Output**: "Recently Done" section shows the N most recently completed tasks with relative timestamps ("done Xm ago")

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

1. When a task is marked as done (moved to completion), its completion time should be accurately tracked
2. The status command should correctly identify which done tasks are most recent based on completion time
3. Recently completed tasks should appear at the top of the "Recently Done" list
4. Both orchestrator tasks and their subtasks should be properly tracked and displayed
5. Display should show human-readable relative time (e.g., "done 2m ago", "done 4h ago", "done 1d ago")

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# CLI Command
ace-taskflow status

# CURRENT (BUGGY) Output:
## Task Activity

### Recently Done
- 177: Fix ace-taskflow doctor to respect configured archive folder (done 1d ago)
- 176: Standardize gemspec configurations across all ace-* packages (done 1d ago)
- 175: Optimize ace-test-runner test performance (8s to under 5s) (done 2d ago)

### In Progress
- 002: Create Root Gemfile for Workspace

### Up Next
- 149: Base36 Compact ID Format Implementation


# EXPECTED (FIXED) Output:
## Task Activity

### Recently Done
- 150: CLI Standardization - Thor migration and ConfigSummary across all 13+ ACE gems (done 4h ago)
- 150.37: Update ace-review CHANGELOG (done 4h ago)
- 150.36: Update ace-prompt CHANGELOG (done 4h ago)
- 177: Fix ace-taskflow doctor to respect configured archive folder (done 1d ago)
- 176: Standardize gemspec configurations across all ace-* packages (done 1d ago)

### In Progress
- 002: Create Root Gemfile for Workspace

### Up Next
- 149: Base36 Compact ID Format Implementation
```

**Error Handling:**
- No recently completed tasks: Show message "No recently completed tasks" or skip section
- Task files missing/inaccessible: Gracefully skip with optional warning in verbose mode
- Invalid completion timestamps: Skip task and log warning

**Edge Cases:**
- Tasks completed within minutes: Should appear immediately in "Recently Done"
- Bulk task completion (multiple tasks at once): All should appear with correct timestamps
- Orchestrator vs subtask display: Both should be tracked, show most recent first regardless of hierarchy
- Git operations affecting file mtimes: System should use reliable completion time tracking

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Accurate recent detection**: Tasks completed within minutes/hours appear in "Recently Done" section
- [ ] **Correct ordering**: Most recently completed tasks appear at the top of the list
- [ ] **Relative timestamps**: Time shown in human-readable format ("Xm ago", "Xh ago", "Xd ago")
- [ ] **Subtask visibility**: Subtasks completed recently (e.g., 150.37) appear alongside parent tasks
- [ ] **Performance**: Status command remains fast (<1s for typical projects)
- [ ] **Deterministic output**: Same invocation produces consistent, parseable results

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [ ] **Root cause - File locations**: Are task 150 and its subtasks (150.01-150.37) actually in `.ace-taskflow/v.0.9.0/t/done/`? What are their actual file mtimes compared to task 177 files?
- [ ] **Task completion workflow**: How are tasks currently marked as done after PR merge? What's the exact mechanism that moves them to `t/done/`?
- [ ] **File mtime investigation**: Do task 150 files have older mtimes than expected? Is there a pattern in the mtime data?
- [ ] **Git operations impact**: Do git worktree operations, merges, PR workflows, or file moves affect file mtimes in unexpected ways?
- [ ] **Subtask handling**: Should orchestrator tasks (150) show separately from subtasks (150.01-150.37), or should only the most recent from the group appear?
- [ ] **Time tracking approach**: Should we rely on file mtime, or should we add explicit `completed_at` timestamp to task frontmatter?

## Objective

Ensure that the `ace-taskflow status` command accurately reports recently completed tasks, providing developers and AI agents with real-time visibility into progress. Currently, tasks completed today (e.g., task 150 merged 4 hours ago) do not appear in the "Recently Done" section, while tasks from 1-2 days ago are shown. This creates confusion and hampers the ability to track rapid development progress.

## Scope of Work

### User Experience Scope
- **Status command output**: The "Recently Done" section of `ace-taskflow status`
- **Time granularity**: Accurate detection from minutes to days
- **Task hierarchy**: Both orchestrator tasks and subtasks
- **Display format**: Human-readable relative timestamps

### System Behavior Scope
- **Completion time tracking**: How task completion time is determined and stored
- **Task filtering and sorting**: How "recently done" tasks are identified and ordered
- **Performance**: Must remain fast for typical project sizes

### Interface Scope
- **CLI command**: `ace-taskflow status` (no API or UI changes)
- **Configuration**: Existing `status.activity.recently_done_limit` config
- **Output format**: Markdown (current format, just with correct data)

### Deliverables

#### Behavioral Specifications
- User experience flow for status command execution
- System behavior specification for completion time tracking
- Interface contract for status output format

#### Validation Artifacts
- Success criteria validation methods
- Reproduction steps for current bug
- Test scenarios for fixed behavior

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- **Implementation Details**: Specific file structures, code organization, function names (for replan phase)
- **Technology Decisions**: Whether to use file mtime vs frontmatter timestamp (for replan phase)
- **Performance Optimization**: Beyond ensuring the fix doesn't degrade performance
- **Feature Changes**: No change from count-based (top N) to time-based filtering
- **Scope Expansion**: Not including archived releases, not changing output format significantly

## References

### Source Idea
- `.ace-taskflow/v.0.9.0/ideas/done/20251229-231901-ace-taskflow-fix/accurately-report-recently-completed-tasks.s.md`

### Related Code
- `ace-taskflow/lib/ace/taskflow/molecules/task_activity_analyzer.rb` - Completion detection and task categorization
- `ace-taskflow/lib/ace/taskflow/molecules/task_loader.rb` - Task loading and metadata extraction
- `ace-taskflow/lib/ace/taskflow/molecules/task_display_formatter.rb` - Output formatting

### Configuration
- `ace-taskflow/.ace-defaults/taskflow/config.yml` - `status.activity.recently_done_limit: 3`

### Example Bug Scenario
**Current Behavior (Buggy)**:
```
ace-taskflow status
## Recently Done
- 177: Fix ace-taskflow doctor (done 1d ago)
- 176: Standardize gemspec configs (done 1d ago)
- 175: Optimize ace-test-runner (done 2d ago)
```
Task 150 (merged 4h ago via PR #123) is missing entirely.

**Expected Behavior (Fixed)**:
```
ace-taskflow status
## Recently Done
- 150: CLI Standardization (done 4h ago)
- 150.37: Update ace-review CHANGELOG (done 4h ago)
- 177: Fix ace-taskflow doctor (done 1d ago)
```
Most recent tasks appear first with accurate timestamps.
