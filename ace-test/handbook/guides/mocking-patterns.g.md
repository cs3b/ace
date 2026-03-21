---
doc-type: guide
title: Mocking Patterns
purpose: Mocking and isolation patterns
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Mocking Patterns

## Testing ENV-Dependent Classes

When testing classes that depend on environment variables, use the protected method pattern for parallel-safe, fast tests.

### Pattern: Protected Method for ENV Access

Instead of directly accessing ENV in your code, extract it to a protected method:

```ruby
class ProjectRootFinder
  def find
    # Check environment variable first
    project_root_env = env_project_root
    if project_root_env && !project_root_env.empty?
      project_root = expand_path(project_root_env)
      return project_root if Dir.exist?(project_root)
    end
    # ... fallback logic
  end

  protected

  # Extract ENV access to allow test stubbing
  def env_project_root
    ENV['PROJECT_ROOT_PATH']
  end
end
```

### Testing Without ENV Modification

Use method stubbing to test different ENV scenarios without modifying global state:

```ruby
def test_finds_project_without_env_variable
  finder = ProjectRootFinder.new
  # Stub env method to simulate no ENV variable
  finder.stub :env_project_root, nil do
    assert_equal expected_path, finder.find
  end
end

def test_uses_env_variable_when_set
  finder = ProjectRootFinder.new
  # Stub to simulate ENV variable being set
  finder.stub :env_project_root, "/custom/path" do
    assert_equal "/custom/path", finder.find
  end
end

def test_ignores_invalid_env_path
  finder = ProjectRootFinder.new
  # Stub to simulate invalid ENV path
  finder.stub :env_project_root, "/nonexistent" do
    # Should fall back to marker detection
    assert_equal project_dir_with_git, finder.find
  end
end
```

### Benefits

1. **Parallel-Safe**: No global ENV modification means tests can run in parallel
2. **Fast**: No subprocess spawning overhead (20x faster than subprocess approach)
3. **Clean**: Production code stays simple with just a protected method
4. **Complete**: Can test all ENV scenarios including presence, absence, and invalid values

### Anti-Pattern: Subprocess for ENV Testing

Avoid using subprocesses just to test ENV absence:

```ruby
# DON'T DO THIS - Slow and complex
def test_without_env_slow
  code = <<~RUBY
    ENV.delete('MY_VAR')
    obj = MyClass.new
    puts obj.find
  RUBY

  output = run_in_subprocess(code)
  assert_equal expected, output
end
```

Each subprocess adds ~150ms overhead on typical systems.

## Subprocess Stubbing with Open3

When production code uses `Open3.capture3` for subprocess calls, stub it to avoid the ~150ms overhead:

```ruby
# Production code using subprocess
def execute_command(cmd, *args)
  stdout, stderr, status = Open3.capture3(cmd, *args)
  { stdout: stdout, stderr: stderr, success: status.success? }
end

# Test helper for stubbing Open3
def with_stubbed_subprocess(stdout: "", stderr: "", success: true)
  mock_status = Object.new
  mock_status.define_singleton_method(:success?) { success }
  mock_status.define_singleton_method(:exitstatus) { success ? 0 : 1 }

  Open3.stub :capture3, [stdout, stderr, mock_status] do
    yield
  end
end

# Usage in tests
def test_command_parsing
  with_stubbed_subprocess(stdout: "expected output") do
    result = MyCommand.execute("tool", "--flag")
    assert result[:success]
    assert_equal "expected output", result[:stdout]
  end
end
```

### Prefer Higher-Level Stubs

Stub at the boundary closest to your test subject:

| Test Subject | Stub At | Not At |
|--------------|---------|--------|
| Command class | Command.execute | Open3.capture3 |
| Organism using Molecule | Molecule.call | Atom subprocess |
| CLI option parsing | API method | Subprocess |
| Integration test | Nothing (use real) | - |

### CLI Binary Testing Without Subprocess

Convert CLI subprocess tests to API tests when possible:

```ruby
# BEFORE: Slow subprocess test (~500ms)
def test_cli_flag
  output, status = Open3.capture3("bin/ace-tool", "--verbose")
  assert status.success?
  assert_includes output, "Verbose mode"
end

# AFTER: Fast API test (~5ms)
def test_cli_flag
  result = Ace::Tool.call(verbose: true)
  assert result.success?
  assert_includes result.output, "Verbose mode"
end
```

