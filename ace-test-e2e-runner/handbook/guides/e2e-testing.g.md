---
guide-id: g-e2e-testing
title: E2E Testing Guide
description: Conventions and best practices for agent-executed end-to-end tests
version: "1.5"
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

### The E2E Value Gate

Before creating any E2E test case, answer this question:

> **Does this behavior require the full CLI binary, real external tools (StandardRB, gitleaks, etc.), AND real filesystem I/O to test meaningfully?**

If the answer is **no**, the behavior belongs in unit tests (atoms/molecules) or integration tests (organisms), not E2E.

### Behaviors That Require E2E

1. **Real subprocess execution** — Behaviors that depend on actually running external tools (StandardRB, RuboCop, gitleaks) as subprocesses, not stubbed
2. **CLI binary pipeline** — The full path from `bin/ace-{tool}` → argument parsing → execution → stdout/stderr → exit code
3. **Real filesystem discovery** — Config file discovery, project root detection, file globbing that depends on actual directory traversal
4. **Multi-tool orchestration** — Workflows that chain multiple CLI tools or require real tool installation detection
5. **Environment-specific behavior** — Tool version detection, PATH resolution, shim behavior with version managers (mise, rbenv)

### Behaviors That Do NOT Require E2E

Do NOT create E2E test cases for:

- **Output formatting** (verbose/quiet modes, colors, column alignment) — test via unit tests on the formatter
- **Config parsing** (YAML structure, validation, defaults) — test via unit tests on the parser
- **Error message content** (wording, exit code mapping) — test via unit tests on the error handler
- **Data transformations** (report structure, JSON schema) — test via unit tests on the serializer
- **Flag permutations** (--fix, --report, --group combinations) — test 1-2 key flags in E2E, exhaustive permutations in unit tests

**Lesson learned:** In ace-lint, ~60% of E2E TCs (19/31) duplicated coverage already provided by 265 unit tests. After applying this gate, the suite dropped to 9 TCs with no loss of unique coverage.

### Cost and Scope

**Cost per TC:** Each E2E test case requires 1 LLM agent invocation (~$0.05-0.15 in API cost, 30-120 seconds of execution time). A suite of 30 TCs costs $1.50-$4.50 per run; a suite of 9 TCs costs $0.45-$1.35.

**Healthy scenario scope:**
- **2-5 TCs per scenario** — TCs within a scenario share setup (fixtures, git init, env vars). Fewer than 2 suggests the scenario could merge with another; more than 5 suggests splitting.
- **Consolidation rule:** Multiple assertions that share the same CLI invocation and setup belong in ONE TC, not separate TCs. For example, checking `report.json` structure, exit code, and `ok.md` existence after a single `ace-lint lint` call is one TC with multiple verification steps, not three TCs.

**Reference:** ace-lint consolidated from 8 scenarios / 31 TCs to 3 scenarios (5, 2, 2 TCs) — each scenario is a coherent pipeline with shared fixtures.

## Convention

### Location

Test scenarios are stored in individual packages in two formats:

#### MT-Format (Single File)

```
{package}/test/e2e/MT-{AREA}-{NNN}-{slug}.mt.md
```

A single markdown file containing all test cases, setup, and test data inline.

#### TS-Format (Per-TC Directory)

```
{package}/test/e2e/TS-{AREA}-{NNN}-{slug}/
    scenario.yml                    # Scenario metadata + setup config
    TC-001-{slug}.tc.md             # Individual test case files
    TC-002-{slug}.tc.md
    fixtures/                       # Shared fixtures (copied to sandbox)
```

Each test case is a separate `.tc.md` file, with shared fixtures and setup configuration in `scenario.yml`.

#### When to Use Which

- **MT-format**: Simpler scenarios, single file, inline test data, fewer test cases
- **TS-format**: Complex scenarios, per-TC isolation, fixture directories, Ruby-driven sandbox setup

Both conventions:
- Keep tests alongside the code they test
- Separate from automated tests (`test/atoms/`, `test/molecules/`, etc.)
- Are automatically excluded from `ace-test`

