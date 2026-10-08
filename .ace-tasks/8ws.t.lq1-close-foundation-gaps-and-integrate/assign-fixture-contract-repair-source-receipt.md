# Assign fixture contract repair — 2026-10-08

Source candidate from f66a1d258; independent review pending. Production code, deadlines, kernel/native policies and canonical owners are unchanged.

Original feat report3636f47f-948b-45d6-8ceb-1b4a46f487ec retained455 parsed tests/5348 assertions/10 errors, plus five separate180-second timeout messages in execution_error. The ten errors are three stale interfaces repeated through inherited classes: AtomicServiceMutationTest replay fixture lacks canonical operation projection (three occurrences); ProtectedDeploymentTest two maintenance cases omit deadline keyword (six occurrences); LaunchScopeParentCapTest client omits timeout keyword (one occurrence).

Repairs preserve intended assertions:

* Replay fixture now uses existing Endcap service_projection from its actual retained record; changed-body refusal and unchanged canonical ref remain.
* OrderedSlotLock accepts maintained optional deadline:nil; existing exact enter/leave/root ordering remains.
* Parent-cap fake client accepts explicit timeout and rejects any nonpositive/>30 budget; real controlled observer/journal abort/release/replay and next-reservation assertions remain.

Executed using checkout bin/ace-test, inspected declaration selectors and injected existing OS/manager/native boundaries:

| Command suffix after bin/ace-test ace-assign | Report | Result |
|---|---|---|
| test/feat/atomic_service_mutation_test.rb:192 --timeout 60 |678d3086-d9a0-473f-96ed-2f75a69c48ad|1/12 PASS2.49309s|
| test/feat/authority/deployment_test.rb:534 test/feat/authority/deployment_test.rb:573 --timeout 60|a4b6d9e5-83a5-4710-b991-cad881904485|2/38 PASS.00446s|
| test/feat/authority/launch_scope_parent_cap_test.rb:23 --timeout 60|e2696bc8-f542-4efd-b448-bad355ed652f|1/21 PASS12.01741s|

Raw run options identify exactly the four intended methods; total4tests/71assertions, no failures/errors/skips. Reports reside in this repair worktree .ace-local/test/reports/assign. Initial accidental selector190 resolved preceding test_pending_import_record_event_and_reply_share_one_commit_with_exact_bytes; report4bd0b649-3aab-4f1a-bb46-c4972f7a5b32 PASS1/16 is excluded from repair acceptance. It had already terminated when interruption was attempted; no live duplicate was started. This is retained selection-error history, not failure of repaired behavior.

Timeout accounting: original files_tested has58 entries, raw output has53 completed run blocks, and execution_error has five timeout messages. Exactly five selected files have no method output: authority/historical_rotation_test.rb, authority/launch_lifecycle_test.rb, campaign_receipt_test.rb, prepared_managed_flow_test.rb and prepared_worker_test.rb. The report lacks per-file timeout result association, so this is bounded inventory correlation, not a proven individual cause or receipt for those files. Runtime_binding_consumer inherits methods that did execute; it is not inferred as one of the missing five. No timeouts were rerun or budgets increased. This checkpoint does not claim whole feat/package acceptance.
