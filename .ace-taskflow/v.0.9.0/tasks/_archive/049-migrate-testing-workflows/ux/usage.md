# Testing Workflows Usage Guide

## Overview

This migration provides comprehensive testing automation through Claude Code commands. The system supports:

- **Fix Tests** - Automatically identify and fix failing tests
- **Create Test Cases** - Generate comprehensive test cases for features
- **Improve Coverage** - Identify and test uncovered code paths

**IMPORTANT:** These are Claude Code commands (thin wrappers to workflows), **NOT** bash CLI tools.

## Command Type

### Claude Code Commands (Agent/Claude Only)

These commands run within Claude Code and are **NOT executable from bash**:

```
/ace:fix-tests              # Fix failing tests workflow
/ace:create-test-cases      # Create test cases workflow
/ace:improve-code-coverage  # Improve coverage workflow
```

**How they work:**
- Invoked via slash command in Claude Code
- Execute via: `ace-nav wfi://[workflow-name]`
- Thin wrappers that delegate to self-contained workflows
- Full AI-assisted workflow execution

## Usage Scenarios

### Scenario 1: Fix Failing Tests

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

### Scenario 2: Create Test Cases for New Feature

**Goal:** Generate comprehensive test cases for authentication feature

**Claude Code:**
```
/ace:create-test-cases
```

Then provide context about the target code file when prompted.

**Expected Output:**
- Test case document with scenarios
- Happy path tests
- Edge cases and error conditions
- Test implementation examples

### Scenario 3: Improve Code Coverage

**Goal:** Identify and test uncovered code paths

**Claude Code:**
```
/ace:improve-code-coverage
```

Then specify the target directory or threshold when prompted.

**Expected Output:**
- Coverage analysis report
- New tests for uncovered code
- Updated coverage metrics

## Command Reference

### `/ace:fix-tests`

**Purpose:** Systematically fix failing automated tests

**Invocation:**
```
/ace:fix-tests
```

**Delegates to:** `ace-nav wfi://fix-tests`

**Process:**
1. Runs test suite to identify failures
2. Analyzes error messages and stack traces
3. Implements fixes based on root cause analysis
4. Re-runs tests to verify fixes

### `/ace:create-test-cases`

**Purpose:** Generate structured test cases for features

**Invocation:**
```
/ace:create-test-cases
```

**Delegates to:** `ace-nav wfi://create-test-cases`

**Process:**
1. Analyzes target code structure and behavior
2. Identifies test scenarios (happy path, edge cases, errors)
3. Generates test case documentation
4. Provides test implementation examples

### `/ace:improve-code-coverage`

**Purpose:** Improve code coverage by testing uncovered paths

**Invocation:**
```
/ace:improve-code-coverage
```

**Delegates to:** `ace-nav wfi://improve-code-coverage`

**Process:**
1. Analyzes current coverage metrics
2. Identifies uncovered code paths
3. Prioritizes coverage improvements
4. Generates tests for uncovered areas

## Tips and Best Practices

### Test Fixing
- Run full test suite first to identify all failures
- Understand root cause before applying fixes
- Validate fixes don't break other tests
- Follow project testing conventions

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

## Migration Notes

### Legacy vs New Commands

**Old (dev-handbook):**
- Workflows in `dev-handbook/workflow-instructions/`
- No direct command integration
- Manual workflow invocation

**New (ace-taskflow):**
- Workflows in `ace-taskflow/handbook/workflow-instructions/`
- Claude commands as thin wrappers
- wfi:// protocol integration
- Workflows are self-contained per ADR-001

### Key Architecture

**Two-Layer Architecture:**

1. **Workflows** (.wf.md files)
   - Self-contained in `ace-taskflow/handbook/workflow-instructions/`
   - Discoverable via `ace-nav wfi://` protocol
   - Complete testing logic and framework detection

2. **Claude Commands** (.claude/commands/ace/)
   - Thin wrapper files invoking workflows
   - **ONLY executable from Claude Code/agents**
   - **NOT runnable from bash command line**

### What's NOT Included

- ❌ **CLI Tools**: No `ace-taskflow test *` bash commands
- ❌ **Linting Workflows**: Migrated to ace-handbook package (task 052)

## Troubleshooting

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
- Verify workflow is discoverable via ace-nav

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

### Claude Code Workflow

```
User: The test suite has 5 failures in the authentication module

Claude: I'll fix these test failures systematically.
        /ace:fix-tests

        [Workflow executes via ace-nav wfi://fix-tests]

        I've analyzed and fixed 5 test failures:
        - Updated authentication token validation (2 tests)
        - Fixed session timeout handling (2 tests)
        - Corrected password encryption test (1 test)

        All tests now pass ✓
```

### Test Case Generation

```
User: Create comprehensive test cases for the UserService class

Claude: I'll generate test cases for UserService.
        /ace:create-test-cases

        [Workflow executes via ace-nav wfi://create-test-cases]

        I've created comprehensive test cases covering:

        Unit Tests:
        - User creation with valid data
        - User validation edge cases
        - Error handling scenarios

        Integration Tests:
        - Database persistence
        - Service layer interactions

        Each test case includes setup, execution, and assertions.
```

### Coverage Improvement

```
User: Our coverage is at 65%, let's improve it

Claude: I'll analyze coverage and generate tests for uncovered paths.
        /ace:improve-code-coverage

        [Workflow executes via ace-nav wfi://improve-code-coverage]

        Coverage analysis complete:

        Uncovered areas identified:
        - UserService#validate_email (lines 45-52)
        - SessionManager#cleanup (lines 78-85)

        I've generated tests for these uncovered paths.
        New coverage: 82% (+17%)
```

## Framework Support

The workflows support multiple testing frameworks with automatic detection:

**Ruby:**
- RSpec (detects via Gemfile, spec/ directory)
- Minitest (detects via Gemfile, test/ directory)

**JavaScript:**
- Jest (detects via package.json)
- Mocha (detects via package.json)
- Jasmine (detects via package.json)

**Python:**
- pytest (detects via requirements.txt)
- unittest (detects via test files)

**Go:**
- testing package (detects via *_test.go files)

The workflows automatically detect the framework and adapt their approach accordingly.
