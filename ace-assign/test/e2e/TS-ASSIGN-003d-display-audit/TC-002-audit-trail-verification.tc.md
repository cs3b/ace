---
test-id: MT-ASSIGN-003d-TC002
title: Audit Trail Verification
suite: TS-ASSIGN-003d
---

# Audit Trail Verification

## Objective

Verify that all audit trail metadata fields are present and correctly populated for child injection, sibling injection, renumbering, and dynamic adds.

## Prerequisites

- Ruby >= 3.0 installed
- ace-assign package available (via bundle exec or installed)

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="assign"
SHORT_ID="003d"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

export PROJECT_ROOT_PATH="$TEST_DIR"
CACHE_BASE="$TEST_DIR/.cache/ace-assign"
mkdir -p "$CACHE_BASE"
ACE_ASSIGN="bundle exec $PROJECT_ROOT/ace-assign/exe/ace-assign"
```

## Test Steps

1. Create assignment and add child phase for audit trail testing
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "job.yaml" << 'EOF'
   name: audit-trail-test
   description: Test audit trail metadata

   steps:
     - name: initial-phase
       instructions: Starting phase

     - name: second-phase
       instructions: Second phase
   EOF

   CREATE_OUTPUT=$($ACE_ASSIGN create "job.yaml" 2>&1)
   [ "$?" -eq 0 ] && echo "PASS: Assignment created" || echo "FAIL: Assignment creation failed"
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)

   ADD_OUTPUT=$($ACE_ASSIGN add child-task --after 010 --child -i "Child task" 2>&1)
   [ "$?" -eq 0 ] && echo "PASS: Child added" || echo "FAIL: Child add failed"
   SANDBOX
   ```

2. Verify child_of audit trail
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   grep -q 'added_by:.*child_of:010' "$ASSIGNMENT_DIR/phases/010.01-child-task.ph.md" && echo "PASS: added_by: child_of:010 present" || echo "FAIL: child_of audit missing"
   grep -q 'parent:.*"010"' "$ASSIGNMENT_DIR/phases/010.01-child-task.ph.md" && echo "PASS: parent: 010 present" || echo "FAIL: parent field missing"
   SANDBOX
   ```

3. Add another child and inject sibling to trigger renumbering
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   $ACE_ASSIGN add another-child --after 010 --child -i "Another child" > /dev/null 2>&1
   ADD_OUTPUT=$($ACE_ASSIGN add injected-sibling --after 010.01 -i "Injected sibling" 2>&1)
   echo "$ADD_OUTPUT"
   [ "$?" -eq 0 ] && echo "PASS: Sibling injected" || echo "FAIL: Sibling injection failed"
   SANDBOX
   ```

4. Verify injected_after and renumbering audit trails
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   grep -q 'added_by:.*injected_after:010.01' "$ASSIGNMENT_DIR/phases/010.02-injected-sibling.ph.md" && echo "PASS: added_by: injected_after:010.01 present" || echo "FAIL: injected_after audit missing"

   RENAMED_FILE=$(ls "$ASSIGNMENT_DIR/phases/"*another-child*.ph.md 2>/dev/null | head -1)
   echo "Renamed file: $RENAMED_FILE"
   [ -n "$RENAMED_FILE" ] && echo "PASS: Renamed file found" || echo "FAIL: Renamed file not found"

   grep -q 'renumbered_from:' "$RENAMED_FILE" && echo "PASS: renumbered_from present" || echo "FAIL: renumbered_from missing"
   grep -q 'renumbered_at:' "$RENAMED_FILE" && echo "PASS: renumbered_at present" || echo "FAIL: renumbered_at missing"
   SANDBOX
   ```

5. Verify ISO8601 timestamp format on renumbered_at
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   TIMESTAMP=$(grep 'renumbered_at:' "$RENAMED_FILE" | sed 's/renumbered_at: *//')
   echo "Timestamp: $TIMESTAMP"
   echo "$TIMESTAMP" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' && echo "PASS: ISO8601 format" || echo "FAIL: Not ISO8601 format"
   SANDBOX
   ```

6. Add dynamic phase and verify dynamic audit trail
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   sed -i.bak 's/status: in_progress/status: done/' "$ASSIGNMENT_DIR/phases/010-initial-phase.ph.md"
   ADD_OUTPUT=$($ACE_ASSIGN add dynamic-phase -i "Dynamically added" 2>&1)
   echo "$ADD_OUTPUT"
   [ "$?" -eq 0 ] && echo "PASS: Dynamic phase added" || echo "FAIL: Dynamic phase add failed"

   DYNAMIC_FILE=$(ls "$ASSIGNMENT_DIR/phases/"*dynamic-phase*.ph.md 2>/dev/null | head -1)
   echo "Dynamic file: $DYNAMIC_FILE"
   grep -q 'added_by:.*dynamic' "$DYNAMIC_FILE" && echo "PASS: added_by: dynamic present" || echo "FAIL: dynamic audit missing"
   SANDBOX
   ```

## Expected Results

- Child phases have `added_by: child_of:<parent>` and `parent: "<parent>"`
- Injected siblings have `added_by: injected_after:<number>`
- Renumbered phases have `renumbered_from: <old_number>` and `renumbered_at: <ISO8601>`
- Dynamic phases have `added_by: dynamic`

## Status

[ ] Pass / [ ] Fail

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
echo "Cleanup complete"
```
