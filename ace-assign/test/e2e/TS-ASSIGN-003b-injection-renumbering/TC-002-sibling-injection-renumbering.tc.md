---
tc-id: MT-ASSIGN-003b-TC002
title: Sibling Injection with Renumbering
suite: TS-ASSIGN-003b
---

# Sibling Injection with Renumbering

## Objective

Verify that `add --after X` (without --child) creates a sibling phase and renumbers existing siblings.

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

1. Add sibling phase after 010.01 and verify renumbering output
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ADD_OUTPUT=$($ACE_ASSIGN add run-linter --after 010.01 -i "Run linter checks" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"

   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   echo "$ADD_OUTPUT" | grep -q "Number: 010.02" && echo "PASS: New phase is 010.02" || echo "FAIL: Expected phase number 010.02"
   echo "$ADD_OUTPUT" | grep -q "sibling after 010.01" && echo "PASS: Relationship shows 'sibling after 010.01'" || echo "FAIL: Relationship should show sibling"
   echo "$ADD_OUTPUT" | grep -q "Renumbered phases:" && echo "PASS: Renumbering announced" || echo "FAIL: Renumbering not shown"
   echo "$ADD_OUTPUT" | grep -q "010.02 -> 010.03" && echo "PASS: 010.02 shifted to 010.03" || echo "FAIL: Renumbering shift not shown"
   SANDBOX
   ```

2. Verify new 010.02 is run-linter with correct provenance
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$ASSIGNMENT_DIR/phases/010.02-run-linter.ph.md" ] && echo "PASS: 010.02-run-linter.ph.md exists" || echo "FAIL: 010.02-run-linter.ph.md missing"
   grep -q 'added_by:.*injected_after:010.01' "$ASSIGNMENT_DIR/phases/010.02-run-linter.ph.md" && echo "PASS: added_by shows injected_after" || echo "FAIL: added_by missing or incorrect"
   SANDBOX
   ```

3. Verify old 010.02 renamed to 010.03 with audit trail
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$ASSIGNMENT_DIR/phases/010.03-write-integration-tests.ph.md" ] && echo "PASS: Old 010.02 is now 010.03" || echo "FAIL: Old 010.02 not found at 010.03"
   [ ! -f "$ASSIGNMENT_DIR/phases/010.02-write-integration-tests.ph.md" ] && echo "PASS: Old 010.02-write-integration-tests no longer exists" || echo "FAIL: Old file still exists"
   grep -q 'renumbered_from:.*010.02' "$ASSIGNMENT_DIR/phases/010.03-write-integration-tests.ph.md" && echo "PASS: renumbered_from: 010.02 present" || echo "FAIL: renumbered_from missing"
   grep -q 'renumbered_at:' "$ASSIGNMENT_DIR/phases/010.03-write-integration-tests.ph.md" && echo "PASS: renumbered_at timestamp present" || echo "FAIL: renumbered_at missing"
   SANDBOX
   ```

## Expected Results

- Exit code: 0
- New phase created as 010.02
- Output shows "Renumbered phases:" with 010.02 -> 010.03
- Old 010.02 renamed to 010.03 with `renumbered_from` and `renumbered_at` metadata

## Status

[ ] Pass / [ ] Fail

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
echo "Cleanup complete"
```
