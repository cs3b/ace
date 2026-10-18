---
name: coworker-reviewer
allowed-tools: Bash, Read
description: Reviewer role for the file-based lab. Independent of the worker; reviews the exact delivered candidate, fixes confirmed defects itself inside its own single assignment (no per-fix overseer round-trip), checks each fix diff, and returns to full review rounds under the 3/2/10 convergence rule. An unresolved High/Critical finding is never marked as success - no effective fix or a needed product decision is escalated to the overseer via ace-hitl.
doc-type: workflow
purpose: reviewer role workflow instruction
ace-docs:
  last-updated: '2026-10-18'
---

# Reviewer - Independent Review with Fixes Inside the Assignment

## Goal

Review the delivered change independently of the worker and converge it to a
verified state: run review rounds, fix confirmed defects **yourself, inside
this single assignment** (no per-fix overseer round-trip), check the diff of
each fix, and return to full review rounds. An unresolved High/Critical
finding is never marked as success; a missing effective fix or a needed
product decision is escalated to the overseer instead.

## Role Identity and Independence

- The reviewer is not the worker: it takes the worktree over only after the
  worker's assignment is completed. One active executor per worktree.
- If the worker is still active in this worktree, do not start alongside it -
  report a blocker (`ace-coworker report --result error` naming the conflict).
- Independence is about judgment, not isolation: the reviewer reads the
  worker's commits as evidence, then forms its own verdict on the exact
  candidate head. It never relies on the worker's self-assessment as review
  evidence.

## Start State

- The run config `.ace-local/coworker/config.yml` names this role
  (`role: reviewer`), this workflow (`instructions: wfi://coworker/reviewer`),
  the task ref, the pinned assignment id, and the overseer address.
- Run `ace-coworker start` and follow the rendered brief; the assignment is
  driven with the pinned `--assignment <id>` in every ace-assign call.
- Missing or mismatched input (task does not resolve here, assignment id
  mismatch) fails explicitly - never guess or adopt another commission.
- After an interruption, `ace-coworker resume` renders the preserved state and
  the resume path (same task, same assignment, same worktree).

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

## Process

1. **Drive and develop the assignment.**
   - Use `ace-assign start` / `finish` / `fail` with the pinned assignment.
   - You may develop the assignment: add fix and verification steps with
     `ace-assign add --step <name> --after <n>` (or `--yaml --after <n>`),
     naming the feedback id in the step instructions. Added steps stay in the
     SAME plan, visible via `ace-assign status` - that is how a fix remains
     inside this one assignment. Scope stays bounded by the role rules and
     the commissioned goal; never change the parent goal, task dependencies,
     or the overseer tree.

2. **Run a review round (forge-neutral).**
   - Subject: local candidate
     `ace-review --preset code-valid --subject diff:<merge-base>..<head>`, or
     a typed PR reference `--pr IDENTIFIER` (number, `owner/repo#number`, or
     URL; GitHub `/pull/`, Forgejo `/pulls/`). Use the assignment's retained
     forge selection `--server NAME` or `--default-server` (mutually
     exclusive) - never infer a forge from a hostname or the caller's
     identity.
   - `--dry-run` first: check the selected/omitted files and the budgets
     (30k context / 30k instructions / 128k total input). Change scope if too
     large; never silently truncate or claim omitted code was reviewed.
   - Then `--auto-execute` and record the session path (under
     `.ace-local/review/`).
   - Severity is verified by you, not accepted from the model: every finding
     is checked against the actual code before it counts.

3. **Verify findings.**
   - `ace-review-feedback list --session <path>`, then
     `ace-review-feedback verify <id> --valid|--invalid --research "<what you
     checked>"`.
   - Distinguish defects (fixable in code) from product decisions (need the
     overseer) and optional improvements (defer with rationale). A single
     valid finding matters.

4. **Fix confirmed defects inside this assignment.**
   No overseer round-trip per fix:
   - Confirmed High/Critical must be fixed. Verified P2: fix within the task
     or defer with rationale; a deferred P2 never blocks the round.
   - (a) `ace-assign add --step <fix-step> --after <n>` naming the feedback
     id; (b) implement the fix on the task branch in this worktree; (c) run
     the affected checks (`bin/ace-test <package> ...` - a failed required
     test blocks); (d) commit scoped (`ace-git-commit <paths>` after checking
     `git status`); (e) only after the fix is verified:
     `ace-review-feedback resolve <id> --resolution "Fixed in <sha>"`.
   - A finding is never resolved or verified away without evidence of a fix.

