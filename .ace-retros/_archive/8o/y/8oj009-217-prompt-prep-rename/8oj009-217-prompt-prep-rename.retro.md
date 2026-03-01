---
id: 8oj009
title: Task 217 - ace-prompt-prep Rename
type: standard
tags: []
created_at: "2026-01-20 00:00:16"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8oj009-217-prompt-prep-rename.md
---
# Reflection: Task 217 - ace-prompt-prep Rename

**Date**: 2026-01-20
**Context**: Complete rename of ace-prompt to ace-prompt-prep with bundle terminology updates
**Task**: 217 - Prompt Refactor Package Rename
**PR**: #166
**Type**: Standard

## What Went Well

- Two-phase rename strategy (ace-prompt → ace-prep → ace-prompt-prep) worked cleanly with no conflicts
- Clean rebase against origin/main preserved all commits
- All tests pass across affected packages (ace-bundle, ace-prompt-prep)
- Comprehensive PR description documents all changes clearly
- Bundle terminology update (`--context` → `--bundle`, ContextLoader → BundleLoader) aligns naming with actual functionality
- Added preset/presets frontmatter support to ace-bundle as part of the work

## What Could Be Improved

- Task 217.01 and 217.02 could have been a single task since the intermediate ace-prep name was never released
- The two-stage rename added overhead without clear benefit given pre-1.0 status
- Worktree management added complexity vs single branch approach for this type of refactor

## Key Learnings

- Compound naming pattern (ace-git-commit, ace-prompt-prep) provides clearer semantics than abbreviated names
- Bundle terminology (`--bundle`) is more accurate than context terminology for describing what the tool loads
- ADR-024 (no backward compatibility pre-1.0) simplifies renames significantly - can make breaking changes directly
- When intermediate state won't be released, direct renames are more efficient than staged approaches

## Action Items

### Stop Doing

- Multi-stage renames when intermediate state won't be released

### Continue Doing

- Using compound naming patterns for clarity (ace-[tool]-[action])
- Aligning terminology with actual functionality (bundle vs context)
- Comprehensive PR descriptions documenting all changes

### Start Doing

- Consider direct renames when pre-1.0 and intermediate state serves no purpose
- Document compound naming convention in contributing guide

## Technical Details

**Packages affected:**
- `ace-prompt` → `ace-prompt-prep` (renamed)
- `ace-bundle` (updated ContextLoader → BundleLoader, added preset frontmatter support)

**Key changes:**
- Executable renamed: `ace-prompt` → `ace-prompt-prep`
- Module renamed: `AcePrompt` → `AcePromptPrep`
- CLI flag renamed: `--context` → `--bundle`
- Class renamed: `ContextLoader` → `BundleLoader`

## Additional Context

- Task file: `.ace-taskflow/v.0.9.0/tasks/drafts/217-prompt-refactor-package-rename.md`
- Branch: `217-rename-ace-prompt-to-ace-prep`
- Subtasks completed: 217.01, 217.02
