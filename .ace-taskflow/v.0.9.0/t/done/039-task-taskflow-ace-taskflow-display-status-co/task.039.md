---
id: v.0.9.0+task.039
status: done
estimate: 1h
dependencies: []
---

# Improve ace-taskflow task display with status colors and unified sorting

## Behavioral Context

**Issue**: The ace-taskflow commands had inconsistent behavior between `task` (singular) and `tasks` (plural), used priority-based coloring instead of status-based, and didn't properly utilize the preset system for both commands.

**Key Behavioral Requirements**:
- Both `task` and `tasks` commands should use the same preset system
- Colors should represent task status for immediate visual clarity
- Task sorting should be simplified to use sort attribute or task ID
- Display format should be more compact and informative

## Objective

Unified ace-taskflow display behavior with status-based colors and consistent sorting across both singular and plural task commands.

## Scope of Work

- Modified default sort order from priority-based to sort/ID-based
- Replaced priority color indicators with status colors
- Improved compact display format combining Estimate and Dependencies
- Updated task_command.rb to use preset system like tasks_command.rb
- Updated default presets to use consistent sorting

### Deliverables

#### Create
- No new files created

#### Modify
- ace-taskflow/lib/ace/taskflow/commands/task_command.rb - Added preset system, formatted display
- ace-taskflow/lib/ace/taskflow/commands/tasks_command.rb - Status colors, compact format
- ace-taskflow/lib/ace/taskflow/molecules/list_preset_manager.rb - Updated default presets
- .ace/taskflow/presets/next.yml - Changed sort from priority to sort attribute

#### Delete
- Removed priority_indicator method (replaced with status colors)

## Implementation Summary

### What Was Done

- **Problem Identification**: User reported inconsistency between task commands and confusion about priority colors
- **Investigation**: Found task command bypassed preset system and returned only file paths
- **Solution**: Unified both commands to use presets and status-based colors
- **Validation**: Tested all display modes and verified sorting behavior

### Technical Details

**Status Color Mapping**:
- ⚫ (black circle) = draft
- ⚪ (white/gray circle) = pending
- 🟡 (yellow) = in-progress
- 🟢 (green) = done
- 🔴 (red) = blocked/skipped

**Sorting Changes**:
- Changed from `sort: { by: :priority, ascending: false }`
- To `sort: { by: :sort, ascending: true }`
- Falls back to task ID when no sort attribute

**Display Format**:
- Combined Estimate and Dependencies on single line with pipe separator
- Example: `Estimate: 2 days | Dependencies: task.021`

### Testing/Validation

```bash
# Test single task command with new formatting
ace-taskflow task
# Output: Task: v.0.9.0+035 🟡 Implement configuration-based provider...

# Test tasks command with limit
ace-taskflow tasks next --limit 3
# Shows formatted tasks with status colors

# Test path mode for backward compatibility
ace-taskflow task --path
# Output: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/035...

# Test specific task display
ace-taskflow task 023
# Shows formatted task with status color

# Test statistics still work
ace-taskflow tasks --stats
# Shows statistics with status icons
```

**Results**: All commands now display consistent, informative output with clear visual status indicators

## References

- Commits: To be created after this documentation
- Related issues: User feedback about confusing priority colors and inconsistent commands
- Documentation: Help text updated in both command files
- Follow-up needed: None - implementation complete