---
name: overseer-bootstrap-delegation
description: Delegate project startup to lab workers and accept their observed results
allowed-tools: Bash, Read
doc-type: workflow
title: Delegated Project Bootstrap
purpose: Complete one lab-owned startup commission without the overseer doing the repair.
---
# Delegated project bootstrap

If tool output truncates any instruction, reload this workflow with
`wfi://overseer/bootstrap-delegation --output cache --compressor off` and read
the returned file before proceeding. In installed mode run `ace-bundle`; in
an ACE source checkout in auto mode use its `bin/ace-bundle`. Never infer a
missing deadline or command.

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

From the lab root, use the explicit private-folder selector when creating
the manager; a title or `lab-coordination` tag does not select its location:

```bash
ace-task list --in _overseer
ace-task create "Bootstrap <project> readiness" --in _overseer --tags bootstrap,lab-coordination
ace-task create "Prepare <project>" --child-of <manager-ref>
ace-task create "Independently verify <project>" --child-of <manager-ref>
ace-task create "Confirm start <project>" --child-of <manager-ref>
ace-task update <verify-ref> --add dependencies=<prepare-ref>
ace-task update <confirm-ref> --add dependencies=<verify-ref>
ace-task show <manager-ref>
ace-task list --in _overseer
```

Use the full task IDs returned by the commands, not abbreviated references.
Children inherit the parent's location.
Before dispatch, verify the manager and its three direct children resolve
under `<lab>/.ace-tasks/_overseer/` and are gitignored. A manager in the public
task root does not satisfy this contract. Reconcile its location through the
task owner's public CLI before dispatch; do not create a duplicate commission
or treat a successful worker report as proof that the manager is private.

Create the executable bootstrap task through `ace-task` in the target project's
canonical root, linking it as the private lab manager's `project_task` and
recording `project_root`. Keep its specification in its project task folder.
Run executable-task creation, lookup, coworker preparation and role handoff
from that project. Run private coordination-task updates from the lab root.
Shell calls do not retain a preceding call's working directory. The worker receives
only the project mount and cannot read lab-private tasks. The lab's installed
observation reads configured project assignments and reports from their owners;
records remain in the project rather than being copied into lab state. Include the canonical target repository path, required
configuration, observed failure, desired outcome, allowed changes, runtime
mode, acceptance checks and report recipient. Assign diagnosis and reproduction
as well as preparation to the worker. This task describes infrastructure setup within the project, separate from its product issue backlog.

The preparation and verifier acceptance checks stop at a validated project
configuration and readiness to start. Do not require a running project
Overseer, a first turn, or active project eyes in either worker assignment:
those are the coordinator's confirm-start checks after verification. Workers
must not start the project Overseer themselves. This prevents a circular gate.
Worker/verifier checks must be executable with their commissioned session's
permissions. Validate the prepared configuration, installed CLI/gem paths and
owned project files. Do not require host-wide `ace-lab verify`, host D-Bus or
systemd inspection, reading either overseer's private task tree, or a healthy
full `ace-overseer observe` projection from a worker session. Those checks need
the host or overseer role; private-tree masking is intentional.
`ace-task doctor` from the canonical project root also enumerates the masked
`.ace-tasks/_overseer` directory. Commission any task-store check for the
worker or verifier in the execution worktree. The authorized project Overseer
can audit the canonical task store after start. A worker reports
missing authority and the exact blocked check instead of repairing host services
or attempting to access the coordinator's private state. The coordinator proves
full observation from the authorized project Overseer during confirm-start.
`ace-coworker status` describes one commissioned executor, not whether a
project can host an Overseer. A canonical project without a default coworker
commission is not a bootstrap defect. Do not require or create a canonical
`.ace-local/coworker/config.yml` merely to make that query ready, and never copy
a worktree commission into another checkout where its assignment cannot resolve.
Read an executor's status in its returned worktree with its returned `--config`.
A configuration parse, exit zero or absence of the words "not ready" is not
proof of readiness: require the intended identity and resolved assignment.
Do not require a worker or verifier to rerun `prepare` as an acceptance check
while its assignment is active. Preparation coordinates executors; its active
executor conflict is not a configuration validation result. Accept project
configuration through its own documented schema and installed runtime checks.

