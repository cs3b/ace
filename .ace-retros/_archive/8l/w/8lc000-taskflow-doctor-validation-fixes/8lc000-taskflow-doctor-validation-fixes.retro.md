---
id: 8lc000
title: "Retro: ace-taskflow Doctor Validation and Statistics Fixes"
type: self-review
tags: []
created_at: "2025-10-13 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8lc000-taskflow-doctor-validation-fixes.md
---
# Retro: ace-taskflow Doctor Validation and Statistics Fixes

**Date**: 2025-10-13
**Context**: Fixed two critical issues in ace-taskflow doctor: retro file misidentification and confusing statistics display
**Author**: Claude + User
**Type**: Self-Review

## What Went Well

- **Root cause analysis was thorough**: Identified the exact pattern matching bug where filename patterns (`/task\.\d+\.md$/`) were checked before directory patterns (`/retros/`), causing retros named like `finish-work-on-task.38.md` to be misidentified as tasks
- **Configuration-driven solution**: Updated both `FrontmatterValidator` and `TaskflowDoctor` to use configured directory names from `.ace/taskflow/config.yml` instead of hardcoded paths
- **Reusable statistics logic**: Leveraged existing `StatsFormatter` patterns used by `ace-taskflow tasks` and `ace-taskflow ideas` commands, ensuring consistent display across the CLI
- **Fixed secondary bug proactively**: Discovered and fixed type coercion issue where `frontmatter["id"].match?` failed when YAML parsed numeric IDs as integers
- **User caught configuration oversight**: User correctly identified that directory names should come from config, not be hardcoded - this prevented future configuration mismatches

## What Could Be Improved

- **Initial fix attempt missed configuration**: First implementation hardcoded directory names like `/retros/` instead of reading from `config.retro_dir`, requiring user intervention to correct
- **Context initialization confusion**: Initial stats collection used wrong root path, leading to empty statistics - had to debug through multiple test iterations to find the correct `@root_path` initialization
- **Complex pattern matching logic**: The reordered case statement with `Regexp.escape` and nested directory detection (`ideas_dir.split('/').last`) is harder to understand than it could be

## Key Learnings

- **Pattern matching order matters critically**: When detecting component types, directory structure should ALWAYS be checked before filename patterns, as file location is more reliable than content
- **Configuration cascade principle**: ace-taskflow uses configuration-driven directory names throughout - any hardcoded paths break user customization
- **Type coercion in YAML parsing**: YAML parsers can return different Ruby types for the same field (String vs Integer for `id: 042`) - always use `.to_s` before calling String methods like `.match?`
- **Statistics collection context**: When collecting stats for display, the context string (e.g., "v.0.9.0") must match how `TaskManager` and `IdeaLoader` resolve contexts - using `active_release[:name]` is the correct pattern

## Action Items

### Stop Doing

- Hardcoding directory paths when configuration exists
- Assuming YAML fields will always be strings
- Testing validation changes in isolation without checking actual `ace-taskflow doctor` output

### Continue Doing

- Using configuration-driven patterns for directory detection
- Leveraging existing formatter patterns for consistency
- Fixing secondary bugs discovered during investigation (like the type coercion issue)
- Verifying fixes with real commands (`ace-taskflow doctor`, `ace-taskflow tasks all`)

### Start Doing

- Consider extracting pattern matching logic into a dedicated molecule/atom for reusability and testability
- Add unit tests for `detect_component_type` with various filename patterns and directory structures
- Document the configuration-first principle in code comments for future maintainers

## Technical Details

### Issue #1: Retro File Misidentification

**Root Cause**:
```ruby
# OLD (WRONG) - filename patterns checked first
when /\/t\/.*\.md$/, /task\.\d+\.md$/  # Matches "task.38.md" anywhere
  :task
when /\/retros\/.*\.md$/              # Never reached for retros named "task.NN.md"
  :retro
```

**Solution**:
```ruby
# NEW (CORRECT) - directory patterns checked first
when /\/#{Regexp.escape(retro_dir)}\//   # Check retros/ directory first
  :retro
when /\/#{Regexp.escape(task_dir)}\//, /task\.\d+\.md$/  # Then check tasks
  :task
```

### Issue #2: Confusing Statistics Display

**Problem**: Doctor showed "Tasks: 0 total, Ideas: 0 total" but "Components validated: 49 tasks, 148 ideas"

**Root Cause**: Two different stat sources:
- `components[:structure]` counted only ACTIVE release tasks/ideas (empty for new releases)
- `components[:integrity]` counted ALL files scanned across ALL releases (including done/)

**Solution**: Added `collect_active_stats` method to gather real statistics from primary active release using `TaskManager.get_statistics` and `IdeaLoader.load_all`, displaying:
```
Tasks: ⚫ 1 | ⚪ 0 | 🟡 0 | 🟢 48 | 🔴 0 • 49 total • 98% complete
Ideas: 💡 33 | ✅ 13 • 46 total
Files scanned: 49 tasks, 148 ideas, 14 releases
```

### Files Modified

1. `ace-taskflow/lib/ace/taskflow/molecules/frontmatter_validator.rb` - Configuration-driven directory detection
2. `ace-taskflow/lib/ace/taskflow/organisms/taskflow_doctor.rb` - Same pattern + stats collection
3. `ace-taskflow/lib/ace/taskflow/molecules/doctor_reporter.rb` - Enhanced statistics display with status icons

## Additional Context

- Commits:
  - `a2154c56` - fix(taskflow): Prioritize directory structure for component type detection
  - `5eef6d45` - feat(ace-taskflow): Enhance doctor output with active release stats
- Related commands: `ace-taskflow doctor`, `ace-taskflow tasks all`, `ace-taskflow ideas all`
- Configuration file: `.ace/taskflow/config.yml` (directories.retros, directories.ideas, directories.tasks)
