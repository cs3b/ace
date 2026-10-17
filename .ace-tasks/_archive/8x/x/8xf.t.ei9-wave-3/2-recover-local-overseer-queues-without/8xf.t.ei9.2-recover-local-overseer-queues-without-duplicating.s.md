---
id: 8xf.t.ei9.2
status: skipped
priority: high
created_at: "2026-10-16 10:57:18"
tags: [superseded-no-daemon]
parent: 8xf.t.ei9
estimate: medium
dependencies: [8xf.t.ei9.1]
bundle:
  presets: [project]
  files: [AGENTS.md, docs/tools.md, .ace-tasks/8xf.t.ei9-wave-3/8xf.t.ei9-wave-3.s.md, .ace-tasks/8xf.t.ei9-wave-3/environment-contract.md, .ace-tasks/8xf.t.ei9-wave-3/observations-and-acceptance.md, .ace-tasks/8xf.t.ei9-wave-3/ux/usage.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/8wr.t.qk0-coordinate-responsive-overseer-roles-without-the.s.md, .ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/8wr.t.qkb-run-assignment-delivery-workflows-through-named-forge.s.md]
  commands: []
title: Recover local overseer queues without duplicating execution
needs_review: false
---

# Recover local overseer queues without duplicating execution

Advisory size: **medium**. Existing code owners: 8wr.t.qk0, 8wr.t.qkb.
This child owns the observable program outcome; reuse/adopt their delivered work,
implement only remaining behavior there, and do not duplicate or reopen archived owners.
## Outcome and interface

Local `.ace-tasks/overseer/` stores objective, completion criteria, dependencies,
next action, blocker/owner/deadline and references to canonical Assign executions.
This exact future runtime directory is gitignored by explicit Captain decision;
program specs, nonsecret decisions and durable results remain versioned.
Never duplicate Assign steps, effects or receipts in a second execution store.

Validate public ace-task create/list/update selector for the installed version
(`--in overseer` is intended, not an assumed existing syntax). Do not silently
map to `_overseer` or default list. IDs come from public tooling. Restart recovers
same objective/attempt and supports changed priority/pause/resume without duplicates.

Implementation list legitimately ends PR-ready including its children/parent.
Separate delivery list refers to producer tasks without reparenting. Do not
change automatic parent completion, add completion:explicit or artificial
blocking children. Delivery/installed acceptance is separately owned and cannot
close merely because worker tasks are done; use explicit completion evidence.

## Hygiene and failure behavior

At picking work, wake, restart and closure reconcile task/parent/owner with actual
source, release and installed receipts. Preserve truthful blocked/failed state
with actionable owner; no paper-close because another package progressed.
Specs/tasks themselves use dedicated worktrees and appropriate independent review.
No canonical branch switching, stash of foreign WIP or deletion for clean status.
Empty tool-minted skeleton may be removed only after content comparison proves
supersession, durable replacement exists and no active author owns it.

## Verification

Public create/list/update reads exact directory; git check-ignore includes only
runtime queue, not this program. Restart with active/completed/uncertain attempt
adopts correctly; two sessions do not duplicate execution. Corrupt/missing queue
reconstructs from canonical records or reports unknown, never invents success.
Test source-done plus installed-failed and premature status-only done PR: delivery
remains open. Preserve valuable untracked work while identifying a proven redundant
skeleton. No .gitignore/runtime changes are made by this specification itself.

## Context and readiness

Load this child’s explicit bundle, including environment-contract.md and traceability.
Validate effective public interfaces on the selected source/runtime before effects;
missing capability is a precise readiness result, not permission to invent a route.
Use bin/ace-test or bin/ace-test-suite for focused source checks; installed proofs
are separately attributed. Captain overrides the brief; report results/conflicts to owner.

## Superseded (2026-10-17, Captain's architecture decision)

Skipped: the remaining work as specified assumed the socket-owner/installed
acceptance model. Superseded by: state on files, no background processes,
gems self-service from RubyGems. Reassigned to the successor program
"Python→Ruby migration: file-based Lab, zero daemons".
