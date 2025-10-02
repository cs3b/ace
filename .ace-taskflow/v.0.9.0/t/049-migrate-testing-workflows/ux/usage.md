# Testing Workflows Usage Guide

## Overview

This migration provides comprehensive testing automation through both Claude Code commands and ace-taskflow CLI tools. The system supports:

- **Fix Tests** - Automatically identify and fix failing tests
- **Create Test Cases** - Generate comprehensive test cases for features
- **Improve Coverage** - Identify and test uncovered code paths
- **Fix Linting** - Address code quality issues from linter output

**IMPORTANT DISTINCTION:**
- **Claude Commands** (`/ace:fix-tests`) - Run ONLY from within Claude Code/agents
- **CLI Tools** (`ace-taskflow test fix`) - Run from bash terminal

## Command Types

### Claude Code Commands (Agent/Claude Only)

These commands run within Claude Code and are NOT executable from bash:

```
/ace:fix-tests              # Fix failing tests workflow
/ace:create-test-cases      # Create test cases workflow
/ace:improve-code-coverage  # Improve coverage workflow
/ace:fix-linting-issue-from # Fix linting issues workflow
```

**How they work:**
- Invoked via Task tool or slash command in Claude Code
- Execute via: `ace-nav wfi://[workflow-name]`
- Full AI-assisted workflow execution

### Bash CLI Commands (Terminal Only)

These commands run from your terminal/shell:

```bash
ace-taskflow test fix [options]      # Fix failing tests
ace-taskflow test create [options]   # Create test cases
ace-taskflow test coverage [options] # Improve coverage
ace-taskflow test lint [options]     # Fix linting issues
```

**How they work:**
- Direct bash execution
- Delegates to workflows via `ace-nav wfi://`
- Can be used in scripts and CI/CD

## Usage Scenarios

### Scenario 1: Fix Failing Tests (Claude Code)

**Goal:** Fix all failing tests in the test suite using AI assistance

**Steps:**
1. In Claude Code, run: `/ace:fix-tests`
2. Claude analyzes test failures
3. AI identifies root causes and implements fixes
4. Validates fixes by re-running tests

**Expected Output:**
- Fixed test files
- Test run results showing passes
- Explanation of fixes applied

### Scenario 2: Fix Failing Tests (Bash CLI)

**Goal:** Fix tests from command line or CI/CD pipeline

**Steps:**
```bash
# Run test fix workflow
ace-taskflow test fix

# Fix specific test file
ace-taskflow test fix --path spec/models/user_spec.rb

# Fix tests matching pattern
ace-taskflow test fix --pattern "Authentication"
```

**Expected Output:**
- Test failures identified and fixed
- Test execution report
- Exit code 0 on success

### Scenario 3: Create Test Cases for New Feature

**Goal:** Generate comprehensive test cases for authentication feature

**Claude Code:**
```
/ace:create-test-cases --target lib/auth/authenticator.rb --type unit
```

**Bash CLI:**
```bash
ace-taskflow test create --target lib/auth/authenticator.rb --type unit
```

**Expected Output:**
- Test case document with scenarios
- Happy path tests
- Edge cases and error conditions
- Test implementation examples

### Scenario 4: Improve Code Coverage

**Goal:** Identify and test uncovered code paths

**Claude Code:**
```
/ace:improve-code-coverage --threshold 80 --path lib/services
```

**Bash CLI:**
```bash
ace-taskflow test coverage --threshold 80 --path lib/services
```

**Expected Output:**
- Coverage analysis report
- New tests for uncovered code
- Updated coverage metrics

### Scenario 5: Fix Linting Issues

**Goal:** Fix code quality issues from linter output

**Claude Code:**
```
/ace:fix-linting-issue-from --from .lint-errors.md
```

**Bash CLI:**
```bash
ace-taskflow test lint --from .lint-errors.md
```

**Expected Output:**
- Fixed source files
- Linting validation results
- Remaining issues report

## Command Reference

### `ace-taskflow test fix`

**Purpose:** Systematically fix failing automated tests

**Syntax:**
```bash
ace-taskflow test fix [--path <test-file>] [--pattern <test-pattern>]
```

**Parameters:**
- `--path <test-file>` - Fix specific test file (optional)
- `--pattern <test-pattern>` - Fix tests matching pattern (optional)

**Delegates to:** `ace-nav wfi://fix-tests`

**Examples:**
```bash
# Fix all failing tests
ace-taskflow test fix

# Fix specific test file
ace-taskflow test fix --path spec/models/user_spec.rb

# Fix tests with pattern
ace-taskflow test fix --pattern "UserAuthentication"
```

### `ace-taskflow test create`

**Purpose:** Generate structured test cases for features

**Syntax:**
```bash
ace-taskflow test create --target <code-file> [--type <unit|integration|e2e>]
```

**Parameters:**
- `--target <code-file>` - Target code file (required)
- `--type <test-type>` - Test type: unit, integration, e2e (optional)

**Delegates to:** `ace-nav wfi://create-test-cases`

**Examples:**
```bash
# Create unit tests
ace-taskflow test create --target lib/services/user_service.rb --type unit

# Create integration tests
ace-taskflow test create --target app/controllers/api/users_controller.rb --type integration
```

### `ace-taskflow test coverage`

**Purpose:** Improve code coverage by testing uncovered paths

**Syntax:**
```bash
ace-taskflow test coverage [--threshold <percentage>] [--path <directory>]
```

**Parameters:**
- `--threshold <percentage>` - Target coverage percentage (optional)
- `--path <directory>` - Directory to analyze (optional)

**Delegates to:** `ace-nav wfi://improve-code-coverage`

