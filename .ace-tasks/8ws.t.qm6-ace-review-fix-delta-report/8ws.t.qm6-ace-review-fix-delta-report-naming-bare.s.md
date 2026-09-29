---
id: 8ws.t.qm6
status: pending
priority: low
created_at: "2026-09-29 17:44:39"
estimate: 
dependencies: []
tags: [ace-review, review-loop, delta]
---

# ace-review: fix delta report naming, bare --pr full-round default, and stale-head delta retry

## Origin

Hit three times during the 8wr.t.t8j review loop (PR #352, 2026-09-29).

## Behavioral Specification

### Expected Behavior

- Follow-up delta rounds read prior-session evidence without manual file
  surgery. Today `ReviewEvidence.build` globs only `review-report-*.md`,
  while the multi-model executor saves `review-<role-model>.md` (e.g.
  `review-role-review-codex.md`) and no-op rounds save `review.md`; every
  delta round after those fails with `No review report in <session>` until
  the report is manually aliased.
- A bare `ace-review --pr N` on a fresh PR runs a FULL review round. Today
  `process_delta` sees the `:delta` option key (ace-support-cli passes all
  declared options), normalizes nil to `:auto`, and the round fails with
  `No prior review session records a head`; a full round currently requires
  `--delta <base>`.
- A delta round launched immediately after a push may read a stale GH
  `headRefOid` (equal to the delta reference head) and report an empty
  no-op delta, silently skipping the round. When
  `delta_base_head == delta_reference_head` but the local branch head is
  newer, retry the PR metadata fetch (or fail loudly instead of recording
  a no-op).

### Interface Contract

No CLI surface change required; naming acceptance and defaults only.

### Success Criteria and Verification

- [ ] Delta round works against a session whose report uses the executor's role-named file and against a no-op session, without manual aliasing.
- [ ] `ace-review --pr <fresh-PR>` executes a full round; `--delta` keeps current meaning.
- [ ] Push-then-delta no longer records a false empty no-op round.

## Slice and Review Decisions

Owner: ace-review (`review_evidence.rb`, `delta_resolver.rb`,
`review_manager.rb`, `cli/commands/review.rb`). Reference session dirs:
`.ace-local/review/sessions/review-8wsopg` (role-named report) and
`review-8wsprm` (no-op `review.md`) in the t8j worktree history.