The commission must include the target project's eyes configuration path
`<project>/.ace-local/overseer/eyes.json` and
the project Overseer's configured HITL recipient for its own eyes, separately
from the lab recipient that receives bootstrap reports: the worker prepares the configuration
and the independent verifier checks it before project start. Missing or
ambiguous recipient information is a blocker, never a guessed address. The
project Overseer arms the prepared configuration; it does not create or edit it.
The project's private task directory is `<project>/.ace-tasks/_overseer`;
never require or create a top-level `<project>/_overseer` directory.

Put all commission and supporting files in the executable task's own tracked
folder, never in the private `_overseer` tree. Before preparing its worktree,
commit those files and the task specification using the task/commit tools.

Resolve the executable task in its owner checkout and use the returned
file's parent directory:

```bash
cd "<canonical-project-root>" && ace-task show "<project-task-id>" --path
```

If lookup reports not found, check the command's working directory and the
task ID from the create result. Correct the lookup once. If it still fails,
record the blocker on the private coordination task and end the turn.
Check `git status --short -- <task-directory>` in the project: uncommitted
or untracked supporting files will not appear in the new worktree.

After preparation, verify every referenced commission file exists in the
returned worktree before launch. If one is missing, report a preparation
failure and keep the worker unstarted.
Workers must not edit the private coordination tree. Resolve each task
folder from its owner's checkout before writing commission, dispatch or
receipt notes. Use the returned path even when it differs from the title slug.

Explicit `ACE_TOOLCHAIN=installed` remains installed in every subprocess,
worker and resumed session. The project checkout is domain data. Never modify
tracked binstubs to bypass this selection. In auto mode retain the project's
own dependency model. If package code is defective, commission its repair;
do not patch installed gems. Preserve unrelated changes.

## Arm eyes before dispatch

Use the lab's existing eyes JSON configuration, including its configured project observations. The `ace_eyes` tool accepts
`{"action":"start","configPath":"<absolute eyes JSON path>"}`.
Inspect the returned state: enabled=true, breaker=null, errors=0 and at least
one observation. Read pending revisions from their original owners, reconcile
existing commissions, and ack each exact key/revision only after acceptance.
A missing extension, invalid configuration or degraded source blocks dispatch;
report that capability gap. Do not claim that mentioning `/eyes` armed it.

## Prepare and actually launch a worker

Read the lab's armed eyes configuration to identify the commissioning
coordinator's recipient, then resolve that address in the target project's
HITL configuration. Use the target configuration's key for THAT same lab
address, not its project Overseer address. Lab and project coordinators must
have distinct configured addresses, with absolute folder paths when using
folder-form addresses. A relative `.ace-local/hitl` repeated across roots does
not identify which coordinator owns the report. The task specification, `--to`, and returned start configs
must agree; do not invent an address or append a machine suffix. If no valid
recipient is configured, report a blocking gap before dispatch.

From the target project root, use `ace-coworker prepare --task <executable-task> --roles bootstrap-worker,bootstrap-verifier
--to <configured-lab-recipient> --format json`. Read its returned worktree,
assignment IDs and start-config paths; record these on the matching private
steps before launch through the task API, not only in prose:

```bash
ace-task update <prepare-step> --set assignment=<worker-assignment> --set role=bootstrap-worker --set worktree=<returned-worktree>
ace-task update <verify-step> --set assignment=<verifier-assignment> --set role=bootstrap-verifier --set worktree=<returned-worktree>
ace-task update <confirm-step> --set role=confirm-start
```

Start-config paths returned by preparation are relative to the returned
execution worktree, not the canonical project root. Pass the returned path with
that worktree as cwd, or join it to that worktree for an absolute path. Verify
that exact file exists before dispatch; use the same rule for the verifier's
handoff config. Never replace its base directory with the canonical project.

