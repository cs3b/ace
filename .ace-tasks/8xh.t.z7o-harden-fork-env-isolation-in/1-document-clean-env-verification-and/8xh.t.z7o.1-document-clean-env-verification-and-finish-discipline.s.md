---
id: 8xh.t.z7o.1
status: pending
priority: medium
created_at: "2026-10-18 23:28:35"
estimate: TBD
dependencies: []
tags: [process, docs, assignments]
parent: 8xh.t.z7o
---

# Document clean-env verification and finish discipline

## Objective

Turn the validated retro learnings from the closed watch-continuation work into standing guidance for agents driving forked assignment subtrees, so reports stop landing on wrong steps and package verification stops inheriting the fork-session environment.

## Expected Behavior

- Assignment-driving guidance instructs agents to re-read active child/subtree state immediately before every `finish`/report write, because queued child steps can auto-advance between status checks and consume the wrong report.
- Guidance instructs agents running package-level verification inside a forked subtree session to start from a neutral `ACE_ASSIGN_*` (and tmux targeting) environment for the verification command.

## Interface Contract

Docs-only — updates to the relevant workflow instruction files / skills (assignment drive and verification guidance). No code.

## Success Criteria

- [ ] Re-read-before-finish discipline stated where assignment driving guidance lives.
- [ ] Clean-env verification rule stated where package verification guidance lives.
- [ ] Guidance names the concrete variable family (`ACE_ASSIGN_*`, tmux targeting vars), not vague advice.

## Verification Plan

- Docs review: guidance is findable from the driving workflow entry point and matches the env var set scrubbed by 8xh.t.z7o.0.

## Out of Scope

- Enforcing the discipline in tooling/runtime.

## References

- `.ace-retros/8ro1ts-*` (re-read before finish), `.ace-retros/8ro24k-*` and `.ace-retros/8roifd-*` (clean-env verification).
