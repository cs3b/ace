# Test Report

**Generated:** 2026-10-05 15:05:39
**Status:** ❌ Failed
**Execution failure:** /Users/mc/Ps/ace/.ace-wt/review-9c2-runtime/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 35 |
| Passed | 33 |
| Failed | 2 |
| Errors | 0 |
| Skipped | 0 |
| Pass Rate | 94.29% |
| Duration | 499.08185s |

## Failures

### 1. test_real_client_refuses_missing_mismatched_extra_part_and_open_descriptor_before_bytes

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace/.ace-wt/review-9c2-runtime/ace-runtime/lib/ace/runtime/molecules/protected_socket.rb:63`
- **Message:** [Ace::Assign::AttemptErrors::EvidenceUnavailable] exception expected, not
Class: <Ace::Runtime::RuntimeUnavailableError>
Message: <"protected socket deadline expired">
---Backtrace---

### 2. test_real_client_server_submit_lost_reply_exit_restart_status_and_exact_fetch

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace/.ace-wt/review-9c2-runtime/ace-runtime/lib/ace/runtime/molecules/protected_socket.rb:63`
- **Message:** [Ace::Assign::AttemptErrors::EvidenceUnavailable] exception expected, not
Class: <Ace::Runtime::RuntimeUnavailableError>
Message: <"protected socket deadline expired">
---Backtrace---

## Files Tested

- test/feat/completion_generation_test.rb
- test/feat/endcap_service_replay_test.rb
- test/feat/endcap_results_test.rb
