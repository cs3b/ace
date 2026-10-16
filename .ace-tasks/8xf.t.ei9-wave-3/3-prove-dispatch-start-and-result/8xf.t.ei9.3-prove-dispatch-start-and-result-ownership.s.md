---
id: 8xf.t.ei9.3
status: in-progress
priority: high
created_at: "2026-10-16 10:57:18"
tags: []
parent: 8xf.t.ei9
estimate: medium
dependencies: [8xf.t.ei9.1]
bundle:
  presets: [project]
  files: [AGENTS.md, docs/tools.md, .ace-tasks/8xf.t.ei9-wave-3/8xf.t.ei9-wave-3.s.md, .ace-tasks/8xf.t.ei9-wave-3/environment-contract.md, .ace-tasks/8xf.t.ei9-wave-3/observations-and-acceptance.md, .ace-tasks/8xf.t.ei9-wave-3/ux/usage.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/8wr.t.qk0-coordinate-responsive-overseer-roles-without-the.s.md, .ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/8wr.t.qkb-run-assignment-delivery-workflows-through-named-forge.s.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/8x3.t.xz9-execute-scoped-services-across-os-users-with.s.md]
  commands: []
title: Prove dispatch start and result ownership
needs_review: false
---

# Prove dispatch start and result ownership

Advisory size: **medium**. Existing code owners: 8wr.t.qk0, 8wr.t.qkb, 8x3.t.xz9.
This child owns the observable program outcome; reuse/adopt their delivered work,
implement only remaining behavior there, and do not duplicate or reopen archived owners.
## Outcome and interface

A handoff is accountable from selected workflow/authorized executor through actual
start and adopted terminal result. Prompt transport acceptance, requester admission,
actual execution and owner consumption are distinct facts; do not add mandatory
native read receipts/signers just to prove the agent read terminal text.

Record project/task/assignment/attempt, fresh session/pane/tab, worktree/cwd,
request and expected result owner. State distinguishes ready-not-dispatched,
accepted-not-started, running, rejected, uncertain and reconciled-terminal.
Accepted requires durable executor request ID; running requires actual execution
proof. Local reviewed SHA is not remote-ready. Old terminal output is not liveness.
Callback targets project owner, not Lab coordinator by accidental default.

## Behavioral gates

For each operation discover callable input/status/recovery; sending a relay brief
is not executor acceptance. Ack/start deadlines reconcile same request and name
actual responsible owner, missing capability and next remediation. No fabricated
all-lanes-hold: independent eligible work proceeds. Failed callback is visible;
owner adopts canonical result after wake/restart without duplicate worker/effect.

PR create/update correlates operation, intended PR or new-PR intent, configured
repo, expected head with returned PR ID/head and remote readback. AGit adoption/
overwrite mismatch is identity-conflict, not success; preserve original refs and
reconcile before proceeding. No broad force-push to fix identity confusion.

Times: eligibility, dispatch, admission, start/end, reconciliation and cleanup.
Expose false-ready/false-working count, stale age, active-work versus owner-wait;
unknown timestamps stay unknown, not synthetic precision. A piped tail exit0 or
launch sleep does not prove command success. Inspect actual terminal exit/result.

## Verification and failure acceptance

Idle pane with old output stays idle; wrong callback recipient is caught; local
reviewed/remote-old is not merge-ready. Missing ack/start triggers targeted single
escalation, not unchanged WAIT spam. Drop terminal callback then restart owner:
canonical result is adopted once. Returned wrong PR ID does not overwrite another
PR. Failed evidence attachment halts dependent merge; readback must precede it.
Compare metrics with executed event timeline and retain actual provider evidence.

## Context and readiness

Load this child’s explicit bundle, including environment-contract.md and traceability.
Validate effective public interfaces on the selected source/runtime before effects;
missing capability is a precise readiness result, not permission to invent a route.
Use bin/ace-test or bin/ace-test-suite for focused source checks; installed proofs
are separately attributed. Captain overrides the brief; report results/conflicts to owner.