## WebMock for HTTP API Mocking

Use WebMock (already in Gemfile) to intercept HTTP requests at the network level. This is ideal for testing code that calls external APIs (LLM providers, GitHub API, etc.) without making real network calls.

**Setup pattern:**

```ruby
require "webmock/minitest"

class MyAPITest < Minitest::Test
  def setup
    super
    WebMock.disable_net_connect!
  end

  def teardown
    WebMock.reset!
    WebMock.allow_net_connect!
    super
  end
end
```

**Stubbing API responses:**

```ruby
# Stub by URL pattern (regex)
def stub_google_api_success
  stub_request(:post, /generativelanguage\.googleapis\.com/)
    .to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        "candidates" => [{ "content" => { "parts" => [{ "text" => "Mock response" }] } }],
        "usageMetadata" => { "promptTokenCount" => 5, "candidatesTokenCount" => 10 }
      }.to_json
    )
end

# Stub by exact URL
def stub_github_api_success
  stub_request(:get, "https://api.github.com/repos/owner/repo")
    .to_return(status: 200, body: { "id" => 123 }.to_json)
end

# Stub error responses
def stub_api_error(status: 401)
  stub_request(:any, /api\.example\.com/)
    .to_return(status: status, body: { "error" => "Unauthorized" }.to_json)
end
```

**Usage in tests:**

```ruby
def test_cli_routing_with_api_call
  stub_google_api_success
  with_real_config do
    output = invoke_cli(["google:gemini-2.5-flash", "Hello"])
    # Test verifies CLI routing, not API functionality
    refute_match(/^Usage:/, output)
  end
end
```

**When to use WebMock:**
- Tests that verify CLI argument routing (not API responses)
- Tests that need real config but mock network
- Cross-provider tests where mocking at HTTP level is simpler

**Existing usage:**
- `ace-git-secrets/test/atoms/service_api_client_test.rb` - GitHub API mocking
- `ace-llm/test/commands/query_command_test.rb` - LLM API mocking

**Performance:** WebMock stubs are instant (<1ms) vs real API calls (1-10+ seconds).

## Mock Git Repository Pattern

When testing code that interacts with git repositories, use `MockGitRepo` for fast unit tests instead of real git operations.

### When to Use MockGitRepo

- **Unit tests**: Testing file reading, validation, pattern matching
- **Tests that don't need git history**: Testing code that reads repo structure
- **Performance-critical tests**: Avoid ~150ms subprocess overhead per git command

### When to Use Real Repositories

- **Integration tests**: Testing actual git operations (commit, push, rebase)
- **E2E tests**: Verifying real tool execution (gitleaks, git-filter-repo)
- **Git history tests**: Testing log parsing, diff generation, branch operations

### Usage

```ruby
# From ace-support-test-helpers
require 'ace/test_support'

class MyTest < Minitest::Test
  def setup
    @mock_repo = Ace::TestSupport::Fixtures::GitMocks::MockGitRepo.new
  end

  def teardown
    @mock_repo&.cleanup
  end

  def test_file_processing
    @mock_repo.add_file("config.yml", "key: value")
    @mock_repo.add_commit("abc1234", message: "Add config")

    result = MyProcessor.new(@mock_repo.path).process
    assert result.success?
  end

  def test_multiple_scenarios
    # Test first scenario
    @mock_repo.add_file("valid.txt", "content")
    assert valid_result

    # Reset and test second scenario
    @mock_repo.reset!
    @mock_repo.add_file("invalid.txt", "bad content")
    refute valid_result
  end
end
```

### Helper Pattern for Gem-Specific Tests

For gem-specific mocking (like gitleaks), create helpers that wrap the shared MockGitRepo:

```ruby
# In test_helper.rb
def with_mocked_git_repo
  repo = Ace::TestSupport::Fixtures::GitMocks::MockGitRepo.new
  begin
    yield repo
  ensure
    repo.cleanup
  end
end
```

### Thread-Safe Mocking

Use Minitest's `stub` method instead of `define_method` for thread-safe test mocking:

