---
name: test/optimize
description: Semi-automated test performance optimization workflow
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, Bash(ace-test:*), Bash(ace-search:*)
argument-hint: 'package name'
doc-type: workflow
purpose: Systematically improve test suite performance
params:
  package: Package to optimize (required)
  target_time: Target suite time in seconds (optional)
tools:
  - ace-test
  - ace-search
embed_document_source: false
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Optimize Tests Workflow

## Purpose

Systematically optimize test performance by:
1. Profiling to find slow tests
2. Identifying root causes
3. Applying appropriate fixes
4. Migrating tests to correct layers
5. Verifying improvements

## When to Use

- Test suite exceeds time budget
- After `/as-test-verify-suite` identifies issues
- Before major releases
- When developer feedback loop feels slow

## Prerequisites

- Package has existing tests
- `ace-test` available
- Understanding of test layer decision (see guide)

## Workflow Steps

### Step 1: Establish Baseline

Profile current performance:

```bash
# Run 3 times to account for variance
for i in 1 2 3; do
  ace-test <package> --profile 10 2>&1 | tee profile-$i.txt
done

# Extract consistent slow tests
cat profile-*.txt | grep -E "^\s+[0-9]+\." | sort | uniq -c | sort -rn
```

Record baseline:
- Total suite time: ___s
- Number of tests: ___
- Slowest test: ___ (___ms)
- Tests >100ms: ___

### Step 2: Categorize Slow Tests

For each slow test, identify the cause:

| Cause | Symptoms | Fix |
|-------|----------|-----|
| Subprocess spawn | `Open3`, `system()` in stack | Stub availability + execution |
| Real git operations | `git init`, `git commit` | Use MockGitRepo |
| Network calls | HTTP requests | WebMock stubs |
| Filesystem I/O | Large file operations | Use temp files, mock content |
| Sleep statements | Retry logic with delays | Stub `Kernel.sleep` |
| Zombie mocks | Stub exists but test still slow | Update stub target |
| Wrong layer | E2E test in unit folder | Move to e2e/ |

```bash
# Search for subprocess calls in test
ace-search "Open3\|system\(" <package>/test/

# Search for real git operations
ace-search "git init\|`git " <package>/test/

# Search for sleep
ace-search "sleep" <package>/test/
```

### Step 3: Apply Quick Wins

#### 3a: Add Missing Availability Stubs

Pattern found in many optimizations:

```ruby
# BEFORE: Stubs run but not available?
Runner.stub(:run, mock_result) do
  subject.lint(file)  # Calls available?() first!
end

# AFTER: Stub entire chain
Runner.stub(:available?, true) do
  Runner.stub(:run, mock_result) do
    subject.lint(file)
  end
end
```

#### 3b: Stub Sleep in Retry Tests

```ruby
# Add to test or helper
def with_stubbed_sleep
  Kernel.stub :sleep, nil do
    yield
  end
end

# Use in tests
def test_retry_logic
  with_stubbed_sleep do
    result = subject.retry_operation(max: 3, delay: 1.0)
  end
end
```

#### 3c: Replace Real Git with MockGitRepo

```ruby
# BEFORE: Real git (~150ms per init)
def setup
  @repo_path = Dir.mktmpdir
  system("git", "-C", @repo_path, "init")
  # ...
end

# AFTER: MockGitRepo (~0ms)
def setup
  @repo = MockGitRepo.new
  @repo.add_commit("abc123", message: "test", files: ["test.rb"])
end
```

### Step 4: Create Composite Helpers

When multiple tests need the same stubs, create a helper:

```ruby
# In test_helper.rb
module OptimizationHelpers
  def with_mock_lint_context(validators: [:standardrb])
    # Stub all validators as available
    validators.each do |v|
      runner = Ace::Lint::Atoms.const_get("#{v.to_s.capitalize}Runner")
      runner.stub(:available?, true) do
        runner.stub(:run, mock_lint_result) do
          yield
        end
      end
    end
  end

  def mock_lint_result
    Ace::Lint::Models::LintResult.new(
      issues: [],
      exit_code: 0,
      output: "No issues found"
    )
  end
