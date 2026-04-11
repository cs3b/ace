---
doc-type: guide
title: Test Performance
purpose: Test performance optimization
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Test Performance

## Performance Targets

Define explicit performance expectations for each test layer based on patterns established during optimization of 9 ACE packages (60% average improvement).

### Performance Thresholds by Test Type

| Test Layer | Target Time | Hard Limit | Common Issues |
|------------|-------------|------------|---------------|
| Unit (atoms) | <10ms | 50ms | Real git ops, subprocess spawns |
| Unit (molecules) | <50ms | 100ms | Unstubbed dependencies |
| Unit (organisms) | <100ms | 200ms | Missing composite helpers |
| Integration | <500ms | 1s | Too many real operations |
| E2E | <2s | 5s | Should be rare - ONE per file |

### Performance Cost Reference

Know the cost of common operations to guide optimization:

| Operation | Typical Cost | Notes |
|-----------|--------------|-------|
| Real `git init` | ~150-200ms | Use MockGitRepo instead |
| Real `git commit` | ~50-100ms | Stub in unit tests |
| Subprocess spawn (`Open3.capture3`) | ~150ms | Stub or use API calls |
| Sleep in retry tests | 1-2s per sleep | Stub `Kernel.sleep` |
| Cross-package require (cold) | ~50-100ms | Cache or stub dependencies |
| `ace-nav` subprocess | ~150-400ms | Use `stub_synthesizer_prompt_path` |
| Real LLM API call | 1-20s | Use WebMock to stub HTTP |
| Real GitHub API call | 100-500ms | Use WebMock to stub HTTP |

### When Tests Exceed Targets

1. **Profile first**: Run `ace-test --profile 10` to identify actual bottlenecks
2. **Check for zombie mocks**: Stubs that don't match actual code paths (see Zombie Mocks section)
3. **Verify stubbing layer**: Stub at the boundary closest to your test subject
4. **Consider composite helpers**: Reduce setup overhead with consolidated mock helpers
5. **Apply E2E rule**: Keep ONE E2E test per file, convert rest to mocked versions

## Sleep Stubbing for Retry Tests

Tests with retry logic often include `sleep` calls that add seconds to test runtime.

### Pattern: Stub Kernel.sleep

```ruby
def with_stubbed_sleep
  Kernel.stub :sleep, nil do
    yield
  end
end

def test_retry_logic
  with_stubbed_sleep do
    # Retry tests now instant instead of 3+ seconds
    result = RetryableOperation.call(max_retries: 3, delay: 1.0)
    assert result.eventually_succeeded?
  end
end
```

### Alternative: Inject Sleep Dependency

```ruby
# Production code
class RetryableOperation
  def initialize(sleeper: Kernel)
    @sleeper = sleeper
  end

  def call
    attempts = 0
    loop do
      result = try_operation
      return result if result.success?
      attempts += 1
      break if attempts >= max_retries
      @sleeper.sleep(delay)
    end
  end
end

# Test with null sleeper
def test_retry_without_delay
  null_sleeper = Object.new
  null_sleeper.define_singleton_method(:sleep) { |_| nil }

  op = RetryableOperation.new(sleeper: null_sleeper)
  result = op.call
  assert result.eventually_succeeded?
end
```

## E2E Test Strategy: Keep ONE Per Integration File

Keep exactly ONE E2E test per integration test file that exercises real subprocess calls. Convert all other tests to use mocked versions.

### When to Use Real E2E Tests

**Keep as E2E (real subprocess)**:
- CLI parity validation (CLI vs API produce same result)
- Critical path smoke tests
- Tool availability checks (gitleaks, git-filter-repo)
- One representative test per integration file

**Convert to Mocked**:
- Flag/option permutation tests
- Error handling tests
- Edge case tests
- Performance-critical paths

### Migration Pattern: E2E to Mocked

