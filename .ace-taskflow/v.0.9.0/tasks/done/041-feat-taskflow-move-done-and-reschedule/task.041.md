---
id: v.0.9.0+task.041
status: done
estimate: 2 days
dependencies: [task.033, task.040]
---

# Implement move-to-done and reschedule features for ace-taskflow

## Description

Enhance ace-taskflow with two major features: (1) automatic movement of completed tasks and ideas to `done/` subdirectories, and (2) reschedule functionality for ideas and releases similar to existing task rescheduling. These improvements will create cleaner active directories and provide consistent management capabilities across all ace-taskflow entities.

## Behavioral Specification

### Part 1: Move-to-done Functionality

#### For Tasks
When `ace-taskflow task done <ref>` is executed:
1. Update task frontmatter status to "done"
2. Move entire task folder from `.ace-taskflow/v.X.Y.Z/t/<task-id>/` to `.ace-taskflow/v.X.Y.Z/t/done/<task-id>/`
3. Display confirmation: "Task <ref> marked as done and moved to done/"

#### For Ideas (NEW)
Implement `ace-taskflow idea done <ref>` command:
1. Update idea frontmatter:
   - status: done
   - completed_at: <timestamp>
2. Move idea file from `ideas/<filename>.md` to `ideas/done/<filename>.md`
3. Display confirmation: "Idea <ref> marked as done and moved to done/"

#### Listing Enhancement
All listing commands must scan both active and done directories:
- `ace-taskflow tasks` searches in both `t/` and `t/done/`
- `ace-taskflow ideas` searches in both `ideas/` and `ideas/done/`
- Status filters work correctly (e.g., `--status pending` excludes done items)
- Statistics include items from both locations

### Part 2: Reschedule Functionality

#### For Ideas
Implement `ace-taskflow idea reschedule <ref> [options]`:
- Options mirror task reschedule:
  - `--add-next`: Place before other pending ideas
  - `--add-at-end`: Place after all ideas
  - `--after <ref>`: Place after specific idea
  - `--before <ref>`: Place before specific idea
- Ideas use `sort` field (not priority) in frontmatter
- Both `ideas` and `idea` commands respect sort order
- Default display: ascending by sort value

#### For Releases
Implement `ace-taskflow release reschedule <ref> [options]`:
- Options:
  - `--status <value>`: Update release status
  - `--target-date <YYYY-MM-DD>`: Update target completion date
- Maintain consistency with existing patterns

## Implementation Details

### New Components

#### Molecules
- `TaskDirectoryMover`: Handles atomic move of task directories
- `IdeaDirectoryMover`: Handles atomic move of idea files
- `SortValueCalculator`: Computes sort values for reschedule operations

#### Organisms
- `IdeaScheduler`: Manages idea rescheduling with sort-based positioning
- `ReleaseScheduler`: Handles release metadata updates
- Enhanced `TaskManager`: Supports done directory operations
- Enhanced `IdeaLoader`: Scans both ideas/ and ideas/done/

#### Commands
- New subcommand: `idea done` in idea_command.rb
- New subcommand: `idea reschedule` in idea_command.rb
- New subcommand: `release reschedule` in release_command.rb

### Technical Requirements

1. **Atomic Operations**: Status update and file move must be atomic to prevent inconsistent states
2. **Path Validation**: All paths validated using multi-layer validation per ACE security
3. **Error Handling**: Robust error handling with rollback on failure
4. **Backward Compatibility**: Gracefully handle existing done tasks not in done/ folder
5. **CLI Output**: Clear, parseable output for both human and agent consumption

## Acceptance Criteria

- [x] `task done` moves task folder to t/done/ and updates status
- [x] `idea done` command implemented and moves ideas to ideas/done/
- [x] All listing commands scan both active and done directories
- [x] Statistics correctly aggregate from both locations
- [x] `idea reschedule` command works with sort field
- [x] Ideas display respects sort order in both list and single views
- [x] `release reschedule` updates release metadata
- [x] Atomic operations with proper rollback on failure
- [x] Clear CLI output for all operations
- [x] Tests for all new functionality

## Related Ideas

- docs/ideas/041-feat-taskflow-move-done-tasks.md
- docs/ideas/041-feat-taskflow-reschedule-ideas-releases.md

## Notes

This task combines two related feature requests to provide comprehensive improvements to ace-taskflow's organizational capabilities. The move-to-done feature keeps active directories clean, while reschedule functionality provides consistent management across all entity types.