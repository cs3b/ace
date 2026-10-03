---
id: 8wq.t.34i
status: pending
priority: high
created_at: "2026-09-27 02:05:00"
estimate: 
dependencies: [8wr.t.qjl, 8wr.t.qjx]
tags: []
position: 6o0003
bundle:
  presets: [project]
  files: [ace-hitl/lib/ace/hitl/lifecycle/store.rb, ace-hitl/lib/ace/hitl/lifecycle/identity.rb, ace-hitl/lib/ace/hitl/lifecycle/atomic_json.rb]
  commands: []
needs_review: false
title: Protect multi-user HITL state through a scoped privilege boundary
---

# Protect multi-user HITL state through a scoped privilege boundary

## Behavioral Specification

### User Experience

A non-root requester can create and consume its own valid HITL requests while transport and privileged effects cannot impersonate it or access other actors' secrets.

### Expected Behavior

- Replace reliance on direct shared-store writes/root assumptions with an authenticated scoped store boundary. The request/answer/consume/cancel lifecycle remains owned by ace-hitl; ace-lab supplies service identity/authorization, domain executor supplies OS enforcement.
- Bind each request to a verified active assignment attempt, project and requester. Validate under the same transition lock immediately before consuming or applying effects; stale, ended or replaced attempts cannot acquire new authority.
- Requester can create/read/consume its own request; configured transport can submit correlated answers from an authorized Captain; scoped executor can apply the precisely authorized effect; public projections expose only non-secret status. No chmod-to-world-writable workaround.
- Lifecycle transport errors remain visible/recoverable. Duplicate answers/consumes are idempotent; concurrent cancel/answer/consume commits one terminal transition.
- OTP is accepted only for its exact authorized operation after an OTP-required publisher result. Secret bytes never appear in argv, event journals, logs, Git or public projection. Transient protected IPC/memory consumption belongs to the requesting executor; expired/rejected OTP prompts again without logging the value.
- Preserve exact actor and ownership validation on real files. Injection of an environment variable or payload requester name cannot impersonate a user.

### Interface Contract

Existing `ace-hitl ask/deliver/consume/cancel` remain the lifecycle operations, backed by the scoped boundary. Use `--assignment ID --attempt ID --project ID` for managed requests; remove obsolete Work binding when vs2 switches consumers. Public JSON includes request/attempt/state and effect receipt reference, never answer values for OTP. Protocol failures return classified permission/binding/transport errors.

### Success Criteria and Verification Plan

- [ ] SC1: Real multi-UID filesystem/IPC tests prove requester isolation, protected ownership and rejected forged identities; mocked ownership alone is insufficient.
- [ ] SC2: Race deliver/cancel/consume, wrong project, ended attempt and reused process ID; no unauthorized effect.
- [ ] SC3: Run `ace-test ace-hitl all`; installed OS-boundary acceptance joins vs2 and lab-config:gad.b, not claimed complete from local unit tests.

### Scope and Ownership

Owner: **ace-hitl**. Consumers and boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only, not implementation or deployment.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: `8wr.t.qjl`, `8wr.t.qjx`. Canonical cross-repository program: lab-config:`8wl.t.gad`. External acceptance gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown identity/authority is an error, never permission or success. Executed tests plus independent current-head review gate delivery; CI is advisory. Spec readiness is not proof of installed behavior.

### Provenance and Invalidated Assumptions

Replaces empty 34i brief. Store safety is prerequisite for vs2, not a permission relaxation to make the old daemon client work.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. The approved 2026-09-28 specification supersedes conflicting earlier requirements. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.

### Completion versus integrated acceptance

Task delivery is proved with its own installed isolated authenticated service and real multi-UID/IPC/filesystem fixtures, without requiring vs2 or gad.b to be completed. Full deployed Lab transport proof belongs gad.2 after those consumers exist; it is not a circular prerequisite for closing 34i.
