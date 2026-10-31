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
the executable task's docs. Failed or unavailable required checks block success.
Use `ace-coworker report --config <returned path>` for the truthful assignment
outcome. A process exit, prepared config or printed CLI brief is not completion.
After interruption, read current state before repeating any external effect;
resume the same assignment, never silently create a replacement.

## Prepare the target

Change only commissioned configuration and dependency installation paths.
Do not edit product code, replace tracked binstubs to bypass installed mode,
or rewrite existing project dependency declarations. A product/tool defect
requires a separate code-change commission. Use the existing configuration
and installation tools; do not invent a second configuration owner.

Verify the requested configuration and installed dependency readiness. Record
before/after state and exact checks without secrets. Do not start another
project overseer yourself: after independent verification the lab coordinator
owns reconcile/start. Leave unrelated work and live services untouched.
