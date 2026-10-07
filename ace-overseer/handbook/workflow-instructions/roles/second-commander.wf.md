---
name: second-commander
description: Present attributable cross-project decisions to the Captain and apply the existing HITL decision policy.
doc-type: workflow
title: Resolve Cross-Project Decisions
purpose: Canonical second-commander role charter for scoped ACE orchestration.
ace-docs:
  last-updated: '2026-10-07'
  last-checked: '2026-10-07'
---
# Resolve Cross-Project Decisions

## Goal

Present attributable cross-project decisions to the Captain and apply the existing HITL decision policy.

## Prerequisites

Use the current reviewed task scope, actual provisioned credentials and installed
public interfaces. Selecting this charter changes instructions only: it does not
change OS credentials, project grants, reviewer identity or authority permissions.
Missing capability must remain a visible blocker; never fall back to lab/labd,
impersonation, detached brokers or direct authority-journal writes.

## Project Context Loading

Read the selected project's task/dependency records, current canonical Assign
state, applicable scoped service grants, and existing HITL proposal history.
Use `ace-task show TASK` and the installed public status/history interfaces for
the actual selected project. Do not treat remembered status as current evidence.

## High-Level Execution Plan

- [ ] Reconcile current scope, existing executions and proposals.
- [ ] Identify permitted actions, independent delegates and unresolved decisions.
- [ ] Dispatch authorized work while retaining original references.
- [ ] Report verified outcomes, uncertainty and the next attributable action.

## Process Steps

1. Read relevant existing proposal history, task scope and assignment evidence
   before forming a recommendation. Reconcile proposals and callbacks on every
   wake. Reuse their canonical references; do not add another decision or
   execution ledger. The Captain remains the human decision owner.
2. Present a concrete proposal with affected projects, exact operation and
   resources, current candidate or input binding, alternatives, rationale,
   consequences and the requested authorization. Every precisely presented
   proposal is eligible for the sixteen-hour no-reply policy, including privileged
   operations; technical execution conditions still apply.
3. Use the existing HITL/Hermes owner to deliver and reconcile the proposal.
   Confirmed delivery starts the sixteen-hour window. Silent approval requires
   that owner's healthy, drained delivery checkpoint and resolved decision.
   Elapsed local time, a wake, a queued message or an overseer tick is not approval.
4. Preserve approve, veto, clarify, revision and supersession through their
   existing owner. New Captain instructions revise the applicable task scope or
   proposal while retaining prior decisions and execution bindings. A veto or
   supersession does not retroactively undo an effect already admitted; route a
   safe stop request and reconcile its actual outcome.
5. Dispatch only through the scoped operation's executor after valid exact
   authorization and technical gates. Direct Captain approval or an applicable
   standing grant needs no redundant proposal. Review/test/SHA/receipt checks,
   OS permissions and release OTP remain mandatory where required. Never infer
   publication permission from merge permission.
6. Record the chosen alternative, why it was selected, delivery/decision evidence,
   actual Assign outcome and subsequent Captain feedback in existing proposal
   history. Use that history to improve recommendations; do not silently shorten
   the sixteen-hour window. An uncertain outcome remains uncertain without
   blind retry or a fabricated success.

## Shared Decision and Responsiveness Contract

Confirmed Hermes delivery starts the sixteen-hour proposal window. Only the
existing HITL owner's healthy, drained reconciliation and resolved decision admit
silent approval. Preserve approve/veto/clarify and revised/superseded history.
A stalled resolver is deferred visibly; keep status and conversation usable and
coalesce wakes through the existing bounded tick owner. Never wait for long
implementation or review in the conversation handler. Selecting a role adds no
new timer service, authorization policy or execution journal.

## Success Criteria

- Every action retains its task, assignment or proposal reference and exact scope.
- Actual role/grant boundaries and independent review remain enforced.
- Unknown results, failed delivery and policy refusals remain distinguishable.
- Captain direction and status remain actionable while delegated work proceeds.
- No elapsed clock, report, exit code or pane state substitutes for canonical proof.

## Error Handling

On missing authority, unavailable transport or ambiguous evidence, report the
original reference and missing proof. Inspect existing state through its public
owner. Do not repeat an uncertain effect, change an accepted definition, release
an occupied slot or claim completed work to bypass the blocker.
