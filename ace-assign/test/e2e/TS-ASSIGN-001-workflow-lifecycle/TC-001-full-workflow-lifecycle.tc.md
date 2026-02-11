---
tc-id: MT-ASSIGN-001
title: Full Workflow Lifecycle
suite: TS-ASSIGN-001
---

# Full Workflow Lifecycle

## Objective

Verify that ace-assign correctly manages the full workflow lifecycle including assignment creation, phase progression, failure handling, dynamic phase addition, and retry functionality. Error paths are tested first to catch crashes early.

## Prerequisites

- Ruby >= 3.0 installed
- ace-assign package available (via bundle exec or installed)

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="assign"
SHORT_ID="mt001"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Set PROJECT_ROOT_PATH for isolated testing
# This tells ace-assign to use the sandbox as project root for cache resolution
export PROJECT_ROOT_PATH="$TEST_DIR"

# Ensure cache base directory exists (for first-time runs)
CACHE_BASE="$TEST_DIR/.cache/ace-assign"
mkdir -p "$CACHE_BASE"

# Set up command alias for ace-assign
ACE_ASSIGN="bundle exec $PROJECT_ROOT/ace-assign/exe/ace-assign"

# Verify tools are available
echo "=== Tool Verification ==="
$ACE_ASSIGN --version
echo "========================="

# === SANDBOX ISOLATION CHECKPOINT ===
echo "=== SANDBOX ISOLATION CHECK ==="
CURRENT_DIR="$(pwd)"
if [[ "$CURRENT_DIR" == *".cache/ace-test-e2e/"* ]]; then
  echo "PASS: Working directory is inside sandbox"
else
  echo "FAIL: NOT in sandbox! Current: $CURRENT_DIR"
  exit 1
fi
if git rev-parse --git-dir >/dev/null 2>&1; then
  REMOTES=$(git remote -v 2>/dev/null)
  if [ -z "$REMOTES" ]; then
    echo "PASS: No git remotes (isolated repo)"
  else
    echo "FAIL: Git remotes found - NOT isolated!"
    exit 1
  fi
else
  echo "PASS: No git repo in sandbox (tools use PROJECT_ROOT_PATH)"
fi
if [ -f "CLAUDE.md" ] || [ -f "Gemfile" ] || [ -d ".ace-taskflow" ]; then
  echo "FAIL: Main project markers found!"
  exit 1
else
  echo "PASS: No main project markers"
fi
echo "=== ISOLATION VERIFIED ==="
```

## Test Cases

### TC-001: Error — Nonexistent Config File

**Objective:** Verify that `create` with a nonexistent config file exits with code 3 and a clear error message.

**Steps:**
1. Attempt to create an assignment with a nonexistent config
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$($ACE_ASSIGN create nonexistent.yaml 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

2. Verify exit code and error message
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -eq 3 ] && echo "PASS: Exit code is 3" || echo "FAIL: Expected exit code 3, got $EXIT_CODE"
   echo "$OUTPUT" | grep -qi "not found" && echo "PASS: Error mentions 'not found'" || echo "FAIL: Error message does not mention 'not found'"
   SANDBOX
   ```

**Expected:**
- Exit code: 3
- Output contains: "Config file not found"

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Error — Status with No Active Assignment

**Objective:** Verify that `status` with no active assignment exits with code 2 and a clear error message.

**Steps:**
1. Run status command from clean state (no assignment exists)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$($ACE_ASSIGN status 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

2. Verify exit code and error message
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -eq 2 ] && echo "PASS: Exit code is 2" || echo "FAIL: Expected exit code 2, got $EXIT_CODE"
   echo "$OUTPUT" | grep -qi "no active assignment" && echo "PASS: Error mentions 'No active assignment'" || echo "FAIL: Error message missing expected text"
   SANDBOX
   ```

**Expected:**
- Exit code: 2
- Output contains: "No active assignment"

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Error — Report with No Active Assignment

**Objective:** Verify that `report` with no active assignment exits with code 2 rather than crashing.

**Steps:**
1. Create a dummy report file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "# Dummy" > dummy-report.md
   SANDBOX
   ```

