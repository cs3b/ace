---
doc-type: guide
title: Test Mocking Patterns Guide
purpose: Ensure mocks actually test real behavior and stay in sync with production
ace-docs:
  last-updated: 2026-02-01
  last-checked: 2026-03-21
---

# Test Mocking Patterns Guide

## Goal

This guide ensures your mocks:
1. Test **behavior**, not implementation details
2. Stay in sync with real APIs (no drift)
3. Don't become "zombies" that test nothing

## Core Principle: Test Behavior, Not Implementation

### The Difference

**Implementation testing** (fragile):
- "Was method X called?"
- "Was it called with these exact arguments?"
- "Was it called exactly 3 times?"

**Behavior testing** (robust):
- "Given this input, is the output correct?"
- "Given this error condition, is the error message helpful?"
- "Does the system reach the correct final state?"

### Example

```ruby
# BAD: Tests implementation (breaks when refactored)
def test_processes_data
  processor = Minitest::Mock.new
  processor.expect :transform, "result", ["input"]
  processor.expect :validate, true, ["result"]

  subject = DataHandler.new(processor)
  subject.handle("input")

  processor.verify  # "Were these methods called?"
end

# GOOD: Tests behavior (survives refactoring)
def test_processes_data
  result = DataHandler.new.handle("input")

  assert result.success?
  assert_equal "expected_output", result.value
end
```

## Stub Hierarchy: Use the Simplest Double

From simplest to most complex:

| Type | Purpose | When to Use |
|------|---------|-------------|
| **Dummy** | Placeholder, never used | Parameter that won't be called |
| **Stub** | Returns canned values | Control return values |
| **Spy** | Records calls for inspection | Verify interactions happened |
| **Mock** | Verifies expectations | Protocol/contract testing |
| **Fake** | Working implementation | Complex behavior needed |

**Rule**: Use the simplest type that meets your needs.

```ruby
# Dummy - just needs to exist
def test_with_unused_dependency
  dummy_logger = Object.new
  subject = Worker.new(logger: dummy_logger)
  # logger never called in this test path
end

# Stub - control return value
def test_with_stubbed_api
  api_result = { status: "ok", data: [1, 2, 3] }
  ApiClient.stub :fetch, api_result do
    result = subject.process
    assert_equal [1, 2, 3], result.items
  end
end

# Fake - real behavior, simplified
class FakeFileSystem
  def initialize
    @files = {}
  end

  def write(path, content)
    @files[path] = content
  end

  def read(path)
    @files[path] or raise "File not found: #{path}"
  end
end
```

## Zombie Mocks: Detection and Prevention

### What Are Zombie Mocks?

Mocks that stub methods **no longer called** by the implementation. Tests pass but don't test anything real.

### How They Happen

1. Code is refactored, method renamed or removed
2. Tests still stub old method name
3. Real code path executes (slowly or incorrectly)
4. Test passes anyway

### Case Study

```ruby
# Original implementation
class ChangeDetector
  def get_diff(files)
    execute_git_command("git diff #{files.join(' ')}")
  end
end

# Test stubbed this:
ChangeDetector.stub :execute_git_command, "" do
  result = detector.get_diff(files)  # Fast, stubbed
end

# Later, implementation changed:
class ChangeDetector
  def get_diff(files)
    Ace::Git::DiffOrchestrator.generate(files: files)  # New method!
  end
end

# Test still stubs old method - ZOMBIE!
ChangeDetector.stub :execute_git_command, "" do
  result = detector.get_diff(files)  # Slow! Real DiffOrchestrator runs
end
```

### Detection

1. **Profile tests**: `ace-test --profile 10`
2. **Look for slow unit tests**: >100ms indicates zombie
3. **Try breaking the stub**: Change stub return value, test should fail

```ruby
# Zombie detection test
def test_stub_is_actually_used
  # If this stub is a zombie, changing return value won't affect test
  Runner.stub(:run, "UNEXPECTED_VALUE_12345") do
    result = subject.lint(file)
    # If test passes without checking for UNEXPECTED_VALUE_12345,
    # the stub might be a zombie
  end
end
```

### Prevention

1. **Update stubs when refactoring**: Part of the refactoring checklist
2. **Use composite helpers**: Centralized, easier to maintain
3. **Profile regularly**: Weekly `ace-test --profile 20`
4. **Document stub targets**: Comments explaining what's stubbed and why

## Composite Helpers: Reducing Stub Complexity

### The Problem

Deep nesting makes tests hard to read and maintain:

```ruby
def test_complex_workflow
  mock_config do
    mock_git_status do
      mock_diff_generator do
        mock_api_client do
          result = subject.execute
        end
      end
    end
  end
end
```

### The Solution

Composite helpers that combine related stubs:

```ruby
def test_complex_workflow
  with_mock_repo_context(branch: "feature", clean: true) do
    result = subject.execute
    assert result.success?
  end
end

# In test_helper.rb
def with_mock_repo_context(branch: "main", clean: true, diff: nil)
  mock_branch = build_branch_info(name: branch)
  mock_status = clean ? :clean : :dirty
  mock_diff ||= Ace::Git::Models::DiffResult.empty

  Ace::Git::Molecules::BranchInfo.stub :fetch, mock_branch do
    Ace::Git::Atoms::StatusChecker.stub :clean?, clean do
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, mock_diff do
        yield
      end
    end
  end
end
```

### Design Principles

