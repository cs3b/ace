# Test ERROR: test_lost_release_frame_remains_issued_and_exact_exit_cannot_fabricate_no_execution

**Status:** ERROR

## Error Message

Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: Mutation ID is already bound to different input
lib/ace/assign/molecules/journal_mutation.rb:51:in 'block (2 levels) in Ace::Assign::Molecules::JournalMutation#mutate'
<internal:numeric>:257:in 'Integer#times'
lib/ace/assign/molecules/journal_mutation.rb:42:in 'block in Ace::Assign::Molecules::JournalMutation#mutate'
lib/ace/assign/molecules/evidence_journal.rb:751:in 'block in Ace::Assign::Molecules::EvidenceJournal#with_lock'
lib/ace/assign/molecules/evidence_journal.rb:748:in 'IO.open'
lib/ace/assign/molecules/evidence_journal.rb:748:in 'Ace::Assign::Molecules::EvidenceJournal#with_lock'
lib/ace/assign/molecules/journal_mutation.rb:41:in 'Ace::Assign::Molecules::JournalMutation#mutate'
lib/ace/assign/authority/launch_lifecycle.rb:144:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:125:in 'Thread::Mutex#synchronize'
lib/ace/assign/authority/launch_lifecycle.rb:125:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:384:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:381:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:367:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:103:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:334:in 'block (2 levels) in Ace::Assign::ProtectedLaunchLifecycleTest#test_lost_release_frame_remains_issued_and_exact_exit_cannot_fabricate_no_execution'

## Related stderr

```
/Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

```
