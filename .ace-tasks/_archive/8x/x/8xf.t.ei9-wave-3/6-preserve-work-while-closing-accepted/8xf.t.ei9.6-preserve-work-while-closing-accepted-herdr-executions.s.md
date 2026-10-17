---
id: 8xf.t.ei9.6
status: skipped
priority: high
created_at: "2026-10-16 10:57:19"
tags: [superseded-no-daemon]
parent: 8xf.t.ei9
estimate: medium
dependencies: []
bundle:
  presets: [project]
  files: [AGENTS.md, docs/tools.md, .ace-tasks/8xf.t.ei9-wave-3/8xf.t.ei9-wave-3.s.md, .ace-tasks/8xf.t.ei9-wave-3/environment-contract.md, .ace-tasks/8xf.t.ei9-wave-3/observations-and-acceptance.md, .ace-tasks/8xf.t.ei9-wave-3/ux/usage.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/8wr.t.qk0-coordinate-responsive-overseer-roles-without-the.s.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/8x3.t.xz9-execute-scoped-services-across-os-users-with.s.md]
  commands: []
title: Preserve work while closing accepted Herdr executions
needs_review: false
---

# Preserve work while closing accepted Herdr executions

Advisory size: **medium**. Existing code owners: 8wr.t.qk0, 8x3.t.xz9.
This child owns the observable program outcome; reuse/adopt their delivered work,
implement only remaining behavior there, and do not duplicate or reopen archived owners.
## Outcome and interface

Every executor, including specwriter/reviewer/release/publisher, has its own work
pane for its active attempt. Project workspace is distinct from Lab coordinator.
Use short readable labels project/task/role-attempt (e.g. ace/xz95/worker-1), rename
state safely and never include secrets. Stable fresh IDs/session identify control;
labels and remembered pane numbers are not authority or durable addressing.

Fresh tab per active attempt; at most four panes/tab and usable terminal size.
Pending queue entries do not retain tabs. Confirm actual cwd/worktree and start;
a stale exited Pi screen is not a shell reusable by sending commands. Do not rely
on malformed grep parsing or sleep30 as launch proof. Resolve actual transport.

On accepted durable result, accepting overseer closes exact pane and last tab.
Worktree retention/removal has SEPARATE criteria: preserve commits, uncommitted
and untracked valuable work, reports and exact refs; prove no surviving writers or
uncertain effects before deletion. A process exiting alone is not accepted result.
Hourly native loop and restart sweep reconcile stale panes/tabs without holding
queue progress. Protect live/uncertain and other-project writers; unknown is retained.

## Worktree and task hygiene

Task/spec/rebase/release changes belong to dedicated worktrees; canonical checkout
stays clean on main. Preserve divergent local commits and dirty/untracked evidence
before syncing; no reset/stash/branch-switch as cleanup. Compare redundant minted
skeleton against its durable replacement and active ownership before deleting it.
No forced closure merely to satisfy pane cap; defer admission or report capacity.

## Verification and failure acceptance

After accepted result, pane disappears and final tab disappears while report/ref
remains accessible. Worktree stays if its preservation gate is incomplete. Test
restarted owner with stale IDs, exited harness screen, active writer, uncertain
operation, two projects and mixed valuable/redundant untracked files. Verify labels
and max4 at launch, not just eventual cleanup. A malformed address refuses before
sending to another terminal. Installed OS/runtime evidence is separate from fixture.

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
