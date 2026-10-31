---
name: overseer-bootstrap-delegation
description: Delegate project startup to lab workers and accept their observed results
allowed-tools: Bash, Read
doc-type: workflow
title: Delegated Project Bootstrap
purpose: Complete one lab-owned startup commission without the overseer doing the repair.
---
# Delegated project bootstrap

## Commission and ownership

The overseer reads owner state and public CLI contracts to establish scope,
existing execution and the observed symptom. Technical diagnosis, source-code
investigation, troubleshooting and reproduction commands belong to the worker.
Record the known failure and desired outcome in the commission; discovering
the root cause is part of the assigned work, never a prerequisite for dispatch.
Use existing readiness state, or a startup dry run only when that state is
otherwise unknown. Do not turn that check into a technical investigation.
Once the symptom is known, proceed to task creation/reconciliation, observation
and worker dispatch, then end the turn.

Read existing tasks and assignments first. Reuse the open commission for the
same project and goal; unknown execution state never means free capacity.
Create one lab coordination task in `_overseer`, with three direct children:
prepare, independently verify, confirm start. The latter two depend on their
predecessor. Only the lab overseer updates this private tree.

Create a separate executable lab task through `ace-task` for the bootstrap
work, linking it as the manager's `project_task`. Keep its specification in
its task folder. Include the canonical target repository path, required
configuration, observed failure, desired outcome, allowed changes, runtime
mode, acceptance checks and report recipient. Assign diagnosis and reproduction
as well as preparation to the worker. This is lab infrastructure work, not a project product task.
Workers must not edit the private coordination tree.

Explicit `ACE_TOOLCHAIN=installed` remains installed in every subprocess,
worker and resumed session. The project checkout is domain data. Never modify
tracked binstubs to bypass this selection. In auto mode retain the project's
own dependency model. If package code is defective, commission its repair;
do not patch installed gems. Preserve unrelated changes.

## Arm eyes before dispatch

Use the lab's existing eyes JSON configuration. The `ace_eyes` tool accepts
`{"action":"start","configPath":"<absolute eyes JSON path>"}`.
Inspect the returned state: enabled=true, breaker=null, errors=0 and at least
one observation. Read pending revisions from their original owners, reconcile
existing commissions, and ack each exact key/revision only after acceptance.
A missing extension, invalid configuration or degraded source blocks dispatch;
report that capability gap. Do not claim that mentioning `/eyes` armed it.

## Prepare and actually launch a worker

Use `ace-coworker prepare --task <executable-task> --roles bootstrap-worker,bootstrap-verifier
--to <configured-overseer-address> --format json`. Read its returned worktree,
assignment IDs and start-config paths; record these on the matching private
steps before launch. A preparation readiness report is not worker completion.
The task must be present in the execution worktree before any agent starts.

`ace-coworker start --config <returned-path>` validates and prints a brief;
it does NOT launch an agent. Use the configured Herdr provider/profile to
start a separate worker agent in the returned worktree, load the returned
role instructions, and send its first prompt. The prompt commissions only
that task and pinned assignment, requires the worker to read its start brief,
drive that assignment, and finish with `ace-coworker report`. These operational roles explicitly allow the commissioned canonical target
outside the lab task worktree; ordinary product worker/reviewer roles do not.
Use CLI help for
Herdr's current arguments. Record the returned pane/agent identity and verify
first-turn delivery. Never replace a missing executor with your own work.

End the overseer's turn immediately after dispatch. The eyes timer observes
assignment and HITL revisions without invoking the model on unchanged state.

## Receive, verify, start

On wake, read the original report and current assignment. Require matching
report ID, task, assignment and role; a preparation report, process exit or
unmatched message is not success. Use `ace-overseer process-reports --dry-run`
to inspect the matching and continuation before applying it. Only accept
worker success with a completed non-empty assignment and the promised evidence.
Record receipt through task APIs before acknowledging the eyes revision.

Use the existing role handoff gate to prepare the independent reviewer after
worker completion. As with the worker, a printed start command is not a live
agent: launch the reviewer separately with its own returned role/config and
confirm first-turn delivery. Do not launch a second executor while an earlier
one is active or its state is unknown. On repeated delivery, reconcile existing
assignments and agents instead of dispatching again.

Only after accepted worker completion and independent verification does the
overseer perform this commission's project-start coordination operation `ace-overseer start --reconcile`. Confirm the target's session, first
turn and active eyes from actual session evidence. A ready process alone is
not initialized observation. Close the confirmation step and managing task
only with these proofs; the worker report alone cannot close the family.

On error, keep the step open and route repair to the worker. Missing authority
or an actual Captain decision becomes a precise HITL question; end the turn
armed for its answer. Never self-repair or use sleep-poll while waiting.
