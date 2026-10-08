# Protected service CLI — independent integration review

Reviewed source: `85380bcc586d1e3fe9d6077c666669f5c64afed7`.
Reviewer: coordinating agent, independent of the implementation author, with
executed `ace-review` session `review-8x70xc` (terminal success, four findings).
Initial verdict: **changes required**. Repair `d842a9cb5` independently approved by the coordinating reviewer after reading its production/test delta and executed raw reports. Integrated through `dd0f8caf9`; current bounded verdict: **APPROVE**. Whole qkb.1 remains open.

The adapter preserves original prepared selection, delegates canonical status to
the existing Assign owner, and derives a stable claim mutation identity. The
additional test-only commit `aeaf89e1091ac2a61336a334cd29e0496667dcc2`
exercises lost claim response, read-only pending status and exact public replay.
These support the bounded adapter contract, not completion of qkb.1.

## Required repairs

- [x] `8x7124ek`: translate protected request/status refusals into one classified
  JSON error and nonzero CLI result. Verified against the executable, which
  catches only `Ace::Support::Cli::Error`; adapter ArgumentError, SecurityError
  and RuntimeUnavailableError escape. Assign::Error already inherits CLI Error
  (errors.rb), so its gap is the missing JSON envelope, not a backtrace. Test
  the registered command's refusal output and the runtime deadline path.
- [x] `8x7124el`: classify missing installed mapping as EvidenceUnavailable.
  Verified that Deployment.mapping uses Hash#fetch and the new public selection
  hook does not translate its KeyError. Add a focused missing-mapping test.
- [x] Handle post-submission output-bound failure as an uncertain result requiring
  canonical observation, without presenting it as proof that no claim occurred.
- [x] Record the new CLI and public context methods in package changelogs.
- [x] Independently review the repair commit and execute integration verification
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

## Integrated verification

At main `0c191d366`, Lab command/adapter/cleanup owner tests passed27/200 (`lab/842849fc-7ba5-42fd-a690-da3c49dd1acd`), Assign context passed7/47 (`assign/3f599c6d-8a4a-422c-a8fe-7bfb2bd5ecb7`), and actual public lost-claim response/status/exact replay passed1/67 in35.51s (`git/4d558680-5481-4a11-ab87-0185545cc515`). No source changed while these checks ran. Existing held-input evidence was retained when merging task documentation; changelog conflict resolution preserved both source entries.

The separate cleanup runtime-bound repair `d0e5b52ea` was independently approved by `/root/wave_412` and integrated as `0c191d366`:64 selected unique paths with16,384 aggregate argv bytes including terminators. Actual Lab producer measured45 paths/10,091 argv bytes and503,317 entry bytes, within unchanged1MiB entry cap. This proves bounded source composition, not installed root execution or full physical cleanup.
