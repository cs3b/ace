# Test Report

**Generated:** 2026-10-05 11:53:57
**Status:** ❌ Failed
**Execution failure:** /Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 21 |
| Passed | 17 |
| Failed | 0 |
| Errors | 4 |
| Skipped | 0 |
| Pass Rate | 80.95% |
| Duration | 102.02468s |

## Failures

### 1. test_positive_abort_allows_a_new_reservation_for_the_same_scope

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: execution slot has an unreleased canonical reservation
lib/ace/assign/authority/launch_lifecycle.rb:440:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:423:in 'Hash#each'
lib/ace/assign/authority/launch_lifecycle.rb:423:in 'block in Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:422:in 'Array#each'
lib/ace/assign/authority/launch_lifecycle.rb:422:in 'Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:395:in 'Ace::Assign::Authority::LaunchLifecycle#reserve'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'block (3 levels) in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/molecules/journal_mutation.rb:56:in 'block (2 levels) in Ace::Assign::Molecules::JournalMutation#mutate'
<internal:numeric>:257:in 'Integer#times'
lib/ace/assign/molecules/journal_mutation.rb:37:in 'block in Ace::Assign::Molecules::JournalMutation#mutate'
lib/ace/assign/molecules/evidence_journal.rb:751:in 'block in Ace::Assign::Molecules::EvidenceJournal#with_lock'
lib/ace/assign/molecules/evidence_journal.rb:748:in 'IO.open'
lib/ace/assign/molecules/evidence_journal.rb:748:in 'Ace::Assign::Molecules::EvidenceJournal#with_lock'
lib/ace/assign/molecules/journal_mutation.rb:36:in 'Ace::Assign::Molecules::JournalMutation#mutate'
lib/ace/assign/authority/launch_lifecycle.rb:109:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:94:in 'Thread::Mutex#synchronize'
lib/ace/assign/authority/launch_lifecycle.rb:94:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:320:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:320:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:93:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:509:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_positive_abort_allows_a_new_reservation_for_the_same_scope'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:505:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_positive_abort_allows_a_new_reservation_for_the_same_scope'

### 2. test_completed_launch_cycles_do_not_retain_pidfds

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: execution slot has an unreleased canonical reservation
lib/ace/assign/authority/launch_lifecycle.rb:440:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:423:in 'Hash#each'
lib/ace/assign/authority/launch_lifecycle.rb:423:in 'block in Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:422:in 'Array#each'
lib/ace/assign/authority/launch_lifecycle.rb:422:in 'Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:395:in 'Ace::Assign::Authority::LaunchLifecycle#reserve'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'block (3 levels) in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/molecules/journal_mutation.rb:56:in 'block (2 levels) in Ace::Assign::Molecules::JournalMutation#mutate'
<internal:numeric>:257:in 'Integer#times'
lib/ace/assign/molecules/journal_mutation.rb:37:in 'block in Ace::Assign::Molecules::JournalMutation#mutate'
lib/ace/assign/molecules/evidence_journal.rb:751:in 'block in Ace::Assign::Molecules::EvidenceJournal#with_lock'
lib/ace/assign/molecules/evidence_journal.rb:748:in 'IO.open'
lib/ace/assign/molecules/evidence_journal.rb:748:in 'Ace::Assign::Molecules::EvidenceJournal#with_lock'
lib/ace/assign/molecules/journal_mutation.rb:36:in 'Ace::Assign::Molecules::JournalMutation#mutate'
lib/ace/assign/authority/launch_lifecycle.rb:109:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:94:in 'Thread::Mutex#synchronize'
lib/ace/assign/authority/launch_lifecycle.rb:94:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:320:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:320:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:93:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:241:in 'block (2 levels) in Ace::Assign::ProtectedLaunchLifecycleTest#test_completed_launch_cycles_do_not_retain_pidfds'
<internal:numeric>:257:in 'Integer#times'
test/feat/authority/launch_lifecycle_test.rb:240:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_completed_launch_cycles_do_not_retain_pidfds'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:239:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_completed_launch_cycles_do_not_retain_pidfds'

