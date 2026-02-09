---
test-id: MT-COWORKER-003a
title: Hierarchical Jobs - Error Handling
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

# Hierarchical Jobs - Error Handling

## Objective

Verify that ace-coworker reports clear errors when attempting invalid hierarchical operations: completing a parent with incomplete children, and referencing a non-existent job with --after.

## Prerequisites

- Ruby >= 3.0 installed
- ace-coworker package available (via bundle exec or installed)

## Environment Setup

```bash
```

## Test Data

```bash
ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
# Create job.yaml with flat steps (hierarchy will be created dynamically)
cat > "job.yaml" << 'EOF'
name: hierarchical-test
description: Test nested jobs and completion

steps:
  - name: implement-feature
    instructions: Implement the main feature

  - name: document
    instructions: Write documentation
EOF

# Create session and find session directory
CREATE_OUTPUT=$($ACE_COWORKER create "job.yaml" 2>&1)
CREATE_EXIT=$?
echo "Exit code: $CREATE_EXIT"
[ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Session creation failed"
SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)
echo "Session directory: $SESSION_DIR"
SANDBOX
```

## Test Cases

### TC-001: Error - Advance Parent with Incomplete Children

**Objective:** Verify that attempting to complete a parent job while children are incomplete fails with a clear error listing the incomplete children.

**Steps:**
1. Verify initial structure and add children under 010
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$SESSION_DIR/jobs/010-implement-feature.j.md" ] && echo "PASS: Step 010 exists" || echo "FAIL: Step 010 missing"
   [ -f "$SESSION_DIR/jobs/020-document.j.md" ] && echo "PASS: Step 020 exists" || echo "FAIL: Step 020 missing"

   ADD1_OUTPUT=$($ACE_COWORKER add write-unit-tests --after 010 --child -i "Write unit tests for the feature" 2>&1)
   ADD1_EXIT=$?
   [ "$ADD1_EXIT" -eq 0 ] && echo "PASS: Child 010.01 created" || echo "FAIL: Child creation failed"

   ADD2_OUTPUT=$($ACE_COWORKER add write-integration-tests --after 010 --child -i "Write integration tests" 2>&1)
   ADD2_EXIT=$?
   [ "$ADD2_EXIT" -eq 0 ] && echo "PASS: Child 010.02 created" || echo "FAIL: Child creation failed"
   SANDBOX
   ```

2. Verify hierarchical structure and parent fields
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$SESSION_DIR/jobs/010.01-write-unit-tests.j.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Child 010.01 missing"
   [ -f "$SESSION_DIR/jobs/010.02-write-integration-tests.j.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Child 010.02 missing"

   grep -q 'parent:.*"010"' "$SESSION_DIR/jobs/010.01-write-unit-tests.j.md" && echo "PASS: Child 010.01 has parent field" || echo "FAIL: Child 010.01 missing parent field"
   grep -q 'parent:.*"010"' "$SESSION_DIR/jobs/010.02-write-integration-tests.j.md" && echo "PASS: Child 010.02 has parent field" || echo "FAIL: Child 010.02 missing parent field"
   SANDBOX
   ```

3. Check status and attempt to complete parent with incomplete children
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "implement-feature" && echo "INFO: Current step is implement-feature (parent)" || echo "INFO: Current step is not the parent"

   cat > "parent-report.md" << 'EOF'
# Parent Report

Attempting to complete parent with incomplete children.
EOF

   ADVANCE_OUTPUT=$($ACE_COWORKER report "parent-report.md" 2>&1)
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

**Expected:**
- Exit code: non-zero (error)
- Error message contains "incomplete children"
- Error message lists incomplete child job numbers (010.01, 010.02)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Error - Invalid --after Reference

**Objective:** Verify that `add --after` with an invalid job number fails with a clear error showing available jobs.

**Steps:**
1. Attempt to add job with invalid --after reference
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ADD_OUTPUT=$($ACE_COWORKER add test-step --after 999 -i "Test instructions" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"
   SANDBOX
   ```

2. Verify error exit code and available jobs listed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$ADD_EXIT" -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Expected non-zero exit code"
   echo "$ADD_OUTPUT" | grep -qi "not found" && echo "PASS: Error mentions 'not found'" || echo "FAIL: Error should mention 'not found'"
   echo "$ADD_OUTPUT" | grep -qi "available" && echo "PASS: Error mentions available jobs" || echo "FAIL: Error should mention available jobs"
   echo "$ADD_OUTPUT" | grep -q "010" && echo "PASS: Available jobs include 010" || echo "FAIL: Available jobs should include 010"
   SANDBOX
   ```

**Expected:**
- Exit code: non-zero (error)
- Error message contains "not found"
- Error message shows "Available jobs:" with existing job numbers

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

- [ ] TC-001: Advance parent with incomplete children fails with clear error listing children
- [ ] TC-002: Invalid --after reference fails with error showing available jobs
