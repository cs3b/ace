# Retro: ace-docs Test Optimization - Stub Helpers

**Date**: 2026-01-15
**Context**: Optimizing ace-docs CLI command tests that took 129 seconds down to 1.5ms by implementing proper stub helpers
**Author**: claude
**Type**: Self-Review

## What Went Well

- **Identified root cause quickly** - Used profiling (`ace-test --profile 30`) to pinpoint exactly which test was slow (test_numeric_option_conversion: 128.990s)
- **Applied existing patterns** - Leveraged stub helper patterns from `docs/testing-patterns.md` rather than inventing new approaches
- **Massive performance gain** - Achieved ~85,000x speedup on CLI tests (129s → 1.5ms) and ~118x on full suite (2m 9s → 1.1s)
- **Zero test failures** - All 193 tests still pass after optimization

## What Could Be Improved

- **Test helper isolation** - The problematic test was calling `@command.call()` which triggered expensive DocumentRegistry file system scanning across 7,134 markdown files
- **Initial investigation scope** - Had to read multiple files to understand the call chain; could have traced from test → command → analyzer → registry more directly
- **Pattern documentation awareness** - The testing-patterns.md documentation exists but wasn't being applied in this test file

## Key Learnings

- **DocumentRegistry.new is expensive** - Instantiation triggers `Dir.glob("**/*.md")` which scans the entire project root; with 7,134 markdown files in ace-meta, this takes ~130 seconds
- **Test helpers should be in test_helper.rb** - Common stub patterns should be centralized, not duplicated across test files
- **Composite helpers prevent deep nesting** - Instead of 6-7 levels of nested stubs, use single helper methods that combine related mocks
- **Profiling reveals the truth** - Assumptions about slowness are often wrong; `ace-test --profile` shows actual bottlenecks

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Unintended file system scanning**: Test called `@command.call()` which instantiated `CrossDocumentAnalyzer`, which created `DocumentRegistry.new`, which scanned all markdown files
  - Occurrences: 1 test, but dominated all test time (129s out of 129s total)
  - Impact: Made CLI tests practically unusable; developers would avoid running them
  - Root Cause: Test intended to verify type conversion but ended up executing full command including DocumentRegistry initialization

#### Medium Impact Issues

- **Missing stub helpers**: No existing helpers for common operations like DocumentRegistry mocking
  - Occurrences: Would affect any test that needs to avoid file system scanning
  - Impact: Each test would need to implement its own stubbing, leading to code duplication

#### Low Impact Issues

- **None identified** - Once the root cause was found, the fix was straightforward

### Improvement Proposals

#### Process Improvements

- **Add CI test performance gate** - Fail builds if any unit test takes >100ms (as suggested in testing-patterns.md)
- **Run profiling in CI** - Include `ace-test --profile 20` in CI output to catch regressions early
- **DocumentRegistry should accept config override** - Allow tests to pass document list directly instead of always scanning filesystem

#### Tool Enhancements

- **ace-test --watch mode** - Continuously monitor test times and alert on degradation
- **ace-test --busted flag** - Automatically identify tests exceeding performance thresholds

#### Communication Protocols

- **Test review checklist** - Before merging, verify tests aren't doing expensive operations (real subprocess calls, file system scans, network I/O)

## Action Items

### Stop Doing

- Calling real command methods in unit tests when only testing option parsing or type conversion
- Letting tests accidentally trigger expensive operations through deep call chains

### Continue Doing

- Using `ace-test --profile` to identify performance bottlenecks
- Following patterns from `docs/testing-patterns.md` for consistent test approaches
- Centralizing common stub helpers in `test/test_helper.rb`

### Start Doing

- Adding performance assertions to test helpers (e.g., `assert_performance < 0.1`)
- Running `ace-test --profile 10` regularly during development to catch regressions
- Checking for DocumentRegistry, ace-nav subprocess calls, and DiffOrchestrator usage in new tests

## Technical Details

### Changes Made

**File: `ace-docs/test/test_helper.rb`**
- Added `stub_ace_nav_prompts` helper to stub `Open3.capture3("ace-nav", ...)` calls
- Added `with_mock_registry` helper to mock `DocumentRegistry.new` and avoid file system scanning
- Added `with_empty_git_diff` helper to stub `DiffOrchestrator` for git operations

**File: `ace-docs/test/cli/commands/analyze_consistency_test.rb`**
- Updated `test_numeric_option_conversion` to wrap command call with `with_mock_registry` and `stub_ace_nav_prompts`

### Performance Results

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| test_numeric_option_conversion | 128.990s | ~0.001s | ~129,000x faster |
| CLI tests total | 2m 9s | 1.51ms | ~85,000x faster |
| Full test suite | 2m 9s | 1.1s | ~118x faster |

### Patterns Applied

- **Subprocess Stubbing Pattern** (testing-patterns.md:152-180): Stub `Open3.capture3` for ace-nav
- **Composite Test Helpers** (testing-patterns.md:807-912): Single helper combining related mocks
- **DiffOrchestrator Stubbing** (testing-patterns.md:914-963): Use stub for git operations

## Additional Context

- **Commit**: f8e9501af `perf(ace-docs): speed up cli tests with stub helpers`
- **Related docs**: `docs/testing-patterns.md` - comprehensive guide for fast, isolated tests
- **Repo stats**: 7,134 markdown files in ace-meta (reason DocumentRegistry scan was so slow)
