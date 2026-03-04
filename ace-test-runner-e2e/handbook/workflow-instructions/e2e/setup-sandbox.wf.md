---
name: e2e/setup-sandbox
description: Set up safe, isolated E2E test environment with external API handling
allowed-tools: Read, Write, Bash
argument-hint: 'package and test-id'
doc-type: workflow
purpose: E2E test environment setup workflow
params:
  package: Package being tested
  test_id: E2E test ID (e.g., TS-LINT-001)
tools:
  - Bash
  - Read
  - Write
embed_document_source: false
update:
  frequency: on-change
  last-updated: '2026-02-01'
---

# E2E Sandbox Setup Workflow

## Purpose

Set up a safe, isolated environment for E2E tests that:
- Isolates from main project (no pollution)
- Handles external APIs safely (test tokens, limited scope)
- Ensures cleanup on success AND failure
- Captures outputs for debugging

Setup is owned by scenario configuration and fixtures. Runner TC files must not re-implement environment bootstrapping.

## When to Use

- Before running E2E tests that touch filesystem
- When E2E test needs git repository
- When E2E test calls external APIs
- When test creates resources that need cleanup

**Note:** For CLI pipeline runs (`ace-test-e2e`), `SetupExecutor` handles sandbox creation automatically using the 6-phase deterministic pipeline. This workflow is the reference for what `SetupExecutor` implements and for manual/agent-driven runs via `/ace-e2e-run`.

## Prerequisites

- `ace-b36ts` available for unique IDs
- Required tools installed for the specific test
- Test tokens available (if external APIs needed)

## Workflow Steps

### Step 1: Create Isolated Directory

```bash
# Generate unique timestamp ID
TIMESTAMP_ID="$(ace-b36ts encode)"

# Extract short names from test metadata
# Note: params are lowercase (package, test_id) - use them directly
SHORT_PKG="${package#ace-}"  # Remove ace- prefix
SHORT_ID="$(echo "$test_id" | tr '[:upper:]' '[:lower:]' | tr '-' '')"  # ts001

# Create sandbox and reports directories
TEST_DIR=".ace-local/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
REPORTS_DIR="${TEST_DIR}-reports"

mkdir -p "$TEST_DIR"
mkdir -p "$REPORTS_DIR"

# Record for cleanup
echo "$TEST_DIR" > "$REPORTS_DIR/sandbox-path.txt"
echo "$(date -Iseconds)" > "$REPORTS_DIR/start-time.txt"
```

### Step 2: Isolate Environment

```bash
cd "$TEST_DIR"

# Critical: Isolate from main project
export PROJECT_ROOT_PATH="$TEST_DIR"
export ACE_TEST_MODE=true
export ACE_CONFIG_PATH="$TEST_DIR/.ace"

# Record environment for debugging
env | grep -E "^(PROJECT|ACE|PATH)" > "$REPORTS_DIR/environment.txt"
```

### Step 3: Initialize Git (if needed)

```bash
if [ "$NEEDS_GIT" = "true" ]; then
  git init --quiet .
  git config user.email "test@example.com"
  git config user.name "E2E Test"

  # Verify isolation
  if ! PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "ERROR: Failed to get git root (git not initialized properly)"
    exit 1
  fi
  if [ "$PROJECT_ROOT" != "$TEST_DIR" ]; then
    echo "ERROR: Git not isolated, found: $PROJECT_ROOT"
    exit 1
  fi
fi
```

### Step 3.1: Sandbox Isolation Checkpoint (MANDATORY)

> **STOP - Verify Before Continuing**
>
> Before proceeding to test data creation or test execution, you MUST verify sandbox isolation.
> Failure to verify will result in polluting the main repository with test artifacts.

**Run these verification commands:**

