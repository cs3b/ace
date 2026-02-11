---
tc-id: MT-ASSIGN-002
title: Full Fork Context Workflow
suite: TS-ASSIGN-002
---

# Full Fork Context Workflow

## Objective

Verify that ace-assign correctly handles the `context: fork` frontmatter option, producing Task tool instructions for forked job execution instead of raw instructions.

## Prerequisites

- Ruby >= 3.0 installed
- ace-assign package available (via bundle exec or installed)

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="assign"
SHORT_ID="mt002"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

export PROJECT_ROOT_PATH="$TEST_DIR"
CACHE_BASE="$TEST_DIR/.cache/ace-assign"
mkdir -p "$CACHE_BASE"
ACE_ASSIGN="bundle exec $PROJECT_ROOT/ace-assign/exe/ace-assign"

echo "=== Tool Verification ==="
$ACE_ASSIGN --version
echo "========================="
```

## Test Cases

### TC-001: Fork Context Parsed from Job Frontmatter

**Objective:** Verify that `context: fork` in job.yaml creates a phase file with context field in frontmatter.

**Steps:**
1. Create assignment from config
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   CREATE_OUTPUT=$($ACE_ASSIGN create "job.yaml" 2>&1)
   CREATE_EXIT=$?
   echo "Exit code: $CREATE_EXIT"
   echo "Output:"
   echo "$CREATE_OUTPUT"
   SANDBOX
   ```

2. Verify exit code
   ```bash
   ace-test-e2e-sh "$TEST_DIR" [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $CREATE_EXIT"
   ```

3. Find assignment directory
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find ".cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   echo "Assignment directory: $ASSIGNMENT_DIR"
   SANDBOX
   ```

4. Verify fork context in implement phase frontmatter
   ```bash
   ace-test-e2e-sh "$TEST_DIR" grep -q "context: fork" "$ASSIGNMENT_DIR/phases/020-implement.ph.md" && echo "PASS: context: fork in implement phase" || echo "FAIL: context: fork missing from implement phase"
   ```

5. Verify fork context in document phase frontmatter
   ```bash
   ace-test-e2e-sh "$TEST_DIR" grep -q "context: fork" "$ASSIGNMENT_DIR/phases/040-document.ph.md" && echo "PASS: context: fork in document phase" || echo "FAIL: context: fork missing from document phase"
   ```

6. Verify no context field in regular phases
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   grep -q "context:" "$ASSIGNMENT_DIR/phases/010-prepare.ph.md" && echo "FAIL: prepare phase should not have context field" || echo "PASS: prepare phase has no context field"
   grep -q "context:" "$ASSIGNMENT_DIR/phases/030-verify.ph.md" && echo "FAIL: verify phase should not have context field" || echo "PASS: verify phase has no context field"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- `020-implement.ph.md` contains `context: fork` in frontmatter
- `040-document.ph.md` contains `context: fork` in frontmatter
- `010-prepare.ph.md` does NOT contain `context:` field
- `030-verify.ph.md` does NOT contain `context:` field

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Regular Phase Shows Raw Instructions

**Objective:** Verify that a regular phase (no fork context) shows raw instructions directly in status output.

**Steps:**
1. Check status output for first phase (regular, no fork)
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
   ace-test-e2e-sh "$TEST_DIR" [ "$STATUS_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0, got $STATUS_EXIT"
   ```

3. Verify current phase is prepare (regular phase)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" echo "$STATUS_OUTPUT" | grep -q "Current Phase:.*prepare" && echo "PASS: Current phase is prepare" || echo "FAIL: Current phase is not prepare"
   ```

4. Verify instructions shown directly (not Task tool format)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$STATUS_OUTPUT" | grep -q "Instructions:" && echo "PASS: Raw instructions header shown" || echo "FAIL: Instructions header missing"
   echo "$STATUS_OUTPUT" | grep -q "Load project context" && echo "PASS: Raw instruction content shown" || echo "FAIL: Raw instruction content missing"
   SANDBOX
   ```

5. Verify no Task tool instructions for regular phase
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "FAIL: Task tool shown for regular phase" || echo "PASS: No Task tool for regular phase"
   echo "$STATUS_OUTPUT" | grep -q "forked context" && echo "FAIL: Fork instructions shown for regular phase" || echo "PASS: No fork instructions for regular phase"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Current phase is "prepare"
- Output contains "Instructions:" header
- Output contains raw instruction text
- Output does NOT contain "Task tool" or "forked context"

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Fork Phase Shows Task Tool Instructions

**Objective:** Verify that a fork context phase shows Task tool invocation instructions instead of raw instructions.

