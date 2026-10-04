---
id: 8wm.t.y24
status: pending
priority: high
created_at: "2026-09-23 22:42:16"
estimate: 
dependencies: [8wm.t.vs1, 8wq.t.34i, 8x3.t.vft, 8x3.t.vfv]
needs_review: false
tags: [ace-hitl-hermes, migration, telegram, plugin, lab-config, gad]
position: 6o0009
bundle:
  presets: [project]
  files: [ace-hitl-hermes/lib/ace/hitl/hermes/organisms/hermes_box.rb, ace-hitl-hermes/lib/ace/hitl/hermes/schemas/message.v1.schema.json, .ace-tasks/8x3.t.vft-preserve-the-active-hitl-listener/8x3.t.vft-preserve-the-active-hitl-listener-on-refused.s.md, .ace-tasks/8x3.t.vfv-enforce-the-authorized-otp-expiry/8x3.t.vfv-enforce-the-authorized-otp-expiry-at-consumption.s.md, .ace-tasks/_archive/8w/y/8wq.t.34i-privileged-store-boundary-for-ace/8wq.t.34i-privileged-store-boundary-for-ace-hitl-lifecycle.s.md, ace-hitl/lib/ace/hitl/lifecycle/client.rb, ace-hitl/lib/ace/hitl/lifecycle/service.rb, .ace-tasks/8wm.t.y24-ace-hitl-hermes-migrate-telegram/ux/usage.md]
  commands: []
title: Provide correlated Telegram transport through the Hermes package
---

# Provide correlated Telegram transport through the Hermes package

## Behavioral Specification

### User Experience

Kapitan receives a scoped request in the configured Telegram group and can answer it by Reply; a plain message is a new instruction for that group's configured target.

### Expected Behavior

- Move generic plugin/channel registry/correlation behavior from hermes-lab-hitl, lab-hitl-broker and lab-hitl-channels into the Hermes package. Lab retains concrete channel/allowlist configuration only.
- Reply and /hitl-reply identify exactly one original request in the same registered channel and from the configured Captain allowlist. Plain messages route as new instructions and never satisfy an unrelated pending request.
- Record transport submission acknowledgement and message identity for deadline consumers. A send failure cannot start a 16-hour decision clock. Submission acknowledgement is not a read receipt. Also persist non-secret ingress metadata with request/revision/channel identity, trusted received_at and monotonic sequence for each received reply. Expose `ace-hitl-hermes ingress reconcile --request ID --through UTC --format json`: returns healthy/drained plus a checkpoint covering all ingress durably received through the cutoff, and unresolved correlated replies, or unknown/unhealthy. A checkpoint cannot claim drainage while a poll gap, queued reply or uncertain delivery remains. qjz must defer timeout approval on unknown; source reply text remains in protected HITL handling, not this public checkpoint.
- Correlation tombstones remain for 24h as transport dedupe; authoritative decision/receipt history is durable beyond that. Late or duplicate replies cannot create a second effect even after tombstone expiry.
- Preserve channel scoping and fail closed on ambiguous/missing registry entries, unauthorized sender, unknown Reply or malformed envelope. Failed transport remains pending/recoverable and visible.
- OTP bypasses the ordinary persistent message.v1 answer folder entirely. ace-hitl owns the authenticated ephemeral secret-consume boundary (34i); ace-hitl-hermes owns Telegram-to-that-boundary protected IPC as the authorized transport actor. Only metadata/status acknowledgements enter the folder; attempts to encode OTP as an ordinary answer file are rejected. Do not hash OTP into public metadata. sanitized correlation/status must not retain the value. No raw answer logging, public status leakage or forwarding to overseer.

### Interface Contract

Ship installable Hermes plugin and registry support using the existing folder message.v1 contract, Telegram Reply and `/hitl-reply`. Plugin emits a non-secret delivery acknowledgement with channel/message/request identity and timestamp; consumers read it via package contract rather than Telegram implementation details. Existing lifecycle decisions remain owned by ace-hitl.

### Success Criteria and Verification Plan

- [ ] SC1: Port tests/test_hitl_channels.py behavior and plugin contract tests: cross-channel reply, bad sender, duplicate/late reply, unknown message, failed Telegram submit, plain instruction routing, delayed ingress watermark and timeout race. Test an OTP-marked ordinary folder answer is rejected before file creation.
- [ ] SC2: Installed plugin/folder round-trip with actual registered test channel; OTP surrogate is absent from logs, tracked artifacts and public projection.
- [ ] SC3: Run `ace-test ace-hitl-hermes all`; transport smoke joins lab-config:gad.2 without old broker plugin files.

### Scope and Ownership

Owner: **ace-hitl-hermes**. Consumers and boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only, not implementation or deployment.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: `8wm.t.vs1`, `8wq.t.34i`. Canonical cross-repository program: lab-config:`8wl.t.gad`. External acceptance gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown identity/authority is an error, never permission or success. Executed tests plus independent current-head review gate delivery; CI is advisory. Spec readiness is not proof of installed behavior.

### Provenance and Invalidated Assumptions

Preserve vs1 folder core as completed foundation, not proof that plugin transport migration or labd removal is done.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. The approved 2026-09-28 specification supersedes conflicting earlier requirements. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.

### Secret transport failure semantics

If the requesting protected OTP consume endpoint is unavailable, do not buffer the secret in the folder or log. Return secret delivery unavailable with non-secret request identity; after the executor recovers, re-ask for a fresh code. Telegram remains the explicitly approved transient input channel; this contract does not claim erasure of third-party message history.

## Post-delivery repair gate — 2026-10-04

The added prerequisite tasks repair observed producer defects, not a change to this consumer's behavior. Development may use the delivered API in parallel, but acceptance/integration waits for the named repairs and reruns the affected consumer cases after rebase. No local bypass or duplicate validation substitutes for fixing the owning producer. Pending means the specification is ready, not that its prerequisites are already complete.