**Examples:**
```bash
# Improve overall coverage
ace-taskflow test coverage

# Target 90% coverage in services
ace-taskflow test coverage --threshold 90 --path lib/services

# Analyze specific directory
ace-taskflow test coverage --path app/models
```

### `ace-taskflow test lint`

**Purpose:** Fix linting issues from linter output file

**Syntax:**
```bash
ace-taskflow test lint --from <linter-output-file>
```

**Parameters:**
- `--from <linter-output-file>` - Linter output file (required)

**Delegates to:** `ace-nav wfi://fix-linting-issue-from`

**Examples:**
```bash
# Fix issues from error file
ace-taskflow test lint --from .lint-errors.md

# Fix StandardRB issues
ace-taskflow test lint --from standardrb-output.md
```

## Claude Code vs CLI Tools

### When to Use Claude Commands

Use Claude Code commands (`/ace:*`) when:
- You want AI-assisted workflow execution
- You need intelligent analysis and decision-making
- You're working interactively in Claude Code
- You want contextual explanations of fixes

### When to Use CLI Tools

Use CLI tools (`ace-taskflow test *`) when:
- Automating in scripts or CI/CD pipelines
- Running from terminal/shell
- Batch processing multiple files
- Integrating with other command-line tools

### Command Execution Context

**Claude Commands:**
- Execute within Claude Code environment
- Access to all Claude tools (Read, Write, Edit, Bash, etc.)
- AI analyzes context and makes intelligent decisions
- Interactive workflow with explanations

**CLI Tools:**
- Execute in bash/shell environment
- Delegate to same workflows via ace-nav
- Deterministic execution
- Scriptable and automatable

## Tips and Best Practices

### Test Fixing
- Run full test suite first to identify all failures
- Fix tests iteratively using `--pattern` for related tests
- Validate fixes don't break other tests
- Understand root cause before applying fixes

### Test Case Creation
- Review generated test cases for completeness
- Ensure tests cover happy path, edge cases, and errors
- Follow project testing conventions
- Use appropriate test type (unit vs integration vs e2e)

### Coverage Improvement
- Use coverage as attention indicator, not just percentage target
- Focus on meaningful test scenarios
- Prioritize business logic and critical paths
- Test error conditions and edge cases

### Linting Fixes
- Review linter output before fixing
- Understand why rules are violated
- Ensure fixes don't break functionality
- Run linter again to verify fixes

## Migration Notes

### Legacy vs New Commands

**Old (dev-handbook):**
- Workflows in `dev-handbook/workflow-instructions/`
- No direct CLI integration
- Manual workflow invocation

**New (ace-taskflow):**
- Workflows in `ace-taskflow/handbook/workflow-instructions/`
- Dual access: Claude commands AND CLI tools
- wfi:// protocol integration
- Clear separation: Claude-only vs bash-runnable

### Key Differences

1. **Command Context:**
   - Legacy: Mixed usage contexts
   - New: **Clear distinction between Claude commands and CLI tools**

2. **Discoverability:**
   - Legacy: Manual file navigation
   - New: `ace-nav wfi://` protocol for workflow discovery

3. **Integration:**
   - Legacy: Standalone workflows
   - New: Integrated with ace-taskflow CLI and Claude Code

### Transition Guidance

1. **For Claude Code Users:**
   - Use `/ace:fix-tests` instead of manually invoking workflow files
   - Commands are agent/Claude-only, not bash commands

2. **For CLI Users:**
   - Use `ace-taskflow test <command>` for bash automation
   - These are bash commands, not Claude commands

3. **For Scripters:**
   - Integrate `ace-taskflow test *` commands in CI/CD
   - Workflows remain the same, just different invocation methods

## Troubleshooting

### Command Not Found

**Symptom:** `ace-taskflow: command not found`

**Solution:**
```bash
# Install ace-taskflow gem
gem install ace-taskflow

# Or use bundler
bundle exec ace-taskflow test fix
```

### Workflow Not Discoverable

**Symptom:** `ace-nav: workflow not found`

**Solution:**
```bash
# Verify workflow exists
ace-nav wfi://fix-tests --verify

# List available workflows
ace-nav 'wfi://*test*' --list
```

### Claude Command Fails

**Symptom:** Claude command doesn't execute

**Solution:**
- Ensure you're in Claude Code (not bash terminal)
- Use slash command: `/ace:fix-tests`
- Or Task tool: `@fix-tests` (if agent exposed)

### Permission Errors

**Symptom:** Cannot modify test files

**Solution:**
```bash
# Check file permissions
ls -la spec/

# Fix permissions if needed
chmod u+w spec/**/*_spec.rb
```

## Examples in Context

### CI/CD Pipeline Integration

```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
      - name: Install dependencies
        run: bundle install
      - name: Run tests
        run: bundle exec rspec
      - name: Fix failing tests (if any)
        if: failure()
        run: bundle exec ace-taskflow test fix
      - name: Re-run tests
        run: bundle exec rspec
```

### Shell Script Automation

```bash
#!/bin/bash
# fix-all-tests.sh

echo "Running test suite..."
bundle exec rspec

if [ $? -ne 0 ]; then
  echo "Tests failed. Attempting automatic fixes..."
  ace-taskflow test fix

  echo "Re-running tests after fixes..."
  bundle exec rspec
fi
```

### Claude Code Workflow

```
User: The test suite has 5 failures in the authentication module

Claude: I'll fix these test failures systematically.
        /ace:fix-tests

        [Workflow executes]

        I've fixed 5 test failures:
        - Updated authentication token validation (2 tests)
        - Fixed session timeout handling (2 tests)
        - Corrected password encryption test (1 test)

        All tests now pass ✓
```