2. Run report command from clean state
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$($ACE_ASSIGN report "$TEST_DIR/dummy-report.md" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

3. Verify exit code
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -eq 2 ] && echo "PASS: Exit code is 2" || echo "FAIL: Expected exit code 2, got $EXIT_CODE"
   SANDBOX
   ```

**Expected:**
- Exit code: 2
- Output contains: "No active assignment"

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Deprecated `start` Command Migration

**Objective:** Verify that the deprecated `start` command works as a migration alias to `create` with a deprecation warning, creating an assignment successfully.

**Steps:**
1. Attempt to use the old `start` command
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$($ACE_ASSIGN start "$TEST_DIR/job.yaml" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

2. Verify exit code is 0 (success)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   SANDBOX
   ```

3. Verify deprecation warning is shown
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qi "deprecated" && echo "PASS: Deprecation warning shown" || echo "FAIL: No deprecation warning found"
   SANDBOX
   ```

4. Verify assignment was created
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_COUNT=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
   [ "$ASSIGNMENT_COUNT" -gt 0 ] && echo "PASS: Assignment created by 'start' ($ASSIGNMENT_COUNT found)" || echo "FAIL: No assignment created"
   SANDBOX
   ```

5. Verify output matches `create` command (contains assignment ID and first phase)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qE "Assignment:.*\(" && echo "PASS: Output shows assignment info" || echo "FAIL: No assignment info in output"
   echo "$OUTPUT" | grep -q "analyze" && echo "PASS: First phase shown" || echo "FAIL: First phase not shown"
   SANDBOX
   ```

**Expected:**
- Exit code: 0 (success)
- Stderr contains: "deprecated" warning
- Assignment IS created (migration works)
- Output matches `create` command output

**Status:** [ ] Pass / [ ] Fail

---

### TC-004b: Cache Directory Auto-Creation

**Objective:** Verify that the cache base directory is created automatically on first use.

**Steps:**
1. Remove cache directory if it exists
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   CACHE_BASE="$TEST_DIR/.cache/ace-assign"
   rm -rf "$CACHE_BASE"
   [ ! -d "$CACHE_BASE" ] && echo "PASS: Cache removed" || echo "FAIL: Cache still exists"
   SANDBOX
   ```

2. Create an assignment (should auto-create cache directory)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$($ACE_ASSIGN create "$TEST_DIR/job.yaml" 2>&1)
   EXIT_CODE=$?
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Assignment created" || echo "FAIL: Creation failed (exit $EXIT_CODE)"
   SANDBOX
   ```

3. Verify cache directory was created
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -d "$CACHE_BASE" ] && echo "PASS: Cache directory auto-created" || echo "FAIL: Cache missing"
   SANDBOX
   ```

**Expected:**
- Cache directory created automatically
- Assignment creation succeeds

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Create Assignment from YAML Config

**Objective:** Verify that `ace-assign create job.yaml` creates an assignment with the first phase in_progress. Note: TC-004 already created an assignment via the deprecated `start` command, so this creates a second assignment.

**Steps:**
1. Create workflow from config
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   CREATE_OUTPUT=$($ACE_ASSIGN create "$TEST_DIR/job.yaml" 2>&1)
   CREATE_EXIT=$?
   echo "Exit code: $CREATE_EXIT"
   echo "Output:"
   echo "$CREATE_OUTPUT"
   SANDBOX
   ```

2. Verify exit code
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $CREATE_EXIT"
   SANDBOX
   ```

