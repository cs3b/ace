---
name: maintain-continuation
description: Bootstrap and resume native coordinator duties without duplicating execution.
doc-type: workflow
title: Maintain Coordinator Continuation
purpose: Own progress audits and cleanup through the existing in-process wake extension.
ace-docs:
  last-updated: '2026-10-16'
  last-checked: '2026-10-16'
---
# Maintain Coordinator Continuation

## Goal

Keep authorized project work advancing through native wakes and canonical Assign evidence across coordinator restarts.

## Prerequisites

Use the installed Pi ace-wake extension and the project's reviewed coordinator
role. The domain launcher owns process startup and its exact session path; ACE
owns the duty definitions below. A wake adds no execution or cleanup authority.
The selected runtime must load the reviewed package and effective project guide.

## Project Context Loading

Load the current role, effective `guide://project-delivery`, reviewed objectives,
and existing Assign, HITL and native runtime status. Resolve assets from the
selected installed bundle; source files or remembered versions do not prove
installation. Keep the objective queue's goal, next action, blocker and references
separate from Assign's execution ownership.

## High-Level Execution Plan

- Inspect the selected session and installed extension.
- Bootstrap duties only in a deliberately new coordinator session.
- Resume the exact existing session and verify its persisted subscriptions.
- Reconcile outcomes on each wake without repeating uncertain execution.

## Process Steps

### 1. Establish the native duties

For a deliberately NEW coordinator session, supply these two complete messages
to Pi's native command dispatcher before the role prompt. A supported launcher
may pass each as a separate positional initial message. They are Pi commands,
not shell commands or messages sent through the inbox/sendUserMessage API:

```text
/loop add progress-audit --interval 600 --message Run one bounded progress audit under wfi://overseer/maintain-continuation. Reconcile current project objectives with canonical Assign attempts, results and HITL decisions; continue the next authorized action using original references. Keep unknown outcomes open and do not repeat an uncertain effect.
/loop add lifecycle-cleanup --interval 3600 --message Run one bounded cleanup audit under wfi://overseer/maintain-continuation. Reconcile owned panes and worktrees with accepted Assign results and preserved work; use the existing cleanup owner only when its preservation and no-writer gates pass. Retain active or uncertain work.
```

Run one harmless model turn to persist the session. Verify the real session file
contains the extension's custom entries and `/loop list` reports one copy of each
duty with intervals 600 and 3600. A started process, successful prompt send or
in-memory definition alone is insufficient. Never synthesize session entries.

### 2. Resume without re-registering

Before stopping an idle coordinator, verify its current session ID and exact
persisted session file through the native runtime. Use the launcher's supported
exact-session resume (`--session` with that verified path in Pi). Do not use a
latest-session selector or create a new session with the old ID.

On resume, let ace-wake restore its existing session entries once. Do not replay
`/loop add`, reconstruct definitions from these defaults, or recreate deliberately
removed duties. Report the restored effective subscriptions, including deliberate
removals. No missed-tick replay, second timer service or alternate scheduler.

### 3. Audit progress every ten minutes

Inspect each selected project's objectives, canonical attempt state, native
liveness, pending review/integration and delivered HITL outcomes. Observe actual
process start and accepted results separately from dispatch acknowledgment.
Reuse the original assignment, attempt, request and mutation after a lost reply;
query/reconcile before any retry. An uncertain attempt retains its slot.

Update only the objective's next action, blocker and evidence references. Advance
one serial integration candidate after the previous canonical result; do not
rebase the entire queue. A blocked project must not prevent an independently
authorized project from progressing. Report meaningful changes or required human
action through the existing authorized project route; unchanged state stays quiet.

### 4. Audit cleanup every hour

Reconcile exact pane/session/assignment/attempt identities. Close an owned pane
only after its result is accepted and work is durably preserved; close its tab
when that was its last pane. Worktree removal separately requires the existing
preservation and no-writer checks, including commits and valuable untracked files.
Use the existing cleanup owner's preview and accepted operation. Do not infer
permission from apparent idleness, a disappeared process or a closed pane.

### 5. Maintain project watches

When continuation depends on a known local queue or result path, register a named
`/watch add NAME --path PATH --message TEXT` through the same native dispatcher.
Use the exact selected project's path and reconcile actual canonical state when
woken. Watches are hints, not execution receipts. Persist and resume them through
the same session mechanism; do not create an external poller to replace them.

## Success Criteria

- The installed native session persists and restores each effective duty once.
- A real wake is consumed by the original session and produces an attributable audit.
- Repeated wakes and lost replies do not launch a second execution.
- Active or uncertain work remains preserved; cleanup uses its existing owner.
- Independent project progress and user conversation remain responsive.

## Error Handling

Missing extension, unresolved effective guide, unavailable canonical state or a
mismatched session is an explicit blocker. Preserve the original references and
session file; do not manufacture subscriptions, silently change harness/model or
claim that a dead process will wake itself. Use the existing domain lifecycle
owner for a controlled restart and verify the resulting native session.
