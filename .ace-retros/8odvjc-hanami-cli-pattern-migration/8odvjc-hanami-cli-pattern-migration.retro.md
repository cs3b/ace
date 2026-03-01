---
id: 8odvjc
title: "Retro: Hanami CLI Pattern Migration"
type: self-review
tags: []
created_at: "2026-01-14 21:01:28"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8odvjc-hanami-cli-pattern-migration.md
---
# Retro: Hanami CLI Pattern Migration

**Date**: 2025-01-14
**Context**: Task 213 - Migrate ACE gems CLI to Hanami pattern (Phases 1-3 complete)
**Author**: Claude Code Agent
**Type**: Self-Review

## What Went Well

- **Documentation-first approach**: Starting with Phase 1 (docs/ace-gems.g.md update) established clear patterns before implementation
- **Reference implementation**: ace-search as single-command package provided clean template for complex migrations
- **Iterative review process**: Two rounds of code review (PR #158) caught critical bugs (search_path variable) and naming inconsistencies
- **Package-based release strategy**: Version bumps aligned by package (ace-docs → 0.18.0, ace-search → 0.19.0) with CHANGELOG.md for both
- **Clean PR squashing**: 8 commits → 3 logical commits grouped by package boundary for maintainable history

## What Could Be Improved

- **Task scope estimation**: Task 213 estimated at 8h but only ~40% complete after significant work
  - Wrapper pattern packages (ace-docs: 6 commands) required substantial business logic merging
  - 3 more wrapper packages remain (ace-taskflow, ace-git-worktree, ace-support-timestamp)
  - 12 direct pattern packages still need migration
- **Incomplete migration strategy**: Initial approach didn't account for business logic in ace-docs commands requiring full integration
- **Test framework compatibility**: ace-test expects tests in `test/commands/`, not `test/cli/commands/` - requires keeping tests in old location for compatibility

## Key Learnings

- **Hanami pattern complexity**: Not as simple as `commands/` → `cli/commands/` move
  - Wrapper pattern packages require merging business logic from `Commands::*` classes into `CLI::Commands::*`
  - Direct pattern packages are simpler: just directory/module renaming
  - Task should be split by complexity type, not treated uniformly
- **Critical bug from pattern mismatch**: `search_path` local variable vs `@search_path` instance variable broke functionality
  - Easy to miss during refactoring - requires careful variable scope validation
- **File naming matters**: `_command` suffix in files like `analyze_command.rb` doesn't match class names like `Analyze`
  - Violates Ruby/Zeitwerk conventions - files should match the main class they define
- **PR workflow importance**: Multiple review iterations essential for catching bugs that unit tests don't catch

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Scope Underestimation**: Task complexity significantly underestimated
  - Impact: Task only ~40% complete after substantial effort
  - Root Cause: Initial audit didn't distinguish between wrapper vs direct pattern complexity
  - Occurrences: 1 (initial task estimation)

#### Medium Impact Issues

- **Incomplete migration understanding**: First attempt kept wrapper structure
  - Impact: Code review iteration required to merge business logic
  - Root Cause: Task description said "merge cli/*.rb with commands/*.rb" without clarifying full integration
  - Occurrences: 1 (iteration 2 of ace-docs migration)

- **Test path incompatibility**: ace-test framework hardcoded to `test/commands/`
  - Impact: Had to keep tests in old location instead of matching new structure
  - Root Cause: ace-test discovery not updated for Hanami pattern
  - Occurrences: Ongoing

- **Relative path complexity**: `cli/commands/` requires careful relative path calculation
  - Impact: Multiple iterations to fix require_relative paths
  - Root Cause: Different nesting levels (cli/commands/ vs commands/)
  - Occurrences: 3 (path correction iterations)

#### Low Impact Issues

- **Gemfile.lock management**: Mono-repo requires Gemfile.lock commits with version bumps
  - Impact: Extra step needed in release workflow
  - Root Cause: Workspace dependencies update lockfile
  - Occurrences: Resolved (documented in ace-release workflow)

### Improvement Proposals

#### Process Improvements

- **Task complexity categorization**: Split CLI migration tasks by pattern type
  - Direct pattern: Simple directory/module rename
  - Wrapper pattern: Full business logic integration
  - Hybrid pattern: Complex nested subcommands
  - Allow better time estimation and scoping

- **Pre-migration validation**: Add checklist for each package type
  - Direct: count commands/, check for Commands:: classes
  - Wrapper: verify no business logic in Commands:: classes
  - Hybrid: document nested structure

#### Tool Enhancements

- **ace-test discovery**: Update to find tests in `test/cli/commands/` in addition to `test/commands/`
- **Path validation helper**: Command to validate require_relative paths before commit
- **Scope detection tool**: Automatically categorize packages by migration complexity

## Action Items

### Stop Doing

- **Treating all CLI migrations as equal complexity**: Wrapper pattern requires significantly more work than direct pattern
- **Leaving business logic in separate Commands:: classes**: Must merge into CLI commands for complete Hanami pattern

### Continue Doing

- **Package-based commit squashing**: Group commits by package boundary for clean history
- **Multiple review iterations**: Essential for catching bugs that unit tests miss
- **Documentation-first updates**: Establishes patterns before implementation

### Start Doing

- **Task complexity categorization**: Separate direct/wrapper/hybrid pattern in task planning
- **Pre-migration validation**: Check Commands:: classes for business logic before starting
- **Test path verification**: Ensure ace-test can find tests in new locations

## Technical Details

**Packages Migrated (Phase 1-3):**
- ace-docs (0.17.2 → 0.18.0): 6 commands, wrapper pattern, full business logic merge
- ace-search (0.18.1 → 0.19.0): 1 command, direct pattern, simple migration

**Files Modified:**
- Documentation: `docs/ace-gems.g.md` (CLI Framework section updated)
- ace-docs: 25 files (commands deleted, CLI commands created, tests removed, version bumped)
- ace-search: 5 files (command moved, namespace updated, version bumped)

**Critical Bug Fixed:**
- ace-search `@search_path` instance variable was shadowed by local variable in `execute_analyze`
- Caused search path to always be nil, breaking path resolution

## Additional Context

- **Task**: 213-migrate-ace-gems-cli-to-hanami-pattern
- **Branch**: 213-migrate-ace-gems-cli-to-hanami-pattern
- **PR**: #158 (WIP - partial completion, phases 1-3 of 5)
- **Status**: ~40% complete (2 of ~16 packages migrated)
