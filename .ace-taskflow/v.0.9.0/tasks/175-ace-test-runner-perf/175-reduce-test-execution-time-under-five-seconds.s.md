---
id: v.0.9.0+task.175
status: in-progress
priority: medium
estimate: 2h
dependencies: []
worktree:
  branch: 175-optimize-ace-test-runner-test-performance-8s-to-under-5s
  path: "../ace-task.175"
  created_at: '2026-01-03 13:08:45'
  updated_at: '2026-01-03 13:08:45'
---

# Optimize ace-test-runner test performance (8s to under 5s)

## 0. Status Assessment ✅

**Current State: ALREADY COMPLETE**

- **Current execution time: 3.3s** (well under the 5s target)
- **All 129 tests pass**
- **59% reduction** from original 8.25s

### Completed Optimizations (from commit d7938194, 2025-12-26)

- ✅ **Subprocess stubbing implemented**: Integration tests use `Open3.stub(:capture3, ...)` for fast execution
- ✅ **Mock infrastructure added**: `Ace::TestSupport::Fixtures::TestRunnerMocks` provides mock outputs
- ✅ **65x faster mocked tests**: Reduced from 860ms to 13ms per mocked test

### Performance Breakdown (as of 2026-01-03)

```
Test Suite Time: 3.3s total
├── Atoms:      20ms   (5 tests)
├── Molecules:  52ms   (83 tests)
├── Models:      5ms   (11 tests)
└── Integration: 3.2s  (30 tests)
    ├── E2E tests (3):   2.6s  (0.83-0.91s each)
    └── Mocked tests (27): 0.6s  (22ms each)
```

### Root Cause Analysis

**Already addressed (completed in d7938194):**
- ✅ Dir.mktmpdir + Rakefile creation overhead - optimized with proper test isolation
- ✅ Subprocess spawning overhead (~150ms per spawn) - eliminated via stubbing
- ✅ InProcessRunner vs Subprocess mode selection - already optimal

