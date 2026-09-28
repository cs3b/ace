---
id: 8wm.t.vs2
status: pending
priority: high
created_at: "2026-09-23 21:11:12"
estimate: TBD
dependencies: [8wq.t.34i, 8wm.t.y23, 8wm.t.y24, 8wm.t.vs0, 8wm.t.vs1, 8wr.t.qjy]
needs_review: false
tags: [ace-hitl, integration, lab, hermes]
position: 6o000b
bundle:
  presets: [project]
  files: [ace-hitl/lib/ace/hitl/providers/lab.rb, ace-hitl/lib/ace/hitl/providers/lab/daemon_binding.rb, ace-hitl/lib/ace/hitl/providers/ref.rb, ace-hitl-hermes/lib/ace/hitl/hermes/schemas/message.v1.schema.json]
  commands: []
title: Integrate scoped HITL delivery without the Lab daemon
---

# Integrate scoped HITL delivery without the Lab daemon

## Behavioral Specification

### User Experience

An agent asks, Kapitan replies, and the exact requesting execution receives the answer/effect with no Python Lab daemon or broker running.

### Expected Behavior

- Keep provider=lab as deployment-provider identity, not a requirement for Lab Work engine. Replace DaemonBinding with the assignment attempt contract and scoped HITL store boundary. Remove W/A-only validation, ACE_HITL_LABD_SOCKET and all live socket calls.
- ace-hitl owns the canonical versioned managed request/delivery envelope; publish it with the gem. Hermes and Herdr consume shared contract examples (including y24 ingress received_at/checkpoint/healthy-drained semantics and rejection of secret-bearing folder answers), preserving the existing message.v1 transport envelope and herdr reverse address as distinct nested contracts.
- Envelope references request, project, assignment/attempt, requester identity, reverse address, message/correlation ID, non-secret payload digest and effect authorization/receipt. OTP content and its hash are excluded from persisted/public envelopes. 34i owns protected ephemeral consume IPC, y24 passes secret bytes directly there as an authenticated transport actor; the normal folder receives only secret-free status. No ordinary message.v1 OTP answer file is allowed.
- An in-process live-agent watch/delivery client consumes answers through the package public surface; no hidden labd folder watcher or replacement orchestration daemon. Answer availability and agent wake are separate; pane-less script `wait` remains supported.
- Resolve delivery versus business effect separately. Duplicate answers cannot duplicate effects. Dead requester, expired binding or ambiguous delivery leaves visible state for overseer reconciliation; never routes to a convenient different pane.
- Existing non-decision HITL requests do not expire merely with time. The new 16-hour policy is an explicit proposal kind owned by qjz, not a blanket timeout on every ask.

### Interface Contract

`ace-hitl ask --provider lab --assignment ID --attempt ID --project ID --question TEXT` returns local event and managed request IDs; reverse address is discovered from the active runtime. `ace-hitl pending`, `deliver`, `consume`, and status expose the same binding. Remove old --work-based managed request form and daemon env contract in the same change; no compatibility fallback.

### Success Criteria and Verification Plan

- [ ] SC1: Run shared envelope tests in ace-hitl, ace-hitl-hermes and ace-herdr; reject wrong version/correlation/attempt, double answer and unauthorized effect.
- [ ] SC2: Live installed ask -> Telegram Reply -> exact pane/consumer with /usr/local/bin/lab absent and labd socket unavailable; repeat after requester death/recovery.
- [ ] SC3: Run `ace-test ace-hitl all`, `ace-test ace-hitl-hermes all`, `ace-test ace-herdr all`; attach installed evidence to lab-config:gad.2.

### Scope and Ownership

Owner: **ace-hitl**. Consumers and boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only, not implementation or deployment.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: `8wq.t.34i`, `8wm.t.y23`, `8wm.t.y24`, `8wm.t.vs0`, `8wm.t.vs1`, `8wr.t.qjy`. Canonical cross-repository program: lab-config:`8wl.t.gad`. External acceptance gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown identity/authority is an error, never permission or success. Executed tests plus independent current-head review gate delivery; CI is advisory. Spec readiness is not proof of installed behavior.

### Provenance and Invalidated Assumptions

Replaces A4 stub. Current provider deliberately raises unsupported deliver and queries DaemonBinding; migration is not complete merely because HITL 0.10.0 exists.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. The approved 2026-09-28 specification supersedes conflicting earlier requirements. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.
