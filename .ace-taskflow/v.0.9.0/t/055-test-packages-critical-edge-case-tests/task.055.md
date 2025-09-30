---
id: v.0.9.0+task.055
status: in-progress
priority: high
estimate: 3-5 days
dependencies: []
---

# Add critical edge case tests to ACE packages

## Description

Add comprehensive edge case tests to ensure ACE packages work reliably across different execution contexts, handle errors gracefully, and guard critical behaviors. Focus on tests that provide value by protecting against real-world failure scenarios.

**Key Focus Areas:**
1. Execution from any directory depth in project tree
2. Missing core component tests (CommitOrchestrator, FileStager, NavigationEngine)
3. Error recovery and handling
4. Path edge cases (unicode, spaces, symlinks)
5. Config cascade complexity
6. Git state handling

## Behavioral Specification

### User Experience
Developers and AI agents should be able to:
- Execute ACE commands from any directory level within a project
- Rely on graceful error handling when network/filesystem issues occur
- Trust that path handling works with unicode, spaces, and special characters
- Expect config cascade to resolve correctly from any execution location

### Interface Contract

**Input:** Test suites for ace-core, ace-context, ace-nav, ace-llm, ace-llm-providers-cli, ace-git-commit
**Output:** Comprehensive edge case tests covering critical failure scenarios
**Side Effects:** Increased test coverage for reliability-critical behaviors

## Planning Steps

* [ ] Review current test coverage in each package to identify existing patterns
* [ ] Prioritize test implementation based on risk (P0 → P1 → P2)
* [ ] Set up test fixtures for directory depth scenarios
* [ ] Design test helpers for common edge case patterns

## Execution Steps

### P0 - Critical (Blocks Production)

- [x] **ace-git-commit**: Create `test/organisms/commit_orchestrator_test.rb` with integration tests (10 tests, all passing)
- [x] **ace-git-commit**: Create `test/molecules/file_stager_test.rb` with staging operation tests (15 tests, all passing)
- [x] **ace-nav**: Enable and implement skipped `NavigationEngine` integration tests (Created test/organisms/navigation_engine_test.rb)
- [ ] **ace-core**: Add `test/ace/core/molecules/directory_traverser_edge_test.rb` for deep directory execution
- [ ] **ace-llm**: Add error handling tests for network timeouts, rate limiting, malformed responses

### P1 - Important (Production Quality)

- [ ] **ace-core**: Add path edge case tests (unicode, spaces, special chars, long paths)
- [ ] **ace-core**: Add config cascade edge case tests (circular refs, priority conflicts)
- [ ] **ace-context**: Add preset dependency tests (circular includes, missing files)
- [ ] **ace-context**: Add file content edge case tests (binary, invalid UTF-8, BOM markers)
- [ ] **ace-git-commit**: Add git state edge case tests (detached HEAD, merge conflicts, empty repo)
- [ ] **ace-llm-providers-cli**: Add CLI execution edge case tests (command not found, process killed)

### P2 - Nice to Have (Robustness)

- [ ] All packages: Add performance tests for large files and deep nesting
- [ ] ace-llm: Add concurrency tests for multiple simultaneous requests
- [ ] ace-nav: Add resource discovery edge cases (permission denied, circular symlinks)

## Acceptance Criteria

- [ ] All P0 critical tests implemented and passing
- [ ] Missing component tests (CommitOrchestrator, FileStager, NavigationEngine) created
- [ ] Directory depth execution tested from 5+ levels deep across all packages
- [ ] Error handling tests cover network failures, filesystem errors, and malformed data
- [ ] Path edge cases tested (unicode, spaces, symlinks, long paths)
- [ ] Test coverage report shows improvement in reliability-critical areas
- [ ] All new tests follow existing test patterns and use appropriate helpers

## Implementation Notes

### Test Patterns to Follow

```ruby
# Directory depth testing pattern
Dir.mktmpdir do |tmpdir|
  deep_dir = File.join(tmpdir, *Array.new(10) { "level" })
  FileUtils.mkdir_p(deep_dir)
  Dir.chdir(deep_dir) do
    # Execute command and verify behavior
  end
end

# Error handling pattern
assert_raises(Ace::Core::ConfigError) do
  # Trigger error condition
end

# Edge case fixture pattern
fixture = fixture_path('unicode_filename_café.yml')
result = process(fixture)
assert result.success?
```

### Key Test Locations

- `ace-core/test/ace/core/` - Configuration and path resolution
- `ace-context/test/ace/context/` - Preset and content handling
- `ace-nav/test/ace/nav/` - URI resolution and navigation
- `ace-llm/test/ace/llm/` - Provider management and API calls
- `ace-llm-providers-cli/test/ace/llm_providers_cli/` - CLI execution
- `ace-git-commit/test/ace/git_commit/` - Git operations and orchestration

### Risk Areas

1. **ace-git-commit**: Missing tests for core orchestration (CommitOrchestrator, FileStager) - 0% coverage
2. **ace-nav**: All NavigationEngine tests skipped - integration untested
3. **All packages**: No systematic testing of execution from nested directories
4. **ace-llm**: Network error handling not comprehensively tested

### Success Metrics

- Test coverage for critical components: 0% → 80%+
- Edge case tests added: ~60-80 new test cases across packages
- CI passing with new tests on all supported Ruby versions
- No regressions in existing test suite
