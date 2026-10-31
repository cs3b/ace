---
id: 8xu.t.azx.8
status: in-progress
priority: medium
created_at: "2026-10-31 07:33:33"
estimate: 
dependencies: []
tags: []
parent: 8xu.t.azx
---

# Make projects mo-owned and scope extra access to executor sessions

## Contract

Projects belong to mo:mo. Additional credentials/privileges belong to a particular executor session and expire/revoke after use, rather than permanent lab-admin ownership or broad lab-control grants. Preserve restricted secret modes; runtime/system files remain root-owned. Verify access and denied access with real identities.

## Acceptance

- [ ] Implementation and evidence satisfy this contract.
- [ ] Live acceptance is recorded in the parent task before final closure.