Read back the steps with `ace-task show` and verify exact returned identities.
A preparation readiness report is not worker completion. It does not complete
any of these three steps; never label bootstrap execution as `role=planner`.
Only a separate, explicitly commissioned planner preparation allocation may
accept an unassigned readiness report.
The task must be present in the execution worktree before any agent starts.

`ace-coworker start --config <returned-path>` validates and prints a brief;
it does NOT launch an agent. In the isolated lab use public `ace-herdr dispatch`
with `--cwd <returned-worktree>`, `--role worker` (or `verifier` for independent
verification), `--label <assignment-id>` and `--prompt-file <commission-file>`.
The host selects the installed runtime and standing role instructions. For
each leg write a separate prompt file named for its assignment. Its first
lines must name the bootstrap role, exact assignment ID and exact returned
start-config path. Direct the executor to read that config with
`ace-coworker start --config <path>`, drive that assignment and finish
with `ace-coworker report --config <path>`. Keep the shared task commission
as context referenced by the prompt. Before dispatch, verify the prompt,
config, assignment label and host role all refer to the same leg. The bootstrap
role allows changes to the commissioned canonical project configuration; ordinary product
worker/reviewer roles stay within their task worktree.

Before dispatch, record the commission path on the private step and arm the
startup deadline. Use `ace_eyes` action `deadline`, key
`bootstrap-<assignment-id>`, revision `<assignment-id>` and
`at=now_unix_ms + 300000`. Keep it armed if acknowledgement is uncertain.
Allow the dispatch tool call up to 180 seconds. The dispatcher waits until the terminal can accept input, submits the
commission once and returns the real terminal and normalized agent name.
Record those returned identities on the matching private step. An existing
name or uncertain acknowledgement means preserve and reconcile that session;
never retry by inventing another name or using a plain shell start.

If the deadline cannot be armed, report the observation blocker before
dispatch. End the supervisor turn after recording the dispatch outcome. Do not use sleep,
completion waits or polling. The already armed eyes observes assignment,
report and session changes without additional model turns while unchanged.

On wake, inspect the recorded terminal once with `herdr agent get <terminal>`.
If dispatch did not return one, use `herdr agent list` to find the unique
assignment-labelled session with the expected role and worktree. Record and
use its full `term_…` ID. Pane indexes such as `p5` are display identifiers.
Read the pinned assignment through its owner in the returned worktree.
An active step or a step report for that exact assignment proves execution
began. A busy terminal without progress on the pinned assignment is only
evidence that Pi is running. Cancel the corresponding eyes deadline once
confirmed. If the deadline fires and the session is idle with the pinned
assignment untouched, verify the prompt/config binding. Allow a correction
when that binding was wrong, or a recovery when delivery was uncertain and
the session is interactive-ready with no completed turn. In either case,
require that the private step has no earlier correction attempt. Record
`prompt_correction=attempted` before sending the corrected or original
leg-specific prompt to the same session with `herdr agent prompt`. Arm one
new deadline `bootstrap-recovery-<assignment-id>` after confirmed delivery.
Cancel it on activity of that assignment or a report. If it expires,
delivery remains uncertain, or confirmed delivery produced no assignment
activity, record the unconfirmed start and escalate through HITL.

End the overseer's turn immediately after dispatch. The eyes timer observes
assignment and HITL revisions without invoking the model on unchanged state.

## Receive, verify, start

