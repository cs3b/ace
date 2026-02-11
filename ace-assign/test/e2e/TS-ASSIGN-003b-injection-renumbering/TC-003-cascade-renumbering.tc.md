---
test-id: MT-ASSIGN-003b-TC003
title: Cascade Renumbering
suite: TS-ASSIGN-003b
---

# Cascade Renumbering

## Objective

Verify that when a parent phase is renumbered, all its descendants are also renumbered.

## Prerequisites

- Ruby >= 3.0 installed
- ace-assign package available (via bundle exec or installed)

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="assign"
SHORT_ID="003b"
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

# Add two initial children under 010
$ACE_ASSIGN add write-unit-tests --after 010 --child -i "Write unit tests for the feature" > /dev/null 2>&1
$ACE_ASSIGN add write-integration-tests --after 010 --child -i "Write integration tests" > /dev/null 2>&1

[ -f "$ASSIGNMENT_DIR/phases/010.01-write-unit-tests.ph.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Child 010.01 missing"
[ -f "$ASSIGNMENT_DIR/phases/010.02-write-integration-tests.ph.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Child 010.02 missing"
```

## Test Steps

1. Add a child under 010.02 (the write-integration-tests)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ADD_OUTPUT=$($ACE_ASSIGN add integration-db-tests --after 010.02 --child -i "Database integration tests" 2>&1)
   ADD_EXIT=$?
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Child created" || echo "FAIL: Child creation failed"
   [ -f "$ASSIGNMENT_DIR/phases/010.02.01-integration-db-tests.ph.md" ] && echo "PASS: 010.02.01 created" || echo "FAIL: 010.02.01 not created"
   SANDBOX
   ```

2. Inject sibling after 010.01 to trigger cascade renumbering
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ADD_OUTPUT=$($ACE_ASSIGN add static-analysis --after 010.01 -i "Run static analysis" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"

   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   echo "$ADD_OUTPUT" | grep -q "010.02 -> 010.03" && echo "PASS: Parent 010.02 shifted to 010.03" || echo "FAIL: Parent shift not shown"
   SANDBOX
   ```

3. Verify files renamed correctly including cascaded child
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$ASSIGNMENT_DIR/phases/010.02-static-analysis.ph.md" ] && echo "PASS: New 010.02-static-analysis.ph.md exists" || echo "FAIL: New 010.02 missing"
   [ -f "$ASSIGNMENT_DIR/phases/010.03-write-integration-tests.ph.md" ] && echo "PASS: Old 010.02 is now 010.03" || echo "FAIL: Old 010.02 not at 010.03"
   [ -f "$ASSIGNMENT_DIR/phases/010.03.01-integration-db-tests.ph.md" ] && echo "PASS: Child cascaded to 010.03.01" || echo "FAIL: Child not cascaded"
   [ ! -f "$ASSIGNMENT_DIR/phases/010.02.01-integration-db-tests.ph.md" ] && echo "PASS: Old 010.02.01 no longer exists" || echo "FAIL: Old child file still exists"
   grep -q 'renumbered_from:.*010.02.01' "$ASSIGNMENT_DIR/phases/010.03.01-integration-db-tests.ph.md" && echo "PASS: Child has renumbered_from: 010.02.01" || echo "FAIL: Child missing renumbered_from"
   SANDBOX
   ```

## Expected Results

- Exit code: 0
- Parent phase 010.02 shifted to 010.03
- Child phase 010.02.01 cascaded to 010.03.01
- All shifted phases have `renumbered_from` and `renumbered_at` metadata

## Status

[ ] Pass / [ ] Fail

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
echo "Cleanup complete"
```
