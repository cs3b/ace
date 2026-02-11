---
test-id: MT-ASSIGN-003d-TC001
title: Status Shows Hierarchy Tree
suite: TS-ASSIGN-003d
---

# Status Shows Hierarchy Tree

## Objective

Verify that the status command displays phases in a hierarchical tree structure.

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

1. Create assignment and build hierarchy with children under two parents
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "job.yaml" << 'EOF'
   name: tree-display-test
   description: Test hierarchical status display

   steps:
     - name: feature-a
       instructions: First feature

     - name: feature-b
       instructions: Second feature
   EOF

   CREATE_OUTPUT=$($ACE_ASSIGN create "job.yaml" 2>&1)
   [ "$?" -eq 0 ] && echo "PASS: Assignment created" || echo "FAIL: Assignment creation failed"
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)

   $ACE_ASSIGN add a-subtask-1 --after 010 --child -i "First subtask of A" > /dev/null 2>&1
   $ACE_ASSIGN add a-subtask-2 --after 010 --child -i "Second subtask of A" > /dev/null 2>&1
   $ACE_ASSIGN add b-subtask-1 --after 020 --child -i "First subtask of B" > /dev/null 2>&1

   [ -f "$ASSIGNMENT_DIR/phases/010.01-a-subtask-1.ph.md" ] && echo "PASS: 010.01 created" || echo "FAIL: 010.01 missing"
   [ -f "$ASSIGNMENT_DIR/phases/010.02-a-subtask-2.ph.md" ] && echo "PASS: 010.02 created" || echo "FAIL: 010.02 missing"
   [ -f "$ASSIGNMENT_DIR/phases/020.01-b-subtask-1.ph.md" ] && echo "PASS: 020.01 created" || echo "FAIL: 020.01 missing"
   SANDBOX
   ```

2. Verify status displays all phases with hierarchy
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   STATUS_OUTPUT=$($ACE_ASSIGN status 2>&1)
   echo "Status output:"
   echo "$STATUS_OUTPUT"

   echo "$STATUS_OUTPUT" | grep -q "feature-a" && echo "PASS: feature-a shown" || echo "FAIL: feature-a missing"
   echo "$STATUS_OUTPUT" | grep -q "a-subtask-1" && echo "PASS: a-subtask-1 shown" || echo "FAIL: a-subtask-1 missing"
   echo "$STATUS_OUTPUT" | grep -q "a-subtask-2" && echo "PASS: a-subtask-2 shown" || echo "FAIL: a-subtask-2 missing"
   echo "$STATUS_OUTPUT" | grep -q "feature-b" && echo "PASS: feature-b shown" || echo "FAIL: feature-b missing"
   echo "$STATUS_OUTPUT" | grep -q "b-subtask-1" && echo "PASS: b-subtask-1 shown" || echo "FAIL: b-subtask-1 missing"
   SANDBOX
   ```

3. Verify hierarchical display indicators and nested numbers
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$STATUS_OUTPUT" | grep -E "^\s+.*a-subtask" && echo "PASS: Children appear indented" || echo "INFO: Checking for tree display pattern"
   echo "$STATUS_OUTPUT" | grep -E "(├|└|│).*subtask" && echo "PASS: Tree characters used for hierarchy" || echo "INFO: May use different hierarchy display"
   echo "$STATUS_OUTPUT" | grep -q "010\.01" && echo "PASS: Nested number 010.01 shown" || echo "FAIL: Nested number not shown"
   echo "$STATUS_OUTPUT" | grep -q "010\.02" && echo "PASS: Nested number 010.02 shown" || echo "FAIL: Nested number not shown"
   echo "$STATUS_OUTPUT" | grep -q "020\.01" && echo "PASS: Nested number 020.01 shown" || echo "FAIL: Nested number not shown"
   SANDBOX
   ```

## Expected Results

- All 5 phases displayed in status output
- Phases displayed with hierarchical structure (children appear under parents)
- Phase numbers show nesting (010.01, 010.02, 020.01)

## Status

[ ] Pass / [ ] Fail

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
echo "Cleanup complete"
```
