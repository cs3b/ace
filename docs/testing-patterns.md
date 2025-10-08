# Testing Patterns for ACE

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

## Summary

- Extract external dependencies to protected methods
- Use method stubbing instead of subprocess isolation
- Profile tests regularly to catch performance regressions
- Document patterns for team consistency
- Only use subprocesses when true process isolation is required
- **Never call exit in commands or organisms - return status codes and raise exceptions**
- **Handle exit only at the CLI entry point (exe/ace-\*)**