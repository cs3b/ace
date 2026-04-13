---
id: 8qki2c
title: h5e-e2e-coverage-batch
type: standard
tags: [e2e, batch, assignment]
created_at: "2026-03-21 12:02:37"
status: active
task_ref: 8qe.t.h5e
---

# h5e-e2e-coverage-batch

## What Went Well

- **Fork-based parallelism worked reliably**: 27 sequential fork-run subtrees completed successfully (26 clean, 1 recovered from pre-existing test failures). The fork delegation pattern provided clean context isolation for each package's E2E review/plan/rewrite lifecycle.

- **Consistent E2E lifecycle across packages**: The 3-stage pattern (review → plan-changes → rewrite) produced uniform quality — every package got a coverage matrix, change plan with ADD/KEEP/MODIFY/REMOVE/CONSOLIDATE decisions, and targeted rewrites. Decision records for new packages provide clear value-gate evidence.

- **Review cycles found minimal real issues**: 3 review cycles (valid/fit/shine) across 21 total feedback items yielded only 1 genuine fix (TC reference typo). This suggests the fork subtrees produced high-quality output with good self-review during pre-commit steps.

- **Commit reorganization was clean**: ace-git-commit's scope-based grouping turned 61 interleaved commits into 28 clean per-package commits without manual intervention.

- **Test suite remained green throughout**: 6384 tests, 16853 assertions, 0 failures across 33 packages after all changes. Per-package verification during each fork ensured no regressions.

## What Could Be Improved

- **ace-git-commit provider unavailability was pervasive**: Nearly every fork subtree reported that ace-git-commit failed due to LLM provider/network unavailability, requiring manual `git commit` fallback. This happened consistently across all 27 forks, suggesting the Codex provider used by forks lacks reliable access to the commit message generation models.

- **GitHub API unavailability blocked review fork delegation**: The valid review fork (040) failed twice due to GitHub API connection errors. The circuit breaker and inline execution fallback worked, but required manual intervention from the driver. The fork provider (codex) apparently can't reach api.github.com reliably.

- **Fork subtree step 040 left orphaned failed state**: After the fork failed and the driver executed the review inline (step 031), the 040 subtree remained in a failed state. The assignment shows both the failed 040 fork and the successful 031 inline execution. This creates confusing status output but doesn't block progress.

- **Batch continuation without user confirmation**: The workflow processed all 27 forks sequentially without pause points. For a batch this large, intermediate checkpoints (e.g., after every 10 tasks) could help catch systematic issues earlier rather than discovering them across all 27 subtrees.

- **ace-test-runner-e2e pre-existing test failures**: The verify-test step for task 8qe.t.h5e.o failed due to pre-existing molecule test failures (TestExecutorTest, SetupExecutorTest tmux-session issues) unrelated to the E2E changes. These pre-existing failures in the baseline should be tracked separately.

## Key Learnings

- **Fork providers have different network capabilities than the driver**: The Codex fork provider couldn't reach GitHub API or LLM providers for commit generation, while the driver (Claude Code) had no issues. This asymmetry matters for steps that require external API access (reviews, commit generation).

- **E2E-only changes are inherently low-risk**: Since this batch only modified test scenario files (markdown/YAML) and not package source code, all release steps were correctly identified as no-ops. The verify-test-suite step confirmed no regressions. The review cycles found almost nothing because there's little to get wrong in test scenario files.

- **The assignment framework handles large batches well**: 27 fork subtrees × 7 steps each = 189 sub-steps, plus 13 top-level steps = ~200 total steps managed cleanly. The sequential batch container pattern with fork delegation scales effectively.

## Action Items

### Continue
- Use fork-run for context isolation on per-task work — it keeps the driver context clean
- Use inline execution fallback for LLM-tool steps when fork providers can't reach external APIs
- Run ace-test-suite as cross-package regression check after batch completion

### Start
- **Track pre-existing test failures**: Create a task to fix ace-test-runner-e2e molecule test failures (TestExecutorTest, SetupExecutorTest)
- **Add fork provider capability checks**: Before delegating review steps to forks, verify the fork provider can reach required APIs (GitHub, LLM providers)
- **Consider intermediate batch checkpoints**: For batches > 15 items, add a driver-level quality gate after every N completions

### Stop
- Retrying fork-run more than once for the same network failure — the circuit breaker (1 retry) is sufficient; further retries waste time on persistent outages

## Automation Insights

- The `ace-assign fork-run` + `ace-assign start` + sequential loop pattern is effective but verbose. A higher-level `ace-assign drive-batch --sequential` command could encapsulate the start→fork→verify-reports→advance cycle.
- Fork crash recovery (commit partial work → inject recovery steps → re-fork) worked as documented but required careful manual orchestration. Automating the detection of "pre-existing vs new" test failures would reduce false fork failures.