3. Verify output contains assignment ID
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$CREATE_OUTPUT" | grep -qE "Assignment:.*\(" && echo "PASS: Output shows assignment info" || echo "FAIL: No assignment info in output"
   SANDBOX
   ```

4. Extract assignment ID from output for later tests
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_ID=$(echo "$CREATE_OUTPUT" | grep -oE '\(([a-z0-9]+)\)' | head -1 | tr -d '()')
   echo "Assignment ID: $ASSIGNMENT_ID"
   [ -n "$ASSIGNMENT_ID" ] && echo "PASS: Assignment ID extracted" || echo "FAIL: Could not extract assignment ID"
   SANDBOX
   ```

5. Verify output mentions first phase
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$CREATE_OUTPUT" | grep -q "analyze" && echo "PASS: First phase 'analyze' shown" || echo "FAIL: First phase not shown in output"
   echo "$CREATE_OUTPUT" | grep -q "in_progress" && echo "PASS: Phase status shown as in_progress" || echo "FAIL: Phase status not shown"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output contains assignment ID
- Output shows first phase "analyze" with status in_progress

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Verify Actual File Structure + Array Instructions

**Objective:** Verify that the assignment creates the correct on-disk structure, that array instructions are normalized, and that old/wrong paths do NOT exist.

**Steps:**
1. Verify assignment directory exists in `.cache/ace-assign/`
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   [ -d "$ASSIGNMENT_DIR" ] && echo "PASS: Assignment directory found at $ASSIGNMENT_DIR" || echo "FAIL: No assignment directory in .cache/ace-assign/"
   SANDBOX
   ```

2. Verify assignment.yaml exists
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   [ -f "$ASSIGNMENT_DIR/assignment.yaml" ] && echo "PASS: assignment.yaml exists" || echo "FAIL: assignment.yaml missing"
   SANDBOX
   ```

3. Verify phases/ directory with phase files (.ph.md extension)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   [ -d "$ASSIGNMENT_DIR/phases" ] && echo "PASS: phases/ directory exists" || echo "FAIL: phases/ directory missing"
   PHASE_COUNT=$(ls "$ASSIGNMENT_DIR/phases/"*.ph.md 2>/dev/null | wc -l | tr -d ' ')
   [ "$PHASE_COUNT" -eq 3 ] && echo "PASS: 3 phase files created" || echo "FAIL: Expected 3 phase files, found $PHASE_COUNT"
   SANDBOX
   ```

4. Verify phase file naming convention (010-analyze.ph.md, 020-implement.ph.md, 030-verify.ph.md)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   [ -f "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" ] && echo "PASS: 010-analyze.ph.md exists" || echo "FAIL: 010-analyze.ph.md missing"
   [ -f "$ASSIGNMENT_DIR/phases/020-implement.ph.md" ] && echo "PASS: 020-implement.ph.md exists" || echo "FAIL: 020-implement.ph.md missing"
   [ -f "$ASSIGNMENT_DIR/phases/030-verify.ph.md" ] && echo "PASS: 030-verify.ph.md exists" || echo "FAIL: 030-verify.ph.md missing"
   SANDBOX
   ```

5. Verify reports/ directory exists (for split report files)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   [ -d "$ASSIGNMENT_DIR/reports" ] && echo "PASS: reports/ directory exists" || echo "FAIL: reports/ directory missing"
   SANDBOX
   ```

6. Verify first phase frontmatter has status in_progress
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   grep -q "status: in_progress" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "PASS: Phase 010 is in_progress" || echo "FAIL: Phase 010 not in_progress"
   SANDBOX
   ```

7. Verify skill field preserved in phase file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   grep -q 'skill:.*ace:research' "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "PASS: skill field preserved in phase file" || echo "FAIL: skill field missing from phase file"
   SANDBOX
   ```

8. Verify array instructions were joined in phase file (normalize_instructions)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   grep -q "Analyze the codebase structure" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "PASS: First instruction line present" || echo "FAIL: First instruction line missing"
   grep -q "Identify key components and dependencies" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "PASS: Second instruction line present" || echo "FAIL: Second instruction line missing"
   SANDBOX
   ```

9. Verify plain string instructions also work (020-implement.ph.md)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   grep -q "Implement the required changes" "$ASSIGNMENT_DIR/phases/020-implement.ph.md" && echo "PASS: Plain string instructions preserved" || echo "FAIL: Plain string instructions missing"
   SANDBOX
   ```

10. Negative assertions — wrong paths must NOT exist
    ```bash
    ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
    ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
    [ ! -d "$TEST_DIR/.assign" ] && echo "PASS: .assign/ does NOT exist (correct)" || echo "FAIL: .assign/ exists (wrong path)"
    [ ! -f "$ASSIGNMENT_DIR/queue.yaml" ] && echo "PASS: queue.yaml does NOT exist (correct)" || echo "FAIL: queue.yaml exists (wrong format)"
    [ ! -f "$ASSIGNMENT_DIR/phases/010-analyze.md" ] && echo "PASS: No .md files (correct)" || echo "FAIL: .md files exist (should be .ph.md)"
    SANDBOX
    ```

**Expected:**
- `.cache/ace-assign/<id>/assignment.yaml` exists
- `.cache/ace-assign/<id>/phases/` contains 3 .ph.md phase files
- `.cache/ace-assign/<id>/reports/` directory exists
- Phase files named: `010-analyze.ph.md`, `020-implement.ph.md`, `030-verify.ph.md`
- First phase has `status: in_progress` in frontmatter
- Skill field `ace:research` preserved in `010-analyze.ph.md`
- Array instructions (analyze phase) joined into phase file body
- Plain string instructions (implement phase) preserved as-is
- NO `.assign/` directory, NO `queue.yaml`, NO `.md` files (only `.ph.md` and `.r.md`)

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Check Status Output

**Objective:** Verify that `status` displays all phases, current phase details, and skill field.

**Steps:**
1. Run status command
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   STATUS_OUTPUT=$($ACE_ASSIGN status 2>&1)
   STATUS_EXIT=$?
   echo "Exit code: $STATUS_EXIT"
   echo "Output:"
   echo "$STATUS_OUTPUT"
   SANDBOX
   ```

2. Verify exit code
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$STATUS_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $STATUS_EXIT"
   SANDBOX
   ```

3. Verify all three phases shown in output
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$STATUS_OUTPUT" | grep -q "analyze" && echo "PASS: analyze phase shown" || echo "FAIL: analyze phase missing"
   echo "$STATUS_OUTPUT" | grep -q "implement" && echo "PASS: implement phase shown" || echo "FAIL: implement phase missing"
   echo "$STATUS_OUTPUT" | grep -q "verify" && echo "PASS: verify phase shown" || echo "FAIL: verify phase missing"
   SANDBOX
   ```

4. Verify current phase indicator
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$STATUS_OUTPUT" | grep -q "in_progress" && echo "PASS: in_progress status shown" || echo "FAIL: in_progress not shown"
   echo "$STATUS_OUTPUT" | grep -q "Current Phase:.*analyze" && echo "PASS: Current phase is analyze" || echo "FAIL: Current phase not analyze"
   SANDBOX
   ```

5. Verify skill field displayed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$STATUS_OUTPUT" | grep -q "Skill:.*ace:research" && echo "PASS: Skill field displayed" || echo "FAIL: Skill field not displayed"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- All three phases (analyze, implement, verify) displayed
- Current phase is analyze with in_progress status
- Skill field "ace:research" shown for analyze phase

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Complete Phase with Report

**Objective:** Verify that reporting on a phase marks it `done` (not `completed`), creates a separate .r.md report file in reports/ directory, and advances to the next phase.

**Steps:**
1. Create report content
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > report.md << 'EOF'
# Analysis Report

## Findings
- Codebase structure is clean
- No issues found

## Recommendation
Proceed with implementation
EOF
   SANDBOX
   ```

2. Complete current phase with report
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   REPORT_OUTPUT=$($ACE_ASSIGN report "$TEST_DIR/report.md" 2>&1)
   REPORT_EXIT=$?
   echo "Exit code: $REPORT_EXIT"
   echo "Output:"
   echo "$REPORT_OUTPUT"
   SANDBOX
   ```

3. Verify exit code
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$REPORT_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $REPORT_EXIT"
   SANDBOX
   ```

4. Find assignment directory
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   SANDBOX
   ```

5. Verify phase 010 marked as `done` (NOT `completed`)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "PASS: Phase 010 is done" || echo "FAIL: Phase 010 not marked done"
   grep -q "status: completed" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "FAIL: Phase uses 'completed' instead of 'done'" || echo "PASS: Phase does not use 'completed'"
   SANDBOX
   ```

6. Verify report file created in reports/ directory
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   [ -f "$ASSIGNMENT_DIR/reports/010-analyze.r.md" ] && echo "PASS: Report file created at reports/010-analyze.r.md" || echo "FAIL: Report file not found"
   grep -q "Analysis Report" "$ASSIGNMENT_DIR/reports/010-analyze.r.md" && echo "PASS: Report content in .r.md file" || echo "FAIL: Report content not found in .r.md file"
   SANDBOX
   ```

7. Verify report NOT appended inline to job file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   grep -q "Analysis Report" "$ASSIGNMENT_DIR/phases/010-analyze.ph.md" && echo "FAIL: Report content incorrectly appended to job file" || echo "PASS: Report content NOT in job file (correct)"
   SANDBOX
   ```

8. Verify next phase (020) is now in_progress
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   grep -q "status: in_progress" "$ASSIGNMENT_DIR/phases/020-implement.ph.md" && echo "PASS: Phase 020 is in_progress" || echo "FAIL: Phase 020 not in_progress"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Phase 010 marked as `done` (not `completed`)
- Report content in separate `reports/010-analyze.r.md` file
- Report NOT in job file
- Phase 020 (implement) now in_progress

**Status:** [ ] Pass / [ ] Fail

---

### TC-009: Mark Phase as Failed

**Objective:** Verify that failing a phase marks it `failed` with an error message and does NOT auto-advance.

**Steps:**
1. Mark current phase as failed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   FAIL_OUTPUT=$($ACE_ASSIGN fail -m "Test failure: encountered blocking issue" 2>&1)
   FAIL_EXIT=$?
   echo "Exit code: $FAIL_EXIT"
   echo "Output:"
   echo "$FAIL_OUTPUT"
   SANDBOX
   ```

2. Verify exit code
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$FAIL_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $FAIL_EXIT"
   SANDBOX
   ```

3. Find assignment directory
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   SANDBOX
   ```

4. Verify phase 020 marked as failed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   grep -q "status: failed" "$ASSIGNMENT_DIR/phases/020-implement.ph.md" && echo "PASS: Phase 020 marked failed" || echo "FAIL: Phase 020 not marked failed"
   SANDBOX
   ```

5. Verify error message recorded in phase file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   grep -q "blocking issue" "$ASSIGNMENT_DIR/phases/020-implement.ph.md" && echo "PASS: Error message recorded" || echo "FAIL: Error message not found in phase file"
   SANDBOX
   ```

6. Verify no auto-advance — phase 030 should still be pending
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   grep -q "status: pending" "$ASSIGNMENT_DIR/phases/030-verify.ph.md" && echo "PASS: Phase 030 still pending (no auto-advance)" || echo "FAIL: Phase 030 is not pending"
   SANDBOX
   ```

7. Verify queue is stalled — status shows no current phase
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   STALL_STATUS=$($ACE_ASSIGN status 2>&1)
   echo "$STALL_STATUS" | grep -q "Current Phase:" && echo "FAIL: Queue should be stalled but shows a current phase" || echo "PASS: No current phase — queue is stalled after fail"
   SANDBOX
   ```

8. Verify report is rejected when queue is stalled
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "# Dummy" > "$TEST_DIR/stall-dummy-report.md"
   STALL_OUTPUT=$($ACE_ASSIGN report "$TEST_DIR/stall-dummy-report.md" 2>&1)
   STALL_EXIT=$?
   [ "$STALL_EXIT" -ne 0 ] && echo "PASS: Report rejected on stalled queue (exit $STALL_EXIT)" || echo "FAIL: Report should fail on stalled queue"
   echo "$STALL_OUTPUT" | grep -q "No phase currently in progress" && echo "PASS: Correct stall error message" || echo "FAIL: Expected 'No phase currently in progress' message"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Phase 020 (implement) marked as `failed`
- Error message "blocking issue" recorded in phase file
- Phase 030 remains `pending` (failure does not auto-advance)
- Status shows no "Current Phase:" line (queue is stalled)
- Report command rejected with exit code 1 and "No phase currently in progress" message

**Status:** [ ] Pass / [ ] Fail

---

### TC-010: Add Dynamic Phase and Retry Failed Phase

**Objective:** Verify that adding a dynamic phase auto-activates it when the queue is stalled, that completing it auto-advances to the next pending phase, and that retry creates a pending phase without changing the current phase.

**Steps:**
1. Add a dynamic phase (queue is stalled after TC-009 fail)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ADD_OUTPUT=$($ACE_ASSIGN add "fix-issue" -i "Fix the blocking issue that caused failure" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"
   SANDBOX
   ```

2. Verify exit code
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $ADD_EXIT"
   SANDBOX
   ```

3. Find assignment directory and verify dynamic phase file exists
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   DYNAMIC_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*fix-issue* 2>/dev/null | head -1)
   [ -f "$DYNAMIC_PHASE" ] && echo "PASS: Dynamic phase file created at $DYNAMIC_PHASE" || echo "FAIL: Dynamic phase file not found"
   SANDBOX
   ```

4. Verify dynamic phase has `added_by: dynamic`
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   DYNAMIC_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*fix-issue* 2>/dev/null | head -1)
   grep -q "added_by.*dynamic" "$DYNAMIC_PHASE" && echo "PASS: added_by: dynamic present" || echo "FAIL: added_by: dynamic missing"
   SANDBOX
   ```

5. Verify add auto-activated the phase (queue was stalled, so new phase becomes in_progress)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   DYNAMIC_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*fix-issue* 2>/dev/null | head -1)
   grep -q "status: in_progress" "$DYNAMIC_PHASE" && echo "PASS: Dynamic phase auto-activated (in_progress)" || echo "FAIL: Dynamic phase not auto-activated"
   ADD_STATUS=$($ACE_ASSIGN status 2>&1)
   echo "$ADD_STATUS" | grep -q "Current Phase:.*fix-issue" && echo "PASS: Current phase is fix-issue" || echo "FAIL: Current phase is not fix-issue"
   SANDBOX
   ```

