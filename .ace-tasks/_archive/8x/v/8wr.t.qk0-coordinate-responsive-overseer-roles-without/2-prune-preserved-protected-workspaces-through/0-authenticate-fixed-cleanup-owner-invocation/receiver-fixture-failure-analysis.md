# Receiver orchestration fixture failure analysis

Failure: ProtectedServiceReceiverTest.test_fresh_permission_and_final_read_transfer_real_candidate_handler_evidence, with the same shared fixture used by test_lost_completion_reply_never_claims_success_after_real_handler_effect. Category: test_infrastructure. Confidence: high.

Evidence: unchanged baseline failure was retained in input-source-checkpoint.md. Root reproduced the positive case at af5dc0d3f: d5749e56-8daf-49e4-a906-7a807362c158 (1/1 failed). A temporary TracePoint diagnostic in .ace-local/receiver-diagnosis, run via bin/ace-test, receipt87e4fbc6-ad37-471b-a558-412cb14f4701, observed real candidate/proof.txt creation and calls through service_authorization. BoundedProcess#kill_group then raises Errno::EPERM at Process.kill(KILL, -pid); the maintained handler catches PostLaunchError and returns nil. Receiver truthfully reports uncertain, never fabricated completion. No source failure in new capacity/claim callback is implicated.

Fix target: test infrastructure in ace-lab/test/organisms/protected_service_receiver_test.rb only. Use an explicit fixture-only BoundedProcess adapter for the exact configured fixture handler argv; assert that production requested cleanup_group:true, then delegate the real bounded child with post-exit group cleanup disabled for this controlled orchestration test. Keep actual temporary Git, candidate materialization, ordinary shell effect, receipt/evidence handling and normal deadline behavior. Other subprocesses retain their options.

Do not touch: production BoundedProcess, ProtectedServiceHandler/Receiver, permission/error classification, native/systemd tests or installed acceptance criteria. Actual process-group cleanup remains a separate installed obligation in gad.2. Independent wave_n0n agreed the proposed layer/seam; final diff and results still require review.

Disconfirming check: if the targeted positive still returns uncertain with this specific boundary controlled, stop and revise the classification; do not weaken additional assertions. First rerun the two failures, then the inspected full receiver fixture file. Expected: real handler evidence reaches complete_service for success; lost completion still uncertain with one effect.

## Fix verification

Applied only the exact fixture-handler runner seam. Targeted two original failures: bin/ace-test ace-lab ace-lab/test/organisms/protected_service_receiver_test.rb:128 ace-lab/test/organisms/protected_service_receiver_test.rb:147 --timeout 90, 2 tests/12 assertions PASS1.15s, receipt8a7d7028-2aa4-43ce-aa72-72c587ee897e. Inspected full file: bin/ace-test ace-lab ace-lab/test/organisms/protected_service_receiver_test.rb --timeout 90, 10 tests/46 assertions PASS3.35s, receiptc0de9db3-bdfe-4064-8840-12d33b7fd272. Both sessions terminal0. Earlier two baseline failures are now explained and resolved for orchestration coverage, not reclassified as native cleanup success.

Independent wave_n0n scoped APPROVE exact6a0b55b3f970a17658cff6b2335f475f855deb92: only exact configured fixture argv receives the boundary override, production cleanup request remains asserted, actual candidate/shell/evidence retained. No native guarantee relaxed. Root doctor:790tasks/32folders, zero errors, unchanged464historical warnings; diff check passed.
