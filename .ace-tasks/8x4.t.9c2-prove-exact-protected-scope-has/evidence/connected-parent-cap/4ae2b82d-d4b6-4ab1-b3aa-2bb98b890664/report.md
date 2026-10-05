# Test Report

**Generated:** 2026-10-05 13:59:20
**Status:** ❌ Failed
**Execution failure:** /Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 21 |
| Passed | 15 |
| Failed | 0 |
| Errors | 6 |
| Skipped | 0 |
| Pass Rate | 71.43% |
| Duration | 139.60591s |

## Failures

### 1. test_lost_release_frame_remains_issued_and_exact_exit_cannot_fabricate_no_execution

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: Mutation ID is already bound to different input
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

### 2. test_definition_change_requires_all_scopes_terminal

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: execution slot has an unreleased canonical reservation
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

### 3. test_bind_precedes_single_durable_release_and_replay_never_resends

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: Mutation ID is already bound to different input
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
test/feat/authority/launch_lifecycle_test.rb:269:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_bind_precedes_single_durable_release_and_replay_never_resends'
test/feat/authority/launch_lifecycle_test.rb:96:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:70:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:252:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_bind_precedes_single_durable_release_and_replay_never_resends'

### 4. test_completed_launch_cycles_do_not_retain_pidfds

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: execution slot has an unreleased canonical reservation
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
test/feat/authority/launch_lifecycle_test.rb:282:in 'block (2 levels) in Ace::Assign::ProtectedLaunchLifecycleTest#test_completed_launch_cycles_do_not_retain_pidfds'
<internal:numeric>:257:in 'Integer#times'
test/feat/authority/launch_lifecycle_test.rb:281:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_completed_launch_cycles_do_not_retain_pidfds'
test/feat/authority/launch_lifecycle_test.rb:96:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:70:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:280:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_completed_launch_cycles_do_not_retain_pidfds'

### 5. test_positive_abort_allows_a_new_reservation_for_the_same_scope

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: execution slot has an unreleased canonical reservation
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
test/feat/authority/launch_lifecycle_test.rb:550:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_positive_abort_allows_a_new_reservation_for_the_same_scope'
test/feat/authority/launch_lifecycle_test.rb:96:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:70:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:546:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_positive_abort_allows_a_new_reservation_for_the_same_scope'

### 6. test_inconclusive_abort_can_resolve_only_with_exact_retained_exit_and_no_issuance

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: execution slot has an unreleased canonical reservation
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
test/feat/authority/launch_lifecycle_test.rb:398:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_inconclusive_abort_can_resolve_only_with_exact_retained_exit_and_no_issuance'
test/feat/authority/launch_lifecycle_test.rb:96:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:70:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:381:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_inconclusive_abort_can_resolve_only_with_exact_retained_exit_and_no_issuance'
Finished in 139.60591s
21 tests, 143 assertions, 0 failures, 6 errors, 0 skips

## Files Tested

- test/feat/authority/launch_lifecycle_test.rb
