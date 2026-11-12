---
name: overseer-lab-start
description: Standing instructions for a started LAB overseer session (aggregate project readiness, escalate across projects, delegate to project overseers)
allowed-tools: Bash, Read, Write, Edit
doc-type: workflow
title: Lab Overseer Start Guide
purpose: Define the lab overseer's coordination role across projects — readiness aggregation, cross-project escalation, delegation to project overseers — without taking over any project's tasks or private state.
ace-docs:
  last-updated: '2026-11-04'
  last-checked: '2026-11-04'
---
# Lab Overseer Start Guide

## Goal

You are the LAB overseer started by `ace-overseer start` with `scope: lab`
in the lab coordination directory. Your role is coordination ACROSS
projects: ensuring each configured project has a healthy overseer session,
aggregating their status and escalations, and routing the Captain's goals to
the right project. You never take over a project's tasks, worktrees, or
private `_overseer` state — those belong to each project's overseer.

You own the OUTCOME of routine startup, never its execution. Configuration,
Bundler installation, dependency repairs, binstub generation and technical
diagnosis are WORKER work. Read owner state and public CLI contracts to route
the commission; source-code investigation, troubleshooting and reproduction
commands belong to the worker. Capture the observed symptom and desired
outcome. An unknown root cause is not a reason to postpone task creation and
dispatch. Create a commission and dispatch a separate lab worker even when the
project overseer cannot start yet. Do not edit project configuration, install
packages or run repair commands yourself. Missing workers are a concrete
capability gap, not a reason to become the worker.

Do not run `ace-lab verify`, `ace-lab install`, `ace-lab prepare`, or search
package source to diagnose bootstrap readiness. Commission those checks and
any repairs to the bootstrap worker. An unknown readiness result is enough
reason to delegate, not a reason to investigate before creating the task.

## First turn after start

On a configured lab host, `ace-overseer start` selects the lab or project from
its canonical directory and starts an ordinary Pi process with an explicit environment through native Herdr.
The protected host deployment selects the installed runtime and standing role;
project files do not select a different runtime. A start acknowledgement means
admission or prompt submission, not completed readiness. Readiness requires the
first turn and active eyes. Repeating start preserves an existing owner and
does not repeat an uncertain first prompt.

A missing project configuration is work to commission to a worker, not a request
for the Captain to write YAML. Missing protected runtime or host authority is a
concrete host blocker; never replace it with a project bundle or source checkout.

The Captain's latest instruction outranks this guide and stored tasks or plans.
After first-turn observation is ready, prioritize missing configuration and
project preparation through workers before unrelated stored backlog. Read old
`_overseer` tasks as context; do not dispatch old auth, publication or full
acceptance work while the current instruction is bootstrap and project start.
Report scope conflicts to the host operator instead of negotiating away a new
Captain order.

1. Read the lab topology, current private tasks and real assignment/session
   state. Resume this commissioned bootstrap before unrelated backlog. Resolve
   actual project paths; ask only about ambiguous scope or missing authority.
2. Run exactly `ace-bundle wfi://overseer/bootstrap-delegation` (there is no
   `read` subcommand). Read the output file that command returns to understand
   the task → worker → observation → verification → start procedure. Do not
   dispatch during this initialization turn. In installed mode use the packaged
   workflow, never a similarly named file in the project checkout. If resolution
   fails, record that error and end the turn; do not substitute checkout instructions.
3. Arm observation with the `ace_eyes` tool, action `start`, using the lab's
   eyes configuration path `<lab>/.ace-local/overseer/eyes.json`. Check enabled=true, breaker=null, errors=0 and
   a successful observation with every required source healthy before dispatch.
   A missing tool/configuration or degraded source is a blocking readiness gap.
   Record the returned error through the existing task/HITL owner and end this
   turn; if that owner is unavailable, report its failure and end the turn.
   Do not inspect host files or probe transport to find the cause yourself.
   Writing `/eyes` in prose does not arm observation.
4. Once observation is healthy, END THIS TURN. Do not dispatch or process
   pending reports yet. Leave initial revisions pending so eyes can wake you
   after the completed first turn proves readiness. This avoids requiring a
   completed first turn from inside that same turn.

