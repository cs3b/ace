---
guide-id: g-e2e-testing
title: E2E Testing Guide
description: Conventions and best practices for agent-executed end-to-end tests
version: "1.1"
source: ace-test-e2e-runner
---

# E2E Testing Guide

## Overview

E2E (end-to-end) tests are tests that are executed by an AI agent rather than an automated test runner. They are designed for scenarios that are:

- **Too slow** for regular test suites
- **Environment-dependent** requiring specific setup
- **Complex** requiring agent judgment
- **Exploratory** in nature

## When to Use E2E Tests

Use E2E tests when:

1. **Integration with external tools** - Tests that require real tool installations (StandardRB, RuboCop, etc.)
2. **Complex environment setup** - Tests needing specific file structures or configurations
3. **End-to-end validation** - Full workflow testing from CLI to output
4. **Edge cases** - Scenarios that are hard to automate
5. **Slow operations** - Tests taking minutes to run

Do NOT use E2E tests when:

- Unit tests would suffice
- The test can be automated with mocks
- Speed is critical for feedback

## Convention

### Location

Test scenarios are stored in individual packages:

```
{package}/test/e2e/*.mt.md
```

This convention:
- Keeps tests alongside the code they test
- Separates from automated tests (`test/atoms/`, `test/molecules/`, etc.)
- Uses `.mt.md` extension to distinguish from other markdown

### Test Execution Directory

Test artifacts are created in project-local cache:

```
.cache/test-e2e/{timestamp}-{package}/
```

Examples:
- `.cache/test-e2e/8oig0h-ace-lint/` - Package-specific test
- `.cache/test-e2e/8oig0h/` - Project-wide test

**Benefits:**
- **Project-local** - Artifacts stay with the codebase
- **Already gitignored** - `.cache` is in `.gitignore`
- **Consistent naming** - Uses ace-timestamp for unique IDs
- **Easy debugging** - Inspect artifacts without hunting in `/tmp`
- **Package-scoped** - Directory name includes package for clarity

**Setup in test scenarios:**
```bash
TEST_ID="$(ace-timestamp encode)"
TEST_DIR=".cache/test-e2e/${TEST_ID}-{package-name}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
```

### Test ID Format

```
MT-{AREA}-{NNN}
```

- `MT` - Test prefix (legacy: "Manual Test")
- `{AREA}` - Area code (uppercase, e.g., LINT, REVIEW, BUILD)
- `{NNN}` - Three-digit sequential number

Examples:
- `MT-LINT-001` - First lint E2E test
- `MT-REVIEW-015` - Fifteenth review E2E test
- `MT-GIT-003` - Third git E2E test

### Filename Convention

```
MT-{AREA}-{NNN}-{slug}.mt.md
```

The slug should be kebab-case and descriptive:
- `MT-LINT-001-ruby-validator-fallback.mt.md`
- `MT-REVIEW-002-pr-comment-parsing.mt.md`

## Writing Test Scenarios

### Frontmatter

Required fields:
```yaml
---
test-id: MT-LINT-001
title: Ruby Validator Fallback Behavior
area: lint
package: ace-lint
priority: high
---
```

Optional fields:
```yaml
duration: ~15min
automation-candidate: false
requires:
  tools: [standardrb, rubocop]
  ruby: ">= 3.0"
last-verified: 2026-01-18
verified-by: claude-opus-4
```

### Structure

1. **Objective** - What the test verifies (1-2 sentences)
2. **Prerequisites** - What must be in place before testing
3. **Environment Setup** - Commands to prepare the test environment
4. **Test Data** - Files and data needed for the test
5. **Test Cases** - Individual test cases (TC-NNN)
6. **Cleanup** - Commands to clean up after testing
7. **Success Criteria** - Checklist for overall success
8. **Observations** - Space for notes during execution

### Test Cases

Each test case should:
- Have a clear objective
- Include step-by-step commands
- Define expected results precisely
- Provide space for actual results

Example:
```markdown
### TC-001: StandardRB Available - Valid File

**Objective:** Verify that valid Ruby code passes linting when StandardRB is available.

**Steps:**
1. Create a valid Ruby file
   ```bash
   cat > "$TEST_DIR/valid.rb" << 'EOF'
   # frozen_string_literal: true

   class Example
     def hello
       "Hello, World!"
     end
   end
   EOF
   ```
2. Run linter
   ```bash
   ace-lint lint "$TEST_DIR/valid.rb"
   ```

**Expected:**
- Exit code: 0
- Output contains: "no issues"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail
```

## Executing Tests

### Invocation

Use the skill:
```
/ace:run-e2e-test <package> <test-id>
```

Or use the workflow directly:
```
ace-bundle wfi://run-e2e-test
```

### Agent Responsibilities

When executing an E2E test, the agent should:

1. **Verify prerequisites** before starting
2. **Execute steps exactly** as documented
3. **Record actual results** for comparison
4. **Report failures immediately** with details
5. **Clean up resources** after testing
6. **Update verification metadata** if tests pass

### Recording Results

Fill in actual results during execution:
```markdown
**Expected:**
- Exit code: 0
- Output contains: "no issues"

**Actual:**
- Exit code: 0
- Output: "Linting complete: 0 issues found in 1 file"

**Status:** [x] Pass / [ ] Fail
```

## Discovery

### Find All E2E Tests

```bash
find . -name "*.mt.md" -path "*/test/e2e/*"
```

### Find Tests by Area

```bash
find . -name "MT-LINT-*.mt.md" -path "*/test/e2e/*"
```

### Find Tests in Package

```bash
find {package}/test/e2e -name "*.mt.md"
```

## Maintenance

### Verification Tracking

Update frontmatter after successful execution:
```yaml
last-verified: 2026-01-18
verified-by: claude-opus-4
```

### Outdated Tests

Consider a test outdated if:
- `last-verified` is more than 30 days old
- Package had significant changes since verification
- Prerequisites changed

### Archiving Tests

Move obsolete tests to:
```
{package}/test/e2e/archive/
```

## Integration with ace-test

E2E tests are automatically excluded from `ace-test` because:
- They use `.mt.md` extension (not `*_test.rb`)
- They're in `test/e2e/` directory

The `ace-test` tool only runs files matching `*_test.rb`.

## Best Practices

### Environment Setup
1. **Capture PROJECT_ROOT first** - Before any `cd` operations, capture the project root:
   ```bash
   PROJECT_ROOT="$(pwd)"
   ```
2. **Use absolute paths** - Reference project binaries as `$PROJECT_ROOT/bin/ace-{tool}`
3. **Be explicit** - Don't assume environment state

### Tool Version Managers (mise, asdf, rbenv)
4. **Avoid PATH manipulation for tool hiding** - Shims bypass PATH changes
5. **Use binary renaming instead** - For testing fallback behavior:
   ```bash
   TOOL_PATH="$(mise which standardrb)"
   mv "$TOOL_PATH" "${TOOL_PATH}.disabled"
   # ... run test ...
   mv "${TOOL_PATH}.disabled" "$TOOL_PATH"
   ```

### Test Data & Cleanup
6. **Use heredocs for test files** - Ensures reproducibility
7. **Cleanup is optional** - Artifacts in `.cache/test-e2e/` are gitignored
8. **Configure cleanup behavior** - Set `cleanup.enabled` in config

### Documentation
9. **Document edge cases** - Note quirks discovered during execution
10. **Keep tests focused** - One scenario per test file
11. **Version prerequisites** - Specify exact tool versions if critical
