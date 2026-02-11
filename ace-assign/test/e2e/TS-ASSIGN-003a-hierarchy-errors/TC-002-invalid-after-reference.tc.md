---
test-id: MT-ASSIGN-003a-TC002
title: Invalid --after Reference
suite: TS-ASSIGN-003a
---

# Invalid --after Reference

## Objective

Verify that `add --after` with an invalid phase number fails with a clear error showing available phases.

## Prerequisites

- Ruby >= 3.0 installed
- ace-assign package available (via bundle exec or installed)

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="assign"
SHORT_ID="003a"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

export PROJECT_ROOT_PATH="$TEST_DIR"
CACHE_BASE="$TEST_DIR/.cache/ace-assign"
mkdir -p "$CACHE_BASE"
ACE_ASSIGN="bundle exec $PROJECT_ROOT/ace-assign/exe/ace-assign"

# Create job.yaml and assignment
cat > "job.yaml" << 'EOF'
name: hierarchical-test
description: Test nested phases and completion

steps:
  - name: implement-feature
    instructions: Implement the main feature

  - name: document
    instructions: Write documentation
EOF

CREATE_OUTPUT=$($ACE_ASSIGN create "job.yaml" 2>&1)
CREATE_EXIT=$?
echo "Exit code: $CREATE_EXIT"
[ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Assignment created" || echo "FAIL: Assignment creation failed"
ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)
echo "Assignment directory: $ASSIGNMENT_DIR"
```

## Test Steps

1. Attempt to add phase with invalid --after reference
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ADD_OUTPUT=$($ACE_ASSIGN add test-phase --after 999 -i "Test instructions" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"
   SANDBOX
   ```

2. Verify error exit code and available phases listed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$ADD_EXIT" -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Expected non-zero exit code"
   echo "$ADD_OUTPUT" | grep -qi "not found" && echo "PASS: Error mentions 'not found'" || echo "FAIL: Error should mention 'not found'"
   echo "$ADD_OUTPUT" | grep -qi "available" && echo "PASS: Error mentions available phases" || echo "FAIL: Error should mention available phases"
   echo "$ADD_OUTPUT" | grep -q "010" && echo "PASS: Available phases include 010" || echo "FAIL: Available phases should include 010"
   SANDBOX
   ```

## Expected Results

- Exit code: non-zero (error)
- Error message contains "not found"
- Error message shows "Available phases:" with existing phase numbers

## Status

[ ] Pass / [ ] Fail

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
echo "Cleanup complete"
```
