---
tc-id: TC-001
title: Full Workflow Lifecycle
---

## Objective

Verify the full ace-coworker workflow lifecycle end-to-end: session creation via both deprecated and current commands, file structure verification, status display, step completion with reports, failure handling with queue stall, dynamic step addition with auto-activation, retry mechanics, and workflow completion.

## Steps

### Phase 1: Session Creation and Structure

1. Create session from job.yaml and verify exit code
   ```bash
   CREATE_OUTPUT=$(ace-coworker create job.yaml 2>&1)
   CREATE_EXIT=$?
   echo "Exit code: $CREATE_EXIT"
   echo "$CREATE_OUTPUT"
   [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Expected exit code 0, got $CREATE_EXIT"
   echo "$CREATE_OUTPUT" | grep -qE "Session:.*\(" && echo "PASS: Output shows session info" || echo "FAIL: No session info in output"
   echo "$CREATE_OUTPUT" | grep -q "analyze" && echo "PASS: First step 'analyze' shown" || echo "FAIL: First step not shown"
   ```

2. Verify on-disk file structure and array instructions
   ```bash
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   [ -f "$SESSION_DIR/session.yaml" ] && echo "PASS: session.yaml exists" || echo "FAIL: session.yaml missing"
   [ -d "$SESSION_DIR/jobs" ] && echo "PASS: jobs/ directory exists" || echo "FAIL: jobs/ missing"
   [ -d "$SESSION_DIR/reports" ] && echo "PASS: reports/ directory exists" || echo "FAIL: reports/ missing"
   STEP_COUNT=$(ls "$SESSION_DIR/jobs/"*.j.md 2>/dev/null | wc -l | tr -d ' ')
   [ "$STEP_COUNT" -eq 3 ] && echo "PASS: 3 step files created" || echo "FAIL: Expected 3 step files, found $STEP_COUNT"
   [ -f "$SESSION_DIR/jobs/010-analyze.j.md" ] && echo "PASS: 010-analyze.j.md exists" || echo "FAIL: 010-analyze.j.md missing"
   [ -f "$SESSION_DIR/jobs/020-implement.j.md" ] && echo "PASS: 020-implement.j.md exists" || echo "FAIL: 020-implement.j.md missing"
   [ -f "$SESSION_DIR/jobs/030-verify.j.md" ] && echo "PASS: 030-verify.j.md exists" || echo "FAIL: 030-verify.j.md missing"
   grep -q "status: in_progress" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "PASS: Step 010 is in_progress" || echo "FAIL: Step 010 not in_progress"
   grep -q 'skill:.*ace:research' "$SESSION_DIR/jobs/010-analyze.j.md" && echo "PASS: skill field preserved" || echo "FAIL: skill field missing"
   grep -q "Analyze the codebase structure" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "PASS: First instruction line present" || echo "FAIL: First instruction line missing"
   grep -q "Identify key components and dependencies" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "PASS: Second instruction line present" || echo "FAIL: Second instruction line missing"
   grep -q "Implement the required changes" "$SESSION_DIR/jobs/020-implement.j.md" && echo "PASS: Plain string instructions preserved" || echo "FAIL: Plain string instructions missing"
   ```

3. Verify negative assertions (wrong paths must NOT exist)
   ```bash
   [ ! -d ".coworker" ] && echo "PASS: .coworker/ does NOT exist" || echo "FAIL: .coworker/ exists (wrong path)"
   [ ! -f "$SESSION_DIR/queue.yaml" ] && echo "PASS: queue.yaml does NOT exist" || echo "FAIL: queue.yaml exists (wrong format)"
   [ ! -f "$SESSION_DIR/jobs/010-analyze.md" ] && echo "PASS: No .md files (correct .j.md)" || echo "FAIL: .md files exist"
   ```

### Phase 2: Status and Step Completion

4. Verify status output shows all steps and current step details
   ```bash
   STATUS_OUTPUT=$(ace-coworker status 2>&1)
   STATUS_EXIT=$?
   [ "$STATUS_EXIT" -eq 0 ] && echo "PASS: Status exit code 0" || echo "FAIL: Expected 0, got $STATUS_EXIT"
   echo "$STATUS_OUTPUT" | grep -q "analyze" && echo "PASS: analyze step shown" || echo "FAIL: analyze step missing"
   echo "$STATUS_OUTPUT" | grep -q "implement" && echo "PASS: implement step shown" || echo "FAIL: implement step missing"
   echo "$STATUS_OUTPUT" | grep -q "verify" && echo "PASS: verify step shown" || echo "FAIL: verify step missing"
   echo "$STATUS_OUTPUT" | grep -q "in_progress" && echo "PASS: in_progress status shown" || echo "FAIL: in_progress not shown"
   echo "$STATUS_OUTPUT" | grep -q "Skill:.*ace:research" && echo "PASS: Skill field displayed" || echo "FAIL: Skill field not displayed"
   ```

