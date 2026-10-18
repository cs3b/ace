---
id: 8xh.t.z7o
status: pending
priority: medium
created_at: "2026-10-18 23:28:32"
estimate: TBD
dependencies: []
tags: [ace-assign, tests, process-guidance]
bundle:
  presets: [project]
  files: []
  commands: []
---

# Harden fork env isolation in ace-assign tests and drive guidance

## Objective

Salvage the two still-relevant learnings from closed PR #304 (April watch-continuation work) into current main on ace-assign 0.72.0: (1) fork-runtime environment variables leak from forked drive sessions into package verification and pollute test results; (2) the drive/review process needs explicit guidance on re-reading active child state before reporting completion and on running verification from a clean environment inside forked subtrees.

## Expected Behavior

- Running the `ace-assign` package test suite from inside a forked assignment/drive session (where `ACE_ASSIGN_*` runtime env vars are exported) produces identical results to running it from a clean shell.
- Agents following `/as-assign-drive`-family guidance re-check active child state immediately before every `finish`/report write, and clear fork-only env before package-level verification runs.

## Success Criteria

- [ ] `ace-assign` test helper scrubs the full active fork-runtime variable set around each test and restores it afterwards.
- [ ] A regression test demonstrates that inherited `ACE_ASSIGN_*` variables do not affect test outcomes.
- [ ] Workflow guidance documents clean-env verification and re-read-before-finish discipline for forked subtrees.

## Vertical Slice Decomposition (Task/Subtask Model)

- `8xh.t.z7o.0` — env scrub in `ace-assign/test/test_helper.rb` (code + regression test). Size: small.
- `8xh.t.z7o.1` — process guidance in workflow instructions (docs-only). Size: small.

## Out of Scope

- Reintroducing any part of the `ace-assign watch` command.
- Changes to fork-run or assignment runtime behavior.

## References

- Closed PR: https://github.com/cs3b/ace/pull/304
- `.ace-retros/8ro1ts-*`, `.ace-retros/8ro24k-*`, `.ace-retros/8roifd-*` (archived retro learnings)
