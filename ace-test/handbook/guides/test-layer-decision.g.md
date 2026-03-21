---
doc-type: guide
title: Test Layer Decision Guide
purpose: Help developers and agents decide where to test each behavior
ace-docs:
  last-updated: 2026-02-23
  last-checked: 2026-03-21
---

# Test Layer Decision Guide

## Goal

This guide helps you decide **where** to test each behavior. Placing tests at the wrong layer leads to slow feedback loops, brittle tests, or gaps in coverage.

## The Testing Pyramid

```
        /\
       /E2E\        10% - Critical user journeys
      /------\
     /  Integ \     20% - Component interactions
    /----------\
   /    Unit    \   70% - Pure logic, edge cases
  /--------------\
```

| Layer | Target Time | What It Tests |
|-------|-------------|---------------|
| Unit (atoms) | <10ms | Pure functions, single responsibility |
| Unit (molecules) | <50ms | Composed operations, controlled I/O |
| Integration (organisms) | <500ms | Business logic orchestration |
| E2E | Seconds | Critical user workflows, real dependencies |

## Decision Matrix

Use this matrix to decide where a test belongs:

| Question | Unit | Integration | E2E |
|----------|:----:|:-----------:|:---:|
| Tests pure logic with no side effects? | **Yes** | - | - |
| Tests data transformation? | **Yes** | - | - |
| Tests component orchestration? | - | **Yes** | - |
| Needs real filesystem operations? | No | Sometimes | **Yes** |
| Needs real git repository? | No | Rarely | **Yes** |
| Needs real subprocess execution? | **Never** | Stub | **Yes** |
| Calls external APIs (GitHub, LLM)? | Mock | Mock | **Yes** |
| Tests CLI argument parsing? | API | API | **Yes** |
| Tests CLI output format? | - | 1 per file | **Yes** |
| Tests error messages and exit codes? | API | API | **Yes** |
| Tests tool installation/availability? | - | - | **Yes** |
| Tests multi-step user workflow? | - | - | **Yes** |

## Layer Responsibilities

### Unit Tests (atoms/molecules)

**Purpose**: Verify individual functions work correctly in isolation.

**Test these behaviors**:
- Pure function logic (input → output)
- Edge cases (empty input, nil, boundaries)
- Error handling (invalid input, exceptions)
- Data transformations
- Configuration parsing
- String/path manipulation

**Stub everything external**:
- Filesystem → use temp files or mocks
- Subprocess → stub `Open3.capture3`, `system()`
- Network → stub with WebMock
- Git → use `MockGitRepo`
- Time → stub `Time.now` if needed

**Example**:
```ruby
# atoms/path_expander_test.rb
def test_expands_home_directory
  result = PathExpander.expand("~/config.yml")
  assert_equal "/Users/test/config.yml", result
end

def test_returns_absolute_path_unchanged
  result = PathExpander.expand("/absolute/path.yml")
  assert_equal "/absolute/path.yml", result
end
```

### Integration Tests (molecules/organisms)

**Purpose**: Verify components work together correctly.

**Test these behaviors**:
- Data flow between modules
- Error propagation across components
- Configuration cascade resolution
- Orchestration logic
- ONE CLI parity test per file (verify CLI matches API)

**Stub external dependencies**:
- Real subprocess calls
- External APIs
- Slow operations (git init, network)

**Allow controlled I/O**:
- Temp directories for file tests
- In-memory data structures

**Example**:
```ruby
# organisms/config_resolver_test.rb
def test_merges_project_over_user_config
  with_temp_config_files(
    user: { model: "gpt-4" },
    project: { model: "claude" }
  ) do
    result = ConfigResolver.resolve("llm")
    assert_equal "claude", result[:model]
  end
end

# ONE CLI parity test
def test_cli_matches_api_output
  api_result = Ace::MyTool.process("input.txt")
  cli_output, status = Open3.capture3("ace-mytool", "input.txt")

  assert status.success?
  assert_equal api_result.output, cli_output.strip
end
```

