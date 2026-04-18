---
id: 8rhjyf
title: e2e-contract-stabilization-and-release-boundaries
type: standard
tags:
  - e2e
  - release
  - verifier
  - workflow
  - monorepo
created_at: "2026-04-18 13:18:16"
status: active
---

# e2e-contract-stabilization-and-release-boundaries

## What Went Well
- The remaining red E2E cases were triaged correctly into three buckets: stale scenario/verifier contracts, one sandbox-root stabilization issue, and one evidence-quality gap around suite failure propagation. That kept the fixes narrow instead of reopening the harness broadly.
- The `ace-idea` path was handled with a deterministic guard before assuming a product bug. Adding a fast CLI regression around `list --in archive` gave us a stable proof point and kept the E2E scenario honest.
- Releasing only real gem packages from the working tree worked cleanly. The package set was scoped to releasable `ace-*` gems, version/changelog updates stayed coordinated, and the repo’s split-commit policy still produced a coherent release set.
- Leaving `ace-monorepo-e2e` out of the release and committing it separately was the right boundary. It kept the release metadata accurate while still preserving the scenario-only improvement in history.

## What Could Be Improved
- We spent too much time recovering from stale fixture-path assumptions in E2E prompts. Goal instructions need to name the actual sandbox fixture paths that exist after setup, not vague historical paths that used to work.
- Some E2E verifiers are still too sensitive to formatting thresholds or indirect evidence. Requiring “more than 5 lines” instead of judging whether the summary proves the contract is low-value friction.
- The release workflow still needs a mental override for non-gem directories like `ace-monorepo-e2e`. That distinction is clear once inspected, but the initial package auto-detect review should make it explicit sooner.
- Root `CHANGELOG.md` continues to accumulate dense unreleased entries during clustered release sessions. It remains correct, but readability is degrading.

## Key Learnings
- Scenario fixes should prefer stronger proof, not weaker assertions. The `ace-test-runner` change improved the test by adding a direct `ace-test` precheck for the injected failure instead of merely relaxing the suite-level verifier.
- When an E2E failure suggests a product bug, it is worth checking for a deterministic package-level proof before editing implementation. That prevented an unnecessary speculative `ace-idea` code change.
- Release boundaries matter in this repo: “changed top-level directory” is not the same as “releasable package.” Non-gem support trees need normal commits, not gem version bumps.
- Coordinated release commits remain manageable if the package list is pruned before editing version files. Once version/changelog edits begin, accidental extra package inclusion gets expensive.

## Action Items
- Update older E2E goals that still reference stale fixture paths so they point to the actual copied sandbox layout or explicitly describe fallback order.
- Continue replacing indirect aggregate-oracle checks with direct proof artifacts, especially in scenarios that inject failures or mutate test fixtures.
- Add a lightweight release checklist note or workflow guard that marks non-gem `ace-*` directories as non-releasable when they lack `version.rb` and `CHANGELOG.md`.
- Schedule a root changelog cleanup/squash pass if more coordinated patch releases land in the same unreleased window.
