---
id: 8pb29b
title: "Retro: TS-Format E2E Test Migration (Task 261)"
type: self-review
tags: []
created_at: "2026-02-12 01:30:20"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8pb29b-261-ts-format-e2e-migration.md
---
# Retro: TS-Format E2E Test Migration (Task 261)

**Date**: 2026-02-12
**Context**: Remove legacy .mt.md support from ace-test-e2e-runner and complete migration to TS-format directory structure
**Author**: Claude (agent)
**Type**: Self-Review

## What Went Well

- **ADR-024 enabled clean removal**: No backward compatibility requirements pre-1.0.0 meant we could delete ScenarioParser entirely without deprecation paths
- **Incremental test fixing**: Fixing test paths in batches (atoms → molecules → organisms) allowed early detection of issues
- **Production code was clean**: After grep verification, zero legacy references remained in lib/
- **StubScenarioLoader injection pattern**: Constructor injection for scenario_loader made tests testable without filesystem dependencies

## What Could Be Improved

- **Sed replacement collateral damage**: Converting `.mt.md` → `/scenario.yml` with sed caused malformed paths like `TS-LINT-001scenario.yml` (missing `/`)
- **Test data alignment**: Multiple test failures due to test_name mismatches - tests expected `TS-LINT-001` but directory names were `TS-LINT-001-test`
- **Context loss during long session**: Previous session context was summarized, requiring re-reading of key files

## Key Learnings

- **TS-format directory naming convention**: `extract_test_name` returns full directory name (e.g., `TS-LINT-001-test`), not just the test-id (`TS-LINT-001`). Test stubs must match this convention.
- **Two-phase path conversion**: When bulk-replacing file paths, verify the separator is preserved. Pattern: `path/TS-ID-suffix.mt.md` → `path/TS-ID-suffix/scenario.yml`
- **grep verification is essential**: After bulk changes, `grep -r "pattern" lib/` provides confidence before running tests

## Challenge Patterns Identified

### High Impact Issues

- **Malformed test paths**: Sed replacements removed `/` separator
  - Occurrences: 17+ files
  - Impact: 7 test failures in organisms, required manual fix of each path
  - Root Cause: Regex replacement didn't account for word boundaries

### Medium Impact Issues

- **test_name assertion mismatch**: Tests asserted `TS-LINT-001` but got `TS-LINT-001-test`
  - Occurrences: 4 tests
  - Impact: Required updating both test stubs and assertions

### Low Impact Issues

- **Large diff output**: git diff exceeded display limits, required reading from file
  - Occurrences: 2 times
  - Impact: Minor delay, workaround via Read tool on saved file

## Improvement Proposals

### Process Improvements

- Add post-sed verification step: After bulk path replacement, run `grep '\wscenario\.yml'` to catch missing separators
- Create a migration checklist for format changes: paths, patterns, assertions, stubs

### Tool Enhancements

- Consider adding a path migration helper that validates separator preservation
- ace-test could report which test files have malformed paths

## Action Items

### Stop Doing

- Using simple sed for path transformations without verifying separator preservation
- Assuming test_name in stubs will match extract_test_name output without checking

### Continue Doing

- Verifying with grep after bulk changes
- Running tests incrementally by layer (atoms → molecules → organisms)
- Using StubScenarioLoader injection pattern for testability

### Start Doing

- Document TS-format directory naming conventions in a guide
- Add example of test_name vs test_id distinction to testing guide

## Technical Details

**Key distinction:**
- `test_name` = full directory name from `extract_test_name` (e.g., `TS-LINT-001-test`)
- `test_id` = canonical ID extracted via regex from directory name (e.g., `TS-LINT-001`)

**Extract methods in SuiteOrchestrator:**
```ruby
def extract_test_name(test_file)
  File.basename(File.dirname(test_file))  # → "TS-LINT-001-test"
end

def extract_test_id(test_file)
  dir_name = File.basename(File.dirname(test_file))
  dir_name.match(/(TS-[A-Z]+-\d+)/)&.[](1)  # → "TS-LINT-001"
end
```

## Additional Context

- Task: `.ace-taskflow/v.0.9.0/tasks/_archive/261-e2e-feat/261.04-remove-legacy-markdown-support.s.md`
- Release: ace-test-e2e-runner v0.16.0
- Commits: `7cc8fec25`, `9db007cc7`, `f16968de1`
- Tests: 444 tests pass, 0 failures
