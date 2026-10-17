# Actual host Git ownership regression

RED: `bin/ace-test ace-lab test/feat/command_owner_candidate_integration_test.rb`
on frozen 2b source with the new test: 3 tests, 23 assertions, one error. Test-only
RED commit `25b738091` also adds the pending Linux distinct-UID probe.

GREEN source `638148235`: focused production admission/kernel selection: 9 tests,
32 assertions, zero failures/errors, one truthful Linux/root-only host skip.
The source fix is only Git safe.directory package cwd → retained repository
root, twice.

The real canonical host fixture controls Git's ownership observation using
`GIT_TEST_ASSUME_DIFFERENT_OWNER=1`; Git discovery/config/status and the real
Assign canonical candidate/policy/compiler checks execute. No child command or
canonical successful-test receipt is invented. Root kernel probe execution is
still pending, not inferred from this host switch. All emitted raw reports are
retained with SHA256 inventory. The runner emitted no separate raw_stderr file;
the initial copy assumed one and stopped, so this docs-only followup completes
receipt retention without changing source or synthesizing missing output.
