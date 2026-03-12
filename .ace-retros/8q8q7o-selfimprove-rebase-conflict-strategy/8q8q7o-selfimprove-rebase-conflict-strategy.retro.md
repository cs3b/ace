---
id: 8q8q7o
title: selfimprove-rebase-conflict-strategy
type: self-improvement
tags: [process-fix]
created_at: "2026-03-09 17:28:32"
status: active
---

# selfimprove-rebase-conflict-strategy

## What Went Well
- The rebase workflow already captured enough session state to make a process correction safe.
- The conflict happened in a narrow, understandable place (`CHANGELOG.md`), which exposed the policy problem clearly.

## What Could Be Improved
- The workflow treated any conflict as an automatic reason to abandon normal rebase and switch to cherry-pick.
- That policy was too coarse: a single localized conflict should stay on `git rebase --continue`, while cherry-pick should be reserved for repeated or high-coordination conflicts.
- The cherry-pick replay logic relied on commit-subject matching, which is weaker than explicit applied-SHA tracking.

## Action Items
- Updated `ace-git/handbook/workflow-instructions/git/rebase.wf.md` to make the first conflict a triage point instead of an automatic fallback.
- Added explicit guidance to continue normal rebase for small conflict sets and escalate to cherry-pick only for repeated, large, or user-requested conflict handling.
- Added session-local `applied-shas.txt` tracking so resumed cherry-pick replay uses explicit SHAs instead of subject matching.
- Expected impact: fewer unnecessary branch rewrites during rebases, better preservation of normal rebase flow, and safer recovery when cherry-pick escalation is actually needed.
