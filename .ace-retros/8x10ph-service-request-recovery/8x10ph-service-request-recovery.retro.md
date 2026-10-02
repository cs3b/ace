---
id: 8x10ph
title: service-request-recovery
type: standard
tags: [ace-lab, ace-assign, recovery]
created_at: "2026-10-02 00:28:19"
status: active
---

# Service request recovery for task 8wr.t.qjx

Date: 2026-10-02  
Context: Assignment 8x0z1i scoped subtree 010.01; generic service request and assignment evidence integration.  
Author: Codex  
Type: Standard

## What Went Well

- The interrupted fork left three scoped commits and reports. Reading those artifacts and the cached plan made it possible to resume from the actual gap instead of replaying the implementation.
- Journal claims already prevented repeated dispatch. Adding coordinator receipt validation and an executor policy recheck closed the remaining trust boundary without adding another request store.
- The local OS/filesystem fixture and package tests exercised a real fixed argv handler and repeated request ID. `ace-lab` passed 169 tests; `ace-assign` passed 757; the dependency follower `ace-overseer` passed 252.
- Path scoped commits preserved unrelated task-tree edits, and the local release moved `ace-assign`, `ace-lab`, and `ace-overseer` together with matching constraints and lockfile.

## What Could Be Improved

- The first fork hit its 1800-second deadline mid-implementation. Its attempt was left uncertain until the committed work was inspected, completed, tested, and reconciled with a verified receipt.
- The initial receipt shape was too weak: the coordinator would accept a terminal result containing only outcome and evidence. A package test surfaced this after receipt validation was added; the test fixture was updated to carry the exact claim binding.
- The pre-commit review provider resolved to a role alias, so the native `/review` command was unavailable. `ace-lint` passed with 54 style/layout warnings, but it did not provide an independent reviewer verdict. The parent PR review remains the independent delivery gate.
- The `ace-assign` feature suite took several minutes because campaign receipt cases issue many coordinator CLI calls. Profile output identifies the slow path without changing verification requirements.

## Key Learnings

- A durable request claim and a terminal executor response need separate validation. The coordinator now checks the receipt against the journal claim before accepting `succeeded` or `failed`.
- The executor must recheck its exact operation, authorization, and lease immediately before dispatch; routing and approval performed earlier in the service flow are insufficient at the effect boundary.
- A taskless local assignment attempt can be reconciled from a lost worker process once tested artifact and check evidence is available. The journal commit, candidate head, and local attempt receipt remain distinct.

## Action Items

- [ ] Complete the installed operation and OS identity proofs in lab-config task `8wl.t.gad.b` before retiring Lab; this generic subtree does not supply domain handlers or credentials.
- [ ] Integrate the resolved decision producer from task `8wr.t.qjz` with the exact authorization reference; continue rejecting unresolved references.
- [ ] Use the parent assignment's independent PR review before merge. Treat the lint fallback as a style check only.
- [ ] Consider profiling the campaign receipt feature cases if their runtime becomes a repeated delivery bottleneck.