### E2E Tests (manual tests)

**Purpose**: Verify complete user workflows work in real environments.

**Test these behaviors**:
- Critical user journeys end-to-end
- Tool installation and availability
- Real API interactions (sandboxed)
- Complex multi-step workflows
- Environment-specific behavior
- CLI behavior with real tools

**Use real dependencies**:
- Real filesystem
- Real git operations
- Real subprocess calls
- Real external tools (StandardRB, gitleaks, etc.)

**Example** (TS-format `TC-*.tc.md`):
```markdown
### TC-001: Full Lint Workflow

**Steps:**
1. Create test file with lint issues
2. Run `ace-lint test.rb`
3. Verify issues detected
4. Run `ace-lint test.rb --fix`
5. Verify issues fixed

**Expected:**
- Step 2: Exit code 1, issues listed
- Step 4: Exit code 0, file modified
```

## Quick Reference: Where Does This Test Go?

### Put in Unit Tests
- "Does `parse_config` handle empty YAML?"
- "Does `format_output` escape special characters?"
- "Does `validate_input` reject nil?"
- "Does `calculate_score` handle edge cases?"

### Put in Integration Tests
- "Does the config cascade merge correctly?"
- "Does error in component A propagate to B?"
- "Does the CLI produce same output as API?" (ONE test)
- "Does the workflow orchestrator coordinate correctly?"

### Put in E2E Tests
- "Does the full lint workflow work with real StandardRB?"
- "Can users run `ace-git-commit` from any directory?"
- "Does tool detect when gitleaks is not installed?"
- "Does the complete review workflow produce valid reports?"

## Common Mistakes

### Mistake 1: E2E Tests for Flag Permutations

**Wrong**: 10 E2E tests for each CLI flag combination
```ruby
# Each takes 500ms+ due to subprocess
def test_verbose_flag; Open3.capture3(BIN, "--verbose"); end
def test_quiet_flag; Open3.capture3(BIN, "--quiet"); end
def test_debug_flag; Open3.capture3(BIN, "--debug"); end
```

**Right**: 1 E2E test + unit tests for flags
```ruby
# E2E: verify CLI works
def test_cli_executes_successfully
  _, status = Open3.capture3(BIN, "input.txt")
  assert status.success?
end

# Unit: test flag handling via API
def test_verbose_flag_enables_debug_output
  result = MyTool.process("input.txt", verbose: true)
  assert result.debug_output_enabled?
end
```

### Mistake 2: Real Git in Unit Tests

**Wrong**: Each test creates real git repo (~150ms)
```ruby
def setup
  @repo = create_real_git_repo  # SLOW
end
```

**Right**: Use MockGitRepo for unit tests
```ruby
def setup
  @repo = MockGitRepo.new  # FAST
  @repo.add_commit("abc123", message: "test commit")
end
```

### Mistake 3: Missing Availability Stubs

**Wrong**: Stub `run` but not `available?`
```ruby
Runner.stub(:run, result) do
  subject.lint(file)  # Calls available?() → subprocess!
end
```

**Right**: Stub entire call chain
```ruby
Runner.stub(:available?, true) do
  Runner.stub(:run, result) do
    subject.lint(file)  # Fast
  end
end
```

## Performance Targets

| Test Type | Target | Hard Limit | Action if Exceeded |
|-----------|--------|------------|-------------------|
| Unit (atoms) | <10ms | 50ms | Check for subprocess leaks |
| Unit (molecules) | <50ms | 100ms | Check for unstubbed deps |
| Integration | <500ms | 1s | Move real calls to E2E |
| E2E | <5s | 30s | Split into smaller scenarios |

## See Also

- [Test Performance Guide](guide://test-performance) - Optimization techniques
- [Test Mocking Patterns](guide://test-mocking-patterns) - How to stub correctly
- [E2E Testing Guide](guide://e2e-testing) - E2E test conventions