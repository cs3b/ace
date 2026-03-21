---
id: 8qkop7
title: docs-overhaul-core-readmes
type: standard
tags: []
created_at: "2026-03-21 16:28:00"
status: active
task_ref: 8q4.t.ums
---

# Documentation Overhaul: Core Package READMEs

Batch: 8q4.t.ums.0–.4 (root, ace-bundle, ace-task, ace-review, ace-git-commit)
Assignment: 8qkmvy | PR: #251

## What Went Well

- **Scoped commit tool**: ace-git-commit correctly separated changes by package scope, producing clean per-package commits without manual intervention
- **Fork delegation model**: All 5 tasks completed their core documentation work through fork-run, demonstrating the batch assignment pattern works for parallelizable doc tasks
- **Consistent output quality**: All fork agents produced READMEs in the same landing-page structure and getting-started guides with similar depth, despite running independently
- **Net reduction of 2067 lines**: Replaced verbose reference manuals with focused landing pages + tutorials — better information density

## What Could Be Improved

- **VHS runtime broken**: Every task hit the same VHS segfault (`randomPort()` nil pointer dereference). Demo tapes were written but no GIFs could be recorded. This blocked the work-on-task step in all 4 package tasks (010.02–010.05), requiring manual crash recovery each time
- **Fork provider connectivity**: All 3 review cycles (valid, fit, shine) failed because the codex fork provider couldn't reach GitHub API. The driver had to circuit-break all review cycles
- **ace-git-commit provider unavailability in forks**: Fork agents couldn't use ace-git-commit for LLM-generated messages (providers unavailable), falling back to manual git commits
- **Crash recovery overhead**: Each failed fork required: check status → read failure → check uncommitted files → commit partial work → add completion step → advance queue. This 6-step recovery repeated 4 times for the same root cause
- **Subtree won't auto-complete with failed steps**: Even when all meaningful work is done, a single failed step (VHS crash) prevents subtree auto-completion, requiring injected top-level acknowledgement steps

## Key Learnings

- **Docs-only batches don't need release/test/e2e steps**: All release, verify-test, and verify-e2e steps correctly resolved as no-ops. For future docs-only assignments, these steps could be omitted from the job template
- **Fork crash recovery is repetitive for systemic failures**: When the same environment issue affects all forks, recovery should be batched rather than per-fork
- **Review cycles need connectivity fallback**: When fork providers can't reach GitHub, the driver should attempt review inline rather than circuit-breaking all cycles

## Action Items

- **STOP**: Including release-minor, verify-test, verify-e2e steps in docs-only assignment templates — they always resolve as no-op
- **CONTINUE**: Using scoped commits via ace-git-commit for multi-package changes — produces clean history
- **CONTINUE**: Fork delegation for independent task batches — works well when providers are healthy
- **START**: Investigating VHS runtime crash (segfault in randomPort) — blocks all demo recording
- **START**: Adding connectivity health check before launching fork-run for review cycles — fail fast instead of waiting for timeout

