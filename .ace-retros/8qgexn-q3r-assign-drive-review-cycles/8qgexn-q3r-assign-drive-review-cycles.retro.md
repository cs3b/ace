---
id: 8qgexn
title: q3r-assign-drive-review-cycles
type: standard
tags: [assignment, review, fork-delegation]
created_at: "2026-03-17 09:57:24"
status: active
---

# q3r-assign-drive-review-cycles

## What Went Well

- **Inline review recovery worked**: When fork-run failed twice due to GitHub API unreachable from the codex fork environment, the driver correctly classified review-pr as an LLM-tool phase and executed the review inline. All three review cycles (valid, fit, shine) completed successfully without fork delegation.
- **Assignment state management was robust**: Despite 16 historical failures across cycles 1 and 2, the assignment queue correctly tracked all phases. Phase injection (`ace-assign add`) and finish/fail transitions worked reliably.
- **Conditional release rule prevented unnecessary churn**: All three review cycles found no actionable issues, so the release phases correctly skipped version bumps (no-op), avoiding empty releases.
- **PR description update was evidence-based**: The `ace-git diff --format grouped-stats` output provided a clean, structured file change summary that was pasted verbatim into the PR body.
- **Circuit breaker logic applied correctly**: Review cycle 1 failures (network + PR too large) were properly superseded by cycle 2, avoiding infinite retry loops.

## What Could Be Improved

- **Fork environment GitHub API connectivity**: The codex fork provider consistently failed to reach `api.github.com` (3 attempts across 2 fork-runs), while the driver had no connectivity issues. This forced all review work inline, defeating the context isolation benefit of fork delegation. Root cause: likely network sandbox restrictions in the codex provider environment.
- **ace-llm invocation unclear for file-based prompts**: After `ace-review` prepared the session, the suggested `ace-llm --file` command didn't work (`--file` is not a valid flag). The ace-llm help shows `--prompt` and `--system` but both expect text strings, not file paths. There's no documented way to pipe a large file-based prompt into ace-llm from the command line.
- **Auto-inserted retry phases at wrong level**: When finishing phase 160.01.02 (inline review), the queue auto-inserted phase 151 as a top-level retry of 160.01. This created an unexpected phantom phase that had to be manually finished. The retry injection should respect the subtree boundary.
- **Assignment remains in "failed" state**: Even though all actionable work completed (phases 000–210), the assignment shows `state: failed` because historical failures (cycle 1, 010.04.04) are never cleared. There's no mechanism to mark an assignment as "completed with historical failures resolved."
- **`gh pr diff --name-only` still hits 300-file limit**: Even though `gh pr view --json files` returned 100 files, the diff endpoint still reported 300+ file limit. This inconsistency suggests the file count differs between the files API and the diff API.

## Key Learnings

- **Fork-run is not suitable for phases that need GitHub API access in sandboxed providers.** When the fork provider can't reach external APIs, the driver must handle LLM-tool phases inline. This is a known workflow pattern but needs better detection — ideally fork-run should report "network unreachable" distinctly from "provider unavailable."
- **Transient vs permanent failure distinction matters.** The workflow's circuit breaker rules (retry once for transient, skip for permanent) were the right framework but the failure was misclassified. The GitHub API was reachable from the driver but not from the fork — this is a permanent environment limitation, not a transient network issue.
- **Review cycles on large PRs with no code changes are pure overhead.** When apply-feedback yields no findings in all three cycles, the entire review-release loop is wasted. A fast-path skip ("if valid review finds no issues, skip fit and shine") would save significant time.

## Action Items

### Stop
- Stop attempting fork-run for review phases when the codex provider is known to lack GitHub API access. Detect this on first failure and switch to inline immediately.

### Continue
- Continue using conditional release skips — they correctly prevented empty version bumps across all three review cycles.
- Continue the inline review fallback pattern for LLM-tool phases during fork failures.

### Start
- **Investigate codex fork network restrictions**: Determine why `api.github.com` is unreachable from fork-run subprocesses and whether this is configurable.
- **Add file-path support to ace-llm**: Support `--prompt @file.md` or `--prompt-file path` syntax so that large prepared prompts can be passed without shell argument limits.
- **Consider review cycle fast-path**: If the valid review cycle finds zero actionable findings, allow the assignment to skip remaining fit/shine cycles when no code changes are expected.

## Workflow Proposals

- **Fork capability detection**: Before fork-run, probe whether the fork environment can reach required external APIs (GitHub, LLM providers). If not, fail fast with a clear "environment limitation" error rather than retrying.
- **Assignment completion semantics**: Add an `ace-assign complete` command that marks an assignment as "done" even when some historical phases are failed, provided all actionable phases are complete. This avoids the perpetual "failed" state on assignments where all work is actually done.
