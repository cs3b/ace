---
id: v.0.9.0+task.252
status: done
priority: medium
estimate: 1h
dependencies:
- '251'
---

# Mock ace-bundle in context_extractor_test to eliminate 4.49s bottleneck

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-test ace-review` or `ace-test-suite`
- **Process**: Test suite executes with mocked ace-bundle responses instead of real project context loading
- **Output**: Same test coverage with ~4s faster execution for ace-review molecules

### Expected Behavior
The `context_extractor_test.rb` in ace-review currently calls real `Ace::Bundle.load_auto` which loads actual project context, taking 4.49s for 20 tests. After this change:
- Tests should mock `Ace::Bundle.load_auto` to return predetermined context
- Test assertions remain valid (same behavioral coverage)
- Test execution time drops from 4.49s to <100ms

### Interface Contract

```ruby
# Current slow pattern (to be replaced):
Dir.chdir(@temp_dir) do
  result = @extractor.extract("project")  # Calls real ace-bundle
  refute_empty result
end

# Target mocked pattern:
ace_bundle_mock = Minitest::Mock.new
ace_bundle_mock.expect(:content, "Mock context content")

Ace::Bundle.stub(:load_auto, ace_bundle_mock) do
  result = @extractor.extract("project")
  assert_equal "Mock context content", result
end
```

**Error Handling:**
- Tests should still validate error conditions by mocking error responses
- Existing error path tests remain unchanged

**Edge Cases:**
- Mock should handle nil/empty context scenarios
- Mock should support different preset types ("project", YAML config, file paths)

### Success Criteria
- [x] `context_extractor_test.rb` runs in <100ms (vs current 4.49s) [VERIFIED: 40.52ms]
- [x] All 20 tests in the file continue to pass [VERIFIED: 20 tests, 0 failures]
- [x] Test coverage of ContextExtractor behavior is preserved
- [x] `ace-test ace-review` total time reduced by ~4s [VERIFIED: 1.28s total]

### Validation Questions
- [x] **Pattern exists**: Tests in same file already use `@extractor.stub(:ace_bundle_preset_exists?, true)` pattern (line 196)
- [x] **Mock infrastructure**: `Ace::Bundle.stub(:load_auto, ...)` pattern is already used (line 201)
- [x] **Coverage risk**: Verify real ace-bundle integration is still tested in E2E [VERIFIED: MT-REVIEW-001 and other E2E tests cover real integration]

## Objective

Reduce ace-review test execution time by eliminating unnecessary real ace-bundle calls during unit testing. The profiling identified this as the single largest bottleneck in the test suite.

## Scope of Work

- **User Experience Scope**: Developer test execution experience - faster feedback loop
- **System Behavior Scope**: ContextExtractor test mocking - isolate unit tests from integration behavior
- **Interface Scope**: No public API changes - internal test refactoring only

### Deliverables

#### Behavioral Specifications
- Mocked ace-bundle responses that exercise same code paths
- Validation that mocked tests still verify expected behavior

#### Validation Artifacts
- Before/after timing comparison
- Test count and assertion verification

## Out of Scope

- ❌ **Implementation Details**: Exact mock structure decisions for plan phase
- ❌ **Other test files**: Only context_extractor_test.rb in this task
- ❌ **E2E creation**: Real ace-bundle testing belongs in E2E (already exists)

## Technical Approach

### Architecture Pattern
- **Pattern**: Test double substitution using Minitest stub
- **Integration**: Follows existing mock patterns in the same test file (lines 194-206)
- **Impact**: No production code changes, test-only refactoring

### Technology Stack
- Minitest::Mock for object mocking
- Method stubbing via `.stub()` for class methods
- Dir.mktmpdir for isolated temp directories (already in place)

## File Modifications

### Modify
- `ace-review/test/molecules/context_extractor_test.rb`
  - **Changes**: Wrap slow tests with `Ace::Bundle.stub(:load_auto, mock_result)` blocks
  - **Impact**: Test execution time reduction from 4.49s to <100ms
  - **Integration points**: No changes to production code

## Implementation Plan

### Planning Steps

* [x] Identify tests calling real ace-bundle (lines 26-62, 64-89, 208-230, 248-274)
* [x] Review existing mock patterns in same file (lines 194-206)
* [x] Verify E2E coverage exists for real ace-bundle integration

### Execution Steps

- [x] Create helper mock method for ace-bundle result
  ```ruby
  def mock_bundle_result(content = "Mock context content")
    mock = Minitest::Mock.new
    mock.expect(:content, content)
    mock
  end
  ```

- [x] Refactor `test_extract_from_string_yaml_config_with_cache` (was 2.350s)
  - Added `with_mocked_ace_bundle_loading` wrapper to mock ContextComposer.load_context_via_ace_bundle
  - Maintains cache file creation assertions

- [x] Refactor `test_extract_from_hash_config_with_cache` (was 2.300s)
  - Added `with_mocked_ace_bundle_loading` wrapper
  - Maintains cache file content structure assertions

Note: Other tests in the plan were already fast (<10ms each) in profiling, so no mocking needed:
- `test_extract_project_context_*` - already fast
- `test_extract_from_string_yaml_config` (without cache) - already fast
- `test_extract_from_string_file_path*` - already fast
- `test_extract_from_hash_config` (without cache) - already fast
- `test_extract_with_empty_config` - already fast
- `test_backward_compatibility_without_cache_dir` - already fast

- [x] Verify all tests pass [20 tests, 55 assertions, 0 failures]

- [x] Measure timing improvement [40.52ms vs 4.69s = 99.1% reduction]

## Acceptance Criteria

- [x] `context_extractor_test.rb` runs in <100ms (vs current 4.49s) [VERIFIED: 40.52ms]
- [x] All 20 tests in the file continue to pass [VERIFIED: 20 tests, 55 assertions, 0 failures]
- [x] Test coverage of ContextExtractor behavior is preserved [context.md creation and content validation still tested]
- [x] `ace-test ace-review` total time reduced by ~4s [VERIFIED: Full suite runs in 1.28s]

## Risk Assessment

### Technical Risks
- **Risk**: Mock may not exercise all code paths
  - **Probability**: Low
  - **Impact**: Medium (reduced test coverage)
  - **Mitigation**: Verify each test still validates intended behavior
  - **Rollback**: Revert to original tests

### Integration Risks
- **Risk**: Real ace-bundle integration bugs may go undetected
  - **Probability**: Low (E2E tests exist)
  - **Impact**: Low
  - **Mitigation**: Verify E2E tests cover real integration

## References

- Profiling Report: `.ace-taskflow/v.0.9.0/tasks/_archive/251-test-refactor/docs/test-profiling-report.md`
- Source file: `ace-review/test/molecules/context_extractor_test.rb`
- Parent optimization task: Task 251