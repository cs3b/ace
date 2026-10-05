# Test Report

**Generated:** 2026-10-05 13:55:09
**Status:** ❌ Failed
**Execution failure:** /Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 21 |
| Passed | 1 |
| Failed | 2 |
| Errors | 18 |
| Skipped | 0 |
| Pass Rate | 4.76% |
| Duration | 23.3918s |

## Failures

### 1. test_launcher_loss_closes_admission_and_established_gate_never_reconnects

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:258:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_launcher_loss_closes_admission_and_established_gate_never_reconnects'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:257:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_launcher_loss_closes_admission_and_established_gate_never_reconnects'
- **Fix:** Resource doesn't exist. Check paths and names

### 2. test_definition_change_requires_all_scopes_terminal

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:517:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_definition_change_requires_all_scopes_terminal'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:516:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_definition_change_requires_all_scopes_terminal'
- **Fix:** Resource doesn't exist. Check paths and names

### 3. test_pre_release_exact_child_exit_is_required_for_abort

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:395:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_pre_release_exact_child_exit_is_required_for_abort'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:394:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_pre_release_exact_child_exit_is_required_for_abort'
- **Fix:** Resource doesn't exist. Check paths and names

### 4. test_driver_losing_cas_to_same_id_acceptance_never_creates_native_child

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:419:in 'Ace::Assign::ProtectedLaunchLifecycleTest::ClientAdapter#call'
lib/ace/assign/authority/launch_driver.rb:36:in 'Ace::Assign::Authority::LaunchDriver#launch'
test/feat/authority/launch_lifecycle_test.rb:482:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_driver_losing_cas_to_same_id_acceptance_never_creates_native_child'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:465:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_driver_losing_cas_to_same_id_acceptance_never_creates_native_child'
- **Fix:** Resource doesn't exist. Check paths and names

### 5. test_reservation_replay_and_overlap_never_create_another_intent

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:184:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_reservation_replay_and_overlap_never_create_another_intent'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:183:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_reservation_replay_and_overlap_never_create_another_intent'
- **Fix:** Resource doesn't exist. Check paths and names

### 6. test_worker_cannot_mutate_origin_and_changed_child_cannot_bind

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:200:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_worker_cannot_mutate_origin_and_changed_child_cannot_bind'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:199:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_worker_cannot_mutate_origin_and_changed_child_cannot_bind'
- **Fix:** Resource doesn't exist. Check paths and names