```ruby
# BEFORE: E2E test using subprocess (~500ms each, 5 tests = 2.5s)
def test_cli_with_verbose_flag
  output, status = Open3.capture3(BIN, "analyze", "--verbose")
  assert status.success?
  assert_includes output, "Verbose output"
end

def test_cli_with_quiet_flag
  output, status = Open3.capture3(BIN, "analyze", "--quiet")
  assert status.success?
  refute_includes output, "Debug"
end

# AFTER: Keep ONE E2E, convert rest to API tests (~5ms each)
def test_cli_parity_with_api  # Keep this ONE E2E test
  cli_output, status = Open3.capture3(BIN, "analyze", "file.rb")
  api_result = Ace::MyModule.analyze("file.rb")
  assert status.success?
  assert_equal api_result.output, cli_output.strip
end

def test_verbose_flag  # Converted to API test
  result = Ace::MyModule.analyze("file.rb", verbose: true)
  assert result.success?
  assert_includes result.output, "Verbose output"
end

def test_quiet_flag  # Converted to API test
  result = Ace::MyModule.analyze("file.rb", quiet: true)
  assert result.success?
  refute_includes result.output, "Debug"
end
```

### Real Example: ace-test-runner Optimization

Task 175 reduced ace-test-runner tests from 8.25s to 3.3s (60% reduction) by:
1. Keeping ONE E2E test for genuine CLI validation
2. Converting 2 redundant E2E tests to use `run_ace_test_with_mock` helper
3. Adding TestRunnerMocks infrastructure to ace-support-test-helpers

```ruby
# Helper for mocked CLI tests
def run_ace_test_with_mock(args, expected_output: "", expected_status: 0)
  mock_status = Object.new
  mock_status.define_singleton_method(:success?) { expected_status == 0 }
  mock_status.define_singleton_method(:exitstatus) { expected_status }

  Open3.stub :capture3, [expected_output, "", mock_status] do
    yield
  end
end
```

## Composite Test Helpers

Reduce deeply nested stubs by creating composite helpers that combine related mocks.

### The Problem: Deep Nesting

```ruby
# BAD: 6-7 levels of nesting (hard to read, slow due to setup overhead)
def test_complex_operation
  mock_config_loader do
    mock_diff_generator do
      mock_diff_filter do
        mock_branch_info do
          mock_pr_fetcher do
            mock_commits_fetcher do
              result = SUT.call
              assert result.success?
            end
          end
        end
      end
    end
  end
end
```

### The Solution: Composite Helpers

```ruby
# GOOD: Single composite helper with keyword options
def test_complex_operation
  with_mock_repo_load(branch: "feature", task_pattern: "123") do
    result = SUT.call
    assert result.success?
  end
end

# In test_helper.rb - consolidates 6 stubs into one helper
def with_mock_repo_load(branch: "main", task_pattern: nil, usable: true)
  branch_info = build_mock_branch_info(name: branch, task_pattern: task_pattern)
  mock_config = build_mock_config
  mock_diff = Ace::Git::Models::DiffResult.empty

  Ace::Config.stub :create, mock_config do
    Ace::Git::Molecules::BranchInfo.stub :fetch, branch_info do
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, mock_diff do
        yield
      end
    end
  end
end
```

### Composite Helper Design Principles

1. **Sensible Defaults**: Most tests need standard values; customize only what matters
2. **Keyword Arguments**: Allow targeted overrides without changing unrelated values
3. **Clear Naming**: `with_mock_<context>` pattern indicates scope
4. **Single Responsibility**: Each helper handles one "thing" completely

### Examples from ACE Packages

| Package | Helper | Purpose |
|---------|--------|---------|
| ace-git | `with_mock_repo_load` | Combines 6 stubs for RepoStatusLoader |
| ace-git | `with_mock_diff_orchestrator` | ConfigLoader + DiffGenerator + DiffFilter |
| ace-git-secrets | `with_rewrite_test_mocks` | gitleaks + rewriter + working directory |
| ace-task | `with_real_test_project` | ConfigResolver + project setup |
| ace-docs | `with_empty_git_diff` | Simple DiffOrchestrator stub |
| ace-review | `stub_synthesizer_prompt_path` | ace-nav subprocess stub |

