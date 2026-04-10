---
id: 8r7x6l
title: selfimprove-e2e-classification-gates
type: standard
tags: [self-improvement, process-fix, e2e, workflow]
created_at: "2026-04-08 22:07:20"
status: active
---

# selfimprove-e2e-classification-gates

## What Went Well

- The failure pattern was identified while the E2E reruns were still in progress, so the process issue could be fixed before more drift accumulated.
- The branch already had concrete examples of all three failure classes: runner infrastructure, stale scenario contracts, and real code-risk candidates.
- The workflow change could be kept narrowly scoped to the two E2E workflow instruction files.

## What Could Be Improved

- E2E analysis allowed `test-issue` conclusions without making implementation inspection a hard gate.
- The fix workflow assumed upstream classification quality and allowed execution to continue when the desired behavior source was still implicit.
- This created extra loops where runner/verifier artifacts were corrected before the behavior contract was grounded in code, tests, or CLI docs.

## Action Items

- Added mandatory implementation-backed classification to `ace-test-runner-e2e/handbook/workflow-instructions/e2e/analyze-failures.wf.md`.
- Added desired-behavior-source and implementation-evidence fields to the analysis output contract.
- Added fix-workflow gates in `ace-test-runner-e2e/handbook/workflow-instructions/e2e/fix.wf.md` so `test-issue` fixes cannot proceed without implementation-backed justification.
- Added explicit examples for artifact drift, stale command contracts, and mixed evidence to reduce future misclassification.
- Expected impact: future `as-e2e-fix` loops should classify failures from artifacts + scenario + implementation together before editing tests or product code.
