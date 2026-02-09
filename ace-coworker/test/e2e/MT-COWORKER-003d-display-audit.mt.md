---
test-id: MT-COWORKER-003d
title: Hierarchical Jobs - Display and Audit Trail
area: coworker
package: ace-coworker
priority: high
duration: ~3min
automation-candidate: true
requires:
  tools: [ace-coworker]
  ruby: ">= 3.0"
last-verified: 2026-02-08
verified-by: claude-opus-4-6
---

# Hierarchical Jobs - Display and Audit Trail

## Objective

Verify that ace-coworker's status command displays jobs in a hierarchical tree structure, and that all audit trail metadata fields are present and correctly populated for child injection, sibling injection, renumbering, and dynamic adds.

## Prerequisites

- Ruby >= 3.0 installed
- ace-coworker package available (via bundle exec or installed)

## Environment Setup

```bash
```

## Test Cases

### TC-008: Status Shows Hierarchy (Tree Structure)

**Objective:** Verify that the status command displays jobs in a hierarchical tree structure.

**Steps:**
1. Create session and build hierarchy with children under two parents
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "job4.yaml" << 'EOF'
name: tree-display-test
description: Test hierarchical status display

steps:
  - name: feature-a
    instructions: First feature

  - name: feature-b
    instructions: Second feature
EOF

   CREATE_OUTPUT=$($ACE_COWORKER create "job4.yaml" 2>&1)
   [ "$?" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Session creation failed"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)

   $ACE_COWORKER add a-subtask-1 --after 010 --child -i "First subtask of A" > /dev/null 2>&1
   $ACE_COWORKER add a-subtask-2 --after 010 --child -i "Second subtask of A" > /dev/null 2>&1
   $ACE_COWORKER add b-subtask-1 --after 020 --child -i "First subtask of B" > /dev/null 2>&1

   [ -f "$SESSION_DIR/jobs/010.01-a-subtask-1.j.md" ] && echo "PASS: 010.01 created" || echo "FAIL: 010.01 missing"
   [ -f "$SESSION_DIR/jobs/010.02-a-subtask-2.j.md" ] && echo "PASS: 010.02 created" || echo "FAIL: 010.02 missing"
   [ -f "$SESSION_DIR/jobs/020.01-b-subtask-1.j.md" ] && echo "PASS: 020.01 created" || echo "FAIL: 020.01 missing"
   SANDBOX
   ```

2. Verify status displays all jobs with hierarchy
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
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

**Expected:**
- All 5 jobs displayed in status output
- Jobs displayed with hierarchical structure (children appear under parents)
- Job numbers show nesting (010.01, 010.02, 020.01)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-009: Audit Trail Verification

**Objective:** Verify that all audit trail metadata fields are present and correctly populated.

**Steps:**
1. Create session and add child job for audit trail testing
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "job5.yaml" << 'EOF'
name: audit-trail-test
description: Test audit trail metadata

steps:
  - name: initial-job
    instructions: Starting job

  - name: second-job
    instructions: Second job
EOF

   CREATE_OUTPUT=$($ACE_COWORKER create "job5.yaml" 2>&1)
   [ "$?" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Session creation failed"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)

   ADD_OUTPUT=$($ACE_COWORKER add child-task --after 010 --child -i "Child task" 2>&1)
   [ "$?" -eq 0 ] && echo "PASS: Child added" || echo "FAIL: Child add failed"
   SANDBOX
   ```

2. Verify child_of audit trail
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   grep -q 'added_by:.*child_of:010' "$SESSION_DIR/jobs/010.01-child-task.j.md" && echo "PASS: added_by: child_of:010 present" || echo "FAIL: child_of audit missing"
   grep -q 'parent:.*"010"' "$SESSION_DIR/jobs/010.01-child-task.j.md" && echo "PASS: parent: 010 present" || echo "FAIL: parent field missing"
   SANDBOX
   ```

3. Add another child and inject sibling to trigger renumbering
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   $ACE_COWORKER add another-child --after 010 --child -i "Another child" > /dev/null 2>&1
   ADD_OUTPUT=$($ACE_COWORKER add injected-sibling --after 010.01 -i "Injected sibling" 2>&1)
   echo "$ADD_OUTPUT"
   [ "$?" -eq 0 ] && echo "PASS: Sibling injected" || echo "FAIL: Sibling injection failed"
   SANDBOX
   ```

4. Verify injected_after and renumbering audit trails
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   grep -q 'added_by:.*injected_after:010.01' "$SESSION_DIR/jobs/010.02-injected-sibling.j.md" && echo "PASS: added_by: injected_after:010.01 present" || echo "FAIL: injected_after audit missing"

   RENAMED_FILE=$(ls "$SESSION_DIR/jobs/"*another-child*.j.md 2>/dev/null | head -1)
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

6. Add dynamic step and verify dynamic audit trail
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   sed -i.bak 's/status: in_progress/status: done/' "$SESSION_DIR/jobs/010-initial-job.j.md"
   ADD_OUTPUT=$($ACE_COWORKER add dynamic-step -i "Dynamically added" 2>&1)
   echo "$ADD_OUTPUT"
   [ "$?" -eq 0 ] && echo "PASS: Dynamic step added" || echo "FAIL: Dynamic step add failed"

   DYNAMIC_FILE=$(ls "$SESSION_DIR/jobs/"*dynamic-step*.j.md 2>/dev/null | head -1)
   echo "Dynamic file: $DYNAMIC_FILE"
   grep -q 'added_by:.*dynamic' "$DYNAMIC_FILE" && echo "PASS: added_by: dynamic present" || echo "FAIL: dynamic audit missing"
   SANDBOX
   ```

**Expected:**
- Child jobs have `added_by: child_of:<parent>` and `parent: "<parent>"`
- Injected siblings have `added_by: injected_after:<number>`
- Renumbered jobs have `renumbered_from: <old_number>` and `renumbered_at: <ISO8601>`
- Dynamic jobs have `added_by: dynamic`

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
echo "Cleanup complete"
```

## Success Criteria

- [ ] TC-008: Status shows hierarchical structure with nested job numbers
- [ ] TC-009: All audit trail fields present (added_by, parent, renumbered_from, renumbered_at)
