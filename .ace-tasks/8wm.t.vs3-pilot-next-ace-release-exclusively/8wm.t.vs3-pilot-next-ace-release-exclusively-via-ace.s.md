---
id: 8wm.t.vs3
status: pending
priority: high
created_at: "2026-09-23 21:11:14"
estimate: TBD
dependencies: [8wm.t.vs2, 8wr.t.qjx, 8wr.t.qkb]
needs_review: false
tags: [ace-hitl, pilot, release, rubygems]
position: 6o000l
bundle:
  presets: [project]
  files: [.ace-bin/ace-rubygems-publish, ace-hitl/lib/ace/hitl/lifecycle/kinds.rb, ace-hitl/lib/ace/hitl/lifecycle/effects.rb]
  commands: []
title: Prove release publication through scoped HITL and the tested publisher
---

# Prove release publication through scoped HITL and the tested publisher

## Behavioral Specification

### User Experience

An authorized release reaches the tested publisher through the correct role, requests OTP only when needed and produces an exact release receipt.

### Expected Behavior

- Pilot uses a named artifact/version/head and a scoped authorization (explicit Captain decision, approved standing authorization or qjz proposal result when available). Scope approval and OTP collection are separate.
- First prove the whole sequence with a fake publisher. Real publication runs only for a genuinely approved release, never publishes a dummy package merely to satisfy this test.
- Invoke the tested .ace-bin publisher through the scoped service. Classify publisher result: success, OTP-required/rejected/expired, non-OTP failure or uncertain submission. Only OTP-required/rejected/expired causes an OTP ask; deterministic non-OTP failure stops.
- OTP is ephemeral to the exact requesting executor, absent from argv/logs/Git/persistent events; overseer sees request status only. On uncertainty inspect RubyGems artifact/version evidence before any retry.
- Success receipt identifies artifact digest, version, target registry, accepted authorization and actual publisher result. Merge evidence does not imply a release has happened.
- External installed-service gate: lab-config:gad.b must provide publisher executor receipt before the real pilot; this task does not depend on gad.2 or gad.3, avoiding an acceptance cycle.

### Interface Contract

Existing tested publisher remains the publication entrypoint. `ace-hitl ask --kind otp --assignment ID --attempt ID --project ID` is issued only for a correlated publisher need; secret answer is consumed through protected IPC. The workflow returns publication receipt or classified blocker, not a prose-only success.

### Success Criteria and Verification Plan

- [ ] SC1: Fake publisher: direct success, OTP needed, rejected/expired OTP, non-OTP failure, uncertain result and duplicate delivery; no secret in emitted artifacts.
- [ ] SC2: One authorized real release through installed executor with no old lab CLI/broker; verify registry artifact digest/version and exact attempt receipt.
- [ ] SC3: Run affected `ace-test ace-hitl all` and release workflow fixture tests; record executed evidence, independent review and real pilot receipt separately.

### Scope and Ownership

Owner: **ace-hitl integration and release workflow**. Consumers/boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: `8wm.t.vs2`, `8wr.t.qjx`, `8wr.t.qkb`. Canonical cross-repository program: lab-config:`8wl.t.gad`. External gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown authority is an error, never permission. Executed tests and independent current-head review gate delivery; CI is advisory. Spec readiness is not installed acceptance.

### Provenance and Invalidated Assumptions

Refines existing A5 pilot; publication itself is not authorized by this spec-editing session. No dependency on second-commander rollout is required for an explicitly approved pilot.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.
