---
tc-id: MT-ASSIGN-003a-TC001
title: Advance Parent with Incomplete Children
suite: TS-ASSIGN-003a
---

# Advance Parent with Incomplete Children

## Objective

Verify that attempting to complete a parent phase while children are incomplete fails with a clear error listing the incomplete children.

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

1. Verify initial structure and add children under 010
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$ASSIGNMENT_DIR/phases/010-implement-feature.ph.md" ] && echo "PASS: Phase 010 exists" || echo "FAIL: Phase 010 missing"
   [ -f "$ASSIGNMENT_DIR/phases/020-document.ph.md" ] && echo "PASS: Phase 020 exists" || echo "FAIL: Phase 020 missing"

   ADD1_OUTPUT=$($ACE_ASSIGN add write-unit-tests --after 010 --child -i "Write unit tests for the feature" 2>&1)
   ADD1_EXIT=$?
   [ "$ADD1_EXIT" -eq 0 ] && echo "PASS: Child 010.01 created" || echo "FAIL: Child creation failed"

   ADD2_OUTPUT=$($ACE_ASSIGN add write-integration-tests --after 010 --child -i "Write integration tests" 2>&1)
   ADD2_EXIT=$?
   [ "$ADD2_EXIT" -eq 0 ] && echo "PASS: Child 010.02 created" || echo "FAIL: Child creation failed"
   SANDBOX
   ```

2. Verify hierarchical structure and parent fields
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$ASSIGNMENT_DIR/phases/010.01-write-unit-tests.ph.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Child 010.01 missing"
   [ -f "$ASSIGNMENT_DIR/phases/010.02-write-integration-tests.ph.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Child 010.02 missing"

   grep -q 'parent:.*"010"' "$ASSIGNMENT_DIR/phases/010.01-write-unit-tests.ph.md" && echo "PASS: Child 010.01 has parent field" || echo "FAIL: Child 010.01 missing parent field"
   grep -q 'parent:.*"010"' "$ASSIGNMENT_DIR/phases/010.02-write-integration-tests.ph.md" && echo "PASS: Child 010.02 has parent field" || echo "FAIL: Child 010.02 missing parent field"
   SANDBOX
   ```

3. Check status and attempt to complete parent with incomplete children
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   STATUS_OUTPUT=$($ACE_ASSIGN status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "implement-feature" && echo "INFO: Current phase is implement-feature (parent)" || echo "INFO: Current phase is not the parent"

   cat > "parent-report.md" << 'EOF'
# Parent Report

Attempting to complete parent with incomplete children.
EOF

   ADVANCE_OUTPUT=$($ACE_ASSIGN report "parent-report.md" 2>&1)
   ADVANCE_EXIT=$?
   echo "Exit code: $ADVANCE_EXIT"
   echo "Output:"
   echo "$ADVANCE_OUTPUT"
   SANDBOX
   ```

4. Verify error exit code and incomplete children message
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$ADVANCE_EXIT" -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Expected non-zero exit code"
   echo "$ADVANCE_OUTPUT" | grep -qi "incomplete children" && echo "PASS: Error mentions 'incomplete children'" || echo "FAIL: Error should mention 'incomplete children'"
   echo "$ADVANCE_OUTPUT" | grep -q "010.01" && echo "PASS: Error lists child 010.01" || echo "FAIL: Error should list child 010.01"
   echo "$ADVANCE_OUTPUT" | grep -q "010.02" && echo "PASS: Error lists child 010.02" || echo "FAIL: Error should list child 010.02"
   SANDBOX
   ```

## Expected Results

- Exit code: non-zero (error)
- Error message contains "incomplete children"
- Error message lists incomplete child phase numbers (010.01, 010.02)

## Status

[ ] Pass / [ ] Fail

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
echo "Cleanup complete"
```
