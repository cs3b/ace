# Task 033: Enhanced Stats and Summary Display - Usage Examples

## Core Concept

Every ace-taskflow list command now displays a three-line header showing complete release context:
- **Line 1**: Context (version, displayed/total count, release name)
- **Line 2**: Ideas statistics in lifecycle order
- **Line 3**: Tasks statistics in lifecycle order with completion percentage

This provides instant visibility into the complete project state. Unknown/malformed statuses are shown with ❓ emoji.

## Current Behavior (Before)

```bash
$ ace-taskflow tasks
Tasks: next (4 found)
Next actionable tasks (pending + in-progress)
==================================================
  v.0.9.0+025  ⚪ Add git commit flags
  v.0.9.0+026  🟡 Fix loader crash
  v.0.9.0+027  ⚪ Update docs
[No summary statistics, no global context]

$ ace-taskflow tasks --stats
Total: 42 tasks
By Status:
  Done: 15
  In-progress: 3
  Pending: 24
By Priority:
  High: 10
  Medium: 20
  Low: 12
[Stats separate from listing, includes priority which is deprecated]
```

## New Behavior (After)

```bash
$ ace-taskflow tasks
v.0.9.0: 8/42 tasks • "Neptune" Release
Ideas: 💡 8 | 🔄 3 | ✅ 34 • 45 total
Tasks: ⚫ 0 | ⚪ 24 | 🟡 3 | 🟢 15 | 🔴 0 | ❓ 0 • 42 total • 36% complete
==================================================
Tasks: next (showing 8 of 42 found)
  v.0.9.0+025  ⚪ Add git commit flags
  v.0.9.0+026  🟡 Fix loader crash
  v.0.9.0+027  ⚪ Update docs
[Three-line header provides complete context]
```

## Usage Scenarios

### Scenario 1: Quick Project Status Check
```bash
$ ace-taskflow tasks
v.0.9.0: 10/67 tasks • "Neptune" Release
Ideas: 💡 12 | 🔄 5 | ✅ 28 • 45 total
Tasks: ⚫ 0 | ⚪ 15 | 🟡 4 | 🟢 45 | 🔴 3 | ❓ 0 • 67 total • 67% complete
==================================================
Tasks: next (showing 10 of 67 found)
  v.0.9.0+031  🟡 Implement descriptive paths [2d]
  v.0.9.0+032  ⚪ Preset system design [5d]
  v.0.9.0+033  🟡 Enhanced stats display [3d]

# Three lines: context, ideas, tasks
```

### Scenario 2: Release Overview
```bash
$ ace-taskflow releases
All: 🟢 45 (46%) | 🟡 4 (4%) | ⚪ 43 (44%) | 🔴 5 (5%) • 2 active releases
==================================================

v.0.9.0 "Neptune" (Current)
🟢 45 (64%) | 🟡 4 (6%) | ⚪ 18 (26%) | 🔴 3 (4%) • 64% complete, on track

v.0.10.0 "Orion" (Next)
⚪ 25 (93%) | 🔴 2 (7%) • Not started, begins in 5d
```

### Scenario 3: Filtered Views with Context
```bash
$ ace-taskflow tasks recent --days 1
v.0.9.0: 🟢 45 (67%) | 🟡 4 (6%) | ⚪ 15 (22%) | 🔴 3 (5%) • 67% complete
==================================================
Tasks: recent (8 modified today of 67 total)
  10:30  🟢 v.0.9.0+025  Completed: Add git commit flags
  09:15  🟡 v.0.9.0+026  Started: Fix loader crash
  08:45  ⚪ v.0.9.0+027  Updated: Added test cases

# Global stats remain visible even with filtered view
```

### Scenario 4: Stats-Only Mode for Dashboards
```bash
$ ace-taskflow tasks --stats
╔══════════════════════════════════════════════╗
║          Task Statistics - v.0.9.0           ║
╠══════════════════════════════════════════════╣
║ Total Tasks:           67                    ║
║                                              ║
║ Status Distribution:                         ║
║   🟢 Done:            45 (67%)              ║
║   🟡 In Progress:      4 (6%)               ║
║   ⚪ Pending:         15 (22%)              ║
║   🔴 Blocked:          3 (5%)               ║
║   ⚫ Draft:            0                    ║
╟──────────────────────────────────────────────╢
║ Progress & Velocity:                         ║
║   Completion:         67% (45/67)           ║
║   This Week:          8 tasks completed     ║
║   Last Week:         12 tasks completed     ║
║   Average:           10 tasks/week          ║
║   Est. Remaining:    ~1.5 weeks             ║
╟──────────────────────────────────────────────╢
║ Recent Activity:                             ║
║   Today:              3 completed, 2 started║
║   Yesterday:          5 completed           ║
║   This Week:         15 total changes       ║
╚══════════════════════════════════════════════╝
```

