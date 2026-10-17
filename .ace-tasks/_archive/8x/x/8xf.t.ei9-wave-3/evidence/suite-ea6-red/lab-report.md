# Test Report

**Generated:** 2026-10-16 21:11:24
**Status:** ❌ Failed
**Execution failure:** #<Thread:0x0000000122716998 /Users/mc/Ps/ace/.ace-wt/ei9-program-integration/ace-lab/test/organisms/protected_cleanup_dispatch_test.rb:514 run> terminated with exception (report_on_exception is true):
/Users/mc/Ps/ace/.ace-wt/ei9-program-integration/ace-lab/lib/ace/lab/organisms/protected_cleanup_owner.rb:286:in 'Ace::Lab::Organisms::ProtectedCleanupOwner#inspection': original cleanup lifetime exclusion unavailable (Ace::Runtime::RuntimeUnavailableError)
	from /Users/mc/Ps/ace/.ace-wt/ei9-program-integration/ace-lab/lib/ace/lab/organisms/protected_cleanup_owner.rb:194:in 'Ace::Lab::Organisms::ProtectedCleanupOwner#handle'
	from /Users/mc/Ps/ace/.ace-wt/ei9-program-integration/ace-lab/test/organisms/protected_cleanup_dispatch_test.rb:514:in 'block (3 levels) in exercise_retained_success_recovery'
CLEANUP_OWNER_COST {git: [630, 12.395], read_events: [269, 6.312], service_request: [69, 4.356], service_request_records: [13, 0.679], verify_service_record!: [62, 1.092], event_commits!: [23, 1.912], verify_canonical_prefix!: [15, 1.158]}; RPC=[["service_status", 0.58, {git: [20, 0.391], read_events: [9, 0.164], service_request: [2, 0.042], service_request_records: [1, 0.041], verify_service_record!: [4, 0.003], event_commits!: [1, 0.0], verify_canonical_prefix!: [1, 0.076]}], ["claim_service_settlement", 0.781, {git: [29, 0.571], read_events: [12, 0.156], service_request: [4, 0.096], service_request_records: [0, 0.0], verify_service_record!: [1, 0.001], event_commits!: [0, 0.0], verify_canonical_prefix!: [0, 0.0]}], ["service_status", 0.599, {git: [20, 0.383], read_events: [9, 0.16], service_request: [3, 0.039], service_request_records: [1, 0.038], verify_service_record!: [4, 0.003], event_commits!: [1, 0.0], verify_canonical_prefix!: [1, 0.075]}], ["complete_no_effect", 0.924, {git: [35, 0.667], read_events: [15, 0.261], service_request: [5, 0.096], service_request_records: [0, 0.0], verify_service_record!: [1, 0.002], event_commits!: [1, 0.0], verify_canonical_prefix!: [0, 0.0]}], ["service_status", 0.613, {git: [20, 0.389], read_events: [9, 0.166], service_request: [3, 0.045], service_request_records: [1, 0.04], verify_service_record!: [4, 0.003], event_commits!: [1, 0.0], verify_canonical_prefix!: [1, 0.076]}], ["complete_no_effect", 1.415, {git: [53, 1.037], read_events: [22, 0.344], service_request: [10, 0.16], service_request_records: [1, 0.04], verify_service_record!: [4, 0.004], event_commits!: [4, 0.0], verify_canonical_prefix!: [1, 0.078]}], ["service_status", 0.767, {git: [22, 0.443], read_events: [12, 0.215], service_request: [3, 0.114], service_request_records: [1, 0.043], verify_service_record!: [5, 0.057], event_commits!: [1, 0.0], verify_canonical_prefix!: [1, 0.078]}], ["service_status", 0.722, {git: [22, 0.435], read_events: [12, 0.234], service_request: [3, 0.105], service_request_records: [1, 0.042], verify_service_record!: [5, 0.048], event_commits!: [1, 0.0], verify_canonical_prefix!: [1, 0.077]}], ["service_status", 0.727, {git: [22, 0.435], read_events: [12, 0.231], service_request: [3, 0.106], service_request_records: [1, 0.041], verify_service_record!: [5, 0.048], event_commits!: [1, 0.0], verify_canonical_prefix!: [1, 0.076]}], ["service_status", 0.161, {git: [3, 0.062], read_events: [0, 0.0], service_request: [0, 0.0], service_request_records: [0, 0.0], verify_service_record!: [0, 0.0], event_commits!: [0, 0.0], verify_canonical_prefix!: [0, 0.0]}]]
/Users/mc/Ps/ace/.ace-wt/ei9-program-integration/ace-lab/lib/ace/lab/molecules/protected_publication_publisher.rb:49: warning: detected duplicate key "name" in JSON object. This will raise an error in json 3.0 unless enabled via `allow_duplicate_key: true` at line 1 column 1

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 501 |
| Passed | 495 |
| Failed | 2 |
| Errors | 0 |
| Skipped | 4 |
| Pass Rate | 98.8% |
| Duration | 560.285513s |

## Failures