**Steps:**
1. Complete the prepare phase to advance to implement (fork phase)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "prepare-report.md" << 'EOF'
# Prepare Report

Context loaded, requirements reviewed.
EOF
   $ACE_ASSIGN report "prepare-report.md"
   SANDBOX
   ```

2. Check status for implement phase (fork context)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   STATUS_OUTPUT=$($ACE_ASSIGN status 2>&1)
   STATUS_EXIT=$?
   echo "Exit code: $STATUS_EXIT"
   echo "Output:"
   echo "$STATUS_OUTPUT"
   SANDBOX
   ```

3. Verify current phase is implement
   ```bash
   ace-test-e2e-sh "$TEST_DIR" echo "$STATUS_OUTPUT" | grep -q "Current Phase:.*implement" && echo "PASS: Current phase is implement" || echo "FAIL: Current phase is not implement"
   ```

4. Verify context field displayed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" echo "$STATUS_OUTPUT" | grep -q "Context: fork" && echo "PASS: Context: fork displayed" || echo "FAIL: Context: fork not displayed"
   ```

5. Verify Task tool instructions shown
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$STATUS_OUTPUT" | grep -q "forked context" && echo "PASS: Fork execution instructions shown" || echo "FAIL: Fork execution instructions missing"
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "PASS: Task tool mentioned" || echo "FAIL: Task tool not mentioned"
   SANDBOX
   ```

6. Verify prompt section present
   ```bash
   ace-test-e2e-sh "$TEST_DIR" echo "$STATUS_OUTPUT" | grep -q "Prompt for forked agent" && echo "PASS: Prompt section shown" || echo "FAIL: Prompt section missing"
   ```

7. Verify job content is in prompt
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$STATUS_OUTPUT" | grep -q "## Onboard" && echo "PASS: Onboard section in prompt" || echo "FAIL: Onboard section missing"
   echo "$STATUS_OUTPUT" | grep -q "## Work" && echo "PASS: Work section in prompt" || echo "FAIL: Work section missing"
   echo "$STATUS_OUTPUT" | grep -q "## Report" && echo "PASS: Report section in prompt" || echo "FAIL: Report section missing"
   SANDBOX
   ```

**Expected:**
- Current phase is "implement"
- Output shows "Context: fork"
- Output contains "forked context" and "Task tool" instructions
- Output contains "Prompt for forked agent" section
- Prompt includes "## Onboard", "## Work", "## Report" sections

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Complete Fork Workflow

**Objective:** Verify that the workflow completes successfully after all fork and regular phases.

**Steps:**
1. Complete the implement phase (fork)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "implement-report.md" << 'EOF'
# Implementation Report

- Status: completed
- Changes: src/feature.rb added
- Commits: abc123
EOF
   $ACE_ASSIGN report "implement-report.md"
   SANDBOX
   ```

2. Complete the verify phase
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "verify-report.md" << 'EOF'
# Verification Report

All tests pass.
EOF
   $ACE_ASSIGN report "verify-report.md"
   SANDBOX
   ```

3. Complete the document phase (second fork)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "document-report.md" << 'EOF'
# Documentation Report

Updated:
- README.md
- docs/feature.md
EOF
   $ACE_ASSIGN report "document-report.md"
   SANDBOX
   ```

4. Check final status
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   FINAL_STATUS=$($ACE_ASSIGN status 2>&1)
   FINAL_EXIT=$?
   echo "Exit code: $FINAL_EXIT"
   echo "Output:"
   echo "$FINAL_STATUS"
   SANDBOX
   ```

5. Verify assignment completed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" echo "$FINAL_STATUS" | grep -q "Assignment completed!" && echo "PASS: Assignment completed" || echo "FAIL: Assignment not completed"
   ```

6. Find assignment directory and verify all phases done
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ASSIGNMENT_DIR=$(find ".cache/ace-assign" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   DONE_COUNT=$(grep -rl "status: done" "$ASSIGNMENT_DIR/phases/" 2>/dev/null | wc -l | tr -d ' ')
   [ "$DONE_COUNT" -eq 4 ] && echo "PASS: All 4 phases done" || echo "FAIL: Expected 4 done phases, found $DONE_COUNT"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output contains "Assignment completed!"
- All 4 phases marked as done

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
echo "Cleanup complete"
```

## Success Criteria

- [ ] TC-001: Fork context parsed from job frontmatter into phase files
- [ ] TC-002: Regular phase shows raw instructions directly
- [ ] TC-003: Fork phase shows Task tool invocation instructions
- [ ] TC-004: Complete workflow with fork phases succeeds
