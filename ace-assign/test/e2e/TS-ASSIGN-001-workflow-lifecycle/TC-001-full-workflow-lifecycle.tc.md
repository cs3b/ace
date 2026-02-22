---
tc-id: TC-001
title: Full Workflow Lifecycle
---

## Objective

Verify the full ace-assign workflow lifecycle end-to-end: assignment creation via both deprecated and current commands, file structure verification, status display, phase completion with reports, failure handling with queue stall, dynamic phase addition with auto-activation, retry mechanics, and workflow completion.

## Steps

### Phase 1: Assignment Creation and Structure

1. Create assignment from job.yaml and verify exit code
   ```bash
   CREATE_OUTPUT=$(ace-assign create job.yaml 2>&1)
   CREATE_EXIT=$?
   echo "Exit code: $CREATE_EXIT"
   echo "$CREATE_OUTPUT"
   [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Assignment created" || echo "FAIL: Expected exit code 0, got $CREATE_EXIT"
   echo "$CREATE_OUTPUT" | grep -qE "Assignment:.*\(" && echo "PASS: Output shows assignment info" || echo "FAIL: No assignment info in output"
   echo "$CREATE_OUTPUT" | grep -q "analyze" && echo "PASS: First phase 'analyze' shown" || echo "FAIL: First phase not shown"
   ```

2. Verify on-disk file structure and array instructions
   ```bash
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   [ -f "$ASSIGNMENT_DIR/assignment.yaml" ] && echo "PASS: assignment.yaml exists" || echo "FAIL: assignment.yaml missing"
   [ -d "$ASSIGNMENT_DIR/phases" ] && echo "PASS: phases/ directory exists" || echo "FAIL: phases/ missing"
   [ -d "$ASSIGNMENT_DIR/reports" ] && echo "PASS: reports/ directory exists" || echo "FAIL: reports/ missing"
   PHASE_COUNT=$(ls "$ASSIGNMENT_DIR/phases/"*.ph.md 2>/dev/null | wc -l | tr -d ' ')
   [ "$PHASE_COUNT" -eq 3 ] && echo "PASS: 3 phase files created" || echo "FAIL: Expected 3 phase files, found $PHASE_COUNT"
   [ -f "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" ] && echo "PASS: 010-analyze.ph.md exists" || echo "FAIL: 010-analyze.ph.md missing"
   [ -f "$ASSIGNMENT_DIR/phases/020-implement.ph.md" ] && echo "PASS: 020-implement.ph.md exists" || echo "FAIL: 020-implement.ph.md missing"
   [ -f "$ASSIGNMENT_DIR/phases/030-verify.ph.md" ] && echo "PASS: 030-verify.ph.md exists" || echo "FAIL: 030-verify.ph.md missing"
   grep -q "status: in_progress" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "PASS: Phase 010 is in_progress" || echo "FAIL: Phase 010 not in_progress"
   grep -q 'skill:.*ace-search-research' "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "PASS: skill field preserved" || echo "FAIL: skill field missing"
   grep -q "Analyze the codebase structure" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "PASS: First instruction line present" || echo "FAIL: First instruction line missing"
   grep -q "Identify key components and dependencies" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "PASS: Second instruction line present" || echo "FAIL: Second instruction line missing"
   grep -q "Implement the required changes" "$ASSIGNMENT_DIR/phases/020-implement.ph.md" && echo "PASS: Plain string instructions preserved" || echo "FAIL: Plain string instructions missing"
   ```

3. Verify negative assertions (wrong paths must NOT exist)
   ```bash
   [ ! -d ".assign" ] && echo "PASS: .assign/ does NOT exist" || echo "FAIL: .assign/ exists (wrong path)"
   [ ! -f "$ASSIGNMENT_DIR/queue.yaml" ] && echo "PASS: queue.yaml does NOT exist" || echo "FAIL: queue.yaml exists (wrong format)"
   [ ! -f "$ASSIGNMENT_DIR/phases/010-analyze.md" ] && echo "PASS: No .md files (correct .ph.md)" || echo "FAIL: .md files exist"
   ```

### Phase 2: Status and Phase Completion

4. Verify status output shows all phases and current phase details
   ```bash
   STATUS_OUTPUT=$(ace-assign status 2>&1)
   STATUS_EXIT=$?
   [ "$STATUS_EXIT" -eq 0 ] && echo "PASS: Status exit code 0" || echo "FAIL: Expected 0, got $STATUS_EXIT"
   echo "$STATUS_OUTPUT" | grep -q "analyze" && echo "PASS: analyze phase shown" || echo "FAIL: analyze phase missing"
   echo "$STATUS_OUTPUT" | grep -q "implement" && echo "PASS: implement phase shown" || echo "FAIL: implement phase missing"
   echo "$STATUS_OUTPUT" | grep -q "verify" && echo "PASS: verify phase shown" || echo "FAIL: verify phase missing"
   echo "$STATUS_OUTPUT" | grep -q "in_progress" && echo "PASS: in_progress status shown" || echo "FAIL: in_progress not shown"
   echo "$STATUS_OUTPUT" | grep -q "Skill:.*ace-search-research" && echo "PASS: Skill field displayed" || echo "FAIL: Skill field not displayed"
   ```