### Scenario 5: Compact vs Detailed Views
```bash
# Compact view (default)
$ ace-taskflow tasks --compact
v.0.9.0: 🟢 15 (36%) | 🟡 3 (7%) | ⚪ 24 (57%) • 36% done, ~5d left
==================================================
Tasks: next (8 of 42)
  031  🟡 Descriptive paths
  032  ⚪ Preset system
  033  🟡 Enhanced stats

# Detailed view
$ ace-taskflow tasks --detailed
v.0.9.0: 🟢 15 (36%) | 🟡 3 (7%) | ⚪ 24 (57%) | 🔴 0 • 36% complete
==================================================
Tasks: next (showing 8 of 42 found)
┌─ v.0.9.0+031 ──────────────────────────────┐
│ Status: 🟡 In Progress                     │
│ Title: Implement descriptive paths         │
│ Estimate: 1 week       Progress: 40%       │
│ Started: 2 days ago    Due: in 5 days      │
│ Description: Implement semantic task paths │
│ for better navigation and discovery...     │
└─────────────────────────────────────────────┘
```

### Scenario 6: Multi-Context Aggregation
```bash
$ ace-taskflow tasks all
All: 🟢 61 (49%) | 🟡 4 (3%) | ⚪ 50 (40%) | 🔴 10 (8%) • 49% complete overall
==================================================
Tasks: all (125 total across all contexts)

v.0.9.0 (67 tasks):
  🟢 45 (67%) | 🟡 4 (6%) | ⚪ 15 (22%) | 🔴 3 (5%)

Backlog (42 tasks):
  ⚪ 35 (83%) | 🔴 7 (17%)

v.0.8.0 - Completed (16 tasks):
  🟢 16 (100%)
```

### Scenario 7: Tree View with Stats Header
```bash
$ ace-taskflow tasks --tree
v.0.9.0: T: 🟢 34 | 🟡 0 | ⚪ 4 | 🔴 1 • I: 💡 8 | 🔄 2 | ✅ 25 • 87% complete
==================================================
Tasks: dependency tree (39 total)

├─ v.0.9.0+001 🟢 Core setup
├─ v.0.9.0+002 🟢 Base configuration
├─ v.0.9.0+003 🟢 Initial tests
└─ v.0.9.0+007 ⚪ Create ace-git gem
   ├─ depends on: 001, 002, 003
   └─ blocks: 008, 009
```

### Scenario 8: Ideas List with Unified Header
```bash
$ ace-taskflow ideas
v.0.9.0: T: 🟢 45 | 🟡 4 | ⚪ 15 | 🔴 3 • I: 💡 12 | 🔄 5 | ✅ 28 • 62% conversion
==================================================
Ideas: active (17 of 45 total)
  💡 idea.156  Support for webhooks
  💡 idea.157  Add batch operations
  🔄 idea.158  Enhanced logging (ready for task)
```

### Scenario 9: Unknown Status Handling
```bash
$ ace-taskflow tasks
v.0.9.0: T: 🟢 34 | 🟡 3 | ⚪ 15 | 🔴 2 | ? 3 • I: 💡 8 | ✅ 25 • Warning: 3 unknown
==================================================
Tasks: next (showing 10 of 57 found)
  v.0.9.0+025  ⚪ Add git commit flags
  v.0.9.0+026  ? Fix loader crash [status: "completed"]
  v.0.9.0+027  ⚪ Update docs

# Unknown/malformed statuses are caught with ? indicator
# This helps detect data issues or typos in task files
```


## Display Customization

### Configuration Options
```yaml
# .ace/taskflow/config.yml
display:
  default_view: compact        # compact, detailed, stats
  show_stats_header: true      # Unified header on all listings
  show_ideas_in_header: true   # Include idea counts
  show_unknown_status: true    # Display ? for unknown
  show_estimates: true
  show_velocity: true
  use_colors: true
  task_status_colors:
    done: "🟢"          # Green circle
    in_progress: "🟡"   # Yellow circle
    pending: "⚪"       # White circle
    blocked: "🔴"       # Red circle
    draft: "⚫"         # Black circle
    unknown: "?"        # Unknown/malformed
  idea_status_colors:
    new: "💡"           # Light bulb
    refined: "🔄"       # Refresh/cycle
    converted: "✅"     # Check mark
  compact_stats: true         # Single-line format
```

## Benefits

1. **Complete Context**: See both tasks AND ideas in release at a glance
2. **Visual Status**: Colored indicators (🟢🟡⚪🔴⚫? for tasks, 💡🔄✅ for ideas)
3. **Error Detection**: Unknown statuses caught with ? indicator
4. **Unified Display**: Single header for complete release visibility
5. **Progress & Velocity**: Combined metrics show completion and pace
6. **Consistent Experience**: Same header format across all commands