6. Complete the dynamic phase
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "$TEST_DIR/fix-report.md" << 'EOF'
# Fix Report

Issue has been resolved.
EOF
   $ACE_ASSIGN report "$TEST_DIR/fix-report.md"
   SANDBOX
   ```

7. Verify auto-advance after completing fix-issue: 030-verify should now be in_progress
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   DYNAMIC_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*fix-issue* 2>/dev/null | head -1)
   grep -q "status: done" "$DYNAMIC_PHASE" && echo "PASS: fix-issue phase marked done" || echo "FAIL: fix-issue phase not marked done"
   grep -q "status: in_progress" "$ASSIGNMENT_DIR/phases/030-verify.ph.md" && echo "PASS: 030-verify auto-advanced to in_progress" || echo "FAIL: 030-verify not in_progress"
   ADV_STATUS=$($ACE_ASSIGN status 2>&1)
   echo "$ADV_STATUS" | grep -q "Current Phase:.*verify" && echo "PASS: Current phase is verify after auto-advance" || echo "FAIL: Current phase is not verify"
   SANDBOX
   ```

8. Retry the failed phase (020) — should NOT change current phase
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   RETRY_OUTPUT=$($ACE_ASSIGN retry 020 2>&1)
   RETRY_EXIT=$?
   echo "Exit code: $RETRY_EXIT"
   echo "Output:"
   echo "$RETRY_OUTPUT"
   SANDBOX
   ```

9. Verify retry exit code
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$RETRY_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $RETRY_EXIT"
   SANDBOX
   ```