```bash
echo "=== SANDBOX ISOLATION CHECK ==="

# Check 1: Current directory must be under .ace-local/ace-test-e2e/
CURRENT_DIR="$(pwd)"
if [[ "$CURRENT_DIR" == *".ace-local/ace-test-e2e/"* ]]; then
  echo "PASS: Working directory is inside sandbox"
  echo "  Location: $CURRENT_DIR"
else
  echo "FAIL: NOT in sandbox!"
  echo "  Current: $CURRENT_DIR"
  echo "  Expected: Should contain '.ace-local/ace-test-e2e/'"
  echo "  ACTION: STOP - Do not proceed. Re-run Environment Setup."
fi

# Check 2: Git remote must be empty (fresh isolated repo)
if git rev-parse --git-dir >/dev/null 2>&1; then
  REMOTES=$(git remote -v 2>/dev/null)
  if [ -z "$REMOTES" ]; then
    echo "PASS: No git remotes (isolated repo)"
  else
    echo "FAIL: Git remotes found - NOT an isolated repo!"
    echo "  Remotes: $REMOTES"
    echo "  ACTION: STOP - You are in the main repository."
  fi
else
  echo "PASS: No git repo in sandbox (tools use PROJECT_ROOT_PATH)"
fi

# Check 3: Project root markers should NOT exist
if [ -f "CLAUDE.md" ] || [ -f "Gemfile" ] || [ -d ".ace-taskflow" ]; then
  echo "FAIL: Main project markers found - NOT an isolated repo!"
  echo "  ACTION: STOP - You are in the main repository."
else
  echo "PASS: No main project markers (expected for sandbox)"
fi

echo "=== END ISOLATION CHECK ==="
```

**Interpretation:**
- **All checks PASS**: Continue to Step 4 (Handle External APIs) or Step 5 (Create Test Data)
- **Any check FAILS**:
  1. STOP immediately - do NOT execute any test commands
  2. Return to project root: `cd "$PROJECT_ROOT"`
  3. Re-read and re-execute Environment Setup
  4. Re-run this checkpoint until all checks pass

### Step 4: Handle External APIs Safely

```bash
# Check for test tokens (never use production)
if [ -n "$EXTERNAL_API_REQUIRED" ]; then
  # GitHub example
  if [ -z "$TEST_GITHUB_TOKEN" ]; then
    echo "SKIP: No test GitHub token available"
    echo "Set TEST_GITHUB_TOKEN for full E2E coverage"
    exit 0
  fi

  # Use test token, not production
  export GITHUB_TOKEN="$TEST_GITHUB_TOKEN"

  # Verify token scope is limited
  SCOPES=$(gh auth status 2>&1 | grep "Token scopes" || echo "unknown")
  echo "Token scopes: $SCOPES" >> "$REPORTS_DIR/api-config.txt"
fi
```

### Step 5: Create Test Data

```bash
# Create test files from heredocs (reproducible)
cat > "$TEST_DIR/test-file.rb" << 'EOF'
# Test file content
class Example
  def hello
    "Hello, World!"
  end
end
EOF

# Create test configuration
mkdir -p "$TEST_DIR/.ace/tool"
cat > "$TEST_DIR/.ace/tool/config.yml" << 'EOF'
setting: test-value
EOF

# Record test data for debugging
find "$TEST_DIR" -type f > "$REPORTS_DIR/test-files.txt"
```

### Step 6: Execute with Safety

```bash
# Timeout protection
TIMEOUT_SECONDS="${TIMEOUT:-300}"

# Capture all output
timeout "$TIMEOUT_SECONDS" $COMMAND \
  > "$REPORTS_DIR/stdout.txt" \
  2> "$REPORTS_DIR/stderr.txt"
EXIT_CODE=$?

# Record exit code
echo "$EXIT_CODE" > "$REPORTS_DIR/exit-code.txt"

# Check for timeout
if [ "$EXIT_CODE" -eq 124 ]; then
  echo "FAIL: Command timed out after ${TIMEOUT_SECONDS}s"
fi
```

### Step 7: Verify Results

