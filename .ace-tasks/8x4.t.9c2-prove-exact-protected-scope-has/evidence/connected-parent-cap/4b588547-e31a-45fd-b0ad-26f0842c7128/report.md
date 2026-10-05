# Test Report

**Generated:** 2026-10-05 13:54:15
**Status:** ❌ Failed
**Execution failure:** /Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 24 |
| Passed | 23 |
| Failed | 0 |
| Errors | 1 |
| Skipped | 0 |
| Pass Rate | 95.83% |
| Duration | 0.02036s |

## Failures

### 1. test_absent_native_binding_does_not_erase_canonical_admission

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::EvidenceUnavailable: native admission does not name the exact current reserved owner
lib/ace/assign/molecules/execution_scope_lineage.rb:323:in 'Ace::Assign::Molecules::ExecutionScopeLineage#unavailable!'
lib/ace/assign/molecules/execution_scope_lineage.rb:158:in 'Ace::Assign::Molecules::ExecutionScopeLineage#accept_admission!'
lib/ace/assign/molecules/execution_scope_lineage.rb:55:in 'block in Ace::Assign::Molecules::ExecutionScopeLineage#initialize'
lib/ace/assign/molecules/execution_scope_lineage.rb:51:in 'Array#each'
lib/ace/assign/molecules/execution_scope_lineage.rb:51:in 'Ace::Assign::Molecules::ExecutionScopeLineage#initialize'
test/fast/authority/execution_scope_observation_test.rb:63:in 'Class#new'
test/fast/authority/execution_scope_observation_test.rb:63:in 'Ace::Assign::ExecutionScopeObservationTest#lineage'
test/fast/authority/execution_scope_observation_test.rb:73:in 'Ace::Assign::ExecutionScopeObservationTest#seal_parent'
test/fast/authority/execution_scope_observation_test.rb:110:in 'Ace::Assign::ExecutionScopeObservationTest#test_absent_native_binding_does_not_erase_canonical_admission'

## Files Tested

- test/fast/authority/execution_scope_observation_test.rb
- test/fast/molecules/execution_scope_lineage_test.rb
