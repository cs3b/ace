---
id: 8r8e8n
title: e2e-stabilization-contract-drift
type: standard
tags: [e2e, workflow]
created_at: "2026-04-09 09:29:36"
status: active
---

# e2e-stabilization-contract-drift

## What Went Well

- The repeated investigation eventually separated three different failure classes that had been mixed together: bad artifact extraction, stale verifier oracles, and real scenario-precondition drift.
- Converting the E2E runner to fail early on missing required evidence exposed where the suite was inventing failures from bad contracts instead of actual product behavior.
- Pinpointing implementation evidence before changing scenario expectations worked when it was followed strictly; `ace-assign` and `ace-test-runner` both ended up needing spec fixes, not code fixes.
- Treating transformed output semantically instead of asserting brittle source strings fixed real false positives such as the `ace-bundle` README case.

## What Could Be Improved

- The E2E fix loop spent too long treating every failure as a generic `test_issue` instead of first classifying whether it was an artifact-parser bug, runner contract bug, verifier oracle bug, or actual behavior contradiction.
- The artifact manifest extraction was initially too naive and converted prose, suffixes, and examples into fake required files, which created a large number of false `missing-artifact` failures.
- Several scenarios encoded outdated product assumptions, especially around queue state semantics and exact artifact names, but the workflow did not force those assumptions to be checked against implementation early enough.
- Full-suite reruns were used too long as the main signal, which hid progress and amplified provider/statefulness noise.
- Release work happened while the suite still had unresolved contract drift, which made progress harder to reason about across iterations.

## Key Learnings

- E2E tests in this repo must default to semantic behavior checks, not exact text snapshots, unless exact wording is the product contract.
- Required runner artifacts need an explicit machine-safe grammar; optional evidence must never appear inside required capture sections.
- Stateful CLI scenarios need expectations derived from real state-machine behavior in code and unit tests, not intuitive English labels like "stalled" that may not match implementation.
- Provider variability amplifies weak contracts; it is not the first root cause. The first root cause is usually a bad runner or verifier contract.
- The most reliable unit of progress is a targeted scenario rerun after one fix, not another full suite run.

## Workflow Proposals

- Extend `wfi://e2e/fix` to require a pre-fix classification into one of: `artifact-parser bug`, `runner contract drift`, `verifier oracle drift`, `stateful precondition drift`, `real behavior contradiction`.
- Extend `wfi://e2e/analyze-failures` with an explicit check for transformed output so verifiers do not assert pre-transform literals against normalized output.
- Keep execution-tier metadata in scenarios and treat stateful packages as serial by default.
- Refuse release recommendations while a package is still red due to known contract drift in the active queue.

## Action Items

- Stop using free-form prose as an implicit artifact manifest; keep required artifacts only in explicit `Capture:` blocks.
- Add parser coverage for rejected pseudo-artifacts such as suffix references, wildcard examples, and directory mentions.
- Audit remaining E2E scenarios for exact-text assertions and convert them to semantic checks unless the product explicitly guarantees verbatim output.
- Require every lifecycle/stateful scenario to cite one implementation source and one unit-test source before changing a state expectation.
- Use targeted reruns as the primary loop and reserve suite reruns for checkpoints only.
