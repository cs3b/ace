---
test-id: MT-COWORKER-001
title: Workflow Lifecycle
area: coworker
package: ace-coworker
priority: high
duration: ~15min
automation-candidate: true
requires:
  tools: [ace-coworker]
  ruby: ">= 3.0"
last-verified: null
verified-by: null
---

# Workflow Lifecycle

## Objective

Verify that ace-coworker correctly manages the full workflow lifecycle including session creation, step progression, failure handling, dynamic step addition, and retry functionality.

## Prerequisites

- Ruby >= 3.0 installed
- ace-coworker package available (via bundle exec or installed)

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TEST_ID="$(ace-timestamp encode)"
TEST_DIR="$PROJECT_ROOT/.cache/test-e2e/${TEST_ID}-ace-coworker"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Set up command alias for ace-coworker
ACE_COWORKER="bundle exec $PROJECT_ROOT/ace-coworker/exe/ace-coworker"

# Verify tools are available
echo "=== Tool Verification ==="
$ACE_COWORKER --version
echo "========================="
```

## Test Data

```bash
# Create job.yaml with 3 steps for testing
cat > "$TEST_DIR/job.yaml" << 'EOF'
name: test-workflow
description: Test workflow for E2E testing
steps:
  - name: analyze
    instructions: Analyze the codebase structure
  - name: implement
    instructions: Implement the required changes
  - name: verify
    instructions: Verify the changes work correctly
EOF

echo "Test data created:"
cat "$TEST_DIR/job.yaml"
```

## Test Cases

### TC-001: Start Session from YAML Config

**Objective:** Verify that ace-coworker creates a session from YAML config with first step in_progress.

**Steps:**
1. Start workflow from config
   ```bash
   $ACE_COWORKER start -c "$TEST_DIR/job.yaml"
   ```

2. Verify session directory created
   ```bash
   SESSION_DIR=$(ls -d "$TEST_DIR/.coworker/sessions/"* 2>/dev/null | head -1)
   [ -d "$SESSION_DIR" ] && echo "PASS: Session directory created at $SESSION_DIR" || echo "FAIL: No session directory"
   ```

3. Verify queue.yaml exists
   ```bash
   [ -f "$SESSION_DIR/queue.yaml" ] && echo "PASS: queue.yaml exists" || echo "FAIL: queue.yaml missing"
   ```

4. Verify first step is in_progress
   ```bash
   grep -A1 "010:" "$SESSION_DIR/queue.yaml" | grep "status: in_progress" && echo "PASS: First step in_progress" || echo "FAIL: First step not in_progress"
   ```

**Expected:**
- Exit code: 0
- Session directory created under .coworker/sessions/
- queue.yaml created with all steps
- First step (010) status is in_progress

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Check Status

**Objective:** Verify that ace-coworker status displays the workflow queue correctly.

**Steps:**
1. Run status command
   ```bash
   $ACE_COWORKER status
   ```

2. Verify output includes all steps
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "analyze" && echo "PASS: analyze step shown" || echo "FAIL: analyze step missing"
   echo "$STATUS_OUTPUT" | grep -q "implement" && echo "PASS: implement step shown" || echo "FAIL: implement step missing"
   echo "$STATUS_OUTPUT" | grep -q "verify" && echo "PASS: verify step shown" || echo "FAIL: verify step missing"
   ```

3. Verify current step indicator
   ```bash
   echo "$STATUS_OUTPUT" | grep -E "(in_progress|current|▶)" && echo "PASS: Current step indicated" || echo "Note: Check output format for current step"
   ```

**Expected:**
- Exit code: 0
- All three steps (analyze, implement, verify) displayed
- Current step (analyze) indicated as in_progress

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Complete Step with Report

**Objective:** Verify that completing a step with a report advances to the next step.

**Steps:**
1. Create report content
   ```bash
   cat > "$TEST_DIR/report.md" << 'EOF'
# Analysis Report

## Findings
- Codebase structure is clean
- No issues found

## Recommendation
Proceed with implementation
EOF
   ```

2. Complete current step with report
   ```bash
   $ACE_COWORKER report "$TEST_DIR/report.md"
   ```

3. Verify step completed
   ```bash
   SESSION_DIR=$(ls -d "$TEST_DIR/.coworker/sessions/"* 2>/dev/null | head -1)
   grep -A1 "010:" "$SESSION_DIR/queue.yaml" | grep "status: completed" && echo "PASS: Step 010 completed" || echo "FAIL: Step 010 not completed"
   ```

4. Verify report file saved
   ```bash
   REPORT_FILE="$SESSION_DIR/reports/010-analyze.md"
   [ -f "$REPORT_FILE" ] && echo "PASS: Report saved" || echo "FAIL: Report not saved"
   ```

5. Verify next step started
   ```bash
   grep -A1 "020:" "$SESSION_DIR/queue.yaml" | grep "status: in_progress" && echo "PASS: Step 020 in_progress" || echo "FAIL: Step 020 not started"
   ```

**Expected:**
- Exit code: 0
- Step 010 marked as completed
- Report saved to session reports directory
- Step 020 (implement) now in_progress

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Mark Step as Failed

**Objective:** Verify that failing a step marks it failed and stops progression.

