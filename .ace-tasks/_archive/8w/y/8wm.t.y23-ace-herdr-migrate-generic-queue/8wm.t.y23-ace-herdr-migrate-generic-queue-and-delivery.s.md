---
id: 8wm.t.y23
status: done
priority: high
created_at: "2026-09-23 22:42:16"
estimate: 
dependencies: [8wm.t.vs0, 8wr.t.qjl]
needs_review: false
tags: [ace-herdr, migration, queue, delivery, lab-config, gad]
position: 6o0008
bundle:
  presets: [project]
  files: [ace-herdr/lib/ace/herdr/organisms/deliverer.rb, ace-herdr/lib/ace/herdr/molecules/delivery_record_store.rb, ace-herdr/lib/ace/herdr/models/delivery_record.rb, ace-herdr/lib/ace/herdr/molecules/herdr_executor.rb]
  commands: []
title: Deliver durable agent inbox messages once across recovery
worktree:
  branch: y23-deliver-durable-agent-inbox-messages-once-across-recovery
  path: .ace-wt/ace-t.y23
  created_at: "2026-10-02 00:20:17"
  updated_at: "2026-10-02 00:20:17"
  target_branch: main
---

# Deliver durable agent inbox messages once across recovery

## Behavioral Specification

### User Experience

An accepted inbox message reaches the intended live agent once, or exposes an attributable delivery uncertainty that can be reconciled.

### Expected Behavior

- Move generic enqueue/claim/bind/deliver/reconcile semantics and Codex/Pi identity/native queue integration from lab-config into ace-herdr. Build on vs0 DeliveryRecord/Store rather than adding competing idempotency state.
- Bind event ID + payload digest + intended attempt to verified runtime session/pane/terminal/agent identity before submitting. A changed target identity requires explicit reconciliation; reused pane numbers cannot inherit messages.
- Retry only failures proven to precede submission. A crash after claim with ambiguous submission, or native stalled result, stays uncertain. Resume reconciles consumed/superseded with positive proof, never guesses from age.
- A supervisor configures a trusted receipt public key before enqueue; each event pins its fingerprint. Reconciliation accepts only a matching operator/supervisor native-outcome receipt with a valid detached signature. The native queue clients expose submission only, so absent or invalid proof leaves the event uncertain.
- One per-message claim owner/generation prevents duplicate dispatch. Idle agents receive a wake; busy agents receive the native follow-up queue form. Delivery errors remain discoverable by the supervisor.
- Expose delivery receipts linked to assignment attempts; the message transport does not decide task completion or grant effect authorization.
- Only transport is migrated here. Root-broker domain capabilities do NOT disappear because this task passes; their successor is ace:qjx plus lab-config:gad.b, and deletion belongs gad.3.

### Interface Contract

Extend existing `ace-herdr deliver`/delivery-record public surface with explicit queue and reconciliation operations: `ace-herdr inbox enqueue --event ID --attempt ID --ref FILE --file PAYLOAD`, `ace-herdr inbox status --event ID --format json`, `ace-herdr inbox deliver --event ID`, `ace-herdr inbox reconcile --event ID --receipt FILE`. The supervisor sets `inbox_receipt_public_key` in Herdr project configuration; `FILE.sig` carries the detached signature. Binding refs use existing herdr reverse-address shape; inputs never carry authority by themselves.

### Success Criteria and Verification Plan

- [x] SC1: Port observable scenarios from lab-config tests/test_native_queue_transport.py and test_broker_pane_resolution.py: spoofed identity, digest mismatch, concurrent claim, orphan claim, pre-send rejection vs post-send uncertainty.
- [x] SC2: Native Codex/Pi delivery acceptance covers idle/busy and requester restart; prove one delivered prompt or a visible uncertain result without duplicate text.
- [x] SC3: Run `ace-test ace-herdr all`; installed migration E2E must run without migrated Python transport files.

### Scope and Ownership

Owner: **ace-herdr**. Consumers and boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only, not implementation or deployment.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: `8wm.t.vs0`, `8wr.t.qjl`. Canonical cross-repository program: lab-config:`8wl.t.gad`. External acceptance gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown identity/authority is an error, never permission or success. Executed tests plus independent current-head review gate delivery; CI is advisory. Spec readiness is not proof of installed behavior.

### Provenance and Invalidated Assumptions

Rewrites original migration brief. Invalidated: lab_root_broker.py can be deleted without migrating its domain operations; a folder watcher is not their replacement. lab-config checkout is available locally; no clone assumption.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. The approved 2026-09-28 specification supersedes conflicting earlier requirements. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.
