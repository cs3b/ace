---
id: 8pke7r
title: "Retro: E2E Test Fixes — Patch Releases"
type: standard
tags: []
created_at: "2026-02-21 09:28:36"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8pke7r-e2e-test-fixes-patch-releases.md
---
# Retro: E2E Test Fixes — Patch Releases

**Date**: 2026-02-21
**Context**: Patch release cycle fixing E2E test fragility across 4 packages (ace-assign v0.12.6, ace-git-worktree v0.13.8, ace-overseer v0.4.5, ace-test-runner-e2e v0.16.8)
**Author**: cs3b / Claude
**Type**: Standard

## What Went Well

- All 4 fixes were small and targeted — clear root causes, no workarounds or hacks
- The boolean/nil filter bug in worktree was caught and covered with regression tests immediately after fixing
- The `short_id` regex fix was a one-liner; adding edge-case tests was straightforward
- Releasing all 4 packages in a single session kept context tight and reduced overhead

## What Could Be Improved

- **Hardcoded tmux session names**: `ace-e2e-test` was hardcoded in 3 places in ace-overseer E2E tests — should always use `$ACE_TMUX_SESSION` from the start
- **Test definition files not copied to sandbox**: `TestOrchestrator` silently failed to find `.tc.md` files in the sandbox — failure was opaque and hard to diagnose without reading internals
- **Regex too narrow from inception**: `[A-Z]+` in `short_id` excluded digits (`B36TS`, etc.) — the constraint was never intentional, just incomplete
- **Boolean/nil conflation**: worktree filter used `if options[:key]` rather than `if !options[:key].nil?`, silently treating `false` as "not provided"
- **`task_root_path` not forwarded to TaskLoader**: `WorkOnOrchestrator` instantiated `TaskLoader.new` without a path, relying on implicit `Dir.pwd` — breaks in worktree environments where `PROJECT_ROOT_PATH` differs from cwd

## Key Learnings

- **Explicit nil checks over truthiness for boolean flags**: In Ruby, `false` and `nil` are both falsy but carry different intent for optional boolean options. Use `!opt.nil?` when `false` is a valid value (e.g., filtering with `task_associated: false`).
- **E2E sandbox isolation is not automatic**: Files used by the test runner must be explicitly copied into the sandbox. Never assume tools discover their inputs through the host filesystem.
- **Regex character classes should be liberal by default for identifiers**: `[A-Z]+` is fragile for identifiers that may include digits. Default to `[A-Z0-9]+` unless digits are genuinely excluded by spec.
- **Env-var-aware path resolution belongs at construction time**: Organisms that resolve paths should accept a resolved path as a constructor parameter — not discover it lazily from `Dir.pwd`, which is environment-dependent.
- **Hardcoded environment names in E2E scripts cause silent breakage**: Any test referencing session names, directory names, or IDs literally will silently fail (or worse, pollute) in different environments.

## Action Items

### Stop Doing
- Hardcoding tmux session names (or any environment-specific strings) in E2E test scripts
- Writing `if options[:flag]` when `false` is a meaningful value for the flag
- Assuming test runner infrastructure files are available in the sandbox without explicit copy steps

### Continue Doing
- Adding regression tests immediately after fixing a boolean/nil conflation bug
- Keeping patch fixes small and surgical — one concern per commit
- Testing `short_id`-style formatting helpers with edge-case inputs (digits, suffixes, mixed case)

### Start Doing
- Using `$ACE_TMUX_SESSION` (or equivalent env vars) wherever environment names appear in E2E scripts — never literals
- Adding a sandbox file inventory step to `TestOrchestrator` setup to surface missing files early rather than at execution time
- Including a nil-vs-false check in filter method PR review checklist items

## Technical Details

- `ace-git-worktree/lib/…/organisms/worktree_manager.rb:283`: Changed `if options[:task_associated] || options[:usable]` → `if !options[:task_associated].nil? || !options[:usable].nil?`
- `ace-test-runner-e2e/lib/…/models/test_scenario.rb`: Changed `TS-[A-Z]+-` → `TS-[A-Z0-9]+-` in `short_id` regex
- `ace-overseer/lib/…/organisms/work_on_orchestrator.rb`: Added `task_root_path` private method resolving `ENV["PROJECT_ROOT_PATH"]`; passed to `TaskLoader.new`
- `ace-test-runner-e2e/lib/…/organisms/test_orchestrator.rb`: Added `copy_scenario_definitions` that copies `.tc.md` + `scenario.yml` into sandbox before execution

## Additional Context

PR #210: feat(task-273): namespace workflows with domain prefixes
Releases: ace-assign v0.12.6, ace-git-worktree v0.13.8, ace-overseer v0.4.5, ace-test-runner-e2e v0.16.8
