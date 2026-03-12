---
id: 8q8h15
title: typed-canonical-skill-platform
type: standard
tags: []
created_at: "2026-03-09 11:21:16"
status: active
task_ref: 8q5.t.0or
---

# Typed Canonical Skill Platform Retro

## What Went Well

- **Sequential fork delegation worked reliably**: 7 fork subtrees executed sequentially via `ace-assign fork-run`, each producing clean commits and reports. The fork isolation model kept context manageable for each subtask.
- **Driver-side release recovery was smooth**: When forks failed at `release-minor` (ace-release unavailable in fork env), the driver recovered inline — bumping versions, updating changelogs, committing, and advancing the queue without re-forking.
- **Full test suite stayed green throughout**: 7478 tests across 32 packages passed after all changes. No cross-package regressions despite touching 8 packages.
- **Commit reorganization was effective**: 38 incremental commits collapsed into 11 clean scope-grouped commits via `ace-git-commit` auto-grouping.
- **Review circuit breaker prevented wasted cycles**: When the valid review fork failed on provider unavailability, the driver correctly skipped fit and shine cycles instead of retrying in a loop.

## What Could Be Improved

- **ace-release unavailable in fork environments**: Forks 010.03 and 010.05 both failed at `release-minor` because `ace-release` executable wasn't in the bundle. This is a recurring environment issue — forks should either have access to release tooling or the release phase should be a driver-only phase (not inside fork subtrees).
- **Failed fork children leave batch containers in "pending" state**: 010.03 and 010.05 show 6/7 done with a failed release child, making the batch container (010) appear incomplete even though all work was done. The retry mechanism (phase 011) doesn't retroactively close the parent.
- **Uncommitted fork work accumulates across subtrees**: Forks 010.02 and 010.03 left uncommitted changes that the driver had to commit manually. The fork boundary should ensure all work is committed before exiting, even on failure.
- **Provider unavailability blocks LLM-dependent review phases**: The valid review cycle couldn't complete because neither codex nor claude providers were available. No fallback exists for review when all providers are down.

## Key Learnings

- **Release phases belong at the driver level, not inside fork subtrees**: Forks are for context-isolated code work. Release tooling depends on the full mono-repo environment which forks may not have.
- **Fork crash recovery is well-documented but rarely needed for code phases**: All 7 code work phases succeeded. Failures were exclusively in tooling/environment phases (release, review).
- **Batch container completion tracking doesn't account for driver-recovered children**: When the driver does the work that a failed fork child was supposed to do, the batch container doesn't know about it.

## Action Items

### Start
- Move `release-minor` phase out of fork subtrees and into driver-level post-fork phases (or make it conditional on ace-release availability)
- Add a `--commit-on-exit` flag or default behavior to fork-run so uncommitted work is always saved before the fork exits

### Continue
- Using sequential fork delegation for multi-task batches
- Driver-side inline recovery for LLM-tool phases during provider outages
- Review circuit breaker for provider unavailability

### Stop
- Including release phases inside fork subtrees when the fork environment doesn't have release tooling