### Implementation Pattern

```ruby
# In test_helper.rb
module CompositeHelpers
  def with_empty_git_diff
    empty_result = Ace::Git::Models::DiffResult.empty
    Ace::Git::Organisms::DiffOrchestrator.stub(:generate, empty_result) do
      yield
    end
  end

  def with_mock_diff(content:, files: [])
    mock_result = Ace::Git::Models::DiffResult.new(
      content: content,
      stats: { additions: 1, deletions: 0, files: files.size },
      files: files
    )
    Ace::Git::Organisms::DiffOrchestrator.stub(:generate, mock_result) do
      yield
    end
  end

  def build_mock_status(success: true, exitstatus: 0)
    status = Object.new
    status.define_singleton_method(:success?) { success }
    status.define_singleton_method(:exitstatus) { exitstatus }
    status
  end
end

class MyTestCase < Minitest::Test
  include CompositeHelpers
end
```

## Zombie Mocks Pattern

"Zombie Mocks" occur when mocks stub methods that are no longer called by the implementation, but tests continue to pass because the real code path happens to work (slowly or otherwise).

### Symptoms

- Tests pass but are unexpectedly slow
- Mock setup doesn't match actual code implementation
- Refactored code still uses old mock patterns

### Case Study: ace-docs ChangeDetector

**Problem**: Tests stubbed `ChangeDetector.stub :execute_git_command` but the implementation had evolved to use `Ace::Git::Organisms::DiffOrchestrator.generate`. Tests passed but each ran real git operations (~1 second each).

```ruby
# ZOMBIE MOCK - stubs method no longer in code path
ChangeDetector.stub :execute_git_command, "" do
  result = ChangeDetector.get_diff_for_documents(docs, since: "HEAD~1")
end

# CORRECT - stubs actual method being called
mock_result = Ace::Git::Models::DiffResult.empty
Ace::Git::Organisms::DiffOrchestrator.stub :generate, mock_result do
  result = ChangeDetector.get_diff_for_documents(docs, since: "HEAD~1")
end
```

**Detection**: Run `ace-test --profile 10` to find slow unit tests. Tests taking >100ms often indicate zombie mocks.

**Result**: Fixing zombie mocks reduced test time from 14s to 1.5s (89% improvement).

### Prevention

1. **Profile regularly**: Add `ace-test --profile 10` to development workflow
2. **Review mock targets**: When refactoring, update test mocks to match new code paths
3. **Extract helpers**: Create reusable mock helpers (like `with_empty_git_diff`) that are easy to maintain
4. **Test the mocks**: Verify mocks are being hit by temporarily breaking them

## When to Investigate Test Performance

1. Run tests with profiling: `ace-test --profile 20`
2. Look for patterns in slow tests (similar names, same file)
3. Check for:
   - Subprocess spawning
   - Network I/O
   - Disk I/O
   - Sleep statements
   - Large data processing

## Monitoring Test Performance

Add to your CI pipeline:

```yaml
- name: Check test performance
  run: |
    ace-test --profile 20 | tee profile.txt
    # Fail if any test takes >100ms (except integration tests)
    if grep -E "^\s+[0-9]+\.\s+test_(?!integration)" profile.txt | awk '{print $NF}' | grep -E "[0-9]+\.[1-9][0-9][0-9]s"; then
      echo "Tests taking >100ms detected"
      exit 1
    fi
```

## Related Guides

- [Mocking Patterns](guide://mocking-patterns) - How to stub properly
- [Testing Philosophy](guide://testing-philosophy) - Why performance matters
- [Testable Code Patterns](guide://testable-code-patterns) - Designing for fast tests