10. Verify retry phase created with link to original
    ```bash
    ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
    ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
    RETRY_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*implement* 2>/dev/null | grep -v "020-implement" | head -1)
    [ -f "$RETRY_PHASE" ] && echo "PASS: Retry phase file created at $RETRY_PHASE" || echo "FAIL: Retry phase file not found"
    grep -q "retry_of.*020" "$RETRY_PHASE" && echo "PASS: Retry linked to original phase 020" || echo "FAIL: Retry not linked to phase 020"
    SANDBOX
    ```

11. Verify retry did NOT auto-activate — 030-verify is still current, retry is pending
    ```bash
    ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
    ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
    RETRY_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*implement* 2>/dev/null | grep -v "020-implement" | head -1)
    grep -q "status: pending" "$RETRY_PHASE" && echo "PASS: Retry phase is pending (not auto-activated)" || echo "FAIL: Retry phase should be pending"
    RETRY_STATUS=$($ACE_ASSIGN status 2>&1)
    echo "$RETRY_STATUS" | grep -q "Current Phase:.*verify" && echo "PASS: 030-verify still current after retry" || echo "FAIL: Current phase changed after retry"
    SANDBOX
    ```

**Expected:**
- Dynamic phase "fix-issue" created with `added_by: dynamic` and auto-activated to `in_progress`
- After completing fix-issue, 030-verify auto-advances to `in_progress`
- Retry phase created linked via `added_by: retry_of:020` with status `pending`
- Retry does NOT change current phase (030-verify remains current)
- All operations exit code 0