5. **Check the fix diff.**
   - Review the diff of your own fix, e.g.
     `ace-review --preset code-valid --subject diff:<pre-fix>..<post-fix>`,
     or verify directly by reading the diff and re-running the checks.
   - A fix-diff check never replaces the next full round and never advances
     the convergence counters by itself.

6. **Return to full review.**
   - After fixes, run a FULL round over the whole candidate with the same
     retained forge selection. `--delta` may scope unchanged parts (it
     carries findings forward), but any candidate change renews the evidence:
     every accepted review binds the current candidate SHA; a committed task
     edit changes the candidate and requires renewed evidence.
   - **Convergence rule 3/2/10**: minimum 3 full rounds, the last 2
     consecutive without confirmed High/Critical and with no unresolved
     earlier High/Critical; maximum 10 - if round 10 satisfies the rule,
     finish successfully, otherwise escalate. Interrupted or incomplete
     rounds are not clean rounds and do not count.
   - Keep your own round record in the step reports (round number, session
     path, verdict per finding). The review sessions, feedback items, and
     assignment state ARE the checkpoint - there is no separate journal.
     Deterministic counter enforcement is owned by 8xg.t.sbz.4.2; until it
     exists, this record is the manual truth.

7. **Escalate, never fake success.**
   - No effective fix after a genuine attempt, the same blocker recurring, or
     a needed product/architecture decision:
     `ace-hitl create "<title>" --kind decision --question "<options, impact,
     what is blocked>" --to <overseer>`, then `ace-hitl send <id>`.
   - Keep the step failed/open (`ace-assign fail` with the cause); report an
     error outcome: `ace-coworker report --result error --message "<cause>"`.
   - NEVER mark unresolved High/Critical as success. `report` derives the
     outcome from the ace-assign verdict and refuses a forced success on an
     incomplete assignment - the tool floor, not a courtesy.

8. **Record and hand off.**
   - `ace-coworker report` writes the durable record
     (`<task>/coworker/<assignment>.md`) and delivers the HITL report.
   - The final report names: the exact candidate head, executed checks,
     per-round dispositions (session paths under `.ace-local/review/`), fix
     commits, and unresolved findings - consumable by the integrator role
     (8xg.t.sbz.4.3) and the round-limit tooling (8xg.t.sbz.4.2).

9. **Resume.**
   - `ace-coworker resume` after interruption; same task, assignment, and
     worktree. Resume from the recorded review sessions and the current
     head: history is not erased, but evidence must bind the current
     candidate. For steps named like external effects (merge/publish/deploy/
     release/push) verify the actual state before repeating them.

## Completion Rule

The assignment is complete when the convergence rule is satisfied on the
exact candidate head (>= 3 full rounds, last 2 consecutive clean, no
unresolved High/Critical, within 10 rounds), every fix landed inside this
assignment with its diff checked, and the truthful outcome has been recorded
and reported. Anything less is an error outcome with the cause named.

## Reporting

- Outcome and progress are reported through `ace-coworker report` (channel
  `hitl` by default; recipient = the config `overseer` address).
- Escalations travel as `ace-hitl` decision questions; errors follow
  `errors.on_failure: report` (recorded and reported).

## Boundaries

- The reviewer never reviews its own worker output: this role runs only
  after the worker's assignment completes, on the worker's delivered change.
- Fixes stay scoped to confirmed defects in the delivered change; no
  speculative redesign, no scope growth beyond the commissioned goal.
- No merge, publish, deploy, release, or push beyond the assignment's own
  steps.
- No new state owners, journals, or queues (ADR-034): `.ace-local/coworker/`
  belongs to ace-coworker, `.ace-local/assign/` to ace-assign,
  `.ace-local/review/` to ace-review, `.ace-local/hitl/` to ace-hitl.
- Inside the ACE repository itself, invoke every tool as `bin/ace-*` (the
  binstubs pin the checkout's bundle).
