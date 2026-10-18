---
id: 8xh.t.z7o.0
status: pending
priority: medium
created_at: "2026-10-18 23:28:35"
estimate: TBD
dependencies: []
tags: [ace-assign, tests]
parent: 8xh.t.z7o
---

# Scrub fork runtime env vars in test helper

## Objective

Forked assignment drive sessions export fork-runtime variables (`ACE_ASSIGN_DEFAULT_TARGET`, `ACE_ASSIGN_ID`, `ACE_ASSIGN_CURRENT_ASSIGNMENT_ID`, `ACE_ASSIGN_CURRENT_FORK_ROOT`, `ACE_ASSIGN_LAUNCH_MODE`, `ACE_ASSIGN_FORK_WINDOW`, `ACE_ASSIGN_CALLBACK_PANE`, plus any others the current runtime exports). When package verification runs inside such a session, these variables contaminate tests and produce false failures unrelated to the change under test. Give the `ace-assign` test helper deterministic isolation regardless of caller environment.

## Expected Behavior

- Every `ace-assign` test starts with the complete active fork-runtime variable set absent from `ENV`, whatever the invoking shell exported.
- After each test the original environment is restored exactly (unset stays unset; set variables get their original values back).
- The variable list stays in sync with what fork launching actually exports on 0.72.0, not the April list.

## Interface Contract

Test-infra only — no CLI/API surface changes.

## Success Criteria

- [ ] The current fork-runtime env var set is identified from the 0.72.0 launcher code and scrubbed/restored in the shared `ace-assign` test helper.
- [ ] A regression test simulates an inherited fork env and asserts representative behavior matches a clean run.
- [ ] The `ace-assign` package suite passes from both a clean shell and a shell pre-seeded with fork env variables.

## Verification Plan

- Unit: regression test for env scrub plus representative executor/command behavior under seeded env.
- Failure path: without the fix, a seeded-env package run demonstrates contamination or the scrub is justified as pure hygiene.

## Out of Scope

- Runtime behavior of fork-run, assignment executor, or any shipped command.

## References

- Closed PR #304 diff (`ace-assign/test/test_helper.rb` hunk).
