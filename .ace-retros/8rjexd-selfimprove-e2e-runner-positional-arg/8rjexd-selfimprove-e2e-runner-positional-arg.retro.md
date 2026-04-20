---
id: 8rjexd
title: selfimprove-e2e-runner-positional-arg
type: standard
tags: [self-improvement, process-fix]
created_at: "2026-04-20 09:57:05"
status: active
---

# selfimprove-e2e-runner-positional-arg

## What Went Well
- e2E release command was validated against actual CLI usage before retrying publish verification.
- Found and fixed all stale references in release handbooks in one pass, preventing repeat command failures.

## What Could Be Improved
- Ambiguous workflow documentation still contained a legacy positional pattern (`--test-id`) that did not match current CLI syntax.
- Process guidance should include a direct validation checkpoint for e2e command format before publishing steps are finalized.

## Action Items
- Update `.ace-handbook/workflow-instructions/release/rubygems-publish.wf.md` and `.ace-handbook/workflow-instructions/release/publish.wf.md` to use:
  - `ace-test-e2e ace-monorepo-e2e TS-MONO-001`
  instead of:
  - `ace-test-e2e ace-monorepo-e2e --test-id TS-MONO-001`
- Add/update verification in release workflows (or release checks) to catch stale command syntax in handbooks before execution.
- Confirm immediate issue fix by scanning for remaining `ace-test-e2e ... --test-id` usages and keeping this scan in the self-improve habit.
