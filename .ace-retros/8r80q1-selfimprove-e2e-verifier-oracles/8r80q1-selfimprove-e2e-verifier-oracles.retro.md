---
id: 8r80q1
title: selfimprove-e2e-verifier-oracles
type: standard
tags: [self-improvement, process-fix, e2e, verifier]
created_at: "2026-04-09 00:35:00"
status: active
---

# selfimprove-e2e-verifier-oracles

## What Went Well

- The failing `ace-bundle` case had enough artifact evidence to prove the product behavior was correct.
- The implementation path confirmed the formatter intentionally emits transformed structured output.
- The immediate issue could be fixed without changing product code.

## What Could Be Improved

- The E2E guide did not explicitly forbid brittle verifier checks against transformed output.
- The analysis workflow did not call out pre-transform literal assertions as a distinct `test-issue` pattern.
- This allowed provider variance to look like product instability when the real defect was a stale verifier oracle.

## Action Items

- Updated the E2E guide to require semantic or structural verifier checks for transformed output.
- Updated `analyze-failures` to classify brittle pre-transform literal checks as `test-issue`.
- Updated `fix` to forbid verifier-model escalation as the first response to brittle semantic failures.
- Fixed `ace-bundle` `TC-003` to verify semantic README inclusion instead of the literal heading string.
- Expected impact: transformed-output scenarios should stop oscillating based on verifier/provider compliance when the product behavior is already correct.