**Status:** [ ] Pass / [ ] Fail

---

### TC-011: Complete Remaining Phases — Workflow Completion

**Objective:** Verify that completing all remaining phases results in a completed assignment with "Assignment completed!" output. Validates that each report completes the expected phase by checking phase file status transitions.

**Queue entering TC-011:**
```
010-analyze:       done
011-fix-issue:     done        (dynamic, completed in TC-010)
020-implement:     failed      (original failure from TC-009)
030-verify:        in_progress ← CURRENT
031-implement:     pending     (retry of 020, created in TC-010)
```

**Steps:**
1. Complete the verify phase (030-verify, currently in_progress)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   cat > "$TEST_DIR/verify-report.md" << 'EOF'
# Verification Report

All tests pass. Changes verified.
EOF
   VERIFY_OUTPUT=$($ACE_ASSIGN report "$TEST_DIR/verify-report.md" 2>&1)
   VERIFY_EXIT=$?
   echo "Exit code: $VERIFY_EXIT"
   [ "$VERIFY_EXIT" -eq 0 ] && echo "PASS: Report accepted" || echo "FAIL: Report rejected (exit $VERIFY_EXIT)"
   SANDBOX
   ```

2. Verify 030-verify is now done and retry phase (031) auto-advanced to in_progress
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/030-verify.ph.md" && echo "PASS: 030-verify marked done" || echo "FAIL: 030-verify not done"
   RETRY_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*implement*.ph.md 2>/dev/null | grep -v "020-implement" | head -1)
   grep -q "status: in_progress" "$RETRY_PHASE" && echo "PASS: Retry phase (031) auto-advanced to in_progress" || echo "FAIL: Retry phase not in_progress"
   TC011_STATUS=$($ACE_ASSIGN status 2>&1)
   echo "$TC011_STATUS" | grep -q "Current Phase:.*implement" && echo "PASS: Current phase is now implement (retry)" || echo "FAIL: Current phase is not implement"
   SANDBOX
   ```