### Test Execution Directory {#directory-structure}

Test artifacts and reports are created in project-local cache:

```
.cache/ace-test-e2e/
├── {timestamp}-{short-pkg}-{short-id}/        # Sandbox folder (test artifacts)
│   ├── (git repo, test files, etc.)
│   └── ...
├── {timestamp}-{short-pkg}-{short-id}-reports/  # Reports subfolder
│   ├── summary.r.md
│   ├── experience.r.md
│   └── metadata.yml
└── {suite-timestamp}-final-report.md          # Suite report (multi-test runs)
```

**Naming convention (SHORT format):**
- `{short-pkg}` = package name without `ace-` prefix (e.g., `lint`, `git-commit`)
- `{short-id}` = lowercase test number (e.g., `mt001`, `ts001`)

Examples:
- `.cache/ace-test-e2e/8oig0h-lint-mt001/` - Package-specific test sandbox
- `.cache/ace-test-e2e/8oig0h-lint-mt001-reports/summary.r.md` - Test results report
- `.cache/ace-test-e2e/8osuw3-final-report.md` - Suite report (all tests in package)

**Benefits:**
- **Project-local** - Artifacts stay with the codebase
- **Already gitignored** - `.cache` is in `.gitignore`
- **Consistent naming** - Uses ace-timestamp for unique IDs
- **Easy debugging** - Inspect artifacts without hunting in `/tmp`
- **Package-scoped** - Directory name includes package for clarity
- **Test ID in name** - Each folder includes the test ID (e.g., MT-LINT-001) for easy identification
- **Reports in subfolder** - Report files go in a `-reports/` subfolder for organization
- **Suite reports** - Multi-test runs generate aggregate summary

**Setup in test scenarios:**
```bash
TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="{short-pkg}"    # e.g., git-commit (package name without ace- prefix)
SHORT_ID="{short-id}"      # e.g., mt001 (lowercase test number)
TEST_DIR=".cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
```

**Report Files (in reports subfolder):**
- `{folder}-reports/summary.r.md` - Structured pass/fail results with details
- `{folder}-reports/experience.r.md` - Friction points, root cause analysis, improvement suggestions
- `{folder}-reports/metadata.yml` - Run context (duration, git branch, tool versions)

### Test ID Format

Two formats are supported:

```
MT-{AREA}-{NNN}     # Single-file format
TS-{AREA}-{NNN}     # Per-TC directory format
```

- `MT` / `TS` - Format prefix (MT = single file, TS = per-TC directory)
- `{AREA}` - Area code (uppercase, e.g., LINT, REVIEW, BUILD)
- `{NNN}` - Three-digit sequential number

Examples:
- `MT-LINT-001` - Single-file lint test
- `TS-LINT-001` - Per-TC directory lint test
- `MT-REVIEW-015` - Fifteenth review E2E test

### Naming Convention

**MT-format** (single file):
```
MT-{AREA}-{NNN}-{slug}.mt.md
```

**TS-format** (directory):
```
TS-{AREA}-{NNN}-{slug}/
```

The slug should be kebab-case and descriptive:
- `MT-LINT-001-ruby-validator-fallback.mt.md`
- `TS-LINT-002-json-report-generation/`
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

## TS-Format Scenarios

TS-format scenarios split test definitions across multiple files in a directory structure, enabling per-TC isolation and Ruby-driven sandbox setup.

### scenario.yml

The `scenario.yml` file defines metadata and setup directives:

```yaml
test-id: TS-LINT-001
title: Ruby Validator Fallback Behavior
area: lint
package: ace-lint
priority: high
requires:
  tools: [standardrb, rubocop]
  ruby: ">= 3.0"

setup:
  - copy-fixtures
  - env:
      PROJECT_ROOT_PATH: "."
```

**Setup directives:**
- `copy-fixtures` — Copies the `fixtures/` directory contents into the sandbox
- `git-init` — Initializes a git repository in the sandbox
- `env:` — Sets environment variables for test execution (key-value mappings)

