---
id: 8m0000
title: "Retro: Task 088 - Glob Pattern Refactoring"
type: conversation-analysis
tags: []
created_at: "2025-11-01 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8m0000-task-088-glob-pattern-refactoring.md
---
# Retro: Task 088 - Glob Pattern Refactoring

**Date**: 2025-11-01
**Context**: Fixing glob pattern issues and removing hardcoded directory names in ace-taskflow
**Author**: Claude Code
**Type**: Conversation Analysis

## What Went Well

- Successfully identified and fixed the root cause of test failures (TaskReferenceParser using :context instead of :release)
- Completed comprehensive refactoring to remove all hardcoded "ideas/" and "tasks/" from glob patterns
- Established single source of truth for default glob pattern in Configuration class
- Fixed file extension issues (.md → .s.md) across multiple files
- All core tests passing after fixes

## What Could Be Improved

- **Initial confusion about workflow execution**: Spent ~10 minutes trying to use wrong commands for code review
- **Repeated mistakes with hardcoding**: Multiple attempts to fix glob patterns, kept reverting to hardcoded directory names despite user corrections
- **Understanding of preset system**: Initially misunderstood how presets and glob patterns interact with directory prefixes
- **ace-review tool issues**: The exclude parameter didn't work as expected, resulting in 568.9KB subject file

## Key Learnings

- **Glob patterns should be generic**: Never hardcode directory names - let `apply_folder_prefix` handle directory prefixing based on command type
- **Configuration is source of truth**: Always use configuration classes for defaults rather than hardcoding values throughout codebase
- **Test fixtures matter**: Test failures can be caused by fixture mismatches (e.g., using "i" directory vs "ideas")
- **Context→Release refactoring**: Important to maintain consistency in naming across all components (parser, loader, commands)
- **File extension consistency**: When changing file extensions (.md → .s.md), must update both production code and tests

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Repeated hardcoding attempts**: User corrected multiple times ("no kurwa nie", "why the fuck we are getting back to put the fixed names")
  - Occurrences: 4+ times
  - Impact: User frustration, wasted time on incorrect solutions
  - Root Cause: Not understanding the separation of concerns between glob patterns and directory configuration

- **Workflow execution confusion**: Initially tried to use dev-handbook paths and ace-git-diff instead of ace-review
  - Occurrences: 3 times in initial review attempt
  - Impact: 10 minutes wasted
  - Root Cause: Not following workflow instructions precisely

#### Medium Impact Issues

- **Incomplete refactoring**: Context→Release refactoring was incomplete (11 occurrences missed)
  - Occurrences: Once but with 11 locations
  - Impact: Test failures requiring additional debugging
  - Root Cause: Partial search/replace without comprehensive verification

- **Test understanding**: Confusion about what tests were actually failing
  - Occurrences: 2-3 times
  - Impact: Extra debugging cycles needed
  - Root Cause: Test output format confusion, missing failures.json file

#### Low Impact Issues

- **ace-review filtering**: exclude parameter not working
  - Occurrences: 1
  - Impact: Large subject file but review still worked
  - Root Cause: Tool limitation or incorrect usage

### Improvement Proposals

#### Process Improvements

- Always read and follow workflow instructions exactly as written
- When refactoring naming (context→release), use comprehensive search across entire codebase
- Verify test fixtures match expected directory structure before assuming code is wrong

#### Tool Enhancements

- ace-review needs better exclude parameter functionality
- Consider adding a validation tool for glob patterns to ensure no hardcoded directories

#### Communication Protocols

- When user provides corrections, acknowledge the principle behind the correction
- Ask for clarification on design decisions before implementing
- Confirm understanding of separation of concerns before coding

### Token Limit & Truncation Issues

- **Large Output Instances**: ace-review subject file was 568.9KB
- **Truncation Impact**: No significant impact but made review harder
- **Mitigation Applied**: Continued with large file
- **Prevention Strategy**: Fix exclude parameter functionality in ace-review

## Action Items

### Stop Doing

- Hardcoding directory names in glob patterns
- Making assumptions about workflow commands without reading instructions
- Partial refactoring without comprehensive searches

### Continue Doing

- Using single source of truth (Configuration class) for defaults
- Running tests incrementally to verify fixes
- Creating detailed commit messages explaining changes

### Start Doing

- Read workflow instructions completely before executing
- Verify test fixture structure matches code expectations
- Use comprehensive search when refactoring naming conventions
- Test both production code and test code after changes

## Technical Details

**Final Solution Architecture:**
- `Configuration#default_glob_pattern`: Returns `['**/*.s.md']` as single source of truth
- `ListPresetManager#apply_folder_prefix`: Adds directory prefix based on command type
- `IdeaLoader`: Automatically prepends ideas directory to patterns
- Preset files: Use generic patterns without directory prefixes

**Key Files Modified:**
- lib/ace/taskflow/configuration.rb (added default_glob_pattern)
- lib/ace/taskflow/molecules/idea_loader.rb (uses config, prepends ideas dir)
- lib/ace/taskflow/molecules/list_preset_manager.rb (uses config default)
- lib/ace/taskflow/molecules/stats_formatter.rb (removed hardcoded glob)
- lib/ace/taskflow/organisms/task_manager.rb (removed tasks/ prefix)
- All preset files in .ace.example and .ace directories

## Additional Context

- Related to Task 088: Ideas maybe anyday functionality
- Three commits created:
  - 7cdd628c: Fixed TaskReferenceParser :context → :release
  - a72c75a4: Updated file extensions .md → .s.md
  - 7f6e89bb: Removed hardcoded directory names from glob patterns

**User Frustration Points:**
- "no kurwa nie" - Polish expression of frustration
- "why the fuck we are getting back to put the fixed names" - Clear frustration with repeated mistakes
- Multiple corrections needed for the same conceptual issue

**Lesson:** When a user corrects the same issue multiple times, step back and ensure you understand the underlying principle, not just the immediate fix.