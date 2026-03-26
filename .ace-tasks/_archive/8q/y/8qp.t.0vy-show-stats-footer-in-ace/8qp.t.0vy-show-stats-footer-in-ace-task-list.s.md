---
id: 8qp.t.0vy
status: done
priority: medium
created_at: "2026-03-26 00:35:31"
estimate: TBD
dependencies: []
tags: []
bundle:
  presets: [project]
  files: [ace-task/lib/ace/task/molecules/task_display_formatter.rb, ace-task/test/molecules/task_display_formatter_test.rb, ace-idea/lib/ace/idea/molecules/idea_display_formatter.rb]
  commands: []
needs_review: false
worktree:
  branch: 0vy-show-stats-footer-in-ace-task-list-for-empty-results
  path: ../ace-t.0vy
  created_at: "2026-03-26 00:43:24"
  updated_at: "2026-03-26 00:43:24"
  target_branch: main
---

# Show Stats Footer in ace-task list for Empty Results

## Objective

Improve user experience consistency by ensuring `ace-task list` always provides feedback about the state of the task system, even when no tasks match the current filter. Currently an empty result returns only `"No tasks found."` with no stats — unlike `ace-idea list` which always appends a stats footer. This makes the output feel incomplete and doesn't confirm whether the empty set is from an empty workspace vs. a filter that excluded everything.

## Behavioral Specification

### User Experience

- **Input**: User runs `ace-task list` (with or without filter flags) in a workspace where no tasks match
- **Process**: The system renders the empty message followed by a stats summary, so the user sees the overall task landscape even when the filtered set is empty
- **Output**: `"No tasks found."` followed by a blank line and the stats footer (e.g., `"Tasks: • 0 total"` or `"Tasks: • 0 of 42 — done 30 | archive 12"`)

### Expected Behavior

When `ace-task list` returns zero matching tasks, the output should include:

1. The existing `"No tasks found."` message
2. A blank line separator
3. The stats footer line — identical in format to the one shown for non-empty lists

This matches the established pattern in `ace-idea list`, which already shows a stats footer for empty results. The stats footer provides:
- Status count breakdown (omitting zero-count statuses)
- Total count (`"X total"`) or filtered count (`"X of Y"`) depending on context
- Folder breakdown when applicable (e.g., `"— next 2 | backlog 5 | archive 10"`)

### Interface Contract

```bash
# Empty workspace — no tasks at all
$ ace-task list
No tasks found.

Tasks: • 0 total

# Filtered view — no matches but tasks exist elsewhere
$ ace-task list --folder next
No tasks found.

Tasks: • 0 of 42 — done 30 | archive 12

# Non-empty list — unchanged behavior
$ ace-task list
○ 8qp.t.0vy  Show Stats Footer...  (just now)

Tasks: ○ 1 • 1 total
```

Error Handling:
- No new error conditions — this is additive display behavior on existing empty-list path

Edge Cases:
- Truly empty task workspace (zero tasks globally): shows `"Tasks: • 0 total"`
- Filtered empty result with global tasks: shows `"Tasks: • 0 of N"` with folder breakdown
- `global_folder_stats` provided: folder breakdown always appended

### Success Criteria

- `ace-task list` with no matching tasks displays the stats footer after the empty message
- The footer format is identical to the existing non-empty footer format (same `StatsLineFormatter` output)
- The behavior is consistent with `ace-idea list` empty-result display
- Existing non-empty list output is unchanged

### Validation Questions

No open questions — the idea's 3-Question Brief is complete and the reference implementation (`ace-idea list`) provides a clear behavioral model.

## Vertical Slice Decomposition (Task/Subtask Model)

**Single standalone task** — one behavioral change in one formatter method.

- **Slice**: Empty-list stats footer display
- **Outcome**: `ace-task list` empty results show stats footer
- **Advisory size**: Small — straightforward, low coordination
- **Context dependencies**: `task_display_formatter.rb`, `idea_display_formatter.rb` (reference), `stats_line_formatter.rb` (shared atom, no changes expected)

## Verification Plan

### Unit/Component Validation

- `TaskDisplayFormatter.format_list` with empty tasks array returns `"No tasks found.\n\nTasks: • 0 total"`
- `TaskDisplayFormatter.format_list` with empty tasks + `total_count > 0` returns message + `"Tasks: • 0 of N"` with folder breakdown
- `TaskDisplayFormatter.format_list` with empty tasks + `global_folder_stats` returns message + stats with folder breakdown

### Failure/Invalid Path Validation

- No new failure paths — the empty-list case is already handled; this adds display content to it

### Verification Commands

- `ace-test test/molecules/task_display_formatter_test.rb` — updated empty-list assertions pass
- `ace-test ace-task` — full package regression passes

## Scope of Work

### Behavioral Specifications
- Stats footer visibility rule: always shown, regardless of list emptiness

### Validation Artifacts
- Updated unit tests for empty-list stats display
- Regression pass for full ace-task test suite

## Deliverables

### Behavioral Specifications
- Updated `TaskDisplayFormatter.format_list` empty-path behavior

### Validation Artifacts
- Unit tests covering all empty-list + stats footer combinations
- Full ace-task test suite green

## Out of Scope

- Implementation details: file structures, code organization, technical architecture
- Changes to `StatsLineFormatter` or `ace-idea` — reference only
- Performance optimization
- Future enhancements (e.g., color/styling of stats line)

## References

- Source idea: .ace-ideas/archive/8qmykd-show-stats-footer-in-ace/8qmykd-show-stats-footer-in-ace-task-list.idea.s.md
- Reference implementation: `ace-idea/lib/ace/idea/molecules/idea_display_formatter.rb` (format_list empty path)
- Shared atom: `ace-support-items/lib/ace/support/items/atoms/stats_line_formatter.rb`
