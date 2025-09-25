---
id: v.0.9.0+task.033
status: pending
priority: medium
estimate: 3 days
dependencies: [task.032]
---

# Add enhanced stats and summary display to ace-taskflow

## Description

Phase 3 of ace-taskflow enhancements. Currently, listing commands show basic task/idea/release information without summary statistics. This task adds comprehensive summary headers to all list outputs showing total items vs displayed items, status breakdowns, and context information.

This enhancement provides users and AI agents with immediate visibility into the scope and status distribution of their work.

## Behavioral Specification

Add summary headers to all list outputs:
```
Tasks in Active Release (15 displayed / 42 total):
Status: ✓ done (12) | → in-progress (3) | ○ pending (24) | ⚠ blocked (3)
========================================
[task listings...]
```

Support view modes:
- `--compact` - Minimal display (default)
- `--detailed` - Full information with descriptions
- `--stats` - Statistics only, no item listing

## Acceptance Criteria

- [ ] Summary header shows displayed vs total counts
- [ ] Status breakdown with counts and visual indicators
- [ ] Consistent stats display across tasks, ideas, releases
- [ ] Compact and detailed view modes implemented
- [ ] Stats-only mode for quick overview
- [ ] Group summaries when showing multiple contexts

## Planning Steps

* [ ] Design consistent header format for all entity types
* [ ] Define status icons and color scheme
* [ ] Plan statistics calculation approach
* [ ] Review existing --stats flag implementation

## Execution Steps

- [ ] Create `ace-taskflow/lib/ace/taskflow/molecules/stats_formatter.rb`
  - Format summary headers consistently
  - Calculate status distributions
  - Generate progress indicators

- [ ] Update `ace-taskflow/lib/ace/taskflow/commands/tasks_command.rb`
  - Add summary header to display_tasks
  - Show displayed vs total counts
  - Add status breakdown with counts
  - Implement view modes (compact/detailed)

- [ ] Update `ace-taskflow/lib/ace/taskflow/commands/ideas_command.rb`
  - Add consistent summary headers
  - Show idea status distribution
  - Support view modes

- [ ] Update `ace-taskflow/lib/ace/taskflow/commands/releases_command.rb`
  - Add release summary statistics
  - Show task/idea counts per release
  - Display completion percentages

- [ ] Enhance stats-only mode
  - Improve existing --stats implementation
  - Add charts/graphs for terminal display
  - Show trends and velocity metrics

- [ ] Add configuration options
  - Default view mode in .ace/taskflow/config.yml
  - Customizable status indicators
  - Color scheme preferences

- [ ] Update help text and documentation
  - Document view modes
  - Add examples of different displays
  - Show configuration options

- [ ] Add tests
  - Unit tests for StatsFormatter
  - Integration tests for display changes
  - View mode switching tests

## Implementation Notes

This phase builds on Phase 2 (preset system) and provides immediate value by improving visibility. The enhanced stats will help users and agents quickly understand project state and make better decisions about what to work on next.

Related ideas:
- .ace-taskflow/v.0.9.0/ideas/20250925-010922-in-ace-taskflow-list-ideas-tasks-releases-w.md