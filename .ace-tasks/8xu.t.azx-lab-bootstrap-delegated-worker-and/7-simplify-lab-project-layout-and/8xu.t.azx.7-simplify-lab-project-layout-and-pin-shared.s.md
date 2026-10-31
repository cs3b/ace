---
id: 8xu.t.azx.7
status: in-progress
priority: medium
created_at: "2026-10-31 07:24:27"
estimate: 
dependencies: []
tags: []
parent: 8xu.t.azx
---

# Simplify lab project layout and pin shared operational runtime

## Contract

Use /lab/<project> with .ace-wt and project state inside. Inventory and preserve dirty work, update current topology/HITL/receiver roots and repair Git worktree links during bounded cutover. Shared service state belongs outside project roots; do not delete historical directories blindly.

## Acceptance

- [ ] Implementation and evidence satisfy this contract.
- [ ] Live acceptance is recorded in the parent task before final closure.
