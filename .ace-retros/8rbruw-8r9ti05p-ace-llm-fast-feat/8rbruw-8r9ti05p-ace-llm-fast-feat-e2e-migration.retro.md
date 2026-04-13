---
id: 8rbruw
title: 8r9.t.i05.p ace-llm fast-feat-e2e migration
type: standard
tags: [assignment, ace-llm, testing]
created_at: "2026-04-12 18:34:21"
status: active
---

# 8r9.t.i05.p ace-llm fast-feat-e2e migration

## What Went Well
- The migration cleanly moved deterministic tests to `test/fast` and `test/feat` while preserving package behavior.
- E2E scope was reduced with evidence: `TC-003` was removed and backfilled deterministically in `test/feat/cli_contract_test.rb`.
- Verification gates were fully green after adjustments:
  - `ace-test ace-llm`
  - `ace-test ace-llm feat`
  - `ace-test ace-llm all`
  - `ace-test-e2e ace-llm`
- Release flow completed in the same subtree: `ace-llm` was bumped to `v0.33.0` with package/root changelog updates.

## What Could Be Improved
- The first E2E rerun failed due sandbox setup path assumptions (`$PROJECT_ROOT_PATH` source path). Scenario setup should consistently use `${ACE_E2E_SOURCE_ROOT:-$PROJECT_ROOT_PATH}`.
- Model-selection verifier wording was too strict for credential-limited environments; explicit auth failure tied to the model target should be accepted from the start.
- Pre-commit fallback lint reported many non-blocking warnings; these were not release blockers but still create noise during review.

## Action Items
- Standardize setup commands in remaining package scenarios to the `${ACE_E2E_SOURCE_ROOT:-$PROJECT_ROOT_PATH}` pattern.
- Audit other retained E2E verifier files for the same “auth/config failure is acceptable evidence” contract where applicable.
- Track and reduce recurring markdown lint warning categories in task/spec/E2E docs to improve pre-commit signal quality.
