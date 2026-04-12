---
id: 8q7hkv
title: preset-suffix-migration
type: standard
tags: [assign, refactoring, multi-package]
created_at: "2026-03-08 11:43:12"
status: active
task_ref: vyn
---

# Preset Suffix Migration Retro

## What Went Well

- **Task spec quality**: The behavioral spec had precise file locations, line numbers, and before/after examples for all 28 deliverables. The fork agent executed the implementation with zero ambiguity.
- **Preset system already worked**: ace-llm's `@preset` system was fully functional — this was pure cleanup with no new feature work needed.
- **Fit review caught real issues**: The code-fit review found a leftover `cli_args_map` in `plan.rb` and a stale test in ace-idea that the implementation missed. The 3-cycle review process added genuine value.
- **Net deletion**: -372 lines across 5 packages. Removing duplicated provider flag mappings reduces the surface area for the provider-mismatch crash that motivated this task.
- **Test suite stayed green throughout**: 7640 tests, 0 failures at every verification checkpoint.

## What Could Be Improved

- **Fork didn't commit implementation**: The codex fork executed all changes but left them uncommitted in the working tree. The driver had to discover this during the reorganize-commits phase and create the commit manually. This wasted a phase and caused confusion about branch state.
- **Multi-package release blocked fork**: The `release-minor` phase (020.07) failed because `as-release` expects a single package target. The assignment preset should either skip in-fork release for multi-package tasks or provide a multi-package release phase variant.
- **020 container stuck as "Pending"**: After recovering 020.07 via retry (021), the 020 container never auto-resolved to Done because 020.07 remained Failed. This is cosmetic but confusing in status output.
- **Unrelated uncommitted changes accumulated**: The working tree had ~10 unrelated modified files (assign presets, handbook guides, etc.) from other concurrent worktrees or tool updates. These appeared in `git status` warnings throughout the workflow.

## Key Learnings

- **Codex fork commit behavior**: Codex-based forks may not auto-commit implementation changes. The driver should verify `git status --short` after fork-run completes and commit any unstaged implementation work before proceeding.
- **Release phase design for cross-cutting tasks**: Tasks that touch 5+ packages need a different release strategy than single-package tasks. Either: (a) the assignment composer detects multi-package scope and uses a batch-release phase, or (b) the fork's release phase iterates packages from the diff.
- **Driver as quality gate works**: Reading fork reports before advancing caught no issues this time (valid review was clean), but the fit review's fork did find real problems. The guard pattern is justified.

## Action Items

### Continue
- **3-cycle review process**: Valid/fit/shine caught a real leftover in plan.rb. Keep this for non-trivial refactoring tasks.
- **Detailed task specs with line numbers**: The precision of the spec enabled the fork to execute autonomously with minimal back-and-forth.

### Start
- **Post-fork commit verification**: Add a driver-side check after fork-run: if `git status --short` shows implementation-related uncommitted files, commit them before proceeding to release/review phases.
- **Multi-package release phase**: Create an `as-release-batch` variant or teach `release-minor` to iterate modified packages from `git diff --stat`.

### Stop
- **Assuming fork commits are complete**: Don't trust that fork-run committed everything — always verify working tree state after fork completion.
