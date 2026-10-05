# 9c2 staged lineage checkpoint — independent corrective review

Exact frozen source `c9cca309f9f1367ea43964da967a3c37dcb3e71d`. **APPROVE the bounded staged-reader source checkpoint.** Original d3 REQUEST CHANGES remains in `9c2-scope-lineage-review.md`. Reviewed production delta against main `6485f46b388819b3a27de7b07ee3869a8a87ec57` and independently approved `b6405f1bfbe88ea5e075823fb6cd25d8dd151108` amendment, in own worktree `/Users/mc/Ps/ace/.ace-wt/review-9c2-runtime` detached at exact candidate, no tracked changes.

Prior nonexistent reservation-generation gap is fixed: the reader captures the exact preceding canonical reserve_attempt response with expected project/assignment/attempt/map, validates both reservation and mutation generations against the counted chain, refuses duplicate reservation, ties parent reservation_generation to it, and checks genuine child's command ticket against the retained original ticket. Current JournalMutation actually persists this response under authority_mutation.payload.data, so the reader uses the real owner's format.

Old full-binding dialect is removed. Parent binding has exact immutable parent/resource schema; native and genuine-child events reference the original parent and predecessor native digest, are single-use and cannot arrive after seal. require_launch_bound! requires open full staged lineage. Parent-only sealed closure can yield positive canonical proof without inventing service/child identities. Proof resolves exact parent/seal/boot/InvocationID/object and zero population; duplicates, wrong references and hash/attempt corruption refuse. Returned child/binding projections are copied and deeply frozen. No new verified actionable finding.

This is canonical semantic lineage validation only. Missing scope_provisioning/admission hooks, live manifest/native/kernel observation, effect seal guards, release integration and full owner lifecycle are not claimed delivered by this checkpoint. The exact candidate branch predates the approved spec merge, so a whole branch diff against current main includes older docs; verdict covers the requested production checkpoint, not reverting current specs during integration. Root owns integration preserving the approved amendment.

## Independent executed receipts

- Candidate focused file: **12 tests / 57 assertions PASS**, `668a4c70-30db-4dcb-9787-f37506246294`.
- Reviewer staged adversarial fixture plus inherited candidate cases: **28 / 128 PASS**, `1db14e29-b1d1-4b12-aa21-2b1da2fd6e55`. Added checks cover repeat reconstruction of parent-only positive proof without launchability, child-after-seal refusal with valid chain hashes, foreign native reference refusal, and detached deeply immutable child command.

Ran bin/ace-test only in own worktree; read immutable report summaries under its `.ace-local/test/reports/assign/<execution_id>/`. Reviewer fixture is `.ace-local/review/staged_lineage_boundary_test.rb`. No source edits, broad Assign suite duplication, delegation, native/system-manager/VM/privilege probes or installed tests. Whole 9c2 acceptance remains open.
