# 9c2 canonical scope lineage — independent checkpoint review

Exact source candidate: `d3c9f88045c18817fb10f855326fe86d003483e1`, reviewed in isolated native worktree `/Users/mc/Ps/ace/.ace-wt/review-9c2-runtime` detached at that SHA. **REQUEST CHANGES** for this reader checkpoint. No production changes, delegation, main changes or native/system-manager/VM/privilege probes.

## Verified finding

**[P2] Validate reservation generation against the prior canonical reservation.** `ace-assign/lib/ace/assign/molecules/execution_scope_lineage.rb:83–90` validates scope_generation against the counted attempt-local mutation generation but accepts reservation_generation merely because it is positive. With the fixture's sole preceding reserve authority mutation, changing reservation_generation to 9999 still admits the complete binding, seal and no-writer proof. That generation does not exist in this chain. It contradicts the canonical reservation provenance carried by the approved full generation record and allows an internally inconsistent record to be treated as valid retained proof. Validate the selected reservation against an actual preceding canonical reserve_attempt mutation and its matching retained binding; at minimum nonexistent/future generations must refuse. This issue is independent of the separately evolving pre-child provisioning contract.

Independent reproduction uses the candidate's real event model/reader with a copied controlled fixture: change only reservation_generation, append normal binding/seal/proof events, require EvidenceUnavailable. The test fails because construction accepts the chain. The input is hash-chain-valid; chain integrity alone does not establish semantic reference validity.

## Other reviewed behavior and limits

Exact attempt chain, expected project/assignment/attempt/map projection, counted scope generation, single binding/seal/proof ordering, parent/boot/InvocationID agreement, exact seal/proof digests, population zero, and recursive detached immutable projections are present. Malformed/duplicate binding, seal and proof refuse; caller object mutation cannot alter the reader projection. Full original child/server/native command shape is validated. The reader does not make live owner observations or enforce lifecycle admission, and cannot substitute for those later layers. No verdict on complete generation provisioning, seal admission, close or installed acceptance is asserted.

## Executed local receipts

- Candidate focused reader tests: **7 / 33 PASS**, execution `3648643e-bb69-49b5-8c7d-8b5ab850d5a5`.
- Independent reservation-reference regression with inherited candidate cases: **15 / 67, one expected-refusal failure**, execution `3c0a1d70-0fec-4bc2-9d82-59e4f472b538`. Failure is the new reservation test; no errors. Fixture is `.ace-local/review/lineage_boundary_test.rb` in reviewer worktree. A preliminary --filter invocation selected zero files (execution `843bd306-70e9-42de-af61-e722bbebe2fb`), so it is not a passing test receipt.
- Parent supplied author's journal feature receipt **13 / 164 PASS**, execution `6ddf529c`; not independently rerun or represented as reviewer execution.

All reviewer tests use bin/ace-test with ordinary controlled local data. Receipts reside in the reviewer worktree's immutable `.ace-local/test/reports/assign/<execution_id>/` directories. No broad Assign suite was duplicated. Whole 9c2 acceptance remains open.
