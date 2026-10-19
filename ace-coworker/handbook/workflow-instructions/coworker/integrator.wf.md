---
name: coworker-integrator
allowed-tools: Bash, Read
description: Integrator role for the file-based lab. Performs the project-defined integration; before merging it checks that dependencies are integrated predecessors, the candidate head still matches the reviewed head (no drift), tests were executed and passed, and a fresh independent review verdict accepts the exact candidate head. A stale review, unsatisfied dependency, or missing test evidence WITHHOLDS the merge; an uncertain operation outcome is verified against the real state, never retried blind. Blocked integrations escalate to the overseer via ace-hitl.
doc-type: workflow
purpose: integrator role workflow instruction
ace-docs:
  last-updated: '2026-10-19'
---

# Integrator - Result-Dependent Integration with a Pre-Merge Gate

## Goal

Integrate ready, verified candidates in the order of their real dependencies.
Before any merge, CHECK four facts and merge only when all four hold:
(a) dependencies are satisfied (predecessors integrated - an open PR or a
"work done" message is not integration), (b) current changes match what was
reviewed (candidate head == reviewed head, no drift), (c) tests were executed
and passed (real evidence), and (d) a fresh independent review verdict accepts
the exact candidate head. Otherwise WITHHOLD the merge and report/escalate.

## Role Identity

- The integrator takes the worktree over only after the reviewer's assignment
  completed; one active executor per worktree.
- Integration sequencing, which candidates merge in which order, and the
  dependency map come from the commissioned assignment and the task's
  `dependencies` fields (leaf-level, per execution-order.md) - never from
  self-selected extra work.
- This role never performs the review and never re-litigates it: it verifies
  that a fresh accepting review covers the exact candidate head.

## Start State

- The run config `.ace-local/coworker/config.yml` names this role
  (`role: integrator`), this workflow (`instructions:
  wfi://coworker/integrator`), the task ref, the pinned assignment id, and
  the overseer address.
- Run `ace-coworker start` and follow the rendered brief; drive the pinned
  `--assignment <id>` in every ace-assign call.
- Missing or mismatched input (task does not resolve here, assignment id
  mismatch) fails explicitly - never guess or adopt another commission.
- After an interruption, `ace-coworker resume` renders the preserved state;
  for steps with external effects (merge/push) verify the actual state before
  repeating them.

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

## Process

1. **Drive the assignment.**
   - `ace-assign start` / `finish` / `fail` with the pinned assignment.
   - Scope stays bounded by the commissioned goal; never change the parent
     goal, task dependencies, or the overseer tree.

2. **Collect the gate facts (read-only, from their owners).**
   - **Candidate head**: current head of the candidate branch in this
     worktree (`git rev-parse --short HEAD` after `git status`); the
     worktree state is the truth, not a remembered sha.
   - **Review evidence**: the reviewer's durable report
     (`<task>/coworker/<assignment>.md`) names the exact reviewed candidate
     head, the executed checks, per-round dispositions, and the final
     verdict; the round history lives in
     `.ace-local/coworker/review-rounds/<assignment>.json`
     (`ace-coworker rounds` verdict `accept`). The reviewed head is the head
     that verdict covers.
   - **Test evidence**: executed `bin/ace-test <package> all` results named
     in the worker/reviewer reports (counts, failures) - only real executed
     runs count; CI status is ADVISORY and never a merge blocker.
   - **Dependency states**: for each leaf the candidate depends on, whether
     its result was RECEIVED AND INTEGRATED (merged predecessor), not merely
     finished or reviewed.
   - Any fact you cannot establish is UNCERTAIN: resolve it by checking the
     real state (files, reports, git) before proceeding - never by assuming,
     and never by re-running a merge hoping for a different outcome.

