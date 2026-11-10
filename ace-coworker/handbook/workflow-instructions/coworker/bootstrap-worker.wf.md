---
name: coworker-bootstrap-worker
description: Scoped operational bootstrap-worker for a canonical project bootstrap
allowed-tools: Bash, Read
doc-type: workflow
title: bootstrap-worker
purpose: Execute one lab-owned bootstrap assignment with explicit target scope.
---
# bootstrap-worker

## Commission and scope

Read the prepared start config with `ace-coworker start --config <returned path>`.
Use its pinned assignment ID for every ace-assign operation. Read the executable
lab task and its explicit canonical target path, allowed configuration paths,
operations, runtime selection and acceptance criteria. Missing or ambiguous
scope is an error report, never a guessed directory or permission.
The prepared commission and assignment define this leg. Execute them directly;
do not start a separate `ace-task plan` turn for the commissioned work.

The assignment and evidence belong to the prepared lab task worktree. This
operational role may act on the explicitly commissioned canonical target
outside that worktree; this exception does not authorize other projects or
product implementation. Resolve target paths before effects and reject symlink
escapes outside the commissioned root. Preserve unrelated changes and secrets.
Never write `.ace-tasks/_overseer`; the coordinator alone owns its private tree.

Operational tools use the selected installed ACE closure, not target binstubs
or its development Gemfile. Record actual executable/gem/instruction paths.
Additional credentials or privileges are session-scoped through the existing
auth handoff; do not make permanent group grants or copy credentials into
project config, task evidence or prompts. Missing access is a report to the
coordinator, not permission to borrow an account or change ownership.

## Assignment and report

Drive the pinned ace-assign step through start/finish/fail. Store evidence in
the executable task's docs. Run each `ace-*` check directly, without a pipe or
redirection, and record its actual exit status and output in task docs; when
it prints a file path, read that file. Never use the exit status of `head`, another pipeline command or `echo` as the check's result.
Failed, unavailable or inconclusive required checks block success.
Use `ace-coworker report --config <returned path>` for the truthful assignment
outcome. A process exit, prepared config or printed CLI brief is not completion.
For `reporting.delivery: observe`, publish from the assignment worktree.
The Lab Overseer's inbox is outside your mount by design. Validate the
configured recipient address, never try to read, create or write its folder.
Publication returns an event ID and leaves acceptance to the Lab Overseer.
If the commission asks for a destination-folder write probe, report the
conflicting check to the coordinator instead of attempting the write.
After interruption, read current state before repeating any external effect;
resume the same assignment, never silently create a replacement.

## Prepare the target

Change only commissioned configuration and dependency installation paths.
Do not edit product code, replace tracked binstubs to bypass installed mode,
or rewrite existing project dependency declarations. A product/tool defect
requires a separate code-change commission. Use the existing configuration
and installation tools; do not invent a second configuration owner.

`ace-lab prepare`, `ace-lab install` and `ace-lab verify` are host deployment
commands in every directory. Do not run them, even in dry-run mode. Validate
the commissioned project files and the effective installed runtime directly.
If the assignment requires a host deployment command, fail the step and
report the exact conflicting check to the commissioning Overseer for
correction. End the turn after reporting.

Verify the requested configuration and installed dependency readiness. Record
before/after state and exact checks without secrets. Do not start another
project overseer yourself: after independent verification the lab coordinator
owns reconcile/start. Leave unrelated work and live services untouched.
Prepare the commissioned project eyes configuration using its explicit path
and actual configured HITL recipient. Validate its schema and the runtime paths
available to your worker role. The Overseer start configuration uses
`scope: project`. The eyes JSON uses `"scope": "current"` for this project
and `"recipient"` for its configured recipient. Validate the candidate JSON
against the installed ace-wake validator before writing it to the target path.
Full observation includes private overseer tasks:
the authorized coordinator confirms all sources after independent verification
and project start. Do not require access to that private tree, host systemd or
host-wide verification to complete your scoped preparation. Report missing
capabilities required by your commission; never widen permissions.

Checkout preparation does not run project after-create hooks, mise trust or
bootstrap commands. Read the project's worktree setup configuration and perform
only the setup required by this commission, under your worker identity and
selected runtime. Record executed and inapplicable phases with evidence. The
standalone worktree bootstrap command does not replay after-create hooks; do not
claim those hooks ran merely because bootstrap succeeded.
