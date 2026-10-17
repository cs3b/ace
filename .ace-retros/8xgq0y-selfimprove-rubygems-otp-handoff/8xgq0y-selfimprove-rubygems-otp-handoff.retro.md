---
id: 8xgq0y
title: selfimprove-rubygems-otp-handoff
type: standard
tags: [self-improvement, process-fix]
created_at: "2026-10-17 17:21:03"
status: active
---

# selfimprove-rubygems-otp-handoff

Date: 2026-10-17
Context: `8xg.t.k9y` delivery — publishing `ace-git-worktree 0.27.0` and
`ace-overseer 0.23.1` with `/as-release-rubygems-publish`.
Author: coding agent (work-on-task session)

## What Went Well

- The dry-run produced the correct, minimal plan (2 gems, 2 dependency waves)
  before any credential or OTP work.
- The publisher itself behaved exactly as designed once the operator ran it:
  stale prepared manifest rejected and re-resolved, artifacts built before the
  OTP prompt, both waves published, published artifacts removed.
- RubyGems metadata confirmed the result outside the OTP window, including the
  `ace-git-worktree ~> 0.27` dependency floor on `ace-overseer 0.23.1`.

## What Could Be Improved

- **No single-command handoff.** After the dry-run the agent asked the operator
  to create `~/.gem/credentials` and presented a multi-option questionnaire.
  The correct action was one line: "Everything is ready — run
  `.ace-bin/ace-rubygems-publish --interactive` in your terminal."
- **Agent shell treated as operator shell.** `GEM_HOST_API_KEY` and
  `~/.gem/credentials` were absent in the agent's subprocesses; the operator's
  terminal was fully configured. The agent concluded the wrong thing from its
  own environment.
- **Unnecessary prepare gating.** `--prepare` was treated as an agent
  prerequisite; the live `--interactive` run re-resolves a stale prepared queue
  on its own, so the handoff did not need it.
- **Verification scope creep.** After publication the agent re-ran `--dry-run`
  and hand-rolled the `TS-MONO-001` propagation proof as `bundle install` /
  `--full-index` in `/tmp`, instead of the mandated
  `ace-test-e2e ace-monorepo-e2e TS-MONO-001` (which was provider-blocked).
- **Recurrence.** Retro `8x2ysa` (2026-10-03, qk1.2) already recorded "No
  handoff protocol between 'agent finishes a release' and 'operator publishes'"
  and a Start Doing item for the prepare-then-interactive handoff. The fix never
  reached the agent-facing decision rule in the loaded workflow, so the same
  class of mistake recurred.

## Root Cause

- Category: ambiguous instructions + missing example (primary), assumed context
  and scope creep (contributing).
- The ACE overlay workflow listed four OTP paths but gave no decision rule for
  "agent has no TTY / no credential"; it also never stated that the agent shell
  and operator shell are different environments.
- No workflow example showed the correct handoff message, so the agent invented
  one.

## Improvement Applied

1. `.ace-handbook/workflow-instructions/release/rubygems-publish.wf.md`
   (project overlay, the file `ace-bundle wfi://release/rubygems-publish`
   actually loads):
   - Added **Agent Execution Contract** with a decision table:
     credential-visible → `--dry-run` → `--prepare` → handoff; no credential/no
     TTY → `--dry-run` → single-command handoff; operator-authorized →
     one-OTP-via-`ace-hitl`/chat then agent runs it; versions already live → do
     not re-run.
   - Added the copy-paste operator handoff template.
   - Documented the operator-authorized agent-driven OTP path
     (`GEM_HOST_OTP_CODE` in the environment, never argv; OTP is single-use,
     never persisted to files/logs/retros/evidence; HITL event cleared/archived
     after use).
   - Post-publish rule: never re-run the publisher to confirm a release; never
     substitute hand-rolled `bundle install` proofs for `TS-MONO-001`; report
     the blocked runner and hand it off if unavailable.
2. `ace-handbook/handbook/skills/as-release-rubygems-publish/SKILL.md`
   (canonical skill, projection re-synced): fixed the stale
   `argument-hint` to include `--prepare`, added the last-mile handoff rule and
   the agent-driven OTP path, and the "do not re-run / do not hand-roll proof"
   constraints.

## Expected Impact

- Next release session hands off exactly one command on the first attempt, with
  no credential-setup request and no unnecessary prepare gating.
- When an operator authorizes agent-driven publishing, one fresh OTP via
  ace-hitl/chat is consumed in the environment and never persisted.
- Completed releases are confirmed by dry-run output plus RubyGems metadata;
  the propagation proof stays with the e2e runner.

## Action Items

### Stop Doing

- Asking the operator to configure credentials that already exist in their own
  terminal.
- Gating the handoff on `--prepare` when the agent cannot validate credentials.
- Re-running the publisher or hand-rolling install proofs after a release.

### Start Doing

- Hand off `.ace-bin/ace-rubygems-publish --interactive` as a single command
  after the dry-run plan is known.
- For operator-authorized agent publishing: one OTP request via ace-hitl/chat,
  then `GEM_HOST_OTP_CODE=<otp> .ace-bin/ace-rubygems-publish` immediately.

### Continue Doing

- Dry-run first: plan, waves, and artifact list are the handoff contract.
- Verify RubyGems metadata (versions, yanked flag, dependency floors) after the
  burst, outside the OTP window.

## Technical Details

- Publisher: `.ace-bin/ace-rubygems-publish`; OTP patterns are 6-8 alphanumeric
  characters (`--otp`, `--interactive`, or `GEM_HOST_OTP_CODE`, in that order of
  resolution).
- Supersedes the unapplied Start Doing item from retro `8x2ysa`
  (rubygems-publish-prepare-handoff-gap), which is archived as consumed.