3. **Evaluate the gate (deterministic).**
   - `ace-coworker gate --candidate-head <sha> --review-head <sha>
     --review-verdict accept|continue|escalate --tests executed,passed
     --dep <leaf>=integrated --dep <leaf>=missing`
     (repeat `--dep` per dependency; omit `--candidate-head`/`--review-head`
     when genuinely unknown so the gate blocks on the missing evidence).
   - The gate (`Ace::Coworker::Atoms::IntegrationGate`) is pure: it returns
     `ready` or `blocked` with per-check reasons (dependencies, candidate
     drift, review freshness/verdict, executed+passing tests). `blocked` is a
     legitimate outcome with exit 0; only invalid input fails the command.
   - A candidate change after the review (candidate head != reviewed head)
     invalidates the review: the gate reports a stale review even when the
     verdict says accept.

4. **Merge only a ready candidate.**
   - Verdict `ready`: perform the project-defined integration with the
     existing tools (`git` / `ace-git`, scoped to the commissioned paths;
     never force-push; fetch first and resolve conflicts explicitly).
   - If the merge itself changed the candidate or conflicts were resolved,
     the result is a NEW candidate: re-run the affected checks
     (`bin/ace-test <package> all`) and RENEW the review for the changed
     result (reviewer role) before treating it as integrated - never mix
     acceptance of the old candidate with new code (execution-order.md
     step 4). Then re-evaluate the gate.
   - After merging, verify the actual outcome (branch state, merged head)
     before reporting - an uncertain operation outcome is CHECKED, not
     retried blind: a repeated merge/push is never the verification.

5. **Withhold blocked merges.**
   - Verdict `blocked`: do NOT merge. Record the withholding reason in the
     step report and report the blocked outcome (step 6). Fixable locally
     (e.g. renewed review needed after your own conflict resolution): do it
     inside this assignment, then re-evaluate the gate.
   - A blocked integration that needs the overseer (unsatisfied dependency,
     sequencing decision, reviewer unavailable):
     `ace-hitl create "<title>" --kind decision --question "<options,
     impact, what is blocked>" --to <overseer>`, then `ace-hitl send <id>`;
     keep the step failed/open (`ace-assign fail` with the cause) and report
     an error outcome. NEVER merge to "unblock" past a failed gate.

6. **Record and report the actual outcome.**
   - `ace-coworker report` writes the durable record
     (`<task>/coworker/<assignment>.md`) and delivers the HITL report.
   - The report states the OUTCOME THE NEXT ROLE NEEDS: for an integrated
     candidate - the merged result (target, merged head or PR reference),
     which dependency leaves it unblocks, the gate evidence (verdict,
     candidate/reviewed head, test counts, review verdict), and any renewal
     performed; for a withheld merge - the blocking reasons per check and
     what must change (integrated dependency, fresh review of the new head,
     executed tests). A "work done" message never substitutes for this.

## Completion Rule

The assignment is complete when every commissioned candidate reached a
truthful terminal state - integrated (gate `ready`, merge verified, outcome
reported with the unblocked dependents) or withheld with the blocking reasons
recorded, reported, and escalated where the overseer must decide. Anything
less is an error outcome with the cause named.

## Reporting

- Outcome and progress are reported through `ace-coworker report` (channel
  `hitl` by default; recipient = the config `overseer` address).
- Escalations travel as `ace-hitl` decision questions; errors follow
  `errors.on_failure: report` (recorded and reported).

## Boundaries

- No merge past a blocked gate, no force-pushes, no speculative merges of
  unintegrated dependencies.
- No re-review of the worker's change by this role: renewals go to the
  reviewer role; the integrator only verifies freshness and coverage.
- The gate atom decides readiness only; this role drives git/ace-git - the
  tool never auto-merges.
- No new state owners, journals, or queues (ADR-034): `.ace-local/coworker/`
  belongs to ace-coworker, `.ace-local/assign/` to ace-assign,
  `.ace-local/review/` to ace-review, `.ace-local/hitl/` to ace-hitl.
  Integration decisions persist in the assignment's existing report state
  (ReportStateStore / `<task>/coworker/<assignment>.md` record); no new
  artifact kind is introduced.
- Inside the ACE repository itself, invoke every tool as `bin/ace-*` (the
  binstubs pin the checkout's bundle).
