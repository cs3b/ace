---
id: 8wq.t.1w2
status: in-progress
priority: high
created_at: "2026-09-27 01:15:38"
estimate: TBD
dependencies: []
tags: [ace-test, hermetyczność]
position: 6o0000
bundle:
  presets: [project]
  files: [ace-test/README.md, ace-test/lib/ace/test.rb]
  commands: []
needs_review: false
title: Isolate package tests from ambient Lab and user configuration
---

# Isolate package tests from ambient Lab and user configuration

## Behavioral Specification

### User Experience

A developer runs package tests on a Lab host or clean machine and gets the same behavior regardless of live Lab environment variables, sockets and user configuration.

### Expected Behavior

- Deterministic test subprocesses start from a documented minimal environment allowlist, preserving required runtime/toolchain/temp variables and removing ambient LAB_* plus ACE/runtime/provider configuration that would select live services.
- Tests explicitly supply fixture overrides through existing test helper/runner configuration; do not remove variables required by the test under test. Fixture paths and fake credentials belong to isolated temp homes/project roots.
- Separate deterministic package tests from opt-in live integration/E2E. Live scenarios require explicit target configuration and cannot be silently selected because a Lab socket happens to exist.
- Do not globally mutate the invoking shell, real HOME, installed configuration or service state. Test cleanup only owns fixture resources. Missing required explicit environment is a clear setup error.
- Document preserved keys and test-fixture overrides as the runner contract; changes apply to all subprocess launch paths, including parallel and nested package runs.

### Interface Contract

Existing `ace-test PACKAGE [all]` and `ace-test-suite` become hermetic by default. Explicit live integration remains through existing E2E entrypoints with fixture/target configuration. CLI output identifies deterministic versus live mode and setup failures without echoing credentials.

### Success Criteria and Verification Plan

- [ ] SC1: Run the same fixture suite under clean env and poisoned LAB_*/ACE/runtime vars/home config; results and selected endpoints match and no live connection occurs.
- [ ] SC2: Verify fixture-specific environment survives, parent environment is unchanged, parallel/nested subprocess paths share isolation.
- [ ] SC3: Run `ace-test ace-test all`, affected runner suites and `ace-test-suite`; no package test via raw bundle exec ruby/rake.

### Scope and Ownership

Owner: **ace-test**. Consumers/boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: none. Canonical cross-repository program: lab-config:`8wl.t.gad`. External gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown authority is an error, never permission. Executed tests and independent current-head review gate delivery; CI is advisory. Spec readiness is not installed acceptance.

### Provenance and Invalidated Assumptions

Replaces 1w2 title-only brief and historical missing 1cl reference. This is a reliability prerequisite, not a mandatory green CI policy.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.
