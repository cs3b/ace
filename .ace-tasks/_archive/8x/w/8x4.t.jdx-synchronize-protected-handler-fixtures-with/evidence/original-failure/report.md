# Test Report

**Generated:** 2026-10-05 13:43:29
**Status:** ❌ Failed
**Execution failure:** Test execution did not complete successfully

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 199 |
| Passed | 197 |
| Failed | 0 |
| Errors | 1 |
| Skipped | 1 |
| Pass Rate | 98.99% |
| Duration | 40.134029s |

## Failures

### 1. Ace::Lab::ProtectedServiceHandlerTest#test_receiver_owned_process_group_cleanup_stops_background_writer:

- **Type:** error
- **Location:** ``
- **Message:** NoMethodError: undefined method 'fetch' for nil
    test/molecules/protected_service_handler_test.rb:42:in 'block in Ace::Lab::ProtectedServiceHandlerTest#test_receiver_owned_process_group_cleanup_stops_background_writer'
    test/molecules/protected_service_handler_test.rb:16:in 'block in Ace::Lab::ProtectedServiceHandlerTest#with_handler'

## Files Tested

- test/atoms/binding_freshness_test.rb
- test/atoms/public_projection_test.rb
- test/atoms/service_input_test.rb
- test/atoms/topology_schema_test.rb
- test/molecules/caller_authorizer_test.rb
- test/molecules/capability_router_test.rb
- test/molecules/exact_resolver_test.rb
- test/molecules/grant_resolver_test.rb
- test/molecules/hitl_authorizer_test.rb
- test/molecules/inventory_query_test.rb
- test/molecules/protected_service_handler_test.rb
- test/molecules/protected_service_policy_test.rb
- test/molecules/service_executor_test.rb
- test/molecules/service_policy_test.rb
- test/molecules/topology_loader_test.rb
- test/organisms/authority_composition_test.rb
- test/organisms/protected_service_receiver_test.rb
- test/organisms/service_request_service_test.rb
- test/organisms/topology_service_test.rb
- test/models/runtime_binding_test.rb
- test/models/topology_entry_test.rb
- test/commands/agents_test.rb
- test/commands/fresh_install_test.rb
- test/commands/projects_test.rb
- test/commands/resolve_test.rb
- test/commands/route_test.rb
- test/commands/service_test.rb
- test/commands/services_test.rb
