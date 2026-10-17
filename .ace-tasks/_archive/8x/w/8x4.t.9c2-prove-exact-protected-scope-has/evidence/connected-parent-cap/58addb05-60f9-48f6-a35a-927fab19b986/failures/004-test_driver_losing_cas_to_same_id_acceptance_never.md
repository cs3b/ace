# Test ERROR: test_driver_losing_cas_to_same_id_acceptance_never_creates_native_child

**Status:** ERROR

## Error Message

Minitest::UnexpectedError:         KeyError: key not found: "slice_unit"
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

## Related stderr

```
/Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

```

## Fix Suggestion

Resource doesn't exist. Check paths and names