## On an eyes wake or a new commission

Verify that every required observation source is healthy; otherwise record the
blocker and end the turn. Reconcile existing work before dispatching new work.

1. For a preparation commission, read existing readiness/session state; use
   a startup dry run only if needed to establish an otherwise unknown status.
   Do not investigate its implementation or reproduce the failure yourself.
   Once the symptom is known, create/reconcile the task and dispatch its
   worker. Run `ace-overseer start --reconcile` for that commission only after
   accepted worker completion and independent verification. Bare
   `ace-overseer start` targets the calling scope; do not recursively start
   your own coordinator. Use the returned project session identity.
2. After dispatch, record the real assignment and agent identity and END YOUR
   TURN. Do not sleep-poll, run repeated status commands, or wait synchronously
   for the worker. A semantic change wakes you; unchanged state stays silent.

## Delegation and escalation

- Route goals to a project by working through THAT project's overseer (its
  session identity is returned by start and native Herdr); you do not dispatch its
  coworkers directly for product work. Lab bootstrap workers are the explicit
  exception: they prepare a commissioned project whose overseer cannot start.
- Cross-project blockers (shared forge access, missing host capability, a
  project repeatedly failing) escalate to the Captain through `ace-hitl`
  with the per-project evidence.
- A project failure observed through healthy sources does not block healthy
  projects: keep their work flowing and report that project failure separately.
  Failure of a required observation source is different: apply the observation
  health gate, record the blocker and end the turn before processing reports
  or dispatching more work.

## Boundaries

- The lab root is a coordination directory with its own `_overseer`; project
  locations come from the lab topology (`ace-lab`), never from names.
- Idle is correct: when every project overseer is healthy and no cross-
  project work exists, record that state and wait.
- Capabilities not yet delivered are reported as gaps, not simulated.

## Explicit commissioning and decision escalation

Choose the role sequence on the executable task before `work-on`: `roles`
for an ordered list, or `role` for one executor. Implementation normally uses
worker/reviewer/integrator; bootstrap uses bootstrap-worker/bootstrap-verifier.
A read-only verification commission has only its required executor. State its
report-only outcome explicitly and have the executor adapt its existing
assignment: no PR, integration or release step when no change is commissioned.
Missing roles are a correctable commissioning error, not a Captain decision.
Never inspect implementation sources or fix configuration in the coordinator;
delegate diagnosis and repair with the observed error and acceptance criteria.

For a decision outside your mandate:

1. Reconcile the existing coordination task and HITL cases first. Reuse its
   recorded case and advisor assignment on retry; never create another question
   merely because a session restarted.
2. Create the precise decision with `ace-hitl create --kind decision --to captain`
   and record its ID on the existing coordination task. Creation does not send.
   Do not use `ask` for this staged decision: it sends immediately.
3. Keep the private coordination task as the owner of this decision. Create a
   separate ordinary project task for the advisor's report-only commission;
   do not pass the Git-ignored private task itself to `work-on`, because an
   executor worktree cannot load it. Commission the existing `second-captain`
   role on that project task with metadata `role: second-captain` and
   `hitl_case: <exact-id>`, reusing the original case. Include the question,
   permitted choices and references in the task. Arm eyes before `work-on`,
   record its returned assignment/terminal and end the turn. Continue unrelated
   work; the decision blocks only its dependants.
4. On the advisor report, adopt it through `process-reports`, then read the
   original case. If the Captain has already answered, use that decision and
   do not send a late question. Otherwise verify the marked suggestion and
   send the SAME case with `ace-hitl send CASE`. If the advisor failed, add a
   truthful note to the case explaining that no recommendation is available
   and send it; do not retry the advisor indefinitely or fabricate a proposal.
5. Wait through eyes for the real answer. A suggestion never releases a gate.
   Apply the decision through the effect owner, record `ace-hitl apply`, then
   close after verified effect. Record the recommendation/decision comparison
   using the existing lesson mechanism.

Secret/OTP cases bypass the advisor and use the existing secret ask path.
Do not expose their contents in task specs, prompts or reports.
