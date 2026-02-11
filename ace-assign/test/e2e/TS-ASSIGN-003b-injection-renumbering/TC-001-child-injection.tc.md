---
test-id: MT-ASSIGN-003b-TC001
title: Child Injection with --after --child
suite: TS-ASSIGN-003b
---

# Child Injection with --after --child

## Objective

Verify that `add --after X --child` creates a child phase with correct numbering and metadata.

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

# Add two initial children under 010 (needed for subsequent tests)
$ACE_ASSIGN add write-unit-tests --after 010 --child -i "Write unit tests for the feature" > /dev/null 2>&1
$ACE_ASSIGN add write-integration-tests --after 010 --child -i "Write integration tests" > /dev/null 2>&1

[ -f "$ASSIGNMENT_DIR/phases/010.01-write-unit-tests.ph.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Child 010.01 missing"
[ -f "$ASSIGNMENT_DIR/phases/010.02-write-integration-tests.ph.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Child 010.02 missing"
```

## Test Steps

1. Add a third child under 010, verify number and relationship
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ADD_OUTPUT=$($ACE_ASSIGN add setup-fixtures --after 010 --child -i "Set up test fixtures" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"

   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   echo "$ADD_OUTPUT" | grep -q "010.03" && echo "PASS: New phase is 010.03" || echo "FAIL: Expected phase number 010.03"
   echo "$ADD_OUTPUT" | grep -q "child of 010" && echo "PASS: Relationship shows 'child of 010'" || echo "FAIL: Relationship should show 'child of 010'"
   SANDBOX
   ```

2. Verify file created with correct parent and provenance metadata
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$ASSIGNMENT_DIR/phases/010.03-setup-fixtures.ph.md" ] && echo "PASS: Phase file 010.03-setup-fixtures.ph.md created" || echo "FAIL: Phase file not created"
   grep -q 'parent:.*"010"' "$ASSIGNMENT_DIR/phases/010.03-setup-fixtures.ph.md" && echo "PASS: New phase has parent: 010" || echo "FAIL: New phase missing parent field"
   grep -q 'added_by:.*child_of:010' "$ASSIGNMENT_DIR/phases/010.03-setup-fixtures.ph.md" && echo "PASS: added_by shows child_of:010" || echo "FAIL: added_by missing or incorrect"
   SANDBOX
   ```

## Expected Results

- Exit code: 0
- New phase created as 010.03 (next child number)
- Phase file contains `parent: "010"` and `added_by: child_of:010`

## Status

[ ] Pass / [ ] Fail

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
echo "Cleanup complete"
```
