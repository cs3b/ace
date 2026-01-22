---
update:
  update_frequency: weekly
  max_lines: 1150
  required_sections:
  - testing-philosophy
  - test-organization
  frequency: weekly
  last-updated: '2026-01-22'
---

# Testing Patterns for ACE

## TL;DR

- **Flat structure**: `test/atoms/`, `test/molecules/` - no deep nesting
- **Naming**: `*_test.rb` suffix, descriptive names
- **No IO in unit tests**: Use MockGitRepo, WebMock stubs, method stubbing
- **ENV testing**: Protected method pattern for parallel-safe tests
- **Fixtures**: YAML files in `test/fixtures/`, create via `yaml_fixture`
- **HTTP mocking**: VCR cassettes or WebMock stubs
- **File isolation**: `with_temp_dir` for filesystem tests
- **Run tests**: `ace-test atoms` or `ace-test path/to/test.rb`

See sections below for detailed patterns and examples.

---

## Testing Philosophy

### The Testing Pyramid

ACE follows a strict testing pyramid with clear IO boundaries:

| Layer | Location | IO Policy | Purpose |
|-------|----------|-----------|---------|
| **Unit (atoms)** | `test/atoms/` | **No IO** | Test pure logic in isolation |
| **Unit (molecules)** | `test/molecules/` | **No IO** | Test component composition |
| **Unit (organisms)** | `test/organisms/` | **Mocked IO** | Test business logic with stubbed boundaries |
| **Integration** | `test/integration/` | **Mocked IO** | Test CLI/API surface with stubbed externals |
| **E2E** | `test/e2e/*.mt.md` | **Real IO** | Validate the real system works |

### IO Isolation Principle

**Default: No IO in unit tests.** This means:

- **No file system**: Use `MockGitRepo` or inline strings, not `File.read`
- **No network**: Use `WebMock` stubs, not real HTTP calls
- **No subprocesses**: Use method stubs, not `Open3.capture3`
- **No sleep**: Stub `Kernel.sleep` in retry logic

**Why?**
- Tests run in parallel safely
- Tests are fast (<10ms for atoms)
- Tests are deterministic (no flaky failures)
- CI doesn't need special setup

### When Real IO is Allowed

Real IO belongs in **E2E tests only** (`test/e2e/*.mt.md`):

- Executed by an agent, not the test runner
- Verify the full system works end-to-end
- Run infrequently (on-demand, not every commit)
- Document real tool requirements (standardrb, rubocop, etc.)

See `/ace:run-e2e-test` workflow for execution.

## Test Organization

### Flat Directory Structure

All ACE gems use a **flat test directory structure** that mirrors the ATOM architecture:

```
test/
├── test_helper.rb
├── search_test.rb              # Main module test
├── atoms/
│   ├── pattern_analyzer_test.rb
│   ├── result_parser_test.rb
│   └── tool_checker_test.rb
├── molecules/
│   ├── preset_manager_test.rb
│   └── git_scope_filter_test.rb
├── organisms/
│   ├── unified_searcher_test.rb
│   └── result_formatter_test.rb
├── models/
│   └── search_result_test.rb
└── integration/
    └── cli_integration_test.rb
```

**Key conventions:**
- ✅ Flat structure: `test/atoms/`, not `test/ace/search/atoms/`
- ✅ Suffix naming: `pattern_analyzer_test.rb`, not `test_pattern_analyzer.rb`
- ✅ Layer directories match ATOM architecture
- ✅ Integration tests in separate `integration/` directory

**Benefits:**
- Easier to navigate and find tests
- Matches layer boundaries clearly
- Consistent across all ACE gems
- Less nesting = simpler paths

See `ace-taskflow/test/` for reference implementation.

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

### When Subprocesses Are Necessary

Use subprocesses only when you need true process isolation for:
- Testing signal handling
- Testing process termination
- Testing memory limits
- Testing file descriptor inheritance
- Testing true environment isolation between processes

### Subprocess Stubbing with Open3

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

### WebMock for HTTP API Mocking

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

## Performance Considerations

### Subprocess Overhead

- Ruby subprocess spawn: ~150ms
- Method stubbing: <1ms
- Performance gain: ~150x

### When to Investigate Test Performance

1. Run tests with profiling: `ace-test --profile 20`
2. Look for patterns in slow tests (similar names, same file)
3. Check for:
   - Subprocess spawning
   - Network I/O
   - Disk I/O
   - Sleep statements
   - Large data processing

### Monitoring Test Performance

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

## Test Performance Targets

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

## Avoiding Exit Calls in Testable Code

Commands that call `exit` will terminate the entire test process, preventing test completion and reporting. This manifests as:
- Test runner stops mid-execution
- No test summary is printed
- `ace-test` reports "0 tests, 0 assertions"
- Rake test fails with "Command failed with status (1)"

### Pattern: Return Status Codes in Commands

Commands should return status codes (0 for success, 1 for failure) and let the CLI entry point handle exit:

```ruby
# ❌ BAD - Terminates test process
class MyCommand
  def execute(args)
    if args.include?("--help")
      show_help
      exit 0  # Kills tests!
    end

    do_work
  rescue => e
    puts "Error: #{e.message}"
    exit 1  # Kills tests!
  end
end

# ✅ GOOD - Returns status codes
class MyCommand
  def execute(args)
    if args.include?("--help")
      show_help
      return 0
    end

    do_work
    0
  rescue => e
    puts "Error: #{e.message}"
    1
  end
end
```

### Pattern: Raise Exceptions in Organisms

Organisms (business logic) should raise exceptions instead of calling exit:

