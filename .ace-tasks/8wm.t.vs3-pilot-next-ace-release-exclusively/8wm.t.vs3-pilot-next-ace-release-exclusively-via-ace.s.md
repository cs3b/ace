---
id: 8wm.t.vs3
status: in-progress
priority: high
created_at: "2026-09-23 21:11:14"
estimate: TBD
dependencies: [8wm.t.vs2, 8wr.t.qjx, 8wr.t.qkb]
needs_review: false
tags: [ace-hitl, pilot, release, rubygems]
position: 6o000j
bundle:
  presets: [project]
  files: [.ace-bin/ace-rubygems-publish, ace-hitl/lib/ace/hitl/lifecycle/kinds.rb, ace-hitl/lib/ace/hitl/lifecycle/effects.rb, .ace-tasks/8wm.t.vs3-pilot-next-ace-release-exclusively/scoped-publication-source-contract-candidate.md, .ace-tasks/8wm.t.vs3-pilot-next-ace-release-exclusively/source-contract-review.md]
  commands: []
title: Deliver scoped HITL publication workflow and verification fixtures
---

## Central Lab acceptance — Captain decision 2026-10-05

Lab installation and execution of the shared system test belong to **lab-config:8wl.t.gad.2**, checklist row `scoped-publication`. Installed scenario descriptions below define its referenced obligations, not a second deployment/run owned by this task. This source task must deliver its own implementation, automated package/integration verification and review; missing source behavior cannot be moved to the Lab test or marked done. Any reference below requiring whole installed Lab acceptance before source completion is superseded by this ownership split. Cross-repository acceptance records exact producer versions/source receipts, failures and retest evidence once in gad.2.

This task retains any package-level matrix/scenario/automation deliverables. Its actual deployed end-to-end run is a row in gad.2; that row is not an entry dependency which requires gad.2 to have already succeeded.


# Deliver scoped HITL publication workflow and verification fixtures

## Behavioral Specification

### User Experience

An authorized release reaches the tested publisher through the correct role, requests OTP only when needed and produces an exact release receipt.

### Expected Behavior

- Pilot uses a named artifact/version/head and a scoped authorization (explicit Captain decision, approved standing authorization or qjz proposal result when available). Scope approval and OTP collection are separate.
- First prove the whole sequence with a fake publisher. Real publication runs only for a genuinely approved release, never publishes a dummy package merely to satisfy this test.
- Invoke the tested .ace-bin publisher through the scoped service. Classify publisher result: success, OTP-required/rejected/expired, non-OTP failure or uncertain submission. Only OTP-required/rejected/expired causes an OTP ask; deterministic non-OTP failure stops.
- OTP is ephemeral to the exact requesting executor, absent from argv/logs/Git/persistent events; overseer sees request status only. On uncertainty inspect RubyGems artifact/version evidence before any retry.
- Success receipt identifies artifact digest, version, target registry, accepted authorization and actual publisher result. Merge evidence does not imply a release has happened.
- Central installed-service gate: gad.2 uses gad.b publisher executor implementation and installed receipt before executing its real pilot row. This source workflow does not depend on gad.2 completion; its fake-publisher evidence is an input to that later run.

### Interface Contract

Existing tested publisher remains the publication entrypoint. `ace-hitl ask --kind otp --assignment ID --attempt ID --project ID` is issued only for a correlated publisher need; secret answer is consumed through protected IPC. The workflow returns publication receipt or classified blocker, not a prose-only success.

### Success Criteria and Verification Plan

- [ ] SC1: Fake publisher: direct success, OTP needed, rejected/expired OTP, non-OTP failure, uncertain result and duplicate delivery; no secret in emitted artifacts.
- [ ] SC2: Deliver the publication workflow and runnable pilot scenario contract: named artifact/version/head, scoped authority, protected OTP, classified uncertainty and exact receipt. The actual authorized installed release is the sole gad.2 `scoped-publication` row, not this task's completion gate.
- [ ] SC3: Run affected `ace-test ace-hitl all` and release workflow fixture tests; retain exact-source independent review. gad.2 records the later real pilot receipt against this source/scenario version.

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
