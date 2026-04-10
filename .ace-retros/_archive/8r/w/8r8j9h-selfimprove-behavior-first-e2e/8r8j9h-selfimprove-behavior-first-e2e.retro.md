---
title: Behavior-first E2E runner and verifier contracts
type: standard
tags:
  - self-improvement
  - e2e
  - process-fix
status: active
---

# What happened

Multiple E2E scenarios stayed red because the runner/verifier contract depended on synthetic support artifacts instead of the product behavior.

# Actual result

The suite was sensitive to agent style and artifact naming drift. `ace-b36ts` was the clearest example: the tool printed the correct token, but the TC failed because it expected a token-named file.

# Expected result

Runners should capture a small deterministic evidence set, and verifiers should judge behavior from command output and real state.

# Root cause

- Missing validation
- Missing example
- Ambiguous instructions

The handbook did not explicitly separate:
- command captures
- state oracles
- optional support artifacts

# Fix applied

- Updated the E2E guide to define artifact classes and behavior-first runner/verifier rules.
- Updated `analyze-failures` to classify synthetic artifact oracles as `test-issue`.
- Updated `fix` to prefer removing synthetic artifact requirements over adding more captures.
- Converted `ace-b36ts` `TC-002` into the reference example: verify the token from stdout instead of from a token-named file.

# Expected impact

- Fewer false positives from artifact drift
- Better portability across providers and agent styles
- Simpler runner files and more semantic verifiers