5. Complete analyze phase with report and verify advancement
   ```bash
   REPORT_OUTPUT=$(ace-assign report report.md 2>&1)
   REPORT_EXIT=$?
   [ "$REPORT_EXIT" -eq 0 ] && echo "PASS: Report exit code 0" || echo "FAIL: Expected 0, got $REPORT_EXIT"
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "PASS: Phase 010 marked done" || echo "FAIL: Phase 010 not done"
   grep -q "status: completed" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "FAIL: Uses 'completed' instead of 'done'" || echo "PASS: Does not use 'completed'"
   [ -f "$ASSIGNMENT_DIR/reports/010-analyze.r.md" ] && echo "PASS: Report file created at reports/010-analyze.r.md" || echo "FAIL: Report file not found"
   grep -q "Analysis Report" "$ASSIGNMENT_DIR/reports/010-analyze.r.md" && echo "PASS: Report content in .r.md file" || echo "FAIL: Report content missing"
   grep -q "Analysis Report" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "FAIL: Report incorrectly in phase file" || echo "PASS: Report NOT in phase file"
   grep -q "status: in_progress" "$ASSIGNMENT_DIR/phases/020-implement.ph.md" && echo "PASS: Phase 020 now in_progress" || echo "FAIL: Phase 020 not in_progress"
   ```

### Phase 3: Failure Handling

6. Mark current phase as failed and verify queue stalls
   ```bash
   FAIL_OUTPUT=$(ace-assign fail -m "Test failure: encountered blocking issue" 2>&1)
   FAIL_EXIT=$?
   [ "$FAIL_EXIT" -eq 0 ] && echo "PASS: Fail exit code 0" || echo "FAIL: Expected 0, got $FAIL_EXIT"
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   grep -q "status: failed" "$ASSIGNMENT_DIR/phases/020-implement.ph.md" && echo "PASS: Phase 020 marked failed" || echo "FAIL: Phase 020 not failed"
   grep -q "blocking issue" "$ASSIGNMENT_DIR/phases/020-implement.ph.md" && echo "PASS: Error message recorded" || echo "FAIL: Error message not found"
   grep -q "status: pending" "$ASSIGNMENT_DIR/phases/030-verify.ph.md" && echo "PASS: Phase 030 still pending" || echo "FAIL: Phase 030 not pending"
   ```

7. Verify queue is stalled and report is rejected
   ```bash
   STALL_STATUS=$(ace-assign status 2>&1)
   echo "$STALL_STATUS" | grep -q "Current Phase:" && echo "FAIL: Queue should be stalled" || echo "PASS: No current phase (stalled)"
   echo "# Dummy" > stall-dummy-report.md
   STALL_OUTPUT=$(ace-assign report stall-dummy-report.md 2>&1)
   STALL_EXIT=$?
   [ "$STALL_EXIT" -ne 0 ] && echo "PASS: Report rejected on stalled queue (exit $STALL_EXIT)" || echo "FAIL: Report should fail on stalled queue"
   echo "$STALL_OUTPUT" | grep -q "No phase currently in progress" && echo "PASS: Correct stall error message" || echo "FAIL: Expected 'No phase currently in progress'"
   ```

### Phase 4: Dynamic Phases and Retry

8. Add dynamic phase (auto-activates on stalled queue) and complete it
   ```bash
   ADD_OUTPUT=$(ace-assign add "fix-issue" -i "Fix the blocking issue that caused failure" 2>&1)
   ADD_EXIT=$?
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Add exit code 0" || echo "FAIL: Expected 0, got $ADD_EXIT"
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   DYNAMIC_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*fix-issue* 2>/dev/null | head -1)
   [ -f "$DYNAMIC_PHASE" ] && echo "PASS: Dynamic Phase file created" || echo "FAIL: Dynamic Phase file not found"
   grep -q "added_by.*dynamic" "$DYNAMIC_PHASE" && echo "PASS: added_by: dynamic present" || echo "FAIL: added_by: dynamic missing"
   grep -q "status: in_progress" "$DYNAMIC_PHASE" && echo "PASS: Dynamic Phase auto-activated" || echo "FAIL: Dynamic Phase not auto-activated"
   ADD_STATUS=$(ace-assign status 2>&1)
   echo "$ADD_STATUS" | grep -q "Current Phase:.*fix-issue" && echo "PASS: Current phase is fix-issue" || echo "FAIL: Current phase is not fix-issue"
   ```

9. Complete dynamic phase and verify auto-advance to 030-verify
   ```bash
   ace-assign report fix-report.md
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   DYNAMIC_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*fix-issue* 2>/dev/null | head -1)
   grep -q "status: done" "$DYNAMIC_PHASE" && echo "PASS: fix-issue marked done" || echo "FAIL: fix-issue not done"
   grep -q "status: in_progress" "$ASSIGNMENT_DIR/phases/030-verify.ph.md" && echo "PASS: 030-verify auto-advanced" || echo "FAIL: 030-verify not in_progress"
   ```