### 7. test_launcher_pidfd_refusal_cannot_commit_or_wedge_reservation

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-assign/lib/ace/assign/authority/execution_scope_observation.rb:157`
- **Message:** [Ace::Runtime::RuntimeUnavailableError] exception expected, not
Class: <KeyError>
Message: <"key not found: \"slice_unit\"">
---Backtrace---
- **Fix:** Resource doesn't exist. Check paths and names

### 8. test_exact_child_exit_projects_uncertainty_without_releasing_ownership

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:94:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_exact_child_exit_projects_uncertainty_without_releasing_ownership'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:93:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_exact_child_exit_projects_uncertainty_without_releasing_ownership'
- **Fix:** Resource doesn't exist. Check paths and names

### 9. test_bind_precedes_single_durable_release_and_replay_never_resends

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:212:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_bind_precedes_single_durable_release_and_replay_never_resends'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:211:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_bind_precedes_single_durable_release_and_replay_never_resends'
- **Fix:** Resource doesn't exist. Check paths and names

### 10. test_competing_reservation_acceptance_replays_and_closes_local_handle

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:136:in 'block (2 levels) in Ace::Assign::ProtectedLaunchLifecycleTest#test_competing_reservation_acceptance_replays_and_closes_local_handle'
- **Fix:** Resource doesn't exist. Check paths and names

### 11. test_positive_abort_allows_a_new_reservation_for_the_same_scope

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:506:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_positive_abort_allows_a_new_reservation_for_the_same_scope'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:505:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_positive_abort_allows_a_new_reservation_for_the_same_scope'
- **Fix:** Resource doesn't exist. Check paths and names

### 12. test_public_termination_uses_retained_exit_without_native_close_or_repinnning

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:364:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_public_termination_uses_retained_exit_without_native_close_or_repinnning'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:363:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_public_termination_uses_retained_exit_without_native_close_or_repinnning'
- **Fix:** Resource doesn't exist. Check paths and names

### 13. test_lost_release_frame_remains_issued_and_exact_exit_cannot_fabricate_no_execution

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:282:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_lost_release_frame_remains_issued_and_exact_exit_cannot_fabricate_no_execution'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:281:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_lost_release_frame_remains_issued_and_exact_exit_cannot_fabricate_no_execution'
- **Fix:** Resource doesn't exist. Check paths and names

### 14. test_reservation_replay_and_plan_refusal_open_no_additional_handles

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:110:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_reservation_replay_and_plan_refusal_open_no_additional_handles'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:109:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_reservation_replay_and_plan_refusal_open_no_additional_handles'
- **Fix:** Resource doesn't exist. Check paths and names

### 15. test_driver_never_repeats_creation_after_lost_response_and_reservation_replay

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:419:in 'Ace::Assign::ProtectedLaunchLifecycleTest::ClientAdapter#call'
lib/ace/assign/authority/launch_driver.rb:36:in 'Ace::Assign::Authority::LaunchDriver#launch'
test/feat/authority/launch_lifecycle_test.rb:453:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_driver_never_repeats_creation_after_lost_response_and_reservation_replay'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:450:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_driver_never_repeats_creation_after_lost_response_and_reservation_replay'
- **Fix:** Resource doesn't exist. Check paths and names

### 16. test_completed_launch_cycles_do_not_retain_pidfds

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:241:in 'block (2 levels) in Ace::Assign::ProtectedLaunchLifecycleTest#test_completed_launch_cycles_do_not_retain_pidfds'
<internal:numeric>:257:in 'Integer#times'
test/feat/authority/launch_lifecycle_test.rb:240:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_completed_launch_cycles_do_not_retain_pidfds'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:239:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_completed_launch_cycles_do_not_retain_pidfds'
- **Fix:** Resource doesn't exist. Check paths and names

### 17. test_inconclusive_abort_can_resolve_only_with_exact_retained_exit_and_no_issuance

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:341:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_inconclusive_abort_can_resolve_only_with_exact_retained_exit_and_no_issuance'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:340:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_inconclusive_abort_can_resolve_only_with_exact_retained_exit_and_no_issuance'
- **Fix:** Resource doesn't exist. Check paths and names

### 18. test_uncertain_recovery_without_retained_handle_cannot_infer_exit

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:320:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_uncertain_recovery_without_retained_handle_cannot_infer_exit'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:319:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_uncertain_recovery_without_retained_handle_cannot_infer_exit'
- **Fix:** Resource doesn't exist. Check paths and names

### 19. test_oversized_and_deep_scope_or_oversized_result_refuse_before_commit

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-assign/lib/ace/assign/authority/execution_scope_observation.rb:157`
- **Message:** [ArgumentError] exception expected, not
Class: <KeyError>
Message: <"key not found: \"slice_unit\"">
---Backtrace---
- **Fix:** Resource doesn't exist. Check paths and names

### 20. test_uncertainty_retains_exact_handles_until_completed_shutdown

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Hash#fetch'
lib/ace/assign/authority/execution_scope_observation.rb:157:in 'Ace::Assign::Authority::ExecutionScopeObservation#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'Class#new'
lib/ace/assign/authority/launch_lifecycle.rb:40:in 'block in Ace::Assign::Authority::LaunchLifecycle#initialize'
lib/ace/assign/authority/launch_lifecycle.rb:315:in 'Ace::Assign::Authority::LaunchLifecycle#scope_observer_for'
lib/ace/assign/authority/launch_scope_release.rb:56:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:167:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_uncertainty_retains_exact_handles_until_completed_shutdown'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:166:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_uncertainty_retains_exact_handles_until_completed_shutdown'
Finished in 23.39180s
21 tests, 57 assertions, 2 failures, 18 errors, 0 skips
- **Fix:** Resource doesn't exist. Check paths and names

## Files Tested

- test/feat/authority/launch_lifecycle_test.rb
