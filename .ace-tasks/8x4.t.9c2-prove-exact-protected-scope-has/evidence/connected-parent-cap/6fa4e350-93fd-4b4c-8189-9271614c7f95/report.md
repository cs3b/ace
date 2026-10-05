# Test Report

**Generated:** 2026-10-05 14:59:41
**Status:** ❌ Failed
**Execution failure:** /Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 35 |
| Passed | 32 |
| Failed | 3 |
| Errors | 0 |
| Skipped | 0 |
| Pass Rate | 91.43% |
| Duration | 461.53696s |

## Failures

### 1. test_authorization_read_refuses_closed_scope_before_fresh_policy

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-assign/lib/ace/assign/authority/endcap_services.rb:139`
- **Message:** [Ace::Assign::AttemptErrors::EvidenceUnavailable] exception expected, not
Class: <ArgumentError>
Message: <"structured service input transfer is missing">
---Backtrace---

### 2. test_real_client_server_submit_lost_reply_exit_restart_status_and_exact_fetch

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-runtime/lib/ace/runtime/molecules/protected_socket.rb:63`
- **Message:** [Ace::Assign::AttemptErrors::EvidenceUnavailable] exception expected, not
Class: <Ace::Runtime::RuntimeUnavailableError>
Message: <"protected socket deadline expired">
---Backtrace---

### 3. test_real_client_refuses_missing_mismatched_extra_part_and_open_descriptor_before_bytes

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-runtime/lib/ace/runtime/molecules/protected_socket.rb:63`
- **Message:** [Ace::Assign::AttemptErrors::EvidenceUnavailable] exception expected, not
Class: <Ace::Runtime::RuntimeUnavailableError>
Message: <"protected socket deadline expired">
---Backtrace---

## Files Tested

- test/feat/completion_generation_test.rb
- test/feat/endcap_service_replay_test.rb
- test/feat/endcap_results_test.rb
