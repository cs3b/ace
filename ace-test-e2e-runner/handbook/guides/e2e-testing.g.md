---
guide-id: g-e2e-testing
title: E2E Testing Guide
description: Conventions and best practices for agent-executed end-to-end tests
version: "1.3"
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

### Test Execution Directory {#directory-structure}

Test artifacts and reports are created in project-local cache:

```
.cache/ace-test-e2e/
├── {timestamp}-{package}-{test-id}/       # Sandbox folder (test artifacts)
│   ├── (git repo, test files, etc.)
│   └── ...
├── {timestamp}-{package}-{test-id}.summary.r.md      # Test results
├── {timestamp}-{package}-{test-id}.experience.r.md   # AX report
├── {timestamp}-{package}-{test-id}.metadata.yml      # Run metadata
└── {suite-timestamp}-final-report.md                 # Suite report (multi-test runs)
```

Examples:
- `.cache/ace-test-e2e/8oig0h-ace-lint-MT-LINT-001/` - Package-specific test sandbox
- `.cache/ace-test-e2e/8oig0h-ace-lint-MT-LINT-001.summary.r.md` - Test results report
- `.cache/ace-test-e2e/8osuw3-final-report.md` - Suite report (all tests in package)

**Benefits:**
- **Project-local** - Artifacts stay with the codebase
- **Already gitignored** - `.cache` is in `.gitignore`
- **Consistent naming** - Uses ace-timestamp for unique IDs
- **Easy debugging** - Inspect artifacts without hunting in `/tmp`
- **Package-scoped** - Directory name includes package for clarity
- **Test ID in name** - Each folder includes the test ID (e.g., MT-LINT-001) for easy identification
- **Reports as siblings** - Report files sit alongside sandbox folders for easy scanning
- **Suite reports** - Multi-test runs generate aggregate summary

**Setup in test scenarios:**
```bash
TIMESTAMP_ID="$(ace-timestamp encode)"
TEST_DIR=".cache/ace-test-e2e/${TIMESTAMP_ID}-{package-name}-{test-id}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
```

**Report Files (as siblings to sandbox folder):**
- `{folder}.summary.r.md` - Structured pass/fail results with details
- `{folder}.experience.r.md` - Friction points, root cause analysis, improvement suggestions
- `{folder}.metadata.yml` - Run context (duration, git branch, tool versions)

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
7. **Cleanup is optional** - Artifacts in `.cache/ace-test-e2e/` are gitignored
8. **Configure cleanup behavior** - Set `cleanup.enabled` in config

### Documentation
9. **Document edge cases** - Note quirks discovered during execution
10. **Keep tests focused** - One scenario per test file
11. **Version prerequisites** - Specify exact tool versions if critical

## Avoiding False Positive Tests

E2E tests are only valuable if they catch real bugs. A false positive test — one that passes but validates nothing real — is worse than no test at all, because it creates false confidence.

### Anti-Patterns

#### 1. Testing Only Happy Path with Correct Syntax

**Problem:** When every test case uses the exact correct command syntax and only tests success paths, the test can't catch argument parsing bugs, missing subcommands, or crash-on-bad-input issues.

**Fix:** Always include error/negative test cases that exercise wrong arguments, missing files, and invalid state. Run error TCs first, before any session or state is created.

```markdown
<!-- BAD: Only happy path -->
### TC-001: Start Workflow
$TOOL create config.yaml   # only correct usage tested

<!-- GOOD: Error paths first -->
### TC-001: Error — Missing Config File
$TOOL create nonexistent.yaml   # expected: exit code 3, clear error message

### TC-002: Error — Status with No Active Session
$TOOL status   # expected: exit code 2, "No active session"
```

#### 2. Hardcoding Internal File Structures

**Problem:** When a test hardcodes paths like `.coworker/sessions/` or `queue.yaml` without verifying these paths are what the tool actually creates, the test passes by checking paths that don't exist — and the agent silently adapts.

**Fix:** Discover paths from CLI output or by scanning the actual cache directory. Include negative assertions for paths that should NOT exist.

```markdown
<!-- BAD: Hardcoded assumption -->
SESSION_DIR="$TEST_DIR/.coworker/sessions/my-session"
[ -f "$SESSION_DIR/queue.yaml" ] && echo "PASS"

<!-- GOOD: Discover from reality, negative assertions -->
SESSION_DIR=$(find "$TEST_DIR/.cache/tool-name" -maxdepth 1 -mindepth 1 -type d | head -1)
[ -d "$SESSION_DIR" ] && echo "PASS: Session dir found" || echo "FAIL: Not found"
[ ! -f "$SESSION_DIR/queue.yaml" ] && echo "PASS: No queue.yaml (correct)" || echo "FAIL"
```

