# R2/R3 result join — 2026-10-08

Source base: R3 `0ffbff1fb6d79e19138bd10f62be69c7dc0b4fce` on R2 `c910f1331`.
This is an implementer join audit, not the final independent source review.

## Exact owner correction

`CampaignManager.with_verified_result!` now yields both the verified current
projection and the compact snapshot serialized from that same held store record.
`accepted_result_snapshot` uses the same serializer. Endcap's current receipt
consumer compares the uploaded result against that yielded snapshot rather than
calling `accepted_result_snapshot` again inside the held read transaction. This
removes a second store transaction, projection and historical receipt traversal.
Original policy pre/post validation, parent candidate validation, descriptor
checks, immutable journal selections and acceptance binding remain in place.
CandidateTransfer's 30-second deadline and source-view lifetime checks are unchanged.

## Narrow executed evidence

`bin/ace-test ace-review feat ace-review/test/feat/campaign_canonical_result_join_test.rb`
passed 1 test, 24 assertions in 27.2 seconds. Report:
`.ace-local/test/reports/review/f25668d4-5888-4f01-81c3-54e909dfbfeb/`.
It uses real Git, five existing local qjl accepted executions (three substantive
review collections, required checks and independent approval), existing campaign
manager/store, real CanonicalEvidence import/read at one pinned journal commit and
ReceiptVerifier's same-manager current gate. No native process/OS isolation
simulation or new execution framework is involved. It proves canonical bytes beat
replaced disposable projection bytes, and refuses wrong campaign identity, rebinding
the artifact to a different candidate and an uncommitted candidate change.

`bin/ace-test ace-assign fast ace-assign/test/fast/authority/campaign_result_snapshot_test.rb`
passed 1 test, 6 assertions in 21.13 milliseconds. Report:
`.ace-local/test/reports/assign/e3575058-0c69-4e23-b3ca-022e247c5853/`.
This narrow Endcap seam test forbids a second snapshot read, consumes the yielded
snapshot, checks original pre/post policy and parent guard invocation, and refuses
a different snapshot before invoking the receipt consumer. It does not claim
native/protected runtime execution.

## Retired fixture and preserved obligations

The former active `protected_campaign_result_flow_test.rb` used a delivery policy
of minimum one round and one clean round. That policy is invalid under the reviewed
R3 requirement of minimum three rounds/two clean rounds. Its fake native setup and
three child settlements cannot establish current delivery acceptance; multiplying
it into nine fake native children would add local Lab simulation, not useful join
coverage. The obsolete fixture was removed from active tests. Its original source
and reported failures remain in Git history at `c910f1331` and the R2 checkpoint.
This removal does not turn the prior failed flow into a pass.

Installed/protected GAD2 obligations and the prior 30-second canonical candidate-view
performance failure remain open. The new local join proves source serialization and
canonical artifact/current-gate composition; it does not prove the protected full
runtime flow, solve the candidate-view deadline or replace actual task execution on
Lab after source readiness. No deadline increase, cached expired view, paid provider,
root/native probe, publish, merge, or task-done claim occurred.

## Remaining performance finding

CandidateTransfer starts CampaignReadView's absolute deadline before private Git
materialization. CampaignManager reads current revisions early, then performs
canonical historical receipt traversal, then asks the same candidate view for
cleanliness later. Therefore unrelated canonical R1 reads can consume the Git view's
wall-clock budget. Operation-local R1 inventory reuse and this removed duplicate
projection reduce that work, but the large protected flow was not rerun, and their
sufficiency is unverified. Preserve the existing bound and live guards; investigate
remaining repeated authority traversals with operation-local immutable selection
reuse before considering any additional source correction.
