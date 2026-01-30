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
last-verified:
verified-by:
---

# Workflow Lifecycle

## Objective

Verify that ace-coworker correctly manages the full workflow lifecycle including session creation, step progression, failure handling, dynamic step addition, and retry functionality. Error paths are tested first to catch crashes early.

## Prerequisites

- Ruby >= 3.0 installed
- ace-coworker package available (via bundle exec or installed)

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="coworker"
SHORT_ID="mt001"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Ensure cache base directory exists (for first-time runs)
CACHE_BASE="$PROJECT_ROOT/.cache/ace-coworker"
mkdir -p "$CACHE_BASE"

# Set up command alias for ace-coworker
ACE_COWORKER="bundle exec $PROJECT_ROOT/ace-coworker/exe/ace-coworker"

# Verify tools are available
echo "=== Tool Verification ==="
$ACE_COWORKER --version
echo "========================="
```

## Test Data

```bash
# Create job.yaml with 3 steps for testing (includes skill field on analyze step)
cat > "$TEST_DIR/job.yaml" << 'EOF'
name: test-workflow
description: Test workflow for E2E testing
steps:
  - name: analyze
    skill: "ace:research"
    instructions:
      - Analyze the codebase structure
      - Identify key components and dependencies
  - name: implement
    instructions: Implement the required changes
  - name: verify
    instructions: Verify the changes work correctly
EOF

