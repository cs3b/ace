---
id: 8qlvhx
title: t-q9b-batch-assignment
type: standard
tags: []
created_at: "2026-03-22 20:59:55"
status: active
task_ref: t.q9b
---

# t-q9b-batch-assignment

## What Went Well

- Fork subtree delegation worked well for implementation (010.01) and review cycles (070, 100) — parallel execution saved significant time.
- The fit review cycle (070) caught real architectural issues: config cascade bypass and shared policy extraction. These were genuine quality improvements.
- Reorganized commits produced clean, scope-grouped history from 20 interleaved commits.
- Full monorepo test suite (7712 tests, 33 packages) passed cleanly at every verification checkpoint.

## What Could Be Improved

- **Fork provider config keeps getting reset**: `.ace/assign/config.yml` provider was changed from `codex:codex@yolo` to plain `codex` by prior batch agents. This is the 4th occurrence. Forked agents should not modify orchestration config files.
- **Review feedback synthesis fragile**: Gemini quota exhaustion + Claude sonnet JSON parse error caused synthesis failure in the valid review cycle. Manual extraction from raw reports was needed.
- **Fork retry creates orphan steps**: `ace-assign retry` created top-level sibling steps (031, 032) instead of children inside the 040 subtree, violating the recovery constraint. Required manual queue management.
- **Network transience handling**: First fork-run for review-valid-1 failed due to GitHub API connectivity. The second re-fork also failed because the config hadn't propagated yet.

## Key Learnings

### Review Cycle Analysis
- Valid cycle (code-valid): 3 models reviewed. All 3 converged on the config cascade bypass in ace-lint — high-confidence finding. Rescue path issue caught by 2/3 reviewers.
- Fit cycle (code-fit): Extracted shared `FrontmatterFreePolicy` into ace-support-core. This was a genuine architectural improvement that wouldn't have surfaced without multi-model review.
- Shine cycle (code-shine): No actionable findings remained — previous cycles had addressed all substantive issues.
- False positive rate was low (~15%) — most findings were real issues.

## Action Items

- **Stop**: Forked agents modifying `.ace/assign/config.yml` — needs a guard or read-only marker in fork execution context.
- **Continue**: Multi-model review cycles — convergent findings across 3 reviewers indicate real issues.
- **Start**: Investigating why `ace-assign retry` creates top-level steps instead of subtree children during fork recovery.