end
```

### Step 5: Migrate E2E Tests

For tests that need real subprocess/git/filesystem:

#### 5a: Identify E2E Candidates

Tests that should move to E2E:
- CLI output format validation
- Tool availability checking
- Full workflow with real dependencies
- Tests that are still slow after stubbing

#### 5b: Create E2E Test Directory

```bash
# Create E2E test scenario directory
mkdir -p <package>/test/e2e/TS-<AREA>-00N-<slug>
```

**scenario.yml:**
```yaml
test-id: TS-<AREA>-00N
title: <Descriptive Title>
area: <area>
package: <package>
priority: medium
requires:
  tools: [<required-tools>]

setup:
  - git-init
  - copy-fixtures
  - env:
      PROJECT_ROOT_PATH: "."
```

**TC-001-<scenario>.tc.md:**
```markdown
---
tc-id: TC-001
title: <Scenario>
---

## Objective

Validate <what this tests> with real dependencies.

## Steps

1. <step>
   ```bash
   <command>
   ```

2. Verify result
   ```bash
   [ <assertion> ] && echo "PASS: <description>" || echo "FAIL: <description>"
   ```

## Expected

- <assertion>
```

#### 5c: Delete or Convert Original Test

```ruby
# Option 1: Delete if fully covered by E2E
# Just remove the test method

# Option 2: Convert to mocked version
def test_cli_output_format
  # Mock subprocess, test via API
  mock_result = { output: "Expected format" }
  Runner.stub(:execute, mock_result) do
    result = subject.generate_output
    assert_equal "Expected format", result
  end
end
```

### Step 6: Pre-warm Caches

If package has caching:

```ruby
# In test_helper.rb, at load time (not in setup)
# Pre-warm availability caches
Ace::Package::ValidatorRegistry.available?(:tool_a)
Ace::Package::ValidatorRegistry.available?(:tool_b)
```

### Step 7: Verify Improvements

Re-profile after changes:

```bash
ace-test <package> --profile 10
```

Compare to baseline:
- Total suite time: ___s -> ___s (___% improvement)
- Slowest test: ___ms -> ___ms
- Tests >100ms: ___ -> ___

### Step 8: Document Changes

Create retro or update test helper comments:

```ruby
# test_helper.rb
#
# Performance Optimizations Applied:
# - Pre-warm validator caches at startup (prevents subprocess on first access)
# - with_mock_lint_context helper stubs all validators
# - Real CLI tests moved to test/e2e/
#
# See: .ace-taskflow/.../retros/<timestamp>-<package>-test-optimization.md
```

## Common Optimization Patterns

### Pattern: Subprocess Stubbing

```ruby
def with_stubbed_subprocess(output: "", status: 0)
  mock_status = Object.new
  mock_status.define_singleton_method(:success?) { status == 0 }
  mock_status.define_singleton_method(:exitstatus) { status }

  Open3.stub :capture3, [output, "", mock_status] do
    yield
  end
end
```

### Pattern: Git Stubbing

```ruby
def with_mock_git_repo
  repo = MockGitRepo.new
  yield repo
end

def with_stubbed_git_status(clean: true)
  Ace::Git::Atoms::StatusChecker.stub :clean?, clean do
    yield
  end
end
```

### Pattern: Config Stubbing

```ruby
def with_stubbed_config(config_hash)
  mock_config = Ace::Support::Config::Models::Config.wrap(config_hash)
  Ace::Support::Config.stub :create, ->(*) { mock_config } do
    yield
  end
end
```

### Pattern: LLM Stubbing

```ruby
def with_mock_llm_response(content:)
  mock_response = {
    "choices" => [{ "message" => { "content" => content } }]
  }

  WebMock.stub_request(:post, /api\.anthropic\.com|api\.openai\.com/)
    .to_return(body: mock_response.to_json)

  yield
end
```

## Checklist

- [ ] Baseline established (3 runs)
- [ ] Slow tests categorized by cause
- [ ] Availability stubs added
- [ ] Sleep calls stubbed
- [ ] Real git replaced with mocks
- [ ] Composite helpers created
- [ ] E2E tests migrated
- [ ] Caches pre-warmed
- [ ] Improvements verified
- [ ] Changes documented

## Expected Results

| Before | After | Target |
|--------|-------|--------|
| 30s suite | <10s suite | 70%+ reduction |
| 5 tests >100ms | 0 tests >100ms | Zero violations |
| Flaky timing | Consistent | <10% variance |

## See Also

- [Test Performance Guide](guide://test-performance)
- [Test Layer Decision Guide](guide://test-layer-decision)
- [Test Mocking Patterns Guide](guide://test-mocking-patterns)
- [Verify Test Suite Workflow](wfi://test/verify-suite)