3. Complete the retry phase (031-implement, auto-advanced after verify)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "$TEST_DIR/implement-report.md" << 'EOF'
# Implementation Report

Changes implemented successfully.
EOF
   IMPL_OUTPUT=$($ACE_ASSIGN report "$TEST_DIR/implement-report.md" 2>&1)
   IMPL_EXIT=$?
   echo "Exit code: $IMPL_EXIT"
   [ "$IMPL_EXIT" -eq 0 ] && echo "PASS: Report accepted" || echo "FAIL: Report rejected (exit $IMPL_EXIT)"
   SANDBOX
   ```

4. Verify retry phase is now done
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   RETRY_PHASE=$(ls "$ASSIGNMENT_DIR/phases/"*implement*.ph.md 2>/dev/null | grep -v "020-implement" | head -1)
   grep -q "status: done" "$RETRY_PHASE" && echo "PASS: Retry phase marked done" || echo "FAIL: Retry phase not done"
   SANDBOX
   ```

5. Check final status
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   FINAL_STATUS=$($ACE_ASSIGN status 2>&1)
   FINAL_EXIT=$?
   echo "Exit code: $FINAL_EXIT"
   echo "Output:"
   echo "$FINAL_STATUS"
   SANDBOX
   ```

6. Verify "Assignment completed!" in output
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$FINAL_STATUS" | grep -q "Assignment completed!" && echo "PASS: Assignment shows completed" || echo "FAIL: Assignment not shown as completed"
   SANDBOX
   ```