10. Retry failed phase 020 (should NOT change current phase)
    ```bash
    RETRY_OUTPUT=$(ace-assign retry 020 2>&1)
    RETRY_EXIT=$?
    [ "$RETRY_EXIT" -eq 0 ] && echo "PASS: Retry exit code 0" || echo "FAIL: Expected 0, got $RETRY_EXIT"
    ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
    RETRY_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*implement* 2>/dev/null | grep -v "020-implement" | head -1)
    [ -f "$RETRY_PHASE" ] && echo "PASS: Retry Phase file created" || echo "FAIL: Retry Phase file not found"
    grep -q "retry_of.*020" "$RETRY_PHASE" && echo "PASS: Retry linked to phase 020" || echo "FAIL: Retry not linked"
    grep -q "status: pending" "$RETRY_PHASE" && echo "PASS: Retry Phase is pending" || echo "FAIL: Retry should be pending"
    RETRY_STATUS=$(ace-assign status 2>&1)
    echo "$RETRY_STATUS" | grep -q "Current Phase:.*verify" && echo "PASS: 030-verify still current after retry" || echo "FAIL: Current phase changed"
    ```

### Phase 5: Workflow Completion

11. Complete verify phase and verify retry phase auto-advances
    ```bash
    ace-assign report verify-report.md
    ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
    grep -q "status: done" "$ASSIGNMENT_DIR/phases/030-verify.ph.md" && echo "PASS: 030-verify done" || echo "FAIL: 030-verify not done"
    RETRY_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*implement*.ph.md 2>/dev/null | grep -v "020-implement" | head -1)
    grep -q "status: in_progress" "$RETRY_PHASE" && echo "PASS: Retry Phase auto-advanced to in_progress" || echo "FAIL: Retry Phase not in_progress"
    ```

12. Complete retry phase and verify assignment completion
    ```bash
    ace-assign report implement-report.md
    ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
    RETRY_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*implement*.ph.md 2>/dev/null | grep -v "020-implement" | head -1)
    grep -q "status: done" "$RETRY_PHASE" && echo "PASS: Retry Phase done" || echo "FAIL: Retry Phase not done"
    FINAL_STATUS=$(ace-assign status 2>&1)
    echo "$FINAL_STATUS" | grep -q "Assignment completed!" && echo "PASS: Assignment shows completed" || echo "FAIL: Assignment not completed"
    PENDING=$(grep -rl "status: pending" "$ASSIGNMENT_DIR/phases/" 2>/dev/null | wc -l | tr -d ' ')
    IN_PROGRESS=$(grep -rl "status: in_progress" "$ASSIGNMENT_DIR/phases/" 2>/dev/null | wc -l | tr -d ' ')
    [ "$PENDING" -eq 0 ] && echo "PASS: No pending phases remain" || echo "FAIL: $PENDING pending phases remain"
    [ "$IN_PROGRESS" -eq 0 ] && echo "PASS: No in_progress phases remain" || echo "FAIL: $IN_PROGRESS in_progress phases remain"
    DONE_COUNT=$(grep -rl "status: done" "$ASSIGNMENT_DIR/phases/" 2>/dev/null | wc -l | tr -d ' ')
    FAILED_COUNT=$(grep -rl "status: failed" "$ASSIGNMENT_DIR/phases/" 2>/dev/null | wc -l | tr -d ' ')
    TOTAL=$((DONE_COUNT + FAILED_COUNT))
    PHASE_COUNT=$(ls "$ASSIGNMENT_DIR/phases/"*.ph.md 2>/dev/null | wc -l | tr -d ' ')
    [ "$TOTAL" -eq "$PHASE_COUNT" ] && echo "PASS: All $PHASE_COUNT phases are terminal" || echo "FAIL: $TOTAL of $PHASE_COUNT terminal"
    ```

## Expected

### Phase 1
- Assignment created with exit code 0
- assignment.yaml, phases/, reports/ directories exist
- 3 phase files: 010-analyze.ph.md, 020-implement.ph.md, 030-verify.ph.md
- First phase in_progress with skill field and array instructions joined
- No wrong paths (.assign/, queue.yaml, .md without .ph.md)

### Phase 2
- Status shows all 3 phases, current phase analyze with Skill: ace-search-research
- Report completes phase 010 as "done" (not "completed"), creates separate .r.md report
- Phase 020 advances to in_progress

### Phase 3
- Fail marks phase 020 as failed with error message recorded
- Queue stalls: no Current Phase in status, report rejected with "No phase currently in progress"

### Phase 4
- Dynamic Phase auto-activates (in_progress) on stalled queue with added_by: dynamic
- Completing dynamic phase auto-advances to 030-verify
- Retry creates pending phase linked to 020, does NOT change current phase

### Phase 5
- Completing verify auto-advances retry phase to in_progress
- Completing retry phase results in "Assignment completed!"
- All phases terminal (4 done + 1 failed)
