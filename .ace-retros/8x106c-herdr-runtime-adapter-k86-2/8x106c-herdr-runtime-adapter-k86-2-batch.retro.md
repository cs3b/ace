---
id: 8x106c
title: herdr-runtime-adapter-k86-2-batch
type: standard
tags: [ace-herdr, ace-runtime, adapter]
created_at: "2026-10-02 00:07:04"
status: active
---

# herdr-runtime-adapter-k86-2-batch

Batch retro for 8wq.t.k86.2 (ace-runtime herdr adapter), run as assignment 8x0z2t (work-on-task preset) in worktree `.ace-wt/k86-2-herdr-runtime-adapter`, PR #356.

## What Went Well

- **Vertical-slice spec quality paid off.** The k86.0 contract (shared suite + error model + send matrix) made the herdr adapter a well-bounded implementation: the forked agent implemented all 11 ops and passed the packaged acceptance bar on the first implementation commit, with only conventional nits surfacing later.
- **Fork subtree delegation worked end-to-end in headless mode.** With tmux absent, `launch_mode: auto` fell back to a background `codex exec` session; scoped status (`--assignment id@010.01`) was sufficient to monitor, and the 9-step subtree (onboard → task-load → plan → work → pre-commit-review → verify → release → retro) completed 9/9 with clean commits and reports.
- **Plan artifact reuse.** The cached plan (`.ace-local/task/8wq.t.k86.2/8x0yzh-plan.md`) was generated once in the shared checkout and copied into the worktree; the forked agent executed its 7 steps without regenerating.
- **Suite-failure triage had a fast, decisive path.** 5 failing packages in `ace-test-suite` were proven pre-existing by (a) identical failures on clean main and (b) standalone green runs of each package on the changed branch — no time lost chasing environment flakiness.

## What Could Be Improved

- **`ace-git-worktree create --task` still crashes** (`private method 'commit_scoped' called`) — the known 0.22.0-era bug persists; branch-based creation plus manual `ace-task update --set status=in-progress` is the working path. Task-aware worktree metadata (worktree.frontmatter) is silently missing on task-aware flows that use the fallback.
- **Suite-context flakiness masks real regressions.** ace-assign/ace-review time out at 120s under full-suite parallel load, ace-idea depends on host clipboard state, ace-test-runner's hermetic test hits a LoadError. Every delivery re-proves these are pre-existing; the noise tax recurs per batch.
- **Attempt receipts require in-project artifact paths.** `/tmp` artifact paths are rejected (`escapes project root`) and URLs are rejected (`file not found`); the first receipt submission for the create-pr step failed twice before landing on `.ace-local/assign/<id>/artifacts/`.
- **Fork pre-commit-review degraded to lint-only.** The subtree's pre-commit-review step could not run native `/review` in the fork's API environment and fell back to `ace-lint`; the real review burden shifted entirely to the assignment-level review-pr step.
- **ace-task archive deferral is correct but surprising.** `--move-to archive` silently keeps a subtask in place when sibling subtasks are non-terminal; the Info line is easy to miss in automation logs.

## Key Learnings

- **Branch names from `ace-git-worktree create <branch>` preserve dots** (`k86.2-...`); refspecs must use the exact name — `git push origin <typed-name-with-dashes>` fails confusingly ("src refspec does not match any") when dashes were assumed.
- **Local `main` can run far ahead of `origin/main` during parallel streams** (28d657952 vs 5bdc5c1f8 here). Rebasing a task branch onto local main would drag unrelated unpushed commits into the PR; the correct base check is `git rev-parse origin/main` vs the branch merge-base.
- **The herdr pane-exited model composes cleanly with the contract**: a missing pane satisfies `pane-exited` but keeps `pane-exists` polling — condition-specific `pane_not_found` semantics are what let wait-for-creation and wait-for-exit share one transport.
- **Identity records for idempotent ensure_window** (root/preset provenance under `.ace-local/herdr/runtime-tabs/` with flock + atomic write) solve the "tab found by an earlier adapter instance" freshness risk the plan called out.

## Action Items

- **Fix `ace-git-worktree create --task`** (commit_scoped visibility crash) or remove the broken path in favor of an explicit task-aware branch flow. Owner: ace-git-worktree maintainers; candidate follow-up task.
- **Quarantine suite-context-flaky tests** (ace-idea clipboard test, ace-test-runner hermetic LoadError) behind explicit environment gates, and raise or shard the per-package suite timeout for ace-assign/ace-review so full-suite runs are signal again.
- **Document receipt artifact rules** (paths must exist inside the project; no URLs) next to the `attempt finish` usage docs to save the two failed submissions per new user.
- **Consider surfacing archive-deferral as a first-class result** (`--move-to archive` → "deferred: N non-terminal siblings") rather than an Info line.

## Addendum (2026-10-02): review-campaign outage and reviewer substitution

The review-pr step consumed the entire 10-session review budget (binding policy) without completing a single campaign round:

- **Root cause**: the `review-gemini` leg is dead machine-wide — Gemini CLI auth for individuals is deprecated (`IneligibleTierError`, migrate to Antigravity), and the folder-trust error masked it early on. `claude` is also dead (OAuth expired). Every campaign session that recorded a failed leg can never count: ace-review's campaign evidence validator (main commit 6a2c2cd4c) requires **all** configured legs to succeed, and the review runner deliberately disables role fallback (`fallback: false`).
- **Compounding trap**: campaign round pins are immutable per head, collection receipts and evidence validation bind the live head, and recording requires a clean committed tree — so any fix commit between pin/collect/record kills the round. Seven of the eight sessions died to these two mechanisms, not to review findings.
- **What landed anyway**: 19 findings verified across sessions (2 critical, 5 high) — unowned-tab closure protection (exact-id rollback via the new `TabMaterializationError`), authoritative workspace context, workspace+label identity locks, prepared-pane reuse and pointer records, contract error translation. Plus reviewer-infra fixes: `review-secondary` role on `zai:glm-4.7@ro` (working, API-based) wired into code-valid/code-fit, `zai/ro` preset, campaign workflow knowledge.
- **Action item (urgent)**: re-auth gemini or migrate `review-gemini` roles project-wide to zai/agy; consider making the campaign validator accept sessions where at least one reviewer per scope completed (matching the review-pr workflow text) instead of requiring all legs.
