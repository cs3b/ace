---
name: e2e-sandbox-setup
description: Set up safe, isolated E2E test environment with external API handling
purpose: E2E test environment setup workflow
params:
  package: Package being tested
  test_id: E2E test ID (e.g., MT-LINT-001)
tools:
  - Bash
  - Read
  - Write
embed_document_source: false
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# E2E Sandbox Setup Workflow

## Purpose

Set up a safe, isolated environment for E2E tests that:
- Isolates from main project (no pollution)
- Handles external APIs safely (test tokens, limited scope)
- Ensures cleanup on success AND failure
- Captures outputs for debugging

## When to Use

- Before running E2E tests that touch filesystem
- When E2E test needs git repository
- When E2E test calls external APIs
- When test creates resources that need cleanup

## Prerequisites

- `ace-timestamp` available for unique IDs
- Required tools installed for the specific test
- Test tokens available (if external APIs needed)

## Workflow Steps

### Step 1: Create Isolated Directory

```bash
# Generate unique timestamp ID
TIMESTAMP_ID="$(ace-timestamp encode)"

# Extract short names from test metadata
SHORT_PKG="${PACKAGE#ace-}"  # Remove ace- prefix
SHORT_ID="$(echo "$TEST_ID" | tr '[:upper:]' '[:lower:]' | tr '-' '')"  # mt001

# Create sandbox and reports directories
TEST_DIR=".cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
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
  PROJECT_ROOT=$(git rev-parse --show-toplevel)
  if [ "$PROJECT_ROOT" != "$TEST_DIR" ]; then
    echo "ERROR: Git not isolated, found: $PROJECT_ROOT"
    exit 1
  fi
fi
```

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

Add setup section to `.mt.md` test:

```markdown
## Environment Setup

Follow `wfi://e2e-sandbox-setup` with:
- package: ace-lint
- test_id: MT-LINT-001
- needs_git: true
- external_api: false
```

### With /ace:run-e2e-test

This workflow is called automatically when running E2E tests.

## See Also

- [E2E Testing Guide](guide://e2e-testing)
- [Test Suite Health](guide://test-suite-health)
