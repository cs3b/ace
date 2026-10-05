---
doc-type: workflow
title: Update an attempt-bound pull request
purpose: Update the exact forge-neutral PR and consume current delivery evidence
---

# Update an attempt-bound pull request

## Goal

Update the recorded PR description for the current candidate and preserve provider identity through readiness and integration handoff.

## Prerequisites

A managed assignment with a recorded PR and active delivery attempt. Reuse the original forge selection and complete fork/canonical provenance; changed configuration or identity is a conflict. A new committed candidate, including task-only changes, requires renewed tests and independent review.

## Steps

1. Inspect the committed changes and accepted test/review evidence. Prepare the final description with the concrete behavior, executed test results, independent verdict, and actual limitations. Save it as a local file; do not put credentials or terminal dumps in the attempt journal.
2. Execute `ace-assign delivery --assignment ID --attempt ATTEMPT --operation update --body-file DESCRIPTION`. Supply `--parameters FILE` only if the assignment source lacks the original `delivery` mapping. In this repository use `bin/ace-assign`.
3. On interrupted update, repeat the delivery command. It reads the exact remote title/body and compares the requested field digest before accepting; an unmatched or unreadable outcome remains unresolved. Never blindly resend a mutation.
4. To mark ready, supply two JSON reference files, each containing only `attempt_id` and `receipt_digest`, from coordinator-accepted current-head test and independent review attempts in this assignment/project. Execute `ace-assign delivery --assignment ID --attempt ATTEMPT --operation ready --tests TEST-REF --review REVIEW-REF`. Missing, fabricated, stale, or self-approved evidence cannot authorize readiness. Red CI alone does not veto valid executed tests and review.
5. Merge is an integrator/service operation under the existing exact qjx authorization policy. The authorized executor calls `ace-git pr merge IDENTIFIER --server NAME --expected-head CANDIDATE-SHA --method METHOD --format json` with the retained selection (or `--default-server`, otherwise remote resolution). Both expected SHA and the authorized squash/merge/rebase method are required; there is no default method. It does not recursively request its own future receipt. The worker consumes the completed, verified service receipt using `ace-assign delivery --assignment ID --attempt ATTEMPT --operation merge --tests TEST-REF --review REVIEW-REF --service-request REQUEST`. The request must bind this assignment, attempt, project, candidate and PR URL. No completed receipt means a routed blocker; credentials or caller assertions grant no authority.
6. Unknown merge remains pending service reconciliation and is never automatically retried. Inspect the authoritative selected remote and verified executor evidence. Changed head or scope blocks acceptance. Merge does not authorize publication, deployment or synchronization.

## Success criteria

The exact remote outcome and existing qjl evidence agree. Real artifacts, current executed tests, independent verdict and required authorization gate completion. Preserve unresolved history and distinct candidate_head/journal_commit. qkb.1 supplies installed charter/proposal/service adoption; this workflow does not fabricate that acceptance.
