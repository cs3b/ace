---
id: 8wr.t.qjx
status: pending
priority: high
created_at: "2026-09-28 17:42:09"
estimate: TBD
dependencies: [8wq.t.1w4, 8wr.t.qjl]
tags: [lab-readiness]
bundle:
  presets: [project]
  files: [ace-hitl/lib/ace/hitl/lifecycle/effects.rb, ace-assign/lib/ace/assign/molecules/evidence_calculator.rb, ace-git/lib/ace/git/providers/evidence.rb]
  commands: []
needs_review: false
title: Route scoped role services with verifiable execution receipts
position: 6o0005
---

# Route scoped role services with verifiable execution receipts

## Behavioral Specification

### User Experience

A worker requests an operation it cannot perform directly. The routed executor validates authority and returns an attributable receipt without sharing credentials.

### Expected Behavior

- The generic contract supports configured named operations, including setup-project, provision-integrator, environment review-approval, inbox-settle, promote-runtime, merge, forge-sync, publish and deploy. Domain implementations and operation-specific arguments live in lab-config:8wl.t.gad.b; authenticated host-side maintenance uses a managed attempt with its executable and evidence sink outside the deployment being replaced, and only this exact maintenance attempt is exempt from product-work quiescence checks; no root-broker shell passthrough is an acceptable substitute.
- Requests bind operation, canonical input digest, project, assignment/attempt, caller identity, target resource/candidate_head or artifact digest where applicable, and authorization reference. Consume qjl base_head/candidate_head/evidence_git_ref/journal_commit distinctly; journal commits do not change or authorize a candidate. Authentication derives from OS/service identity; naming a role in payload does not grant it.
- Executor independently validates both authorization for the exact operation and its actual capability/lease. The 16-hour decision reference can authorize any precise proposal, including a scope expansion, but cannot silently supply nonexistent credentials or bypass technical checks.
- Worker can implement/test/create PR; reviewer independently reviews; integrator merges exact accepted head; admin executes privileged operations. A role may request another service, but receives results rather than broad credentials.
- Same request ID and same input returns its existing receipt. Same ID/different input is rejected. Accepted-but-unconfirmed external effects become uncertain; status/reconciliation requires evidence before retry.
- Receipts contain request/attempt/project/operation, authenticated executor, input digest, target head/artifact, outcome and non-secret evidence references. They are bound to the canonical assignment journal. Rejections and failures are auditable and do not become approvals.
- Input is structured data and executed argv, never an arbitrary command accepted because the user has some capability. Dry-run validates/routes and shows scope without granting leases or invoking effects.

### Interface Contract

`ace-lab service request --project PROJECT --assignment ID --attempt ID --operation NAME --input FILE --authorization DECISION --request-id ID [--dry-run]`; `ace-lab service status --request ID --format json`. Approved configured automation may use an existing scoped authorization reference; otherwise resolve a HITL decision. JSON outcome is rejected, accepted, succeeded, failed or uncertain with receipt reference. Nonzero CLI errors include classification.

### Success Criteria and Verification Plan

- [ ] SC1: Exercise authorized operation through a fake executor and a real filesystem/OS identity integration fixture; forged role/project/approval/head must fail.
- [ ] SC2: Race duplicate requests, crash after execution before receipt, expired lease, stale approval and dry-run: never duplicate a side effect.
- [ ] SC3: Run `ace-test ace-lab all` and assignment receipt integration; installed domain proof consumed from lab-config:8wl.t.gad.b before lab retirement.

### Scope and Ownership

Owner: **ace-lab**. Consumers and boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only, not implementation or deployment.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: `8wq.t.1w4`, `8wr.t.qjl`. Canonical cross-repository program: lab-config:`8wl.t.gad`. External acceptance gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown identity/authority is an error, never permission or success. Executed tests plus independent current-head review gate delivery; CI is advisory. Spec readiness is not proof of installed behavior.

### Provenance and Invalidated Assumptions

New generic seam; do not duplicate domain provisioning, catalog, identity/Podman implementation. Environment review-approval is not the independent code-review verdict.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. The approved 2026-09-28 specification supersedes conflicting earlier requirements. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.