### 3. test_inconclusive_abort_can_resolve_only_with_exact_retained_exit_and_no_issuance

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: execution slot has an unreleased canonical reservation
lib/ace/assign/authority/launch_lifecycle.rb:440:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:423:in 'Hash#each'
lib/ace/assign/authority/launch_lifecycle.rb:423:in 'block in Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:422:in 'Array#each'
lib/ace/assign/authority/launch_lifecycle.rb:422:in 'Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:395:in 'Ace::Assign::Authority::LaunchLifecycle#reserve'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'block (3 levels) in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/molecules/journal_mutation.rb:56:in 'block (2 levels) in Ace::Assign::Molecules::JournalMutation#mutate'
<internal:numeric>:257:in 'Integer#times'
lib/ace/assign/molecules/journal_mutation.rb:37:in 'block in Ace::Assign::Molecules::JournalMutation#mutate'
lib/ace/assign/molecules/evidence_journal.rb:751:in 'block in Ace::Assign::Molecules::EvidenceJournal#with_lock'
lib/ace/assign/molecules/evidence_journal.rb:748:in 'IO.open'
lib/ace/assign/molecules/evidence_journal.rb:748:in 'Ace::Assign::Molecules::EvidenceJournal#with_lock'
lib/ace/assign/molecules/journal_mutation.rb:36:in 'Ace::Assign::Molecules::JournalMutation#mutate'
lib/ace/assign/authority/launch_lifecycle.rb:109:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:94:in 'Thread::Mutex#synchronize'
lib/ace/assign/authority/launch_lifecycle.rb:94:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:320:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:320:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:93:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:357:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_inconclusive_abort_can_resolve_only_with_exact_retained_exit_and_no_issuance'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:340:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_inconclusive_abort_can_resolve_only_with_exact_retained_exit_and_no_issuance'

### 4. test_definition_change_requires_all_scopes_terminal

- **Type:** error
- **Location:** ``
- **Message:** Minitest::UnexpectedError:         Ace::Assign::AttemptErrors::Conflict: execution slot has an unreleased canonical reservation
lib/ace/assign/authority/launch_lifecycle.rb:440:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:423:in 'Hash#each'
lib/ace/assign/authority/launch_lifecycle.rb:423:in 'block in Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:422:in 'Array#each'
lib/ace/assign/authority/launch_lifecycle.rb:422:in 'Ace::Assign::Authority::LaunchLifecycle#ensure_slot_available!'
lib/ace/assign/authority/launch_lifecycle.rb:395:in 'Ace::Assign::Authority::LaunchLifecycle#reserve'
lib/ace/assign/authority/launch_lifecycle.rb:115:in 'block (3 levels) in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/molecules/journal_mutation.rb:56:in 'block (2 levels) in Ace::Assign::Molecules::JournalMutation#mutate'
<internal:numeric>:257:in 'Integer#times'
lib/ace/assign/molecules/journal_mutation.rb:37:in 'block in Ace::Assign::Molecules::JournalMutation#mutate'
lib/ace/assign/molecules/evidence_journal.rb:751:in 'block in Ace::Assign::Molecules::EvidenceJournal#with_lock'
lib/ace/assign/molecules/evidence_journal.rb:748:in 'IO.open'
lib/ace/assign/molecules/evidence_journal.rb:748:in 'Ace::Assign::Molecules::EvidenceJournal#with_lock'
lib/ace/assign/molecules/journal_mutation.rb:36:in 'Ace::Assign::Molecules::JournalMutation#mutate'
lib/ace/assign/authority/launch_lifecycle.rb:109:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:94:in 'Thread::Mutex#synchronize'
lib/ace/assign/authority/launch_lifecycle.rb:94:in 'block in Ace::Assign::Authority::LaunchLifecycle#dispatch'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'block (2 levels) in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/molecules/lifecycle_exclusion.rb:141:in 'Ace::Assign::Molecules::LifecycleExclusion#with_shared_multi'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:320:in 'block in Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/molecules/lifecycle_exclusion.rb:88:in 'Ace::Assign::Molecules::LifecycleExclusion#with_exclusive'
lib/ace/assign/authority/launch_lifecycle.rb:320:in 'Ace::Assign::Authority::LaunchLifecycle#with_slot'
lib/ace/assign/authority/launch_lifecycle.rb:309:in 'Ace::Assign::Authority::LaunchLifecycle#with_exclusion'
lib/ace/assign/authority/launch_lifecycle.rb:93:in 'Ace::Assign::Authority::LaunchLifecycle#dispatch'
test/feat/authority/launch_lifecycle_test.rb:63:in 'Ace::Assign::ProtectedLaunchLifecycleTest#call'
test/feat/authority/launch_lifecycle_test.rb:525:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#test_definition_change_requires_all_scopes_terminal'
test/feat/authority/launch_lifecycle_test.rb:56:in 'block in Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/test_helper.rb:36:in 'AceAssignTestCase#with_temp_cache'
test/feat/authority/launch_lifecycle_test.rb:30:in 'Ace::Assign::ProtectedLaunchLifecycleTest#with_authority'
test/feat/authority/launch_lifecycle_test.rb:516:in 'Ace::Assign::ProtectedLaunchLifecycleTest#test_definition_change_requires_all_scopes_terminal'

## Files Tested

- test/feat/authority/launch_lifecycle_test.rb
