---
name: coworker-reviewer
allowed-tools: Bash, Read
description: Reviewer role for the file-based lab. Independent of the worker; reviews the exact delivered candidate, fixes confirmed defects itself inside its own single assignment (no per-fix overseer round-trip), checks each fix diff, and returns to full review rounds under the 3/2/10 convergence rule. An unresolved High/Critical finding is never marked as success - no effective fix or a needed product decision is escalated to the overseer via ace-hitl.
doc-type: workflow
purpose: reviewer role workflow instruction
ace-docs:
  last-updated: '2026-11-06'
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

For a forge issue, ensure the pinned assignment has a final
`publish-approval` step before starting review. Add it through `ace-assign add`
if the commission has not prepared it. Keep that step open while reviewing
and testing. The round verdict `accept` completes review rounds only. An
assignment with an open publication step cannot produce a success report.

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`.
- Load project context with `ace-bundle project --compressor-mode exact` and read
  the returned context file. Context preparation must not launch another model
  merely to summarize documentation; use agent compression only when the
  commission explicitly requests it. This does not change the review model or
  the commissioned execution and verification requirements.

## Process

1. **Drive and develop the assignment.**
   - Use `ace-assign start` / `finish` / `fail` with the pinned assignment.
   - You may develop the assignment: add fix and verification steps with
     `ace-assign add --step <name> --after <n>` for a step name that EXISTS
     in the assignment's preset catalog (`--step` selects an existing
     preset step definition; it never creates a new name), or with
     `ace-assign add --yaml <file> --after <n> --assignment <id>` for a
     newly named step (file with a top-level `steps:` array of
     `name`/`instructions` mappings — see step 4). Added steps stay in the
     SAME plan, visible via `ace-assign status` - that is how a fix remains
     inside this one assignment. Scope stays bounded by the role rules and
     the commissioned goal; never change the parent goal, task
     dependencies, or the overseer tree.

2. **Run a review round (forge-neutral).**
   - A task linked to a forge issue requires the worker's published PR and
     exact tested HEAD before review starts. Read both from the accepted
     worker assignment's step reports and reconcile them with the configured
     forge. The issue link makes this a PR review even when the commission
     omits the PR or calls the work local. If the PR or tested HEAD is
     missing, report a blocked handoff to the overseer for worker publication.
   - Subject: local candidate
     `ace-review --preset code-valid --subject diff:<merge-base>..<head>`, or
     a typed PR reference `--pr IDENTIFIER` (number, `owner/repo#number`, or
     URL; GitHub `/pull/`, Forgejo `/pulls/`). Use the assignment's retained
     forge selection `--server NAME` or `--default-server` (mutually
     exclusive) - never infer a forge from a hostname or the caller's
     identity.
   - Use the session's configured project-scoped credentials for forge reads,
     fetches and approval. When the deployment uses temporary grants, obtain
     a grant through its configured adapter and use `ace-lab auth exec` for
     the individual forge operation (one argument per repeated `--cmd`).
     Keep review, model calls and tests in the ordinary installed session;
     they do not need a forge grant. A static project token needs no lease
     service and must not be revoked after each operation.
   - Run the task's required checks from the assignment worktree on the
     candidate you will approve. Confirm the scope against the issue and
     project requirements, and record the executed commands and results.
     Use installed `ace-test` when `ACE_TOOLCHAIN=installed`. Check the
     test commands and their prerequisites before installing development dependencies.
     A checkout binstub or Gemfile alone does not require `bundle install`.
     If a required installed test tool is missing, report the readiness failure.
     In ACE development mode use the checkout's `bin/ace-test`.
   - For a commissioned PR, review the **full forge PR delta**. Prefer its
     typed PR reference. If using a local diff range, first resolve the actual
     target branch and candidate HEAD from the configured forge, fetch those
     exact refs through your granted access, and compute their merge-base.
     Record the full base and head SHAs and compare the selected files with the
     forge PR diff. Local `main` may contain unpublished coordination/task
     commits and is not evidence of the forge base. Include those commits when
     they are part of the PR; a worker-only slice is not a full review round.
     Missing base/head evidence or omitted PR changes blocks acceptance. After
     candidate/base changes, re-establish the complete range for subsequent
     full rounds; a fix-only check does not replace it.
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
     or defer with rationale (`ace-review-feedback skip <id> --reason
     "<rationale>"`, or verify then skip per the feedback workflow) so the
     finding has a terminal disposition instead of lingering pending; a
     deferred P2 never blocks the round.
   - (a) add a newly named fix step via `ace-assign add --yaml <file>
     --assignment <id> --after <n>`, where `<file>` is a YAML document
     with a top-level `steps:` array and the feedback id named in the
     step instructions, e.g. `.ace-local/fix-<feedback-id>.yaml`:
     ```yaml
     steps:
       - name: fix-feedback-<id>
         instructions: |
           Fix the confirmed review finding <feedback-id> in the delivered
           change. Apply the minimal correct fix, run the affected checks
           with the selected toolchain, and record what changed.
     ```
     (`--step <name>` only selects a step definition that already exists
     in the preset catalog - it cannot mint a new fix-step name);
     (b) implement the fix on the task branch in this worktree; (c) run
     the affected checks with the selected toolchain (a failed required
     test blocks); (d) commit scoped (`ace-git-commit <paths>` after
     checking `git status`); (e) only after the fix is verified:
     `ace-review-feedback resolve <id> --resolution "Fixed in <sha>"`.
   - A finding is never resolved or verified away without evidence of a fix.

