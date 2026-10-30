---
name: overseer-cold-cycle-acceptance
description: The repeatable cold-start full-cycle acceptance scenario — two projects, one delegated task, HITL with a Second Captain suggestion, independent review, merge, publish, install, record; negative install refusal and idempotent re-run
allowed-tools: Bash, Read
doc-type: workflow
title: Cold-Cycle Acceptance Scenario
purpose: Bind the end-to-end acceptance of the autonomous lab family (8xs.t.pu0): explicit preconditions, one identity axis for every handoff, the operator's non-interference contract, a negative install flow, and re-run idempotence — executed on the installed, published set only.
ace-docs:
  last-updated: '2026-10-30'
  last-checked: '2026-10-30'
---
# Cold-Cycle Acceptance Scenario (8xs.t.pu0.e)

## Goal

Prove that every handoff composes into ONE autonomous cycle on the
INSTALLED lab: a cold start with at least two configured projects, a task
carried by real delegation through spec/planning, worker execution, an HITL
question carrying a Second Captain suggestion, independent review, merge,
publication, installation, runtime acceptance under the target account, and
the integrated record. The operator presses START and answers ONLY the
decisions/OTP the Captain must give — no further prompts, no pasted
answers, no manual deploy.

## Preconditions (explicit, NOT hidden autonomy)

- A fresh runtime from the PUBLISHED set: every component (core, wake
  extension projection, all three auth plugins) comes from installed gems —
  a missing dependency/runner/projection is a readiness FAILURE, never
  permission to fall back to the checkout's binstubs (`ACE_TOOLCHAIN=installed`).
- `ace-lab install` converged the manifest (gem closure, exact versions,
  extension projections); `ace-lab verify` passes under the target accounts.
- At least two configured projects (one carries the task; the other proves
  isolation); accounts, keys and auth profiles prepared by install.

## Run

1. `ace-overseer start` in the lab directory (scope lab). Expect: lab space,
   both project overseers started/reused, per-project statuses.
2. State the goal with acceptance criteria to the lab overseer (one explicit
   message). From here the operator only answers HITL.
3. The overseer accepts the goal, delegates spec/planning through the
   EXISTING roles, records the task, and drives dependencies to acceptance —
   delegation is proved by role/assignment evidence, not by the overseer
   doing the work.
4. Worker executes with a developer lease (`ace-lab auth request → use →
   revoke`); reviewer with a reviewer lease (identity DISTINCT from the
   author); integrator with an integrator lease and the formal approver
   account from the configured lane.
5. The required HITL decision carries a marked Second Captain suggestion in
   the SAME case BEFORE the Captain answers; only the human answer releases
   the gated step (the suggestion never does). An OTP ask is `--secret`: the
   value never appears in any wake, log, or argv.
6. Merge only through the gate: HEAD-bound tests, HEAD-bound independent
   review verdict, HEAD-bound formal approval by a different account; the
   adapter's expected-head condition refuses drift.
7. Publisher releases from the published queue (resume by version+digest);
   install converges the runtime; runtime acceptance runs UNDER THE TARGET
   ACCOUNT with the actually installed paths/versions.
8. The record (`wfi://release/cycle-record`) integrates through a reviewed
   record-only PR; the task closes only after acceptance AND record.

## The one identity axis (the acceptance record)

Every handoff names the SAME verifiable chain — capture the real values, no
fabricated suffixes: task id → assignments/roles (worker/reviewer/integrator
+ auth lease ids per role with principal/scope/use_until/expiry_mode) →
HITL case id (suggestion id, decision revision, lesson) → PR + merged HEAD →
review/tests evidence (heads, commands, results) → publish versions +
digests → installed runtime paths/versions + target-account result → record
PR. Producer → consumer at every step; command success alone proves
nothing.

## Negative flow (mandatory)

After a successful publish, REFUSE one required install step (e.g. remove
one manifest dependency or the extension projection). Expect: no done, no
ready, no record; the blocked state names the concrete missing dependency
and the correct escalation addressee; healthy parts keep reporting. After
restoring the cause, resume THE SAME cycle without re-publishing (matching
version+digest = already published).

## Re-run idempotence

After the cycle closes, run `ace-overseer start` again: no re-delegation, no
re-publication, no re-application of a closed decision; previously
started/reused sessions stay; the answer-only replay of an applied decision
is refused by the lifecycle.

## Boundaries

- Tests and scenarios live with their existing owners (ace-lab,
  ace-overseer); no separate test service.
- The scenario is repeatable: a second cold run produces the same evidence
  shape with fresh identifiers.