```ruby
# BAD - Not thread-safe, can cause race conditions
def with_mocked_scanner(result)
  original = ScannerClass.instance_method(:scan)
  ScannerClass.define_method(:scan) { result }
  yield
ensure
  ScannerClass.define_method(:scan, original)
end

# GOOD - Thread-safe stub pattern
def with_mocked_scanner(result)
  ScannerClass.stub :new, ->(**_opts) {
    mock = Object.new
    mock.define_singleton_method(:scan) { result }
    mock
  } do
    yield
  end
end
```

### Benefits

1. **Speed**: MockGitRepo is ~150x faster than real git init
2. **Isolation**: No global state pollution between tests
3. **Determinism**: Predictable results without filesystem race conditions
4. **Portability**: Works in CI environments without git configuration

## Testing Classes with Multiple External Dependencies

For classes with multiple external dependencies (ENV, File, Time, etc.), apply the same pattern:

```ruby
class ConfigLoader
  def load
    config_path = env_config_path || default_config_path
    return nil unless file_exists?(config_path)

    content = read_file(config_path)
    parse_with_timestamp(content, current_time)
  end

  protected

  def env_config_path
    ENV['CONFIG_PATH']
  end

  def file_exists?(path)
    File.exist?(path)
  end

  def read_file(path)
    File.read(path)
  end

  def current_time
    Time.now
  end
end
```

This allows comprehensive stubbing in tests:

```ruby
def test_load_with_all_dependencies_stubbed
  loader = ConfigLoader.new

  loader.stub :env_config_path, "/custom/config.yml" do
    loader.stub :file_exists?, true do
      loader.stub :read_file, "key: value" do
        loader.stub :current_time, Time.at(0) do
          result = loader.load
          assert_equal expected, result
        end
      end
    end
  end
end
```

## DiffOrchestrator Stubbing Pattern

The `Ace::Git::Organisms::DiffOrchestrator` is used across multiple ACE packages. Proper stubbing prevents zombie mock issues and speeds up tests.

### Standard Stubbing Pattern

```ruby
# Helper for tests that need empty diff (most common case)
def with_empty_git_diff
  empty_result = Ace::Git::Models::DiffResult.empty
  Ace::Git::Organisms::DiffOrchestrator.stub(:generate, empty_result) do
    yield
  end
end

# Usage
def test_document_status_without_changes
  with_empty_git_diff do
    result = DocumentAnalyzer.check_status(doc)
    assert_equal :unchanged, result.status
  end
end
```

### Three-Tier Git Testing Strategy

| Test Layer | Git Operations | Stub Level | Example |
|------------|---------------|------------|---------|
| Unit (atoms) | Full mock | MockGitRepo or inline stubs | Pattern parsing, validation |
| Unit (molecules) | Stub DiffOrchestrator | `with_empty_git_diff` | Document change detection |
| Unit (organisms) | Stub DiffOrchestrator | `with_mock_diff` | Business logic with diff |
| Integration | Real git operations | No stubbing | CLI parity, E2E workflows |

### Common Mistake: Stubbing Wrong Method

After refactoring, ensure mocks target the actual code path:

```ruby
# WRONG: Stubs method that no longer exists in code path
ChangeDetector.stub :execute_git_command, "" do
  # Tests pass but run REAL git operations (zombie mock!)
  result = ChangeDetector.get_diff_for_documents(docs)
end

# CORRECT: Stubs actual method being called
Ace::Git::Organisms::DiffOrchestrator.stub :generate, empty_result do
  # Fast, properly mocked test
  result = ChangeDetector.get_diff_for_documents(docs)
end
```

### Cross-Package Usage

When your gem depends on ace-git, use DiffOrchestrator stubbing:

```ruby
# In ace-docs, ace-bundle, or any gem using git diffs
require 'ace/git'

def test_my_feature_with_git_dependency
  with_empty_git_diff do
    # Your test logic here - no real git operations
    result = MyFeature.analyze(path)
    assert result.valid?
  end
end
```

## Related Guides

- [Testing Philosophy](guide://testing-philosophy) - Why IO isolation matters
- [Test Performance](guide://test-performance) - Performance targets and optimization
- [Testable Code Patterns](guide://testable-code-patterns) - Designing for testability