```bash
# Explicit PASS/FAIL assertions
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "PASS: Exit code 0" >> "$REPORTS_DIR/results.txt"
else
  echo "FAIL: Exit code $EXIT_CODE (expected 0)" >> "$REPORTS_DIR/results.txt"
fi

# Check expected output
if grep -q "expected pattern" "$REPORTS_DIR/stdout.txt"; then
  echo "PASS: Output contains expected pattern" >> "$REPORTS_DIR/results.txt"
else
  echo "FAIL: Output missing expected pattern" >> "$REPORTS_DIR/results.txt"
fi

# Check files created
if [ -f "$TEST_DIR/expected-output.txt" ]; then
  echo "PASS: Output file created" >> "$REPORTS_DIR/results.txt"
else
  echo "FAIL: Output file not created" >> "$REPORTS_DIR/results.txt"
fi
```

### Step 8: Cleanup

```bash
# Record end time
echo "$(date -Iseconds)" > "$REPORTS_DIR/end-time.txt"

# Restore environment
unset PROJECT_ROOT_PATH
unset ACE_TEST_MODE
unset ACE_CONFIG_PATH
unset GITHUB_TOKEN

# Cleanup API resources (if created)
if [ -f "$REPORTS_DIR/resources-created.txt" ]; then
  while read -r resource; do
    # Delete resource (implementation depends on API)
    echo "Cleaning up: $resource"
  done < "$REPORTS_DIR/resources-created.txt"
fi

# Determine sandbox disposition
if grep -q "FAIL" "$REPORTS_DIR/results.txt"; then
  echo "Sandbox preserved for debugging: $TEST_DIR"
  echo "Reports: $REPORTS_DIR"
else
  # Optional: Clean up on success
  if [ "$CLEANUP_ON_SUCCESS" = "true" ]; then
    rm -rf "$TEST_DIR"
    echo "Sandbox cleaned up"
  else
    echo "Sandbox preserved: $TEST_DIR"
  fi
fi
```

## Output Files

After running, reports directory contains:

```
{timestamp}-{pkg}-{id}-reports/
├── sandbox-path.txt      # Path to test directory
├── start-time.txt        # When test started
├── end-time.txt          # When test ended
├── environment.txt       # Environment variables
├── test-files.txt        # Files in sandbox
├── api-config.txt        # API configuration (if used)
├── stdout.txt            # Command stdout
├── stderr.txt            # Command stderr
├── exit-code.txt         # Command exit code
├── results.txt           # PASS/FAIL assertions
└── resources-created.txt # API resources to clean up
```

## Safety Checklist

Before running:

- [ ] Using test tokens, not production
- [ ] API scopes are minimal
- [ ] Timeout is set
- [ ] PROJECT_ROOT_PATH isolates sandbox
- [ ] Cleanup is defined for failure case

After running:

- [ ] Results recorded
- [ ] Resources cleaned up
- [ ] Environment restored
- [ ] Sandbox preserved (failure) or cleaned (success)

## Integration

### With E2E Test Files

Add setup directives to `scenario.yml`:

```yaml
# scenario.yml
setup:
  - git-init
  - run: "cp $PROJECT_ROOT_PATH/mise.toml mise.toml && mise trust mise.toml"
  - copy-fixtures
  - agent-env:
      PROJECT_ROOT_PATH: "."
```

### With /ace-e2e-run

This workflow is called automatically when running E2E tests.

## Standard Setup Script

This is the **authoritative copy-executable script** for sandbox setup. Other workflows (like `run-e2e-test.wf.md`) should reference this section rather than duplicating the logic.