**Remaining bottlenecks:**
- 3 E2E validation tests (2.6s total, 79% of suite time)
- These use real subprocess execution for genuine end-to-end CLI validation

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-test ace-test-runner` to execute test suite
- **Process**: Tests execute with mocked subprocess execution and minimal real subprocess for E2E validation
- **Output**: Full test results in <5 seconds ✅ ACHIEVED (currently 3.3s)

### Expected Behavior
Developers experience fast test execution. Subprocess execution is mocked in 27/30 integration tests. Three E2E tests provide genuine CLI validation.

### Success Criteria

- [x] Test suite runs in <5 seconds ✅ (currently 3.3s, was 8.25s)
- [x] All 129 tests pass ✅
- [x] Subprocess execution mocked in unit tests ✅
- [x] Rakefile I/O minimized ✅

## Objective

**COMPLETED**: Reduced ace-test-runner test execution time by 60% (from 8.25s to 3.3s) by mocking subprocess execution in integration tests.

## Scope of Work

### Completed Optimizations

1. ✅ Mock subprocess execution for 27/30 integration tests
2. ✅ Reduce temp Rakefile creation overhead
3. ✅ Ensure InProcessRunner used when appropriate
4. ✅ Add TestRunnerMocks infrastructure to ace-support-test-helpers

### Key Files Modified (in commit d7938194)

- ✅ `ace-test-runner/test/integration/package_argument_test.rb` - Added `run_ace_test_with_mock()` with Open3.stub
- ✅ `ace-support-test-helpers/lib/ace/test_support/fixtures/test_runner_mocks.rb` - Mock infrastructure
- ✅ `ace-test-runner/test/test_helper.rb` - Requires test_support fixtures

### Optional Further Optimizations

**Low-hanging fruit (minimal effort, ~1.7s savings):**

The 3 E2E tests all test the same core functionality (ace-test with package argument) but different variations:
1. `test_run_tests_for_package_by_name` - Tests "ace-test ace-context atoms"
2. `test_package_with_target` - Tests "ace-test ace-nav atoms"
3. `test_package_prefixed_file_path` - Tests "ace-test ace-context/test/atoms/...")

**Option A: Consolidate to 1 E2E test**
- Keep 1 representative E2E test for core CLI validation
- Convert other 2 to use mocks (same coverage, faster)
- Savings: ~1.7s (52% faster overall)
- New total: ~1.6s
- Risk: Low (functionality still covered by mocked tests)
- Effort: Low (change 2 method calls from `run_ace_test` to `run_ace_test_with_mock`)

**Option B: Keep current state (RECOMMENDED)**
- Current time: 3.3s is already excellent
- E2E coverage provides confidence in real CLI behavior
- No further optimization needed
- Effort: None

## Out of Scope

- ❌ Changes to production code in ace-test-runner
- ❌ Reducing test coverage (especially E2E validation)
- ❌ Test parallelization (effort vs benefit not justified for 3.3s suite)

---

## Optional: Further Optimize E2E Tests (Option A)

**Analysis**: The 3 E2E tests (2.6s total, 79% of suite time) all test the same core CLI functionality with minor variations. Converting 2 of them to use mocks would reduce suite time to ~1.6s while maintaining coverage.

### Implementation Plan

#### Planning Steps

* [ ] Verify which E2E test provides best representative coverage
  > TEST: Run each E2E test individually and compare coverage
  > Type: Investigation
  > Assert: Identify which test scenarios are unique vs redundant
  > Command: ace-test ace-test-runner test/integration/package_argument_test.rb -n test_run_tests_for_package_by_name
* [ ] Confirm mocked tests cover the same scenarios
  > TEST: Verify mocked variants exist
  > Type: Coverage Verification
  > Assert: For each scenario tested by E2E tests, a mocked variant exists
  > Command: grep -n "run_ace_test_with_mock" ace-test-runner/test/integration/package_argument_test.rb

#### Execution Steps

- [ ] Convert `test_package_with_target` to use mock (line 54)
  > TEST: Verify test passes with mock
  > Type: Regression Test
  > Assert: Test still validates package+target behavior
  > Command: ace-test ace-test-runner test/integration/package_argument_test.rb -n test_package_with_target
  ```ruby
  # Change from:
  output, status = run_ace_test("ace-nav", "atoms")
  # To:
  output, status = run_ace_test_with_mock("ace-nav", "atoms")
  ```

- [ ] Convert `test_package_prefixed_file_path` to use mock (line 182)
  > TEST: Verify test passes with mock
  > Type: Regression Test
  > Assert: Test still validates package-prefixed file path behavior
  > Command: ace-test ace-test-runner test/integration/package_argument_test.rb -n test_package_prefixed_file_path
  ```ruby
  # Change from:
  output, status = run_ace_test("ace-context/test/atoms/content_checker_test.rb")
  # To:
  output, status = run_ace_test_with_mock("ace-context/test/atoms/content_checker_test.rb")
  ```

- [ ] Run full test suite and verify all tests pass
  > TEST: Full suite validation
  > Type: Integration Test
  > Assert: All 129 tests pass, time <2s
  > Command: ace-test ace-test-runner

- [ ] Update comment on remaining E2E test to indicate it's the sole E2E validation
  ```ruby
  # test_run_tests_for_package_by_name
  # NOTE: This is the ONLY E2E test using real subprocess execution.
  # All other integration tests use mocked subprocess for speed.
  # This test validates the actual CLI integration works end-to-end.
  ```

### Acceptance Criteria

- [ ] Test suite runs in <2 seconds (down from 3.3s)
- [ ] All 129 tests still pass
- [ ] 1 E2E test remains for genuine CLI validation
- [ ] Test coverage unchanged (mocked tests cover same scenarios)

### Rollback Plan

If issues arise:
1. Revert the 2 tests back to `run_ace_test` (real subprocess)
2. Performance returns to current 3.3s (still under 5s target)
3. No production code changes to rollback