#### 3. Verification Commands That Silently Adapt

**Problem:** When a verification step uses bare `grep` or `cat` without explicit PASS/FAIL logic, the agent can observe the output and report "it looks correct" even when the assertion didn't match anything.

**Fix:** Use explicit `&& PASS || FAIL` patterns. Every verification must produce an unambiguous result.

```markdown
<!-- BAD: Agent can interpret anything as success -->
grep "status" "$SESSION_DIR/queue.yaml"
# Agent: "I can see the status field, PASS"

<!-- GOOD: Explicit binary outcome -->
grep -q "status: done" "$FILE" && echo "PASS: Status is done" || echo "FAIL: Status is not done"
```

#### 4. Testing Commands in Isolation from User Journey

**Problem:** Testing each command independently (create, then status, then report) without maintaining state between them means the test doesn't catch bugs that only appear during sequential workflow use.

**Fix:** Structure TCs as a sequential workflow where each TC depends on the state left by the previous one. This mirrors how a real user interacts with the tool.

#### 5. Missing Error Path Coverage

**Problem:** Without testing wrong arguments, missing files, no active state, and exit codes, the test validates the "golden path" where everything works — which is the path least likely to have bugs.

**Fix:** Verify specific exit codes for error commands (not just "non-zero"). Check that error messages contain actionable information. Test what happens when required state doesn't exist.

```markdown
<!-- BAD: Only check success -->
$TOOL report file.md
echo "PASS"

<!-- GOOD: Check specific exit codes and messages -->
OUTPUT=$($TOOL report file.md 2>&1)
EXIT_CODE=$?
[ "$EXIT_CODE" -eq 2 ] && echo "PASS: Exit code 2" || echo "FAIL: Expected 2, got $EXIT_CODE"
echo "$OUTPUT" | grep -qi "no active session" && echo "PASS" || echo "FAIL: Wrong error message"
```

### Reviewer Checklist for E2E Tests

Before approving a new or updated E2E test, verify:

- [ ] At least one error/negative TC is present (wrong args, missing files, invalid state)
- [ ] File paths are discovered at runtime, not hardcoded from assumptions
- [ ] Every verification step produces explicit PASS/FAIL output
- [ ] TCs follow a real user workflow sequence (not isolated commands)
- [ ] Exit codes are checked for error commands (specific codes, not just non-zero)
- [ ] Negative assertions exist (files/directories that should NOT exist are verified absent)

## Environment Isolation for Taskflow-Aware Tests

When E2E tests create isolated git repositories and need to use `ace-taskflow`, `ace-git-worktree`, or other tools that rely on `PROJECT_ROOT_PATH`:

### The Problem

Tools like `ace-taskflow` use `ProjectRootFinder` to locate the project root. By default, this traverses up from the current directory looking for markers (`.git`, `Gemfile`, etc.). In an isolated test repo, this can incorrectly find the **main project** instead of the test repo.

### The Solution

Export `PROJECT_ROOT_PATH` after creating the isolated repo:

```bash
# After creating isolated repo and its structure
export PROJECT_ROOT_PATH="$REPO_DIR"

# Now ace-* commands will use the isolated repo as project root
ace-taskflow task 001  # Looks in $REPO_DIR/.ace-taskflow/
ace-git-worktree create --task 001  # Uses isolated taskflow
```

### When to Use

Set `PROJECT_ROOT_PATH` when your test:

1. Creates an isolated git repository
2. Sets up `.ace-taskflow/` structure in that repo
3. Runs `ace-*` commands that need to find tasks or project metadata

### Placement

Add the export **after** creating the test repo structure but **before** running `ace-*` commands:

```bash
# Environment Setup
REPO_DIR="$TEST_DIR/test-repo"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"
git init --quiet .

# Test Data - create taskflow structure
mkdir -p .ace-taskflow/v.test/tasks/001-feature
# ... create task files ...
git add .ace-taskflow/
git commit -m "Add taskflow structure" --quiet

# IMPORTANT: Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$REPO_DIR"

# Test Cases can now use ace-* commands
ace-git-worktree create --task 001  # Uses isolated repo
```