On wake, read the original report and current assignment. Require matching
report ID, task, assignment and role; a preparation report, process exit or
unmatched message is not success. The observation carries `project_root` and
the original report ID; read the report and `ace-coworker status` through their
public CLI in that project/worktree. Only accept worker success with a completed
non-empty assignment and the promised evidence. The private coordination tree
stays in the lab: do not run a project-local report processor against lab task
IDs or infer completion from a report file alone.
Record the actual accepted HITL event ID and result in step metadata through
`ace-task update <step> --set processed_report=<event-id> --set report_result=<result>`
using the lab task owner.
Mark done only after acceptance; errors keep the step open. If the executor
observation loses the recorded terminal while its assignment is incomplete,
verify the absence in Herdr and record the interruption before reconciling
that assignment. A disappeared session cannot complete a bootstrap leg. Receipt notes in
the path returned by `ace-task show` supplement these fields, never replace them.
Read back the recorded identity before acknowledging the eyes revision.
Never put a preparation readiness ID on a worker, verifier or confirm-start step.

From the target project root, use `ace-overseer handoff --dry-run --task <task>` to read
the existing role handoff gate and returned start configuration for the independent reviewer after
worker completion. As with the worker, a printed start command is not a live
agent: launch the reviewer separately with its own returned role/config, using
a new verifier-only prompt file with the verifier assignment and verifier
start config, plus its own first-turn deadline keyed to that assignment.
The worker prompt and the shared task commission are invalid as verifier
dispatch prompts. Do not launch a second
executor while an earlier one is active or its state is unknown. On repeated delivery, reconcile existing
assignments and agents instead of dispatching again.

Only after accepted worker completion and independent verification does the
overseer perform this commission's project-start coordination operation `ace-overseer start --reconcile`. Confirm the target's session, first
turn and active eyes through that command's authenticated readiness result.
For the target project, `ready=true` proves the matching isolated session's
first turn and active eyes; a terminal's `done` or `interactive_ready` alone
does not. Record the returned target identity and readiness on confirm-start.

When the target returns `ready=false`, preserve its session. Arm one eyes
first-turn deadline (`key=confirm-start-<project-id>`, `revision=<terminal-id>`,
`at=now_unix_ms + 60000`) and end the turn. On a project-session revision or
that deadline, rerun `ace-overseer start --reconcile` from the lab root once.
It reuses the existing session and checks its evidence without resending the
prompt. Cancel the deadline when readiness is confirmed. The deadline is an
observation checkpoint, not a startup failure threshold. If it fires while
readiness remains false, reconcile the actual session activity through Herdr's
public agent state. A matching session still working on its first turn remains
pending: record that fact, acknowledge the handled project-session revision,
cancel the consumed deadline and keep project-session observation armed.
At this first pending checkpoint, arm one separate startup watchdog
(`key=confirm-stall-<project-id>`, `revision=<terminal-id>`,
`at=now_unix_ms + 1800000`) and record its identity on confirm-start before ending the turn. Never
rearm it on subsequent revisions or after session resume. On its expiry,
reconcile readiness and, if still unconfirmed, delegate diagnosis while
preserving the existing session; elapsed time alone never authorizes restart.
Cancel this watchdog when readiness is confirmed or diagnosis takes ownership.
On the next project-session revision, check authenticated readiness again.
Do not ask the Captain whether to keep
waiting for an active session, repeatedly rearm deadlines or poll.

If the session has finished its turn without readiness, exited, or is blocked,
delegate diagnosis with the observed state and readiness result. Unknown
activity or unavailable observation is an explicit unresolved state, never
permission to launch a duplicate or declare success. Escalate only an actual
decision or missing authority; ordinary first-turn latency needs neither.

Do not read implementation files, inspect another session's private files, or
infer another agent's eyes from your own `ace_eyes status`. The public readiness
result is the proof boundary; inability to obtain it is a blocker for the
executor to diagnose. Close the confirmation step and managing task only with
these proofs; the worker report alone cannot close the family.
If first-prompt delivery is unconfirmed, preserve the existing session and do
not submit the prompt again. Inspect its actual activity and escalate an
unresolved delivery through HITL. The project-session observation can wake you
on a configured project's Herdr state change; that state alone does not prove
the project has armed eyes.

On error, keep the step open and route repair to the worker. Missing authority
or an actual Captain decision becomes a precise HITL question; end the turn
armed for its answer. Never self-repair or use sleep-poll while waiting.