### Test Case Files (.tc.md)

Each test case is a separate file named `TC-NNN-{slug}.tc.md`:

```yaml
---
tc-id: TC-001
title: StandardRB Available - Valid File
---
```

The body follows the same structure as MT-format test cases:
- **Objective** — What this specific test case verifies
- **Steps** — Commands to execute
- **Expected** — Expected outcomes

### fixtures/ Directory

Shared test data files placed in `fixtures/` are copied into the sandbox via the `copy-fixtures` setup directive. This avoids inline heredocs for complex test data.

## Executing Tests

### Invocation

Use the skill to run a single test:
```
/ace:run-e2e-test <package> <test-id>
```

The skill routes to the appropriate workflow:
- Without `--sandbox` → `run-e2e-test.wf.md` (full workflow: locate, setup, execute)
- With `--sandbox` → `execute-e2e-test.wf.md` (focused execution in pre-populated sandbox)

### Test Case Filtering

Run specific test cases within a scenario:
```
/ace:run-e2e-test <package> <test-id> TC-001,TC-003
```

### Running Multiple Tests (Parallel)

Use the multi-test skill to run all tests in a package:
```
/ace:run-e2e-tests <package>
/ace:run-e2e-tests <package> --sequential
/ace:run-e2e-tests --all
```

This uses subagents (Task tool) to execute tests in parallel, with results aggregated into a suite report.

### Sandbox Pre-Setup Flow

For TS-format scenarios, the Ruby `SetupExecutor` can pre-populate the sandbox before the agent executes test cases:

1. CLI invokes `SetupExecutor` with the scenario's setup directives
2. `SetupExecutor` creates the sandbox, copies fixtures, initializes git, sets env vars
3. The skill is invoked with `--sandbox <path>` pointing to the pre-populated directory
4. The agent runs `execute-e2e-test.wf.md` which skips setup and goes straight to execution

### Setup Only (No Execution)

To prepare a sandbox without running tests:
```bash
ace-test-e2e setup <package> <test-id>
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
# MT-format tests
find . -name "*.mt.md" -path "*/test/e2e/*"

# TS-format tests
find . -name "scenario.yml" -path "*/test/e2e/*"
```

### Find Tests by Area

```bash
find . -path "*/test/e2e/*LINT*" \( -name "*.mt.md" -o -name "scenario.yml" \)
```

### Find Tests in Package

```bash
find {package}/test/e2e -name "*.mt.md" -o -name "scenario.yml"
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

### Coverage Overlap Review

Periodically review E2E suites for overlap with unit test coverage, especially after:
- Unit test coverage grows significantly (new test files, new assertion batches)
- Package undergoes refactoring that adds mocking-friendly abstractions
- E2E suite execution time or cost exceeds targets

**Review process:**
1. List all E2E TCs and the specific behavior each verifies
2. Search unit tests (atoms/molecules/organisms) for assertions covering the same behavior
3. For each overlapping TC, ask: "Does this TC test something the unit test CAN'T — real binary, real subprocess, real filesystem?"
4. Archive TCs that fail the E2E Value Gate

See also: `/ace:review-e2e-tests` workflow, which includes overlap analysis.

### Archiving Tests

Move obsolete tests to:
```
{package}/test/e2e/archive/
```

## Integration with ace-test

E2E tests are automatically excluded from `ace-test` because:
- MT-format uses `.mt.md` extension (not `*_test.rb`)
- TS-format uses `.tc.md` / `scenario.yml` (not `*_test.rb`)
- Both are in `test/e2e/` directory

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
4. **Never rename or move system binaries** - This affects the entire system and other parallel tests. Binary renaming caused a production incident (2026-02-12) where `/opt/homebrew` was destroyed during parallel E2E test execution.
5. **For testing fallback behavior** - Use environment variable overrides or mock the tool path in test setup. Do not manipulate binaries installed by mise, brew, or system package managers.

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
