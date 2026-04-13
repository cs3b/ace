---
id: 8qby0u
title: ace-bundle exact-mode test optimization
type: standard
tags: [performance, testing, release]
created_at: "2026-03-12 22:40:56"
status: active
---

# ace-bundle exact-mode test optimization

## What Went Well
- Constrained the release cycle to exact-mode compression for tests by forcing `compressor_mode: "exact"` in test execution.
- Removed explicit agent-mode expectations from `ace-bundle` tests and converted coverage to exact-mode behavior.
- Kept changes localized to bundle tests and changelog/version files, minimizing release blast radius.
- Completed a coordinated package + root release update (version, package changelog, root changelog, lockfile, scoped commit).

## What Could Be Improved
- Running agent-mode compressor in tests required additional coordination across both molecule and loader tests; pre-existing helper abstractions made this cleanup straightforward but could be more discoverable.
- The workflow steps are currently documented as manual for some tasks; a single executable `as-release` path could reduce repeated manual follow-up.
- Retro creation remains scaffold-only by default and depends on manual population.

## Action Items
- Keep the test-suite-only compressor override behind a clearly-named env toggle and document it in test contributor docs.
- Add one regression assertion that verifies agent-mode compression can still be exercised when `ACE_BUNDLE_ALLOW_AGENT_COMPRESSION=1` is set.
- Add a small helper in `ace-bundle` release tooling to automatically generate a single commit with `--no-split` to avoid accidental split commits.