5. Complete analyze step with report and verify advancement
   ```bash
   REPORT_OUTPUT=$(ace-coworker report report.md 2>&1)
   REPORT_EXIT=$?
   [ "$REPORT_EXIT" -eq 0 ] && echo "PASS: Report exit code 0" || echo "FAIL: Expected 0, got $REPORT_EXIT"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   grep -q "status: done" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "PASS: Step 010 marked done" || echo "FAIL: Step 010 not done"
   grep -q "status: completed" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "FAIL: Uses 'completed' instead of 'done'" || echo "PASS: Does not use 'completed'"
   [ -f "$SESSION_DIR/reports/010-analyze.r.md" ] && echo "PASS: Report file created at reports/010-analyze.r.md" || echo "FAIL: Report file not found"
   grep -q "Analysis Report" "$SESSION_DIR/reports/010-analyze.r.md" && echo "PASS: Report content in .r.md file" || echo "FAIL: Report content missing"
   grep -q "Analysis Report" "$SESSION_DIR/jobs/010-analyze.j.md" && echo "FAIL: Report incorrectly in job file" || echo "PASS: Report NOT in job file"
   grep -q "status: in_progress" "$SESSION_DIR/jobs/020-implement.j.md" && echo "PASS: Step 020 now in_progress" || echo "FAIL: Step 020 not in_progress"
   ```

### Phase 3: Failure Handling

6. Mark current step as failed and verify queue stalls
   ```bash
   FAIL_OUTPUT=$(ace-coworker fail -m "Test failure: encountered blocking issue" 2>&1)
   FAIL_EXIT=$?
   [ "$FAIL_EXIT" -eq 0 ] && echo "PASS: Fail exit code 0" || echo "FAIL: Expected 0, got $FAIL_EXIT"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   grep -q "status: failed" "$SESSION_DIR/jobs/020-implement.j.md" && echo "PASS: Step 020 marked failed" || echo "FAIL: Step 020 not failed"
   grep -q "blocking issue" "$SESSION_DIR/jobs/020-implement.j.md" && echo "PASS: Error message recorded" || echo "FAIL: Error message not found"
   grep -q "status: pending" "$SESSION_DIR/jobs/030-verify.j.md" && echo "PASS: Step 030 still pending" || echo "FAIL: Step 030 not pending"
   ```

7. Verify queue is stalled and report is rejected
   ```bash
   STALL_STATUS=$(ace-coworker status 2>&1)
   echo "$STALL_STATUS" | grep -q "Current Step:" && echo "FAIL: Queue should be stalled" || echo "PASS: No current step (stalled)"
   echo "# Dummy" > stall-dummy-report.md
   STALL_OUTPUT=$(ace-coworker report stall-dummy-report.md 2>&1)
   STALL_EXIT=$?
   [ "$STALL_EXIT" -ne 0 ] && echo "PASS: Report rejected on stalled queue (exit $STALL_EXIT)" || echo "FAIL: Report should fail on stalled queue"
   echo "$STALL_OUTPUT" | grep -q "No step currently in progress" && echo "PASS: Correct stall error message" || echo "FAIL: Expected 'No step currently in progress'"
   ```

### Phase 4: Dynamic Steps and Retry

8. Add dynamic step (auto-activates on stalled queue) and complete it
   ```bash
   ADD_OUTPUT=$(ace-coworker add "fix-issue" -i "Fix the blocking issue that caused failure" 2>&1)
   ADD_EXIT=$?
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Add exit code 0" || echo "FAIL: Expected 0, got $ADD_EXIT"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   DYNAMIC_STEP=$(ls "$SESSION_DIR/jobs/"*fix-issue* 2>/dev/null | head -1)
   [ -f "$DYNAMIC_STEP" ] && echo "PASS: Dynamic step file created" || echo "FAIL: Dynamic step file not found"
   grep -q "added_by.*dynamic" "$DYNAMIC_STEP" && echo "PASS: added_by: dynamic present" || echo "FAIL: added_by: dynamic missing"
   grep -q "status: in_progress" "$DYNAMIC_STEP" && echo "PASS: Dynamic step auto-activated" || echo "FAIL: Dynamic step not auto-activated"
   ADD_STATUS=$(ace-coworker status 2>&1)
   echo "$ADD_STATUS" | grep -q "Current Step:.*fix-issue" && echo "PASS: Current step is fix-issue" || echo "FAIL: Current step is not fix-issue"
   ```

9. Complete dynamic step and verify auto-advance to 030-verify
   ```bash
   ace-coworker report fix-report.md
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   DYNAMIC_STEP=$(ls "$SESSION_DIR/jobs/"*fix-issue* 2>/dev/null | head -1)
   grep -q "status: done" "$DYNAMIC_STEP" && echo "PASS: fix-issue marked done" || echo "FAIL: fix-issue not done"
   grep -q "status: in_progress" "$SESSION_DIR/jobs/030-verify.j.md" && echo "PASS: 030-verify auto-advanced" || echo "FAIL: 030-verify not in_progress"
   ```