echo "Test data created:"
cat "$TEST_DIR/job.yaml"
```

## Test Cases

### TC-001: Error — Nonexistent Config File

**Objective:** Verify that `create` with a nonexistent config file exits with code 3 and a clear error message.

**Steps:**
1. Attempt to create a session with a nonexistent config
   ```bash
   OUTPUT=$($ACE_COWORKER create nonexistent.yaml 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code and error message
   ```bash
   [ "$EXIT_CODE" -eq 3 ] && echo "PASS: Exit code is 3" || echo "FAIL: Expected exit code 3, got $EXIT_CODE"
   echo "$OUTPUT" | grep -qi "not found" && echo "PASS: Error mentions 'not found'" || echo "FAIL: Error message does not mention 'not found'"
   ```

**Expected:**
- Exit code: 3
- Output contains: "Config file not found"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Error — Status with No Active Session

**Objective:** Verify that `status` with no active session exits with code 2 and a clear error message.

**Steps:**
1. Run status command from clean state (no session exists)
   ```bash
   OUTPUT=$($ACE_COWORKER status 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code and error message
   ```bash
   [ "$EXIT_CODE" -eq 2 ] && echo "PASS: Exit code is 2" || echo "FAIL: Expected exit code 2, got $EXIT_CODE"
   echo "$OUTPUT" | grep -qi "no active session" && echo "PASS: Error mentions 'No active session'" || echo "FAIL: Error message missing expected text"
   ```

**Expected:**
- Exit code: 2
- Output contains: "No active session"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Error — Report with No Active Session

**Objective:** Verify that `report` with no active session exits with code 2 rather than crashing.

**Steps:**
1. Create a dummy report file
   ```bash
   echo "# Dummy" > "$TEST_DIR/dummy-report.md"
   ```

2. Run report command from clean state
   ```bash
   OUTPUT=$($ACE_COWORKER report "$TEST_DIR/dummy-report.md" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify exit code
   ```bash
   [ "$EXIT_CODE" -eq 2 ] && echo "PASS: Exit code is 2" || echo "FAIL: Expected exit code 2, got $EXIT_CODE"
   ```

**Expected:**
- Exit code: 2
- Output contains: "No active session"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Deprecated `start` Command Migration

**Objective:** Verify that the deprecated `start` command works as a migration alias to `create` with a deprecation warning, creating a session successfully.

**Steps:**
1. Attempt to use the old `start` command
   ```bash
   OUTPUT=$($ACE_COWORKER start "$TEST_DIR/job.yaml" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is 0 (success)
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

3. Verify deprecation warning is shown
   ```bash
   echo "$OUTPUT" | grep -qi "deprecated" && echo "PASS: Deprecation warning shown" || echo "FAIL: No deprecation warning found"
   ```

4. Verify session was created
   ```bash
   SESSION_COUNT=$(find "$PROJECT_ROOT/.cache/ace-coworker" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
   [ "$SESSION_COUNT" -gt 0 ] && echo "PASS: Session created by 'start' ($SESSION_COUNT found)" || echo "FAIL: No session created"
   ```

5. Verify output matches `create` command (contains session ID and first step)
   ```bash
   echo "$OUTPUT" | grep -qE "Session:.*\(" && echo "PASS: Output shows session info" || echo "FAIL: No session info in output"
   echo "$OUTPUT" | grep -q "analyze" && echo "PASS: First step shown" || echo "FAIL: First step not shown"
   ```

**Expected:**
- Exit code: 0 (success)
- Stderr contains: "deprecated" warning
- Session IS created (migration works)
- Output matches `create` command output

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004b: Cache Directory Auto-Creation

**Objective:** Verify that the cache base directory is created automatically on first use.

**Steps:**
1. Remove cache directory if it exists
   ```bash
   CACHE_BASE="$PROJECT_ROOT/.cache/ace-coworker"
   rm -rf "$CACHE_BASE"
   [ ! -d "$CACHE_BASE" ] && echo "PASS: Cache removed" || echo "FAIL: Cache still exists"
   ```

2. Create a session (should auto-create cache directory)
   ```bash
   OUTPUT=$($ACE_COWORKER create "$TEST_DIR/job.yaml" 2>&1)
   EXIT_CODE=$?
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Creation failed (exit $EXIT_CODE)"
   ```

3. Verify cache directory was created
   ```bash
   [ -d "$CACHE_BASE" ] && echo "PASS: Cache directory auto-created" || echo "FAIL: Cache missing"
   ```

**Expected:**
- Cache directory created automatically
- Session creation succeeds

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Create Session from YAML Config

**Objective:** Verify that `ace-coworker create job.yaml` creates a session with the first step in_progress. Note: TC-004 already created a session via the deprecated `start` command, so this creates a second session.

**Steps:**
1. Create workflow from config
   ```bash
   CREATE_OUTPUT=$($ACE_COWORKER create "$TEST_DIR/job.yaml" 2>&1)
   CREATE_EXIT=$?
   echo "Exit code: $CREATE_EXIT"
   echo "Output:"
   echo "$CREATE_OUTPUT"
   ```

2. Verify exit code
   ```bash
   [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $CREATE_EXIT"
   ```

3. Verify output contains session ID
   ```bash
   echo "$CREATE_OUTPUT" | grep -qE "Session:.*\(" && echo "PASS: Output shows session info" || echo "FAIL: No session info in output"
   ```

4. Extract session ID from output for later tests
   ```bash
   SESSION_ID=$(echo "$CREATE_OUTPUT" | grep -oE '\(([a-z0-9]+)\)' | head -1 | tr -d '()')
   echo "Session ID: $SESSION_ID"
   [ -n "$SESSION_ID" ] && echo "PASS: Session ID extracted" || echo "FAIL: Could not extract session ID"
   ```

5. Verify output mentions first step
   ```bash
   echo "$CREATE_OUTPUT" | grep -q "analyze" && echo "PASS: First step 'analyze' shown" || echo "FAIL: First step not shown in output"
   echo "$CREATE_OUTPUT" | grep -q "in_progress" && echo "PASS: Step status shown as in_progress" || echo "FAIL: Step status not shown"
   ```

**Expected:**
- Exit code: 0
- Output contains session ID
- Output shows first step "analyze" with status in_progress

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Verify Actual File Structure + Array Instructions

**Objective:** Verify that the session creates the correct on-disk structure, that array instructions are normalized, and that old/wrong paths do NOT exist.

**Steps:**
1. Verify session directory exists in `.cache/ace-coworker/`
   ```bash
   SESSION_DIR=$(find "$TEST_DIR/.cache/ace-coworker" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   [ -d "$SESSION_DIR" ] && echo "PASS: Session directory found at $SESSION_DIR" || echo "FAIL: No session directory in .cache/ace-coworker/"
   ```

2. Verify session.yaml exists
   ```bash
   [ -f "$SESSION_DIR/session.yaml" ] && echo "PASS: session.yaml exists" || echo "FAIL: session.yaml missing"
   ```

3. Verify jobs/ directory with step files (.j.md extension)
   ```bash
   [ -d "$SESSION_DIR/jobs" ] && echo "PASS: jobs/ directory exists" || echo "FAIL: jobs/ directory missing"
   STEP_COUNT=$(ls "$SESSION_DIR/jobs/"*.j.md 2>/dev/null | wc -l | tr -d ' ')
   [ "$STEP_COUNT" -eq 3 ] && echo "PASS: 3 step files created" || echo "FAIL: Expected 3 step files, found $STEP_COUNT"
   ```

4. Verify step file naming convention (010-analyze.j.md, 020-implement.j.md, 030-verify.j.md)
   ```bash
   [ -f "$SESSION_DIR/jobs/010-analyze.j.md" ] && echo "PASS: 010-analyze.j.md exists" || echo "FAIL: 010-analyze.j.md missing"
   [ -f "$SESSION_DIR/jobs/020-implement.j.md" ] && echo "PASS: 020-implement.j.md exists" || echo "FAIL: 020-implement.j.md missing"
   [ -f "$SESSION_DIR/jobs/030-verify.j.md" ] && echo "PASS: 030-verify.j.md exists" || echo "FAIL: 030-verify.j.md missing"
   ```

5. Verify reports/ directory exists (for split report files)
   ```bash
   [ -d "$SESSION_DIR/reports" ] && echo "PASS: reports/ directory exists" || echo "FAIL: reports/ directory missing"
   ```

6. Verify first step frontmatter has status in_progress
   ```bash
   grep -q "status: in_progress" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "PASS: Step 010 is in_progress" || echo "FAIL: Step 010 not in_progress"
   ```

7. Verify skill field preserved in step file
   ```bash
   grep -q 'skill:.*ace:research' "$SESSION_DIR/jobs/010-analyze.j.md" && echo "PASS: skill field preserved in step file" || echo "FAIL: skill field missing from step file"
   ```

8. Verify array instructions were joined in step file (normalize_instructions)
   ```bash
   grep -q "Analyze the codebase structure" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "PASS: First instruction line present" || echo "FAIL: First instruction line missing"
   grep -q "Identify key components and dependencies" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "PASS: Second instruction line present" || echo "FAIL: Second instruction line missing"
   ```

9. Verify plain string instructions also work (020-implement.j.md)
   ```bash
   grep -q "Implement the required changes" "$SESSION_DIR/jobs/020-implement.j.md" && echo "PASS: Plain string instructions preserved" || echo "FAIL: Plain string instructions missing"
   ```

10. Negative assertions — wrong paths must NOT exist
    ```bash
    [ ! -d "$TEST_DIR/.coworker" ] && echo "PASS: .coworker/ does NOT exist (correct)" || echo "FAIL: .coworker/ exists (wrong path)"
    [ ! -f "$SESSION_DIR/queue.yaml" ] && echo "PASS: queue.yaml does NOT exist (correct)" || echo "FAIL: queue.yaml exists (wrong format)"
    [ ! -f "$SESSION_DIR/jobs/010-analyze.md" ] && echo "PASS: No .md files (correct)" || echo "FAIL: .md files exist (should be .j.md)"
    ```

**Expected:**
- `.cache/ace-coworker/<id>/session.yaml` exists
- `.cache/ace-coworker/<id>/jobs/` contains 3 .j.md step files
- `.cache/ace-coworker/<id>/reports/` directory exists
- Step files named: `010-analyze.j.md`, `020-implement.j.md`, `030-verify.j.md`
- First step has `status: in_progress` in frontmatter
- Skill field `ace:research` preserved in `010-analyze.j.md`
- Array instructions (analyze step) joined into step file body
- Plain string instructions (implement step) preserved as-is
- NO `.coworker/` directory, NO `queue.yaml`, NO `.md` files (only `.j.md` and `.r.md`)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Check Status Output

**Objective:** Verify that `status` displays all steps, current step details, and skill field.

**Steps:**
1. Run status command
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   STATUS_EXIT=$?
   echo "Exit code: $STATUS_EXIT"
   echo "Output:"
   echo "$STATUS_OUTPUT"
   ```

2. Verify exit code
   ```bash
   [ "$STATUS_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $STATUS_EXIT"
   ```

3. Verify all three steps shown in output
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "analyze" && echo "PASS: analyze step shown" || echo "FAIL: analyze step missing"
   echo "$STATUS_OUTPUT" | grep -q "implement" && echo "PASS: implement step shown" || echo "FAIL: implement step missing"
   echo "$STATUS_OUTPUT" | grep -q "verify" && echo "PASS: verify step shown" || echo "FAIL: verify step missing"
   ```

4. Verify current step indicator
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "in_progress" && echo "PASS: in_progress status shown" || echo "FAIL: in_progress not shown"
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*analyze" && echo "PASS: Current step is analyze" || echo "FAIL: Current step not analyze"
   ```

5. Verify skill field displayed
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Skill:.*ace:research" && echo "PASS: Skill field displayed" || echo "FAIL: Skill field not displayed"
   ```

**Expected:**
- Exit code: 0
- All three steps (analyze, implement, verify) displayed
- Current step is analyze with in_progress status
- Skill field "ace:research" shown for analyze step

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Complete Step with Report

**Objective:** Verify that reporting on a step marks it `done` (not `completed`), creates a separate .r.md report file in reports/ directory, and advances to the next step.

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
   REPORT_OUTPUT=$($ACE_COWORKER report "$TEST_DIR/report.md" 2>&1)
   REPORT_EXIT=$?
   echo "Exit code: $REPORT_EXIT"
   echo "Output:"
   echo "$REPORT_OUTPUT"
   ```

3. Verify exit code
   ```bash
   [ "$REPORT_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $REPORT_EXIT"
   ```

4. Find session directory
   ```bash
   SESSION_DIR=$(find "$TEST_DIR/.cache/ace-coworker" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   ```

5. Verify step 010 marked as `done` (NOT `completed`)
   ```bash
   grep -q "status: done" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "PASS: Step 010 is done" || echo "FAIL: Step 010 not marked done"
   grep -q "status: completed" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "FAIL: Step uses 'completed' instead of 'done'" || echo "PASS: Step does not use 'completed'"
   ```

6. Verify report file created in reports/ directory
   ```bash
   [ -f "$SESSION_DIR/reports/010-analyze.r.md" ] && echo "PASS: Report file created at reports/010-analyze.r.md" || echo "FAIL: Report file not found"
   grep -q "Analysis Report" "$SESSION_DIR/reports/010-analyze.r.md" && echo "PASS: Report content in .r.md file" || echo "FAIL: Report content not found in .r.md file"
   ```

7. Verify report NOT appended inline to job file
   ```bash
   grep -q "Analysis Report" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "FAIL: Report content incorrectly appended to job file" || echo "PASS: Report content NOT in job file (correct)"
   ```

8. Verify next step (020) is now in_progress
   ```bash
   grep -q "status: in_progress" "$SESSION_DIR/jobs/020-implement.j.md" && echo "PASS: Step 020 is in_progress" || echo "FAIL: Step 020 not in_progress"
   ```

**Expected:**
- Exit code: 0
- Step 010 marked as `done` (not `completed`)
- Report content in separate `reports/010-analyze.r.md` file
- Report NOT in job file
- Step 020 (implement) now in_progress

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-009: Mark Step as Failed

**Objective:** Verify that failing a step marks it `failed` with an error message and does NOT auto-advance.

**Steps:**
1. Mark current step as failed
   ```bash
   FAIL_OUTPUT=$($ACE_COWORKER fail -m "Test failure: encountered blocking issue" 2>&1)
   FAIL_EXIT=$?
   echo "Exit code: $FAIL_EXIT"
   echo "Output:"
   echo "$FAIL_OUTPUT"
   ```

2. Verify exit code
   ```bash
   [ "$FAIL_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $FAIL_EXIT"
   ```

3. Find session directory
   ```bash
   SESSION_DIR=$(find "$TEST_DIR/.cache/ace-coworker" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   ```

4. Verify step 020 marked as failed
   ```bash
   grep -q "status: failed" "$SESSION_DIR/jobs/020-implement.j.md" && echo "PASS: Step 020 marked failed" || echo "FAIL: Step 020 not marked failed"
   ```

5. Verify error message recorded in step file
   ```bash
   grep -q "blocking issue" "$SESSION_DIR/jobs/020-implement.j.md" && echo "PASS: Error message recorded" || echo "FAIL: Error message not found in step file"
   ```

6. Verify no auto-advance — step 030 should still be pending
   ```bash
   grep -q "status: pending" "$SESSION_DIR/jobs/030-verify.j.md" && echo "PASS: Step 030 still pending (no auto-advance)" || echo "FAIL: Step 030 is not pending"
   ```

7. Verify queue is stalled — status shows no current step
   ```bash
   STALL_STATUS=$($ACE_COWORKER status 2>&1)
   echo "$STALL_STATUS" | grep -q "Current Step:" && echo "FAIL: Queue should be stalled but shows a current step" || echo "PASS: No current step — queue is stalled after fail"
   ```

8. Verify report is rejected when queue is stalled
   ```bash
   echo "# Dummy" > "$TEST_DIR/stall-dummy-report.md"
   STALL_OUTPUT=$($ACE_COWORKER report "$TEST_DIR/stall-dummy-report.md" 2>&1)
   STALL_EXIT=$?
   [ "$STALL_EXIT" -ne 0 ] && echo "PASS: Report rejected on stalled queue (exit $STALL_EXIT)" || echo "FAIL: Report should fail on stalled queue"
   echo "$STALL_OUTPUT" | grep -q "No step currently in progress" && echo "PASS: Correct stall error message" || echo "FAIL: Expected 'No step currently in progress' message"
   ```

**Expected:**
- Exit code: 0
- Step 020 (implement) marked as `failed`
- Error message "blocking issue" recorded in step file
- Step 030 remains `pending` (failure does not auto-advance)
- Status shows no "Current Step:" line (queue is stalled)
- Report command rejected with exit code 1 and "No step currently in progress" message

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-010: Add Dynamic Step and Retry Failed Step

**Objective:** Verify that adding a dynamic step auto-activates it when the queue is stalled, that completing it auto-advances to the next pending step, and that retry creates a pending step without changing the current step.

**Steps:**
1. Add a dynamic step (queue is stalled after TC-009 fail)
   ```bash
   ADD_OUTPUT=$($ACE_COWORKER add "fix-issue" -i "Fix the blocking issue that caused failure" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"
   ```

2. Verify exit code
   ```bash
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $ADD_EXIT"
   ```

3. Find session directory and verify dynamic step file exists
   ```bash
   SESSION_DIR=$(find "$TEST_DIR/.cache/ace-coworker" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   DYNAMIC_STEP=$(ls "$SESSION_DIR/jobs/"*fix-issue* 2>/dev/null | head -1)
   [ -f "$DYNAMIC_STEP" ] && echo "PASS: Dynamic step file created at $DYNAMIC_STEP" || echo "FAIL: Dynamic step file not found"
   ```

4. Verify dynamic step has `added_by: dynamic`
   ```bash
   grep -q "added_by.*dynamic" "$DYNAMIC_STEP" && echo "PASS: added_by: dynamic present" || echo "FAIL: added_by: dynamic missing"
   ```

5. Verify add auto-activated the step (queue was stalled, so new step becomes in_progress)
   ```bash
   grep -q "status: in_progress" "$DYNAMIC_STEP" && echo "PASS: Dynamic step auto-activated (in_progress)" || echo "FAIL: Dynamic step not auto-activated"
   ADD_STATUS=$($ACE_COWORKER status 2>&1)
   echo "$ADD_STATUS" | grep -q "Current Step:.*fix-issue" && echo "PASS: Current step is fix-issue" || echo "FAIL: Current step is not fix-issue"
   ```

6. Complete the dynamic step
   ```bash
   cat > "$TEST_DIR/fix-report.md" << 'EOF'
# Fix Report

Issue has been resolved.
EOF
   $ACE_COWORKER report "$TEST_DIR/fix-report.md"
   ```

7. Verify auto-advance after completing fix-issue: 030-verify should now be in_progress
   ```bash
   grep -q "status: done" "$DYNAMIC_STEP" && echo "PASS: fix-issue step marked done" || echo "FAIL: fix-issue step not marked done"
   grep -q "status: in_progress" "$SESSION_DIR/jobs/030-verify.j.md" && echo "PASS: 030-verify auto-advanced to in_progress" || echo "FAIL: 030-verify not in_progress"
   ADV_STATUS=$($ACE_COWORKER status 2>&1)
   echo "$ADV_STATUS" | grep -q "Current Step:.*verify" && echo "PASS: Current step is verify after auto-advance" || echo "FAIL: Current step is not verify"
   ```

8. Retry the failed step (020) — should NOT change current step
   ```bash
   RETRY_OUTPUT=$($ACE_COWORKER retry 020 2>&1)
   RETRY_EXIT=$?
   echo "Exit code: $RETRY_EXIT"
   echo "Output:"
   echo "$RETRY_OUTPUT"
   ```

9. Verify retry exit code
   ```bash
   [ "$RETRY_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $RETRY_EXIT"
   ```

10. Verify retry step created with link to original
    ```bash
    RETRY_STEP=$(ls "$SESSION_DIR/jobs/"*implement* 2>/dev/null | grep -v "020-implement" | head -1)
    [ -f "$RETRY_STEP" ] && echo "PASS: Retry step file created at $RETRY_STEP" || echo "FAIL: Retry step file not found"
    grep -q "retry_of.*020" "$RETRY_STEP" && echo "PASS: Retry linked to original step 020" || echo "FAIL: Retry not linked to step 020"
    ```

11. Verify retry did NOT auto-activate — 030-verify is still current, retry is pending
    ```bash
    grep -q "status: pending" "$RETRY_STEP" && echo "PASS: Retry step is pending (not auto-activated)" || echo "FAIL: Retry step should be pending"
    RETRY_STATUS=$($ACE_COWORKER status 2>&1)
    echo "$RETRY_STATUS" | grep -q "Current Step:.*verify" && echo "PASS: 030-verify still current after retry" || echo "FAIL: Current step changed after retry"
    ```

**Expected:**
- Dynamic step "fix-issue" created with `added_by: dynamic` and auto-activated to `in_progress`
- After completing fix-issue, 030-verify auto-advances to `in_progress`
- Retry step created linked via `added_by: retry_of:020` with status `pending`
- Retry does NOT change current step (030-verify remains current)
- All operations exit code 0

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-011: Complete Remaining Steps — Workflow Completion

**Objective:** Verify that completing all remaining steps results in a completed session with "Session completed!" output. Validates that each report completes the expected step by checking step file status transitions.

**Queue entering TC-011:**
```
010-analyze:       done
011-fix-issue:     done        (dynamic, completed in TC-010)
020-implement:     failed      (original failure from TC-009)
030-verify:        in_progress ← CURRENT
031-implement:     pending     (retry of 020, created in TC-010)
```

**Steps:**
1. Complete the verify step (030-verify, currently in_progress)
   ```bash
   SESSION_DIR=$(find "$TEST_DIR/.cache/ace-coworker" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   cat > "$TEST_DIR/verify-report.md" << 'EOF'
# Verification Report

All tests pass. Changes verified.
EOF
   VERIFY_OUTPUT=$($ACE_COWORKER report "$TEST_DIR/verify-report.md" 2>&1)
   VERIFY_EXIT=$?
   echo "Exit code: $VERIFY_EXIT"
   [ "$VERIFY_EXIT" -eq 0 ] && echo "PASS: Report accepted" || echo "FAIL: Report rejected (exit $VERIFY_EXIT)"
   ```

2. Verify 030-verify is now done and retry step (031) auto-advanced to in_progress
   ```bash
   grep -q "status: done" "$SESSION_DIR/jobs/030-verify.j.md" && echo "PASS: 030-verify marked done" || echo "FAIL: 030-verify not done"
   RETRY_STEP=$(ls "$SESSION_DIR/jobs/"*implement*.j.md 2>/dev/null | grep -v "020-implement" | head -1)
   grep -q "status: in_progress" "$RETRY_STEP" && echo "PASS: Retry step (031) auto-advanced to in_progress" || echo "FAIL: Retry step not in_progress"
   TC011_STATUS=$($ACE_COWORKER status 2>&1)
   echo "$TC011_STATUS" | grep -q "Current Step:.*implement" && echo "PASS: Current step is now implement (retry)" || echo "FAIL: Current step is not implement"
   ```

3. Complete the retry step (031-implement, auto-advanced after verify)
   ```bash
   cat > "$TEST_DIR/implement-report.md" << 'EOF'
# Implementation Report

Changes implemented successfully.
EOF
   IMPL_OUTPUT=$($ACE_COWORKER report "$TEST_DIR/implement-report.md" 2>&1)
   IMPL_EXIT=$?
   echo "Exit code: $IMPL_EXIT"
   [ "$IMPL_EXIT" -eq 0 ] && echo "PASS: Report accepted" || echo "FAIL: Report rejected (exit $IMPL_EXIT)"
   ```

4. Verify retry step is now done
   ```bash
   grep -q "status: done" "$RETRY_STEP" && echo "PASS: Retry step marked done" || echo "FAIL: Retry step not done"
   ```

5. Check final status
   ```bash
   FINAL_STATUS=$($ACE_COWORKER status 2>&1)
   FINAL_EXIT=$?
   echo "Exit code: $FINAL_EXIT"
   echo "Output:"
   echo "$FINAL_STATUS"
   ```

6. Verify "Session completed!" in output
   ```bash
   echo "$FINAL_STATUS" | grep -q "Session completed!" && echo "PASS: Session shows completed" || echo "FAIL: Session not shown as completed"
   ```

7. Verify all steps are done or failed (none pending/in_progress)
   ```bash
   PENDING=$(grep -rl "status: pending" "$SESSION_DIR/jobs/" 2>/dev/null | wc -l | tr -d ' ')
   IN_PROGRESS=$(grep -rl "status: in_progress" "$SESSION_DIR/jobs/" 2>/dev/null | wc -l | tr -d ' ')
   [ "$PENDING" -eq 0 ] && echo "PASS: No pending steps remain" || echo "FAIL: $PENDING pending steps remain"
   [ "$IN_PROGRESS" -eq 0 ] && echo "PASS: No in_progress steps remain" || echo "FAIL: $IN_PROGRESS in_progress steps remain"
   ```

8. Count completed steps
   ```bash
   DONE_COUNT=$(grep -rl "status: done" "$SESSION_DIR/jobs/" 2>/dev/null | wc -l | tr -d ' ')
   FAILED_COUNT=$(grep -rl "status: failed" "$SESSION_DIR/jobs/" 2>/dev/null | wc -l | tr -d ' ')
   echo "Done: $DONE_COUNT, Failed: $FAILED_COUNT"
   TOTAL=$((DONE_COUNT + FAILED_COUNT))
   STEP_COUNT=$(ls "$SESSION_DIR/jobs/"*.md 2>/dev/null | wc -l | tr -d ' ')
   [ "$TOTAL" -eq "$STEP_COUNT" ] && echo "PASS: All $STEP_COUNT steps are terminal (done or failed)" || echo "FAIL: $TOTAL of $STEP_COUNT steps are terminal"
   ```

**Expected:**
- Step 1 completes 030-verify (the current in_progress step), NOT the retry step
- Step 2 confirms 031-implement auto-advanced to in_progress after 030-verify completed
- Step 3 completes 031-implement (the retry step)
- `status` output contains "Session completed!"
- No steps remain as pending or in_progress
- All 5 step files have terminal status (4 done + 1 failed)

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

- [ ] TC-001: Nonexistent config file exits with code 3
- [ ] TC-002: Status with no session exits with code 2
- [ ] TC-003: Report with no session exits with code 2
- [ ] TC-004: Deprecated `start` command works as migration alias with deprecation warning (exit 0)
- [ ] TC-004b: Cache directory is auto-created on first use
- [ ] TC-005: Create session from YAML config succeeds
- [ ] TC-006: File structure correct, array instructions normalized, negative assertions pass
- [ ] TC-007: Status displays all steps, current step, and skill field
- [ ] TC-008: Complete step marks `done`, creates separate .r.md report file, advances to correct next step
- [ ] TC-009: Failed step stops progression, stalls queue, report rejected on stalled queue
- [ ] TC-010: Add auto-activates on stalled queue, auto-advance targets correct step, retry stays pending
- [ ] TC-011: Reports complete the correct steps in order, session shows "Session completed!"

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

### 0.1.2 Fixes Reflected in This Test

- **`start` renamed to `create`** — the old `start` positional arg is now a migration alias to `create` with deprecation warning; TC-004 verifies the migration behavior
- **Array instructions supported** — `normalize_instructions` joins arrays into step body; TC-006 verifies both array (analyze) and string (implement/verify) formats
- **`wfi://coworker-prepare-job` protocol registered** — no longer missing

### Cache Directory Auto-Creation (added in v0.1.8)

- **Cache base directory initialization** — TC-004b verifies that `.cache/ace-coworker/` is automatically created on first use
- Previously, the base cache directory had to be created manually or the first session creation would fail with `Errno::ENOENT`
- The fix ensures `FileUtils.mkdir_p(@cache_base)` is called before `generate_session_id` in `SessionManager.create()`

### State Machine Assertions (added in review)

TC-009 through TC-011 verify the actual state machine transitions, not just command exit codes:

- **TC-009**: After `fail`, the queue is stalled (no `Current Step:` in status), and `report` is rejected with "No step currently in progress"
- **TC-010**: `add` auto-activates when the queue is stalled (fix-issue becomes `in_progress`); completing fix-issue auto-advances to 030-verify (not the retry step); `retry` creates a `pending` step without changing the current step
- **TC-011**: Documents the exact queue state entering the test case; verifies each `report` completes the expected step by checking step file frontmatter; confirms auto-advance from 030-verify to 031-implement (the retry step)

### Implementation Details

- Status value is `done` (not `completed`) — verify actual YAML frontmatter values
- Reports are stored in separate `reports/*.r.md` files, not inline in job files
- Job files use `.j.md` extension (e.g., `010-analyze.j.md`)
- Report files use `.r.md` extension (e.g., `010-analyze.r.md`)
- Session data lives under `.cache/ace-coworker/<id>/`, not `.coworker/sessions/`
- Queue state is individual `jobs/*.j.md` files, not a single `queue.yaml`
- Error TCs (001-004) run first from clean state to catch crashes before session creation
- The `skill` field in job.yaml is preserved through to step files and status output
- `add` auto-activates (sets `in_progress`) when no step is currently in progress; `retry` always creates as `pending`
- `report` always completes `state.current` — it does not match on report filename
