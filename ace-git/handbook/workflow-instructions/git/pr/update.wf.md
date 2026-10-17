---
doc-type: workflow
title: Update a pull request
purpose: Update the exact forge-neutral PR and record current delivery evidence
---

# Update a pull request

## Goal

Update the recorded PR description for the current candidate and preserve provider identity through readiness and integration handoff.

## Prerequisites

An assignment with a recorded PR, or an explicit local PR scope. Reuse the original forge selection and complete fork/canonical provenance; changed configuration or identity is a conflict. A new committed candidate, including task-only changes, requires renewed tests and independent review.

## Steps

1. Inspect the committed changes and accepted test/review evidence. Prepare the final description with the concrete behavior, executed test results, independent verdict, and actual limitations. Save it as a local file; do not put credentials or terminal dumps in the assignment report.
2. Update the PR with the configured forge command:

   ```sh
   ace-git pr update IDENTIFIER --server NAME --expected-head CANDIDATE-SHA --body-file DESCRIPTION --format json
   ```

   Use the retained default/remote selection instead of `--server NAME` when applicable. In this repository invoke the source `bin/ace-git` entrypoint.
3. On an interrupted update, do not assume the command reconciles for you: `ace-git pr update` verifies the head and rewrites the title/body, so a retry is a new write. Explicitly read the exact remote title/body (for example `ace-git pr show IDENTIFIER --format json`), compare it with the prepared description; if identical, treat the update as done, otherwise re-run the command. An unreadable or uncertain read stays unresolved. Never blindly resend a mutation.
4. Mark ready only after tests and independent review pass on the exact head. Record the executed tests and independent review evidence for that head, then run:

   ```sh
   ace-git pr ready IDENTIFIER --server NAME --expected-head CANDIDATE-SHA --format json
   ```

   Missing, stale, or self-approved evidence cannot authorize readiness. Red CI alone does not veto valid executed tests and review.
5. Merge is a separate authorized operation for the exact candidate. The authorized executor runs:

   ```sh
   ace-git pr merge IDENTIFIER --server NAME --expected-head CANDIDATE-SHA --method METHOD --format json
   ```

   with the retained selection (or `--default-server`, otherwise remote resolution). Both the expected SHA and the authorized squash/merge/rebase method are required; there is no default method. Credentials or caller assertions grant no permission.
6. An unknown merge remains an unresolved effect. Inspect the authoritative selected remote and the actual executor evidence; never retry blindly. Changed head or scope blocks acceptance. Merge does not authorize publication, deployment or synchronization.

## Success criteria

The exact remote outcome and the locally recorded evidence agree. Real artifacts, current executed tests and an independent verdict gate completion. Preserve unresolved history and distinguish the candidate head from evidence commits.