10. Retry failed step 020 (should NOT change current step)
    ```bash
    RETRY_OUTPUT=$(ace-coworker retry 020 2>&1)
    RETRY_EXIT=$?
    [ "$RETRY_EXIT" -eq 0 ] && echo "PASS: Retry exit code 0" || echo "FAIL: Expected 0, got $RETRY_EXIT"
    SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
    RETRY_STEP=$(ls "$SESSION_DIR/jobs/"*implement* 2>/dev/null | grep -v "020-implement" | head -1)
    [ -f "$RETRY_STEP" ] && echo "PASS: Retry step file created" || echo "FAIL: Retry step file not found"
    grep -q "retry_of.*020" "$RETRY_STEP" && echo "PASS: Retry linked to step 020" || echo "FAIL: Retry not linked"
    grep -q "status: pending" "$RETRY_STEP" && echo "PASS: Retry step is pending" || echo "FAIL: Retry should be pending"
    RETRY_STATUS=$(ace-coworker status 2>&1)
    echo "$RETRY_STATUS" | grep -q "Current Step:.*verify" && echo "PASS: 030-verify still current after retry" || echo "FAIL: Current step changed"
    ```

### Phase 5: Workflow Completion

11. Complete verify step and verify retry step auto-advances
    ```bash
    ace-coworker report verify-report.md
    SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
    grep -q "status: done" "$SESSION_DIR/jobs/030-verify.j.md" && echo "PASS: 030-verify done" || echo "FAIL: 030-verify not done"
    RETRY_STEP=$(ls "$SESSION_DIR/jobs/"*implement*.j.md 2>/dev/null | grep -v "020-implement" | head -1)
    grep -q "status: in_progress" "$RETRY_STEP" && echo "PASS: Retry step auto-advanced to in_progress" || echo "FAIL: Retry step not in_progress"
    ```

12. Complete retry step and verify session completion
    ```bash
    ace-coworker report implement-report.md
    SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
    RETRY_STEP=$(ls "$SESSION_DIR/jobs/"*implement*.j.md 2>/dev/null | grep -v "020-implement" | head -1)
    grep -q "status: done" "$RETRY_STEP" && echo "PASS: Retry step done" || echo "FAIL: Retry step not done"
    FINAL_STATUS=$(ace-coworker status 2>&1)
    echo "$FINAL_STATUS" | grep -q "Session completed!" && echo "PASS: Session shows completed" || echo "FAIL: Session not completed"
    PENDING=$(grep -rl "status: pending" "$SESSION_DIR/jobs/" 2>/dev/null | wc -l | tr -d ' ')
    IN_PROGRESS=$(grep -rl "status: in_progress" "$SESSION_DIR/jobs/" 2>/dev/null | wc -l | tr -d ' ')
    [ "$PENDING" -eq 0 ] && echo "PASS: No pending steps remain" || echo "FAIL: $PENDING pending steps remain"
    [ "$IN_PROGRESS" -eq 0 ] && echo "PASS: No in_progress steps remain" || echo "FAIL: $IN_PROGRESS in_progress steps remain"
    DONE_COUNT=$(grep -rl "status: done" "$SESSION_DIR/jobs/" 2>/dev/null | wc -l | tr -d ' ')
    FAILED_COUNT=$(grep -rl "status: failed" "$SESSION_DIR/jobs/" 2>/dev/null | wc -l | tr -d ' ')
    TOTAL=$((DONE_COUNT + FAILED_COUNT))
    STEP_COUNT=$(ls "$SESSION_DIR/jobs/"*.j.md 2>/dev/null | wc -l | tr -d ' ')
    [ "$TOTAL" -eq "$STEP_COUNT" ] && echo "PASS: All $STEP_COUNT steps are terminal" || echo "FAIL: $TOTAL of $STEP_COUNT terminal"
    ```

## Expected

### Phase 1
- Session created with exit code 0
- session.yaml, jobs/, reports/ directories exist
- 3 step files: 010-analyze.j.md, 020-implement.j.md, 030-verify.j.md
- First step in_progress with skill field and array instructions joined
- No wrong paths (.coworker/, queue.yaml, .md without .j.md)

### Phase 2
- Status shows all 3 steps, current step analyze with Skill: ace:research
- Report completes step 010 as "done" (not "completed"), creates separate .r.md report
- Step 020 advances to in_progress

### Phase 3
- Fail marks step 020 as failed with error message recorded
- Queue stalls: no Current Step in status, report rejected with "No step currently in progress"

### Phase 4
- Dynamic step auto-activates (in_progress) on stalled queue with added_by: dynamic
- Completing dynamic step auto-advances to 030-verify
- Retry creates pending step linked to 020, does NOT change current step

### Phase 5
- Completing verify auto-advances retry step to in_progress
- Completing retry step results in "Session completed!"
- All steps terminal (4 done + 1 failed)
