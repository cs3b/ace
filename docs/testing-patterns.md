# Testing Patterns for ACE

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

## Summary

- Extract external dependencies to protected methods
- Use method stubbing instead of subprocess isolation
- Profile tests regularly to catch performance regressions
- Document patterns for team consistency
- Only use subprocesses when true process isolation is required