1. **Sensible defaults**: Most tests use standard values
2. **Keyword arguments**: Override only what matters
3. **Clear naming**: `with_mock_<context>` pattern
4. **Single responsibility**: One helper per "context"

### Existing Composite Helpers

| Package | Helper | Stubs |
|---------|--------|-------|
| ace-git | `with_mock_repo_load` | BranchInfo + StatusChecker + DiffOrchestrator |
| ace-git-secrets | `with_rewrite_test_mocks` | gitleaks + rewriter + working directory |
| ace-lint | `with_stubbed_validators` | ValidatorRegistry + Runner availability |
| ace-review | `stub_synthesizer_prompt_path` | ace-nav subprocess |

## Contract Testing: Keeping Mocks in Sync

### The Problem

Mock data can drift from real API responses:

```ruby
# Mock returns this:
{ "status" => "ok", "items" => [] }

# Real API returns this:
{ "status" => "success", "data" => { "items" => [] } }

# Test passes, production fails!
```

### Solution 1: Snapshot-Based Mocks

Capture real API responses and use them as mocks:

```ruby
# 1. Record real response (one-time, manual)
# curl https://api.github.com/repos/owner/repo/pulls/123 > fixtures/pr_response.json

# 2. Use in tests
def mock_pr_response
  JSON.parse(File.read("fixtures/pr_response.json"))
end

def test_fetches_pr_details
  WebMock.stub_request(:get, /pulls\/123/)
    .to_return(body: mock_pr_response.to_json)

  result = PrFetcher.fetch(123)
  assert_equal "open", result.state
end
```

### Solution 2: Schema Validation

Validate mock data against OpenAPI/JSON Schema:

```ruby
# fixtures/schemas/github_pr.json defines the schema

def test_mock_matches_schema
  schema = JSON.parse(File.read("fixtures/schemas/github_pr.json"))
  mock = mock_pr_response

  errors = JSON::Validator.validate(schema, mock)
  assert_empty errors, "Mock doesn't match schema: #{errors}"
end
```

### Solution 3: Periodic Drift Check

Scheduled job that compares mocks to real responses:

```ruby
# Run monthly or after API version updates
def test_mock_matches_live_api
  skip "Run manually to check for API drift"

  live_response = real_api_client.fetch_pr(TEST_PR_ID)
  mock_response = mock_pr_response

  # Compare structure (not exact values)
  assert_same_keys live_response, mock_response
  assert_same_types live_response, mock_response
end
```

## Stubbing Patterns by Dependency Type

### Subprocess Calls

```ruby
# Stub Open3.capture3
Open3.stub :capture3, ["output", "", mock_status] do
  result = Runner.execute("command")
end

# Stub system()
Kernel.stub :system, true do
  Runner.check_availability
end

# Don't forget availability checks!
Runner.stub(:available?, true) do
  # Now stub the actual execution
end
```

### HTTP Requests

```ruby
# Using WebMock
WebMock.stub_request(:get, "https://api.example.com/data")
  .to_return(body: { items: [] }.to_json, status: 200)

# Using VCR for recorded responses
VCR.use_cassette("api_response") do
  result = ApiClient.fetch_data
end
```

### Filesystem

```ruby
# Temp directory helper
def with_temp_dir
  Dir.mktmpdir do |dir|
    yield dir
  end
end

# Fake filesystem for complex tests
def test_with_fake_fs
  fake_fs = FakeFileSystem.new
  fake_fs.write("config.yml", "key: value")

  subject = ConfigLoader.new(filesystem: fake_fs)
  result = subject.load("config.yml")
end
```

### Time

```ruby
# Stub Time.now
Time.stub :now, Time.new(2026, 1, 31, 12, 0, 0) do
  result = subject.generate_timestamp
  assert_equal "2026-01-31T12:00:00", result
end

# Stub sleep for retry tests
Kernel.stub :sleep, nil do
  result = subject.retry_with_backoff(max_retries: 3)
end
```

### Git Operations

```ruby
# Use MockGitRepo (fast, no subprocess)
def test_with_mock_repo
  repo = MockGitRepo.new
  repo.add_commit("abc123", message: "Initial commit", files: ["README.md"])
  repo.add_commit("def456", message: "Add feature", files: ["feature.rb"])

  subject = CommitAnalyzer.new(repo: repo)
  result = subject.analyze("def456")

  assert_equal ["feature.rb"], result.changed_files
end

# Real git only in integration/E2E
def test_with_real_repo
  with_temp_git_repo do |repo_path|
    # Creates real .git directory
    File.write("#{repo_path}/test.txt", "content")
    system("git", "-C", repo_path, "add", ".")
    system("git", "-C", repo_path, "commit", "-m", "test")
  end
end
```

## Checklist: Is My Mock Testing Real Behavior?

- [ ] **Behavior focus**: Test checks output/state, not method calls
- [ ] **Stub is used**: Changing stub return value causes test to fail
- [ ] **Data is realistic**: Mock data from real API snapshot or validated schema
- [ ] **Complete chain**: All entry points to expensive operations stubbed
- [ ] **No zombie**: Stub target matches current implementation
- [ ] **Documented**: Comment explains what's stubbed and why

## See Also

- [Test Layer Decision](guide://test-layer-decision) - Where to test each behavior
- [Test Performance](guide://test-performance) - Performance optimization
- [E2E Testing](guide://e2e-testing) - When mocks aren't enough