```bash
#!/bin/bash
# E2E Sandbox Setup - Standard Script
# Usage: Source or copy-execute in E2E test workflows

# Capture project root before any cd operations
PROJECT_ROOT="$(pwd)"

# Generate unique timestamp ID
TIMESTAMP_ID="$(ace-b36ts encode)"

# Derive short names (adjust PACKAGE and TEST_ID as needed)
SHORT_PKG="${PACKAGE#ace-}"
SHORT_ID=$(echo "$TEST_ID" | sed 's/TS-[A-Z]*-/ts/' | tr '[:upper:]' '[:lower:]')

# Create sandbox and reports directories
TEST_DIR="$PROJECT_ROOT/.ace-local/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
REPORTS_DIR="${TEST_DIR}-reports"

mkdir -p "$TEST_DIR"
mkdir -p "$REPORTS_DIR"

# Record for cleanup
echo "$TEST_DIR" > "$REPORTS_DIR/sandbox-path.txt"
echo "$(date -Iseconds)" > "$REPORTS_DIR/start-time.txt"

# Navigate to sandbox
cd "$TEST_DIR"

# Set isolation environment
export PROJECT_ROOT_PATH="$TEST_DIR"
export ACE_TEST_MODE=true
export ACE_CONFIG_PATH="$TEST_DIR/.ace"

# Record environment for debugging
env | grep -E "^(PROJECT|ACE|PATH)" > "$REPORTS_DIR/environment.txt"

# Initialize git if needed
if [ "$NEEDS_GIT" = "true" ]; then
  git init --quiet .
  git config user.email "test@example.com"
  git config user.name "E2E Test"
fi

# === SANDBOX ISOLATION CHECKPOINT ===
echo "=== SANDBOX ISOLATION CHECK ==="

# Check 1: Path
CURRENT_DIR="$(pwd)"
if [[ "$CURRENT_DIR" == *".ace-local/ace-test-e2e/"* ]]; then
  echo "PASS: Working directory is inside sandbox"
else
  echo "FAIL: NOT in sandbox! Current: $CURRENT_DIR"
  exit 1
fi

# Check 2: Git remotes
if git rev-parse --git-dir >/dev/null 2>&1; then
  REMOTES=$(git remote -v 2>/dev/null)
  if [ -z "$REMOTES" ]; then
    echo "PASS: No git remotes (isolated repo)"
  else
    echo "FAIL: Git remotes found - NOT isolated!"
    exit 1
  fi
else
  echo "PASS: No git repo in sandbox (tools use PROJECT_ROOT_PATH)"
fi

# Check 3: Project markers
if [ -f "CLAUDE.md" ] || [ -f "Gemfile" ] || [ -d ".ace-taskflow" ]; then
  echo "FAIL: Main project markers found!"
  exit 1
else
  echo "PASS: No main project markers"
fi

echo "=== ISOLATION VERIFIED - SAFE TO PROCEED ==="

# Export variables for use by calling script
export PROJECT_ROOT TEST_DIR REPORTS_DIR TIMESTAMP_ID
```

**Expected Variables After Setup:**
- `PROJECT_ROOT` - Original project directory (for accessing binaries like `$PROJECT_ROOT/bin/ace-lint`)
- `TEST_DIR` - Sandbox directory (current working directory after setup)
- `REPORTS_DIR` - Reports directory for test outputs
- `TIMESTAMP_ID` - Unique identifier for this test run

## Using `ace-test-e2e-sh` After Setup

After Environment Setup completes, all subsequent bash blocks (Test Data, Test Cases) MUST use the `ace-test-e2e-sh` wrapper to ensure sandbox isolation persists across separate shell invocations.

**Why:** Each `bash` block in a test scenario runs in a fresh shell. The `cd "$TEST_DIR"` from Environment Setup does not carry over. The wrapper enforces the correct working directory and `PROJECT_ROOT_PATH` for every command.

**Single command:**
```bash
ace-test-e2e-sh "$TEST_DIR" git add README.md
```

**Multi-command block (heredoc):**
```bash
ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
cat > README.md << 'EOF'
# Test Repository
EOF
git add README.md
git commit -m "Initial commit"
SANDBOX
```

**Worktree tests:** Use `$REPO_DIR` (a subdirectory of `$TEST_DIR`) instead:
```bash
ace-test-e2e-sh "$REPO_DIR" git status
```

**Skip wrapping for:**
- The Environment Setup block itself (it creates and enters the sandbox)
- Report-writing blocks (Section 7) that use absolute `$REPORT_DIR` paths

## See Also

- [E2E Testing Guide](guide://e2e-testing)
- [Test Suite Health](guide://test-suite-health)
