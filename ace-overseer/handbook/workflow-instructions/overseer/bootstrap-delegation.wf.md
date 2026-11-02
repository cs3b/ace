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
Run every `ace-*` command directly, without a pipe, redirection or output
post-processing. Record its actual exit status; if it prints a path, read the
file. A pipeline's exit status cannot establish that an ACE operation passed.
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

The preparation and verifier acceptance checks stop at a validated project
configuration and readiness to start. Do not require a running project
Overseer, a first turn, or active project eyes in either worker assignment:
those are the coordinator's confirm-start checks after verification. Workers
must not start the project Overseer themselves. This prevents a circular gate.
The commission must include the target project's eyes configuration path and
the actual configured HITL recipient: the worker prepares the configuration
and the independent verifier checks it before project start. Missing or
ambiguous recipient information is a blocker, never a guessed address. The
project Overseer arms the prepared configuration; it does not create or edit it.
The project's private task directory is `<project>/.ace-tasks/_overseer`;
never require or create a top-level `<project>/_overseer` directory.

Put all commission and supporting files in the executable task's own tracked
folder, never in the private `_overseer` tree. Before preparing its worktree,
commit those files and the task specification using the task/commit tools.

Resolve the task file through `ace-task show <ref> --path` and use its parent
directory. Check `git status --short -- <task-directory>`: uncommitted or
untracked supporting files will not appear in the new worktree.

After preparation, verify every referenced commission file exists in the
returned worktree before launch. If one is missing, report a preparation
failure and keep the worker unstarted.
Workers must not edit the private coordination tree. Resolve each task folder
from `ace-task show <ref>` before writing commission, dispatch or receipt notes;
never construct a folder from a guessed or expanded title slug.

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

Read the actual HITL configuration and use the exact configured recipient key
for the overseer. The task specification, `--to`, and returned start configs
must agree; do not invent an address or append a machine suffix. If no valid
recipient is configured, report a blocking gap before dispatch.

Use `ace-coworker prepare --task <executable-task> --roles bootstrap-worker,bootstrap-verifier
--to <configured-overseer-recipient> --format json`. Read its returned worktree,
assignment IDs and start-config paths; record these on the matching private
steps before launch through the task API, not only in prose:

```bash
ace-task update <prepare-step> --set assignment=<worker-assignment> --set role=bootstrap-worker --set worktree=<returned-worktree>
ace-task update <verify-step> --set assignment=<verifier-assignment> --set role=bootstrap-verifier --set worktree=<returned-worktree>
ace-task update <confirm-step> --set role=confirm-start
```

Read back the steps with `ace-task show` and verify exact returned identities.
A preparation readiness report is not worker completion. It does not complete
any of these three steps; never label bootstrap execution as `role=planner`.
Only a separate, explicitly commissioned planner preparation allocation may
accept an unassigned readiness report.
The task must be present in the execution worktree before any agent starts.

`ace-coworker start --config <returned-path>` validates and prints a brief;
it does NOT launch an agent. Use the configured Herdr provider/profile to
start a separate worker agent in the returned worktree, load the returned
role instructions, and send its first prompt. The prompt commissions only
that task and pinned assignment, requires the worker to read its start brief,
drive that assignment, and finish with `ace-coworker report`. These operational roles explicitly allow the commissioned canonical target
outside the lab task worktree; ordinary product worker/reviewer roles do not.
Before submitting a commission, record the pane and its current agent status.
Submit only when the agent is idle or done; for any other state, including
working, busy, blocked or unknown, reconcile the existing session and do not
send a duplicate prompt.
Then arm one eyes deadline for first-turn evidence:
call `ace_eyes` with `action=deadline`, `key=bootstrap-<assignment-id>`
(using only letters, digits, underscore or hyphen), `revision` set to the
assignment ID, and `at` set to the current Unix time in milliseconds plus
60000. If the deadline cannot be armed, do not dispatch; record the blocked
observation and raise a precise HITL case. Submit with
`herdr agent prompt <pane> <prompt>`,
passing the prompt as one safely quoted argument and excluding secrets. Omit
`--wait` and `--until`: those flags block on the worker's state. Do not
use `herdr agent wait`, sleep or polling to await completion. After the prompt
is accepted, record the pane/agent identity, acknowledge handled revisions and
end your turn. If submission is refused or fails, cancel its deadline with
`ace_eyes` `action=cancel` and the same `key`, record the failure and escalate the actual blocker. Assignment changes and the
worker report wake you through eyes.
On a wake, inspect the recorded pane once with `herdr agent list` and
`herdr agent read <pane>` to verify the first turn. A transition from idle or done to
working after submission or attributable first-turn output is evidence;
acceptance alone or a previously working status is not.
Cancel the deadline with `ace_eyes` `action=cancel` and the same `key` when confirmed. If evidence is absent before the deadline,
keep it armed and end the turn. If the deadline fires without evidence,
record the start as unconfirmed and escalate with a precise HITL case; do not
assert that a slow agent failed. Never replace a missing executor with your
own work or create another dispatch while its state is unknown.

End the overseer's turn immediately after dispatch. The eyes timer observes
assignment and HITL revisions without invoking the model on unchanged state.

## Receive, verify, start

On wake, read the original report and current assignment. Require matching
report ID, task, assignment and role; a preparation report, process exit or
unmatched message is not success. Use `ace-overseer process-reports --dry-run`
to inspect the matching and continuation before applying it. Only accept
worker success with a completed non-empty assignment and the promised evidence.
Record the actual accepted HITL event ID and result in step metadata through
`ace-task update <step> --set processed_report=<event-id> --set report_result=<result>`
(or let `process-reports` perform that same write after its dry run is checked).
Mark done only after acceptance; errors keep the step open. Receipt notes in
the path returned by `ace-task show` supplement these fields, never replace them.
Read back the recorded identity before acknowledging the eyes revision.
Never put a preparation readiness ID on a worker, verifier or confirm-start step.

Use the existing role handoff gate to prepare the independent reviewer after
worker completion. As with the worker, a printed start command is not a live
agent: launch the reviewer separately with its own returned role/config, using
the same nonblocking prompt and its own first-turn deadline keyed to the
reviewer assignment. Do not launch a second
executor while an earlier one is active or its state is unknown. On repeated delivery, reconcile existing
assignments and agents instead of dispatching again.

Only after accepted worker completion and independent verification does the
overseer perform this commission's project-start coordination operation `ace-overseer start --reconcile`. Confirm the target's session, first
turn and active eyes from actual session evidence. A ready process alone is
not initialized observation. Close the confirmation step and managing task
only with these proofs; the worker report alone cannot close the family.
If first-prompt delivery is unconfirmed, preserve the existing session and do
not submit the prompt again. Inspect its actual activity and escalate an
unresolved delivery through HITL. The project-session observation can wake you
on a configured project's Herdr state change; that state alone does not prove
the project has armed eyes.

On error, keep the step open and route repair to the worker. Missing authority
or an actual Captain decision becomes a precise HITL question; end the turn
armed for its answer. Never self-repair or use sleep-poll while waiting.