7. Verify all phases are done or failed (none pending/in_progress)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   PENDING=$(grep -rl "status: pending" "$ASSIGNMENT_DIR/phases/" 2>/dev/null | wc -l | tr -d ' ')
   IN_PROGRESS=$(grep -rl "status: in_progress" "$ASSIGNMENT_DIR/phases/" 2>/dev/null | wc -l | tr -d ' ')
   [ "$PENDING" -eq 0 ] && echo "PASS: No pending phases remain" || echo "FAIL: $PENDING pending phases remain"
   [ "$IN_PROGRESS" -eq 0 ] && echo "PASS: No in_progress phases remain" || echo "FAIL: $IN_PROGRESS in_progress phases remain"
   SANDBOX
   ```

8. Count completed phases
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find "$TEST_DIR/.cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   DONE_COUNT=$(grep -rl "status: done" "$ASSIGNMENT_DIR/phases/" 2>/dev/null | wc -l | tr -d ' ')
   FAILED_COUNT=$(grep -rl "status: failed" "$ASSIGNMENT_DIR/phases/" 2>/dev/null | wc -l | tr -d ' ')
   echo "Done: $DONE_COUNT, Failed: $FAILED_COUNT"
   TOTAL=$((DONE_COUNT + FAILED_COUNT))
   PHASE_COUNT=$(ls "$ASSIGNMENT_DIR/phases/"*.md 2>/dev/null | wc -l | tr -d ' ')
   [ "$TOTAL" -eq "$PHASE_COUNT" ] && echo "PASS: All $PHASE_COUNT phases are terminal (done or failed)" || echo "FAIL: $TOTAL of $PHASE_COUNT phases are terminal"
   SANDBOX
   ```

**Expected:**
- Step 1 completes 030-verify (the current in_progress phase), NOT the retry phase
- Step 2 confirms 031-implement auto-advanced to in_progress after 030-verify completed
- Step 3 completes 031-implement (the retry phase)
- `status` output contains "Assignment completed!"
- No phases remain as pending or in_progress
- All 5 phase files have terminal status (4 done + 1 failed)

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
- [ ] TC-002: Status with no assignment exits with code 2
- [ ] TC-003: Report with no assignment exits with code 2
- [ ] TC-004: Deprecated `start` command works as migration alias with deprecation warning (exit 0)
- [ ] TC-004b: Cache directory is auto-created on first use
- [ ] TC-005: Create assignment from YAML config succeeds
- [ ] TC-006: File structure correct, array instructions normalized, negative assertions pass
- [ ] TC-007: Status displays all phases, current phase, and skill field
- [ ] TC-008: Complete phase marks `done`, creates separate .r.md report file, advances to correct next phase
- [ ] TC-009: Failed phase stops progression, stalls queue, report rejected on stalled queue
- [ ] TC-010: Add auto-activates on stalled queue, auto-advance targets correct phase, retry stays pending
- [ ] TC-011: Reports complete the correct phases in order, assignment shows "Assignment completed!"
