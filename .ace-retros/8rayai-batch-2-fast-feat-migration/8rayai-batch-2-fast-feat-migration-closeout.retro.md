---
id: 8rayai
title: batch-2-fast-feat-migration-closeout
type: standard
tags: []
created_at: "2026-04-11 22:51:41"
status: active
---

# batch-2-fast-feat-migration-closeout

## What Went Well

- The batch subtree structure scaled well for 16 package migrations because each package could carry its own plan, implementation, verification, release, and retro without blocking siblings.
- Package-level verification plus the later batch-level `ace-test-suite` gate caught both local regressions and cross-package drift before the PR closeout stages.
- Existing package docs and demo assets made the final polish steps efficient. Reusing the `ace-hitl` demo tape avoided inventing a new scenario under time pressure.
- Reorganizing the branch into 5 scope-based commits made the PR much easier to review than the original long sequence of task, release, retro, and fix commits.

## What Could Be Improved

- The initial batch-driving loop assumed hex-style subtree numbering after `010.09`; the actual assignment used decimal numbering (`010.10` ... `010.16`). That mismatch cost time and required manual recovery.
- Review-cycle execution exposed avoidable metadata/config issues: one reviewer role was misspelled as `review-geminie`, and some review-session directories lacked expected metadata files.
- Version-contract assertions remain a recurring failure mode during late release steps. `ace-hitl` required multiple follow-up fixes because the test literal lagged the released version line.
- Grouped-stats and PR generation are sensitive to unrelated local worktree changes. An unrelated unstaged task-spec edit forced fallback handling in the first PR draft and had to be isolated before commit reorganization.

## Key Learnings

- For assignment batch drivers, subtree numbering should be derived from `ace-assign status` rather than generated from assumptions about numeric formatting.
- Batch release workflows should distinguish between subtree package releases and top-level follow-up releases. The post-verification `ace-hitl` patch needed a targeted release, not a replay of the whole batch release set.
- Review Cycle Analysis:
  - The most useful repeated finding across review cycles was the stale `ace-hitl` version assertion. It surfaced independently in multiple review sessions and also showed up in the actual batch verification gate, which makes it a good signal rather than review noise.
  - The fit and shine cycles produced meaningful follow-up findings beyond the first valid pass, but they also showed some model/config fragility. One shine-cycle session failed immediately because of the misspelled `review-geminie` role, which is a tooling/config issue rather than a code-quality signal.
  - Codex contributed the most actionable concrete findings in the recorded sessions; Gemini also produced improvement-oriented feedback, but more of it was process or consistency advice rather than directly blocking defects.
  - The review sessions showed that release/test metadata drift is one of the highest-value things to check late in a multi-package branch. It is easy for version constants, changelogs, and contract tests to diverge after incremental patch releases.

## Action Items

- Update assignment batch-driving logic to enumerate pending fork roots from live assignment status instead of synthesizing subtree numbers.
- Add a small guard or helper around release workflows to verify `VERSION`, package changelog, and version-contract tests stay aligned before marking a release step done.
- Audit review workflow configuration for invalid reviewer role slugs and missing session metadata outputs so later cycles do not silently degrade.
- Improve PR generation resilience when unrelated unstaged files exist, ideally by sourcing file-change summaries strictly from the committed range by default.