### 1. Ace::Lab::OrdinaryListenEndToEndTest#test_request_executes_real_ff_merge_settles_receipt_and_next_request_advances [test/organisms/ordinary_listen_e2e_test.rb:109]:

- **Type:** failure
- **Location:** `test/organisms/ordinary_listen_e2e_test.rb:109`
- **Message:** {"status" => "error", "error" => {"schema" => "ace.lab.service.ordinary-merge-refusal/v1", "code" => "ordinary_merge_authorization_invalid", "message" => "canonical ordinary merge evidence owner is not installed", "request_id" => "request-a", "input_digest" => nil}}.
Expected: "ok"
  Actual: "error"
- **Fix:** Check the assertion values. Expected and actual don't match.

### 2. Ace::Lab::OrdinaryListenEndToEndTest#test_new_hitl_proposal_after_first_merge_needs_no_policy_edit_or_receiver_restart [test/organisms/ordinary_listen_e2e_test.rb:189]:

- **Type:** failure
- **Location:** `test/organisms/ordinary_listen_e2e_test.rb:189`
- **Message:** {"status" => "error", "error" => {"schema" => "ace.lab.service.ordinary-merge-refusal/v1", "code" => "ordinary_merge_authorization_invalid", "message" => "canonical ordinary merge evidence owner is not installed", "request_id" => "request-a", "input_digest" => nil}}.
Expected: "ok"
  Actual: "error"

501 runs, 2763 assertions, 2 failures, 0 errors, 4 skips

You have skipped tests. Run with --verbose for details.
- **Fix:** Check the assertion values. Expected and actual don't match.

## Files Tested

- test/atoms/binding_freshness_test.rb
- test/atoms/protected_publication_input_test.rb
- test/atoms/protected_workspace_prune_input_test.rb
- test/atoms/public_projection_test.rb
- test/atoms/service_input_test.rb
- test/atoms/topology_schema_test.rb
- test/molecules/caller_authorizer_test.rb
- test/molecules/capability_router_test.rb
- test/molecules/command_owner_admission_test.rb
- test/molecules/command_policy_test.rb
- test/molecules/exact_resolver_test.rb
- test/molecules/forge_merge_config_test.rb
- test/molecules/forgejo_merge_adapter_test.rb
- test/molecules/grant_resolver_test.rb
- test/molecules/hitl_authorizer_test.rb
- test/molecules/inventory_query_test.rb
- test/molecules/ordinary_admission_resolver_test.rb
- test/molecules/ordinary_execution_observation_test.rb
- test/molecules/ordinary_listener_test.rb
- test/molecules/ordinary_merge_read_test.rb
- test/molecules/ordinary_native_read_test.rb
- test/molecules/ordinary_owner_admission_test.rb
- test/molecules/ordinary_receiver_config_test.rb
- test/molecules/ordinary_socket_test.rb
- test/molecules/ordinary_worktree_read_test.rb
- test/molecules/protected_cleanup_owner_client_test.rb
- test/molecules/protected_cleanup_owner_identity_test.rb
- test/molecules/protected_publication_publisher_test.rb
- test/molecules/protected_service_handler_cleanup_test.rb
- test/molecules/protected_service_handler_test.rb
- test/molecules/protected_service_loading_test.rb
- test/molecules/protected_service_policy_test.rb
- test/molecules/service_executor_test.rb
- test/molecules/service_policy_test.rb
- test/molecules/topology_loader_test.rb
- test/organisms/authority_composition_test.rb
- test/organisms/command_executor_test.rb
- test/organisms/command_run_client_test.rb
- test/organisms/ordinary_assignment_client_test.rb
- test/organisms/ordinary_authority_composition_test.rb
- test/organisms/ordinary_listen_e2e_test.rb
- test/organisms/ordinary_merge_receiver_test.rb
- test/organisms/ordinary_merge_request_test.rb
- test/organisms/protected_cleanup_admission_read_scope_test.rb
- test/organisms/protected_cleanup_dispatch_test.rb
- test/organisms/protected_cleanup_owner_listener_test.rb
- test/organisms/protected_publication_authority_test.rb
- test/organisms/protected_publication_flow_test.rb
- test/organisms/protected_service_boundary_test.rb
- test/organisms/protected_service_expiry_test.rb
- test/organisms/protected_service_listener_test.rb
- test/organisms/protected_service_receiver_test.rb
- test/organisms/protected_service_recovery_test.rb
- test/organisms/protected_service_request_test.rb
- test/organisms/publication_composition_test.rb
- test/organisms/service_request_service_test.rb
- test/organisms/topology_service_test.rb
- test/models/runtime_binding_test.rb
- test/models/topology_entry_test.rb
- test/commands/agents_test.rb
- test/commands/assignment_test.rb
- test/commands/fresh_install_test.rb
- test/commands/projects_test.rb
- test/commands/resolve_test.rb
- test/commands/route_test.rb
- test/commands/service_listen_test.rb
- test/commands/service_test.rb
- test/commands/services_test.rb