```ruby
# ❌ BAD - Terminates test process
class IdeaWriter
  def write(content, options)
    if content.nil? || content.strip.empty?
      puts "Error: No content provided"
      exit 1  # Kills tests!
    end
    # ...
  end
end

# ✅ GOOD - Raises exceptions
class IdeaWriter
  class IdeaWriterError < StandardError; end

  def write(content, options)
    if content.nil? || content.strip.empty?
      raise IdeaWriterError, "No content provided"
    end
    # ...
  end
end
```

### CLI Entry Point Pattern

The CLI entry point (exe/ace-*) should handle status codes and exit only at the top level:

```ruby
#!/usr/bin/env ruby
# exe/ace-taskflow

require_relative "../lib/ace/taskflow"

# CLI.start returns status code
exit_code = Ace::Taskflow::CLI.start(ARGV)
exit(exit_code || 0)
```

```ruby
# lib/ace/taskflow/cli.rb
class CLI
  def self.start(args)
    case args.shift
    when "retro"
      require_relative "commands/retro_command"
      Commands::RetroCommand.new.execute(args)  # Returns status code
    when "--help"
      show_help
      0  # Return status code
    else
      puts "Unknown command"
      1  # Return status code
    end
  end
end
```

### Testing Commands with Status Codes

Test commands by asserting on their return values:

```ruby
def test_help_returns_success
  output = capture_io do
    exit_code = @command.execute(["--help"])
    assert_equal 0, exit_code
  end

  assert_match(/Usage:/, output)
end

def test_error_returns_failure
  output = capture_io do
    exit_code = @command.execute(["invalid"])
    assert_equal 1, exit_code
  end

  assert_match(/Error:/, output)
end
```

### Testing Organisms with Exceptions

Test organisms by asserting on raised exceptions:

```ruby
def test_raises_error_on_invalid_input
  error = assert_raises(Ace::Taskflow::Organisms::IdeaWriterError) do
    @writer.write("")
  end

  assert_match(/No content provided/, error.message)
end
```

### Migration Strategy

When refactoring commands with exit calls:

1. **Identify exit calls**: `grep -r "exit [01]" lib/`
2. **Refactor commands**: Replace `exit N` with `return N`
3. **Refactor organisms**: Replace `exit N` with `raise CustomError`
4. **Update CLI**: Return status codes, exit only at entry point
5. **Update tests**: Assert on return values instead of SystemExit
6. **Verify**: Run full test suite to ensure completion

### Benefits

1. **Test Completion**: Tests run to completion and report properly
2. **Better Debugging**: Exceptions provide stack traces
3. **Composability**: Commands can be called from other commands
4. **Isolation**: Test failures don't affect other tests

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
# ❌ BAD - Not thread-safe, can cause race conditions
def with_mocked_scanner(result)
  original = ScannerClass.instance_method(:scan)
  ScannerClass.define_method(:scan) { result }
  yield
ensure
  ScannerClass.define_method(:scan, original)
end

# ✅ GOOD - Thread-safe stub pattern
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
| ace-taskflow | `with_real_test_project` | ConfigResolver + project setup |
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
# ❌ WRONG: Stubs method that no longer exists in code path
ChangeDetector.stub :execute_git_command, "" do
  # Tests pass but run REAL git operations (zombie mock!)
  result = ChangeDetector.get_diff_for_documents(docs)
end

# ✅ CORRECT: Stubs actual method being called
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

## Zombie Mocks Pattern

"Zombie Mocks" occur when mocks stub methods that are no longer called by the implementation, but tests continue to pass because the real code path happens to work (slowly or otherwise).

### Symptoms

- Tests pass but are unexpectedly slow
- Mock setup doesn't match actual code implementation
- Refactored code still uses old mock patterns

### Case Study: ace-docs ChangeDetector

**Problem**: Tests stubbed `ChangeDetector.stub :execute_git_command` but the implementation had evolved to use `Ace::Git::Organisms::DiffOrchestrator.generate`. Tests passed but each ran real git operations (~1 second each).

```ruby
# ❌ ZOMBIE MOCK - stubs method no longer in code path
ChangeDetector.stub :execute_git_command, "" do
  result = ChangeDetector.get_diff_for_documents(docs, since: "HEAD~1")
end

# ✅ CORRECT - stubs actual method being called
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

## Summary

### Core Principles
- Extract external dependencies to protected methods
- Use method stubbing instead of subprocess isolation
- Profile tests regularly with `ace-test --profile 10`
- Only use subprocesses when true process isolation is required

### Performance Patterns (from 9-package optimization, 60% avg improvement)
- **Follow performance targets**: Unit <10ms, Integration <500ms, E2E <2s
- **Apply E2E rule**: Keep ONE E2E test per file, convert rest to mocked
- **Use composite helpers**: Reduce 6-7 level nesting to single helper calls
- **Stub at correct layer**: DiffOrchestrator for git, Open3 for subprocess
- **Stub sleep in retry tests**: Avoid 1-2s delays per sleep call

### Mock & Stub Patterns
- **Use MockGitRepo for unit tests**, real repos for integration tests
- **Use WebMock for HTTP/API mocking** - intercepts at network level, instant responses
- **Use thread-safe stub pattern** instead of define_method
- **Watch for zombie mocks** - stubs that don't match actual code paths
- **Use `with_empty_git_diff`** for cross-package git stubbing

### Testability Patterns
- **Never call exit in commands or organisms** - return status codes and raise exceptions
- **Handle exit only at the CLI entry point** (exe/ace-\*)
- **Return status codes from commands**, let CLI handle exit
