---
id: 8wm.t.vs2
status: done
priority: high
created_at: "2026-09-23 21:11:12"
estimate: TBD
dependencies: [8wq.t.34i, 8wm.t.y23, 8wm.t.y24, 8wm.t.vs0, 8wm.t.vs1, 8wr.t.qjy]
needs_review: false
tags: [ace-hitl, integration, lab, hermes]
position: 6o000a
bundle:
  presets: [project]
  files: [ace-hitl/lib/ace/hitl/providers/lab.rb, ace-hitl/lib/ace/hitl/providers/lab/assignment_binding.rb, ace-hitl-contract/lib/ace/hitl/contract/ref.rb, ace-hitl-hermes/lib/ace/hitl/hermes/schemas/message.v1.schema.json, .ace-tasks/_archive/8w/y/8wm.t.y23-ace-herdr-migrate-generic-queue/8wm.t.y23-ace-herdr-migrate-generic-queue-and-delivery.s.md, ace-herdr/lib/ace/herdr/organisms/inbox.rb, ace-herdr/docs/usage.md, .ace-tasks/_archive/8w/y/8wm.t.vs2-integration-provider-lab-uses-a2/ux/usage.md]
  commands: []
title: Integrate scoped HITL delivery without the Lab daemon
---

## Acceptance ownership — Captain decision 2026-10-05

This ACE task owns the implemented package behavior and executed source/package tests. **Lab installation and system acceptance are owned once by lab-config:8wl.t.gad.2, checklist row `vs2-hitl`**, not by this task. The original installed requirements are preserved in history/before-centralized-lab-acceptance-2026-10-05.md and mapped into that central checklist. Closing this source task does not claim those probes were executed or the Lab is ready. Defects discovered by gad.2 return to the owning package as tracked fixes.

This explicit Captain scope split supersedes the earlier blocked-on-Lab status and historical implementation-report instructions to keep this task open solely for installed acceptance. Product behavior and refusal requirements are unchanged. Independent scope review precedes source closure.


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

- [x] SC1: Managed envelope validation, exact assignment/runtime binding, signed Inbox consumer and daemon-free LiveClient implementation pass retained component/integration tests.
- [x] SC2: Independent source review APPROVE at 66c91a82d, including real local socket paging/authorization and isolated installed consumer fixtures; actual Lab Telegram/native/OS-user scenario belongs exclusively to gad.2.
- [x] SC3: Accepted source integrated at 0d9590097, with recorded post-merge Assign/HITL checks; published ace-hitl 0.12.0 and contract 0.2.0 preserve this implementation.

### Scope and Ownership

Owner: **ace-hitl**. Consumers and boundaries are named above. Code layout belongs to JIT planning. This record owns source delivery. Deployment execution and Lab acceptance belong to lab-config:8wl.t.gad.2.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: `8wq.t.34i`, `8wm.t.y23`, `8wm.t.y24`, `8wm.t.vs0`, `8wm.t.vs1`, `8wr.t.qjy`. Canonical cross-repository program: lab-config:`8wl.t.gad`. External acceptance gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown identity/authority is an error, never permission or success. Executed tests plus independent current-head review gate delivery; CI is advisory. Spec readiness is not proof of installed behavior.

### Provenance and Invalidated Assumptions

Replaces A4 stub. The original stub raised unsupported deliver and used DaemonBinding. Current source uses AssignmentBinding and LiveClient; actual installed integration is tracked by gad.2.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. The approved 2026-09-28 specification supersedes conflicting earlier requirements. The source implementation has retained independent review; the 2026-10-05 acceptance ownership amendment is reviewed separately.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.

## Signed inbox consumer contract — 2026-10-04

Consume delivered ACE 8wm.t.y23 as implemented, without another journal. An uncertain inbox result can advance only from a verified signed receipt binding event_id, attempt_id, claim_generation, payload_sha256, full native binding and observer/native observation reference. `consumed` maps to completed; `superseded` requeues the same event after trusted non-consumption evidence and may supply a verified replacement target. Superseded is not delivery/business success or a generic dead state. No receipt, stale-generation or mismatched proof, unknown liveness or elapsed time leaves uncertainty visible and prohibits automatic resend/relaunch of the uncertain effect.

The trusted supervisor/observer verifies actual native Codex/Pi consumption or non-consumption before signing. A requester cannot mint its own acceptance. lab-config:gad.8 owns installation of the protected signer process, private key and configured public verification key; gad.b owns the domain operation. Preserve the per-event key fingerprint and existing verifier checks. Rotation cannot make an old event trusted under a new key: retain the matching trusted verifier/signing context for unresolved old events or postpone rotation. Never weaken verification to unblock recovery. Persist non-secret observation/proof references in the existing ace-assign attempt journal, not OTPs or raw private keys. Delivery consumption does not itself authorize or prove a business effect.

- [x] Source consumer acceptance (retained implementation and independent-review receipts): consumed and superseded with correct signature/binding; wrong signer/key/digest/generation/native target; replay; missing proof; supervisor restart and key rotation with unresolved old event. Valid consumption settles once; supersession permits only the explicit verified retry; all invalid or absent proofs stay uncertain.
Central acceptance reference: lab-config:8wl.t.gad.2 `vs2-hitl` requires actual requester and trusted signer OS users and native Codex/Pi observation supplied by gad.8/.b, not only scripted subprocess proof. Its unchecked checklist is the sole installed acceptance tracker.

## Current producer state — 2026-10-04

34i supplies authenticated IPC in source, not full installed Lab acceptance. y24 now carries prerequisite repairs vft (listener ownership) and vfv (OTP challenge expiry). This integration consumes their accepted evidence transitively through y24, including requester/transport/service OS-user proof and the publisher's exact authorization; the mere presence of a result_ref string is not authorization. No reopening of 34i history or second lifecycle owner.
