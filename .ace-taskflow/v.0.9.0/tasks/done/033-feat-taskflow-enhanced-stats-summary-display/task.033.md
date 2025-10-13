---
id: v.0.9.0+task.033
status: done
estimate: 3 days
dependencies: []
---

# Add enhanced stats and summary display to ace-taskflow

## Description

Phase 3 of ace-taskflow enhancements. Currently, listing commands show basic task/idea/release information without summary statistics. This task adds a compact summary header to ALL list outputs showing status distribution with visual indicators, completion percentage, and estimated time remaining.

This enhancement provides users and AI agents with immediate visibility into the overall project state at the top of every listing.

## Behavioral Specification

Add three-line release context header to ALL list outputs:
```
v.0.9.0: 15/42 tasks • "Neptune" Release
Ideas: 💡 8 | 🔄 3 | ✅ 34 • 45 total
Tasks: ⚫ 0 | ⚪ 2 | 🟡 3 | 🟢 34 | 🔴 0 | ❓ 1 • 40 total • 87% complete
========================================
[task or idea listings...]
```

Line 1 - Context:
- For tasks command: `v.0.9.0: 15/42 tasks • "Release Name"`
- For ideas command: `v.0.9.0: 12/45 ideas • "Release Name"`

Line 2 - Ideas status (lifecycle order):
- 💡 new idea
- 🔄 refined/in-progress
- ✅ converted to task

Line 3 - Tasks status (lifecycle order):
- ⚫ draft (black circle)
- ⚪ pending (white circle)
- 🟡 in-progress (yellow circle)
- 🟢 done (green circle)
- 🔴 blocked/skipped (red circle)
- ❓ unknown/malformed status (question mark emoji)

Support view modes:
- `--compact` - Minimal display (default)
- `--detailed` - Full information with descriptions
- `--stats` - Statistics only, no item listing

## Acceptance Criteria

- [ ] Three-line header on ALL list displays
- [ ] Line 1: Context with displayed/total count and release name
- [ ] Line 2: Ideas status in lifecycle order
- [ ] Line 3: Tasks status in lifecycle order with completion %
- [ ] Unknown status handling with ❓ emoji
- [ ] Header shows global release state (unfiltered)

## Planning Steps

* [ ] Design three-line header format
* [ ] Order task statuses by lifecycle: ⚫⚪🟡🟢🔴❓
* [ ] Keep ideas order: 💡🔄✅
* [ ] Context line adapts to command (tasks/ideas)

## Execution Steps

- [x] Create `ace-taskflow/lib/ace/taskflow/molecules/stats_formatter.rb`
  - Format three-line header
  - Line 1: Context with count and release name
  - Line 2: Ideas distribution
  - Line 3: Tasks distribution with lifecycle order
  - Handle unknown statuses with ❓ emoji

- [x] Update `ace-taskflow/lib/ace/taskflow/commands/tasks_command.rb`
  - Add three-line header with "X/Y tasks" on line 1
  - Show ideas and tasks stats on lines 2-3
  - Use lifecycle order: ⚫⚪🟡🟢🔴❓
  - Display global release statistics

- [x] Update `ace-taskflow/lib/ace/taskflow/commands/ideas_command.rb`
  - Use same three-line header format
  - Line 1 shows "X/Y ideas" instead of tasks
  - Lines 2-3 identical to tasks command

- [x] Update `ace-taskflow/lib/ace/taskflow/commands/releases_command.rb`
  - Add compact stats header for each release
  - Show task status distribution per release
  - Include completion percentage and estimates

- [x] Enhance stats-only mode
  - Expand compact header into detailed view
  - Show status distribution with counts
  - Display completion trends (no priority stats)

- [ ] Add configuration options
  - Default view mode in .ace/taskflow/config.yml
  - Option to disable/customize stats header
  - Color scheme preferences for status indicators

- [ ] Update help text and documentation
  - Document view modes
  - Add examples of different displays
  - Show configuration options

- [ ] Add tests
  - Unit tests for StatsFormatter
  - Integration tests for display changes
  - View mode switching tests

## Implementation Notes

This phase builds on Phase 2 (preset system) and provides immediate value by improving visibility. The three-line header appearing on every listing gives instant context about what you're viewing and the complete release state.

Key principles:
- Line 1 adapts to the command (tasks vs ideas) showing relevant counts
- Stats always show GLOBAL release state, not just filtered subset
- Task statuses ordered by lifecycle: draft → pending → in-progress → done
- Unknown/malformed statuses use ❓ emoji to catch data issues
- Both task and idea stats always appear for complete context

Related ideas:
- .ace-taskflow/v.0.9.0/ideas/20250925-010922-in-ace-taskflow-list-ideas-tasks-releases-w.md