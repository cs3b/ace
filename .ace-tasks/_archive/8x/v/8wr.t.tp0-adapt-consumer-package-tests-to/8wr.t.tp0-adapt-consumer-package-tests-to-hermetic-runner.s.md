---
id: 8wr.t.tp0
status: done
priority: high
created_at: "2026-09-28 19:47:47"
estimate: 
dependencies: []
tags: [ace-assign, ace-review, ace-hitl, ace-test]
---

# Adapt consumer package tests to hermetic runner contract

## Behavioral Specification

### User Experience

`ace-test-suite` (and per-package `ace-test`) runs green with the hermetic runner contract from 8wq.t.1w2: test children get the minimal documented environment, so no package test may depend on ambient `LAB_*`/ACE runtime variables, provider credentials, real `gh` authentication, ambient `PROJECT_ROOT_PATH`, or user-level `~/.ace` provider configuration.

### Expected Behavior

- Consumer package tests declare fixture-specific values through the documented runner contract (`environment.preserve`/`overrides` in `.ace/test/runner.yml`) or via test-owned fakes/stubs, never through ambient developer environment state.
- Tests requiring external services (GitHub, LLM providers, Lab sockets) are deterministic: they either stub the boundary or are explicit live-scenario E2E cases under `test/e2e/`.

### Failure inventory (ace-test-suite, 2026-09-28, worktree 8wq-t-1w2-hermetic-tests)

- **ace-assign** (3 failures, 2 errors): workflow binding resolution (`wfi://onboard`, `wfi://release/publish`) and canonical skill content merge resolve differently without ambient nav/user configuration sources.
- **ace-review** (1 error): `test_exempt_paths_are_excluded_from_full_round_subject` raises `GhAuthenticationError` — the test relied on real `gh` authentication from the invoking environment.
- **ace-hitl** (3 errors): LAB fixture selection under sanitized environment; needs triage against the LAB fixture override contract (fixture identities/store/socket must come from runner configuration).
- **ace-test-runner-e2e** (1 failure): `role:e2e-runner should resolve to a CLI provider` — provider role resolution read user-level `~/.ace` provider configuration, absent in the fixture home.

Also pre-existing and unrelated to hermeticity: `ace-test-runner` `package_resolver_test.rb:147` fails because `ace-lab` (committed on main by the ace-lab line) is missing from `.ace/test/suite.yml` package registration.

### Success Criteria and Verification Plan

- [ ] SC1: `ace-test-suite` runs with zero failures across all registered packages (only deliberate skips remain).
- [ ] SC2: Each fixed test keeps or improves its previous coverage; no test was deleted to get green.

### Scope and Ownership

Owners: the respective consumer packages (ace-assign, ace-review, ace-hitl, ace-test-runner-e2e), coordinated through this task. Runner contract reference: `ace-test-runner/docs/usage.md` ("Hermetic Environment Contract").

### Provenance and Invalidated Assumptions

Split out of 8wq.t.1w2 implementation (2026-09-28): the hermetic runner change exposed these ambient dependencies in consumer packages. Per 8wq.t.1w2 scope, the runner owns isolation; consumer tests own their fixture declarations.
