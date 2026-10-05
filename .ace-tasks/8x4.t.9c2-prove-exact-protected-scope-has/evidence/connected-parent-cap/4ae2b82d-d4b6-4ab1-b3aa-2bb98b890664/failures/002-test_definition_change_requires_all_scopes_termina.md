# Test ERROR: test_definition_change_requires_all_scopes_terminal

**Status:** ERROR

## Error Message

Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: execution slot has an unreleased canonical reservation
lib/ace/assign/authority/launch_lifecycle.rb:525:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:491:in 'Hash#each'
lib/ace/assign/authority/launch_lifecycle.rb:491:in 'block in Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:490:in 'Array#each'
lib/ace/assign/authority/launch_lifecycle.rb:490:in 'Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_scope_release.rb:37:in 'Ace::Assign::Authority::LaunchLifecycle#slot_reusable!'
lib/ace/assign/authority/launch_scope_release.rb:43:in 'Ace::Assign::Authority::LaunchLifecycle#retire_released_parent!'
lib/ace/assign/authority/launch_lifecycle.rb:122:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:103:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:566:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_definition_change_requires_all_scopes_terminal'
test/feat/authority/launch_lifecycle_test.rb:96:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:70:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:557:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_definition_change_requires_all_scopes_terminal'

## Related stderr

```
/Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

```
