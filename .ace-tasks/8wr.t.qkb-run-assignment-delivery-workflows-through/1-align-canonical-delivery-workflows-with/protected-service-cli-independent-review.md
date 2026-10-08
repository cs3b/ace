# Protected service CLI — independent integration review

Reviewed source: `85380bcc586d1e3fe9d6077c666669f5c64afed7`.
Reviewer: coordinating agent, independent of the implementation author, with
executed `ace-review` session `review-8x70xc` (terminal success, four findings).
Verdict: **changes required; source not integrated**.

The adapter preserves original prepared selection, delegates canonical status to
the existing Assign owner, and derives a stable claim mutation identity. The
additional test-only commit `aeaf89e1091ac2a61336a334cd29e0496667dcc2`
exercises lost claim response, read-only pending status and exact public replay.
These support the bounded adapter contract, not completion of qkb.1.

## Required repairs

- [ ] `8x7124ek`: translate protected request/status refusals into one classified
  JSON error and nonzero CLI result. Verified against the executable, which
  catches only `Ace::Support::Cli::Error`; adapter ArgumentError and Assign
  exceptions currently escape. Test the registered command's refusal output.
- [ ] `8x7124el`: classify missing installed mapping as EvidenceUnavailable.
  Verified that Deployment.mapping uses Hash#fetch and the new public selection
  hook does not translate its KeyError. Add a focused missing-mapping test.
- [ ] Handle post-submission output-bound failure as an uncertain result requiring
  canonical observation, without presenting it as proof that no claim occurred.
- [ ] Record the new CLI and public context methods in package changelogs.
- [ ] Independently review the repair commit and execute integration verification
  before merging the source and releasing dependent work.

## Remaining family gates

Public foreign/stale selection, unavailable installation, authorization and review
refusals remain part of the required source acceptance. The complete workflow
join, unresolved create-before-review policy, R2/R3 and final acceptance scenarios
remain open. No installed Lab acceptance or release readiness is claimed here.

The detailed local report is
`.ace-local/review/sessions/review-8x70xc/review-report-review-default.md`.
The two blocking findings were independently verified and marked pending in
that session; this record retains the actionable result with the task.
