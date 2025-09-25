# Task 033: Enhanced Stats and Summary Display - Usage Examples

## Current Behavior (Before)

```bash
$ ace-taskflow tasks
Tasks in Active Release:
  task.025  ○ medium  Add git commit flags
  task.026  → high    Fix loader crash
  task.027  ○ low     Update docs
[No summary, no counts, no context about total scope]

$ ace-taskflow tasks --stats
Total: 42 tasks
By Status:
  pending: 24
  in-progress: 3
  done: 15
[Stats separate from listing, no visual indicators]
```

## New Behavior (After)

```bash
$ ace-taskflow tasks
Tasks in v.0.9.0 (showing 8 of 42 total):
Status: ✓ done (15) | → in-progress (3) | ○ pending (24)
Priority: 🔴 critical (2) | 🟠 high (5) | 🟡 medium (20) | ⚪ low (15)
================================================
  task.025  ○ 🟡  Add git commit flags
  task.026  → 🟠  Fix loader crash
  task.027  ○ ⚪  Update docs
[Rich summary header with all context]
```

## Usage Scenarios

### Scenario 1: Quick Project Status Check
```bash
$ ace-taskflow tasks
Tasks in v.0.9.0 (showing 10 of 67 total):
Status: ✓ done (45) | → in-progress (4) | ○ pending (15) | ⚠ blocked (3)
Progress: ████████████████░░░░ 67% complete (45/67)
Velocity: 8 tasks/week average
================================================
  task.031  → 🟠  Implement descriptive paths [2d]
  task.032  ○ 🟠  Preset system design [5d]
  task.033  ○ 🟡  Enhanced stats display [3d]

# Instant understanding of project state
```

### Scenario 2: Release Overview
```bash
$ ace-taskflow releases
Active Releases (2 of 5 total):
================================================

v.0.9.0 "Neptune" (Current)
├─ Status: ✓ 45 | → 4 | ○ 18 | ⚠ 3 (70 total)
├─ Progress: ████████████░░░░░░░░ 64% complete
├─ Due: 5 days remaining
└─ Velocity: On track (8/week needed)

v.0.10.0 "Orion" (Next)
├─ Status: ○ 25 | ⚠ 2 (27 total)
├─ Progress: ░░░░░░░░░░░░░░░░░░░░ 0% complete
├─ Due: Starts in 5 days
└─ Estimated: 3 weeks
```

### Scenario 3: Filtered Views with Context
```bash
$ ace-taskflow tasks recent --days 1
Recent Activity (8 modified of 67 total tasks):
Changed Today: ✓ completed (3) | → started (2) | ✏ updated (3)
================================================
  10:30  ✓ task.025  Completed: Add git commit flags
  09:15  → task.026  Started: Fix loader crash
  08:45  ✏ task.027  Updated: Added test cases
```

### Scenario 4: Stats-Only Mode for Dashboards
```bash
$ ace-taskflow tasks --stats
╔══════════════════════════════════════════════╗
║          Task Statistics - v.0.9.0           ║
╠══════════════════════════════════════════════╣
║ Total Tasks:           67                    ║
║ Completed:            45 (67%)               ║
║ In Progress:           4 (6%)                ║
║ Pending:              15 (22%)               ║
║ Blocked:               3 (5%)                ║
╟──────────────────────────────────────────────╢
║ By Priority:                                 ║
║   🔴 Critical:         2                     ║
║   🟠 High:            12                     ║
║   🟡 Medium:          35                     ║
║   ⚪ Low:             18                     ║
╟──────────────────────────────────────────────╢
║ Velocity:                                    ║
║   This Week:          8 tasks               ║
║   Last Week:          12 tasks              ║
║   Average:            10 tasks/week         ║
╟──────────────────────────────────────────────╢
║ Estimates:                                   ║
║   Remaining Work:     ~2 weeks              ║
║   At Current Pace:    2.5 weeks             ║
╚══════════════════════════════════════════════╝
```

### Scenario 5: Compact vs Detailed Views
```bash
# Compact view (default)
$ ace-taskflow tasks
Tasks (8 of 42):  ✓15 →3 ○24
════════════════════════════════
  031  → Descriptive paths
  032  ○ Preset system
  033  ○ Enhanced stats

# Detailed view
$ ace-taskflow tasks --detailed
Tasks in v.0.9.0 (showing 8 of 42 total):
Status: ✓ done (15) | → in-progress (3) | ○ pending (24)
================================================
┌─ task.031 ─────────────────────────────────┐
│ Status: → In Progress    Priority: 🟠 High  │
│ Title: Implement descriptive paths         │
│ Estimate: 1 week         Progress: 40%     │
│ Started: 2 days ago      Due: in 5 days    │
│ Description: Implement semantic task paths │
│ for better navigation and discovery...     │
└─────────────────────────────────────────────┘
```

### Scenario 6: Multi-Context Aggregation
```bash
$ ace-taskflow tasks all
All Tasks (125 total across all contexts):
================================================

Active Release v.0.9.0 (67 tasks):
  Status: ✓45 →4 ○15 ⚠3  Progress: 67%

Backlog (42 tasks):
  Status: ○35 ⚠7  Priority: 🔴2 🟠8 🟡20 ⚪12

Completed Releases (16 tasks archived):
  v.0.8.0: ✓16 (100% complete)

Summary: 61/125 tasks complete (49% overall)
```

### Scenario 7: Team Performance Metrics
```bash
$ ace-taskflow tasks --stats --team
Team Performance Dashboard:
================================================
         Mon  Tue  Wed  Thu  Fri  Total
Started    2    3    1    0    -      6
Completed  1    2    2    1    -      6
Created    3    1    2    2    -      8

Top Performers This Week:
  @alice:  12 tasks (8 completed, 4 in progress)
  @bob:     8 tasks (6 completed, 2 in progress)

Bottlenecks:
  3 tasks blocked > 3 days
  2 high priority tasks not started
```

### Scenario 8: Ideas and Tasks Together
```bash
$ ace-taskflow ideas
Ideas in v.0.9.0 (12 active of 45 total):
Status: 💡 new (8) | 🔄 refined (3) | ✅ converted (34)
================================================
  💡 idea.156  Support for webhooks
  💡 idea.157  Add batch operations
  🔄 idea.158  Enhanced logging (refined, ready for task)

Conversion Rate: 76% (34/45 ideas → tasks)
Average Time to Task: 3.2 days
```

## Display Customization

### Configuration Options
```yaml
# .ace/taskflow/config.yml
display:
  default_view: compact        # compact, detailed, stats
  show_estimates: true
  show_progress: true
  use_colors: true
  use_emoji: true
  status_indicators:
    done: "✓"
    in_progress: "→"
    pending: "○"
    blocked: "⚠"
  priority_indicators:
    critical: "🔴"
    high: "🟠"
    medium: "🟡"
    low: "⚪"
```

## Benefits

1. **Instant Context**: See total scope vs displayed items immediately
2. **Visual Status**: Icons and colors for quick scanning
3. **Progress Tracking**: Understand completion at a glance
4. **Flexible Views**: Compact for quick checks, detailed for deep dives
5. **Better Decision Making**: Rich context helps prioritization
6. **Team Visibility**: Performance metrics and bottleneck identification