**Steps:**
1. Mark current step as failed
   ```bash
   $ACE_COWORKER fail -m "Test failure: encountered blocking issue"
   ```

2. Verify step marked failed
   ```bash
   SESSION_DIR=$(ls -d "$TEST_DIR/.coworker/sessions/"* 2>/dev/null | head -1)
   grep -A1 "020:" "$SESSION_DIR/queue.yaml" | grep "status: failed" && echo "PASS: Step 020 marked failed" || echo "FAIL: Step 020 not failed"
   ```

3. Verify no current step
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   # Check that no step shows as in_progress
   grep "status: in_progress" "$SESSION_DIR/queue.yaml" || echo "PASS: No step in_progress (expected after failure)"
   ```

**Expected:**
- Exit code: 0
- Step 020 (implement) marked as failed
- Error message recorded
- No step currently in_progress

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Add Dynamic Step

**Objective:** Verify that adding a dynamic step creates it and sets it as current.

**Steps:**
1. Add a new step dynamically
   ```bash
   $ACE_COWORKER add "fix-issue" -i "Fix the blocking issue that caused failure"
   ```

2. Verify new step created
   ```bash
   SESSION_DIR=$(ls -d "$TEST_DIR/.coworker/sessions/"* 2>/dev/null | head -1)
   grep "fix-issue" "$SESSION_DIR/queue.yaml" && echo "PASS: fix-issue step created" || echo "FAIL: fix-issue step missing"
   ```

3. Verify new step is in_progress
   ```bash
   # The new step should have a step number and be in_progress
   grep -B1 "fix-issue" "$SESSION_DIR/queue.yaml" | head -1
   grep -A2 "fix-issue" "$SESSION_DIR/queue.yaml" | grep "status: in_progress" && echo "PASS: New step in_progress" || echo "FAIL: New step not in_progress"
   ```

4. Check status to see new step
   ```bash
   $ACE_COWORKER status
   ```

**Expected:**
- Exit code: 0
- New step "fix-issue" created with instructions
- New step is now in_progress

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Retry Failed Step

**Objective:** Verify that retrying a failed step creates a linked retry step.

**Steps:**
1. First complete the fix-issue step
   ```bash
   cat > "$TEST_DIR/fix-report.md" << 'EOF'
# Fix Report

Issue has been resolved.
EOF
   $ACE_COWORKER report "$TEST_DIR/fix-report.md"
   ```

2. Verify fix-issue completed
   ```bash
   SESSION_DIR=$(ls -d "$TEST_DIR/.coworker/sessions/"* 2>/dev/null | head -1)
   cat "$SESSION_DIR/queue.yaml"
   ```

3. Retry the failed step (020)
   ```bash
   $ACE_COWORKER retry 020
   ```

4. Verify retry step created
   ```bash
   grep "retry" "$SESSION_DIR/queue.yaml" && echo "PASS: Retry step created" || echo "FAIL: Retry step missing"
   ```

5. Verify retry step is in_progress
   ```bash
   # Should show a new step that references the original failed step
   $ACE_COWORKER status
   ```

**Expected:**
- Exit code: 0
- Retry step created linked to step 020
- Retry step is now in_progress

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Complete Workflow

**Objective:** Verify that completing all remaining steps results in a completed workflow.

**Steps:**
1. Complete the retry step
   ```bash
   cat > "$TEST_DIR/implement-report.md" << 'EOF'
# Implementation Report

Changes implemented successfully.
EOF
   $ACE_COWORKER report "$TEST_DIR/implement-report.md"
   ```

2. Complete the verify step (030)
   ```bash
   cat > "$TEST_DIR/verify-report.md" << 'EOF'
# Verification Report

All tests pass. Changes verified.
EOF
   $ACE_COWORKER report "$TEST_DIR/verify-report.md"
   ```

3. Check final status
   ```bash
   $ACE_COWORKER status
   ```

4. Verify all original steps completed
   ```bash
   SESSION_DIR=$(ls -d "$TEST_DIR/.coworker/sessions/"* 2>/dev/null | head -1)
   echo "=== Final Queue State ==="
   cat "$SESSION_DIR/queue.yaml"
   echo "========================="

   # Count completed steps
   COMPLETED=$(grep "status: completed" "$SESSION_DIR/queue.yaml" | wc -l | tr -d ' ')
   echo "Completed steps: $COMPLETED"
   ```

5. Verify all reports saved
   ```bash
   echo "=== Reports Directory ==="
   ls -la "$SESSION_DIR/reports/"
   ```

**Expected:**
- All original steps (010, 020/retry, 030) completed
- Reports saved for each completed step
- Workflow shows as complete

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
echo "Cleanup complete"
```

## Success Criteria

- [ ] TC-001: Start session from YAML config succeeds
- [ ] TC-002: Status displays workflow queue correctly
- [ ] TC-003: Complete step with report advances workflow
- [ ] TC-004: Mark step as failed stops progression
- [ ] TC-005: Add dynamic step creates and activates step
- [ ] TC-006: Retry failed step creates linked retry
- [ ] TC-007: Complete workflow shows all steps done

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Tests use the bundle exec command to run ace-coworker from the development environment
- Session data is stored under .coworker/sessions/ in the test directory
- Each step completion creates a report file in the session's reports directory
- The retry mechanism creates a new step linked to the original failed step
