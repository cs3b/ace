---
id: 8xf.t.ei9.0
status: in-progress
priority: high
created_at: "2026-10-16 10:57:17"
tags: []
parent: 8xf.t.ei9
estimate: large
dependencies: []
bundle:
  presets: [project]
  files: [AGENTS.md, docs/tools.md, .ace-tasks/8xf.t.ei9-wave-3/8xf.t.ei9-wave-3.s.md, .ace-tasks/8xf.t.ei9-wave-3/environment-contract.md, .ace-tasks/8xf.t.ei9-wave-3/observations-and-acceptance.md, .ace-tasks/8xf.t.ei9-wave-3/ux/usage.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/8x3.t.xz9-execute-scoped-services-across-os-users-with.s.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/5-make-integration-handoff-actionable-accepted/8x3.t.xz9.5-make-integration-handoff-actionable-accepted-attempts.s.md]
  commands: []
title: Execute authorized Forgejo integration with canonical results
needs_review: false
---

# Execute authorized Forgejo integration with canonical results

Advisory size: **large**. Existing code owners: 8x3.t.xz9, 8x3.t.xz9.5.
This child owns the observable program outcome; reuse/adopt their delivered work,
implement only remaining behavior there, and do not duplicate or reopen archived owners.
## Outcome and interface

A project overseer submits one eligible PR through a real public scoped service;
its admitted request reaches an executor and returns a canonical Assign result.
Host chat is not the per-item scheduler. Reuse xz9.4/.5 and provider ownership;
verify remaining installed composition rather than rebuild already landed code.

Input: project/repository/provider, intended PR, expected head/base, executed
checks, initial independent review and accepted-head assessment, dependencies,
authorization reference, canonical assignment/attempt and input digest.
Output: stable request/attempt, executor identity, admission/start evidence,
terminal receipt or rejected/uncertain; receipt binds PR, effect and remote target.
Status/recovery must be discoverable from the same request. Every CLI/Assign
entrypoint applies the same checks. Caller cannot choose another UID or supply
arbitrary privileged argv. Use configured receiver identity, no worker sudo/token.

## Required behavior

- Run the actual CLI with valid configuration and canonical coordinator. Missing
  config gives a precise refusal, never a constructor error or fake success.
- Producer and executor bind ONE authoritative Assign journal identity/ref. An
  installed service identity is its sole writer; the requester cannot modify the
  repository, ref, checkout, lock or any ancestor. Producer/status reads are
  read-only. Attempt/proposal mutations must cross admitted existing owner APIs,
  including recovery. Copying the journal into an integration checkout or granting
  shared write permissions is forbidden. Source join and installed isolation must
  both be verified before enabling the receiver.
- Forgejo provider performs actual PR merge/readback. Local update-ref and
  synthetic observations cannot prove it. Do not mutate checked-out main locally.
- Send server-side expected accepted head (head_commit_id for Forgejo), then
  read back exact PR/merged SHA/target. GET alone cannot prevent a head race.
- Trusted authorization/config refresh must match producer digest; bind exact
  candidate/input/project/expiry. Revocation and expiry apply while running.
- A second scoped decision is created and admitted AFTER first merge with the
  receiver still running: no preloaded pair, per-PR root edit or restart.
- After attempted effect, nil/404/unavailable readback stays uncertain. No-effect
  requires positive attributable evidence; reconcile before any repeat mutation.
- Formal reviewer APPROVED actor/state/SHA and initial independent report remain
  distinct from integrator delta assessment; follow child .8, not self-approval.

## Canonical review prerequisite

Before the first installed merge, dereference review and executed-check references
through the sole Assign owner. Validate accepted source records, exact report and
artifact digests, candidate/head association and reviewer independence at admission
and before effect. Caller-supplied `approved` fields, reviewer names, timestamps
and plausible SHA strings cannot certify review or execution, even when an exact
request digest has a separate authorization. Missing/corrupt/revoked records refuse
without a forge mutation. The ordinary candidate/review ingress shared with .8
is a prerequisite to this acceptance; it precedes .5 publication/OTP work.

## Verification and failure acceptance

Execute two real sequential PR merges from the project caller, without host chat;
retain request/start/provider/readback receipts. Restart caller/receiver after a
lost response and recover the same effect once. Deny missing grant, wrong UID,
wrong project, stale base/head, wrong reviewer and expired/revoked decision.
Change head between GET and POST: provider refuses before merge. Inject nil/404
after attempted merge: both invoked/ambiguous recovery remain uncertain, never
settle_no_effect or replay. Untrusted config refresh refuses without wider rights.
Source tests through ace-test plus installed real OS/provider evidence are separate.

## Completion boundary

Callable installed slice works with precise refusals and canonical receipts.
The full protected-runtime replacement program is not a prerequisite; no protected
denial is bypassed by calling this ordinary route. Record installed authority.

## Context and readiness

Load this child’s explicit bundle, including environment-contract.md and traceability.
Validate effective public interfaces on the selected source/runtime before effects;
missing capability is a precise readiness result, not permission to invent a route.
Use bin/ace-test or bin/ace-test-suite for focused source checks; installed proofs
are separately attributed. Captain overrides the brief; report results/conflicts to owner.