5. **Check the fix diff.**
   - Review the diff of your own fix, e.g.
     `ace-review --preset code-valid --subject diff:<pre-fix>..<post-fix>`,
     or verify directly by reading the diff and re-running the checks.
   - A fix-diff check never replaces the next full round and never advances
     the convergence counters by itself.

6. **Return to full review.**
   - For a forge PR, publish scoped fix commits to the existing PR source
     branch before the next full round. Use the reviewer session's own
     project-scoped credentials. Read the current PR source repository, branch and
     HEAD from the forge. Proceed only if that HEAD is the last known PR
     revision and the update is a fast-forward. Push the exact candidate
     to that branch without force and re-read the PR to verify its HEAD.
     An unexpected remote change or denied push blocks this handoff.
   - Run a FULL round over the whole current candidate with the retained
     forge selection and the verified forge base and HEAD. Re-read the forge
     through the configured project access and recompute the
     merge-base if either changes. A fix-only diff or scoped delta is
     separate from a full round. A committed task edit also changes the
     candidate and requires renewed review and test evidence.
   - **Convergence rule 3/2/10**: minimum 3 full rounds, the last 2
     consecutive without confirmed High/Critical and with no unresolved
     earlier High/Critical; maximum 10 - if round 10 satisfies the rule,
     finish successfully, otherwise escalate. Interrupted or incomplete
     rounds are not clean rounds and do not count.
   - Keep your own round record in the step reports (round number, session
     path, verdict per finding). The review sessions, feedback items, and
     assignment state ARE the checkpoint - there is no separate journal.
     Deterministic counter enforcement exists (8xg.t.sbz.4.2):
     `Ace::Coworker::Atoms::RoundRule` evaluates the recorded rounds
     (:continue | :accept | :escalate) and `Molecules::ReviewRoundStore`
     persists them in
     `.ace-local/coworker/review-rounds/<assignment>.json` - record each
     finished round with `ace-coworker rounds record --assignment <id>
     --type full|delta --status completed|aborted [--confirmed id:sev,...]
     [--resolved id,...]` and follow the printed verdict
     (:escalate means the ace-hitl decision question above, never a
     crashed run). A restart reloads the same file: the round counter and
     findings history are never reset.

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

8. **Publish formal approval, then hand off.**
   - For a commissioned PR review, only AFTER the review-round verdict is
     `accept`, required executed tests pass, and the accepted report binds the
     current full head, publish through the configured reviewer account:
     `ace-git pr approve PR --expected-head SHA --body-file REVIEW_REPORT
     --correlation REVIEW_ID --server SERVER --format json` (or the retained
     `--default-server` selection). Keep the report and returned receipt in the
     existing task/review/assignment artifacts. Use one stable REVIEW_ID for
     this repository/PR publication; changed report/head needs a new publication.
   - Finish the `publish-approval` step with the verified receipt and
     executed test evidence in its assignment step report. Then run
     `ace-coworker report`. The approval receipt and its forge-verified
     reviewer identity are the handoff. The worker's PR description does
     not have to be editable by the reviewer.
   - A comment, local acceptance or `pr ready` is not formal approval. Confirm
     the receipt's exact repo/PR/head/reviewer/evidence digest and effective
     approval. Missing permission, unsupported capability or unknown outcome
     blocks successful integration handoff; report the concrete cause via the
     existing HITL/report path. Resume by reconciling the same publication,
     never blindly repeating a POST or switching credentials.
   - Reviewer purpose and provider permissions are independent: deployment
     selects the OS/provider identity. Never borrow worker/admin credentials;
     the PR author cannot approve their own PR. Local-only reviews have no
     remote approval to publish and must not claim one.

8a. **Record and hand off.**
   - `ace-coworker report` writes the durable record
     (`<task>/coworker/<assignment>.md`) and delivers the HITL report.
   - The final report names: the exact candidate head, executed checks,
     per-round dispositions (session paths under `.ace-local/review/`), fix
     commits, and unresolved findings - consumable by the integrator role
     (8xg.t.sbz.4.3) and the round-limit tooling (8xg.t.sbz.4.2). The
      reviewed head is recorded as the full lowercase SHA from
      `git rev-parse HEAD` (never a short form), because the integrator
      compares it for drift against the candidate head on the same
      normalization.

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
- With `ACE_TOOLCHAIN=installed`, use installed executables and packaged
  instructions; the checkout is reviewed project data, never your runtime.
  In development mode inside the ACE repository, use `bin/ace-*`.


Deployment must provide a dedicated automation reviewer identity and one writer
per actor/repository/PR before formal publication. Missing evidence of that
mapping/ownership blocks live use; a role name grants no account permission.
Do not share that identity with manual clients or another host writer. Preserve
and report unrelated pending reviews/comments instead of publishing over them.
Resume only when the provider's path preserves the accepted commit/content;
unsafe or unsupported pending recovery remains blocked with retained evidence.
