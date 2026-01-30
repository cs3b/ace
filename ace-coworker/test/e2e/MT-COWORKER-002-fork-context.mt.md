---
test-id: MT-COWORKER-002
title: Fork Context Feature
area: coworker
package: ace-coworker
priority: high
duration: ~10min
automation-candidate: true
requires:
  tools: [ace-coworker]
  ruby: ">= 3.0"
last-verified:
verified-by:
---

# Fork Context Feature

## Objective

Verify that ace-coworker correctly handles the `context: fork` frontmatter option, producing Task tool instructions for forked job execution instead of raw instructions.

## Prerequisites

- Ruby >= 3.0 installed
- ace-coworker package available (via bundle exec or installed)

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="coworker"
SHORT_ID="mt002"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Ensure cache base directory exists
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
# Create job.yaml with mixed regular and fork context steps
cat > "$TEST_DIR/job.yaml" << 'EOF'
name: test-fork-context
description: Test workflow for fork context feature

steps:
  - name: prepare
    instructions:
      - Load project context
      - Review requirements

  - name: implement
    context: fork
    instructions: |
      ## Onboard

      Load context before starting:
      - ace-bundle project
      - ace-taskflow task 123

      ## Work

      Implement the feature following project conventions.
      Run tests after each change.

      ## Report

      Return structured summary:
      - Status: completed | partial | blocked
      - Changes: files modified
      - Commits: hashes created

  - name: verify
    instructions: Run ace-test and verify implementation

  - name: document
    context: fork
    instructions: |
      ## Work

      Update documentation for the new feature.

      ## Report

      Return list of docs updated.
EOF

echo "Test data created:"
cat "$TEST_DIR/job.yaml"
```

## Test Cases

### TC-001: Fork Context Parsed from Job Frontmatter

**Objective:** Verify that `context: fork` in job.yaml creates a step file with context field in frontmatter.

**Steps:**
1. Create session from config
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

3. Find session directory
   ```bash
   SESSION_DIR=$(find "$TEST_DIR/.cache/ace-coworker" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   echo "Session directory: $SESSION_DIR"
   ```

4. Verify fork context in implement step frontmatter
   ```bash
   grep -q "context: fork" "$SESSION_DIR/jobs/020-implement.j.md" && echo "PASS: context: fork in implement step" || echo "FAIL: context: fork missing from implement step"
   ```

5. Verify fork context in document step frontmatter
   ```bash
   grep -q "context: fork" "$SESSION_DIR/jobs/040-document.j.md" && echo "PASS: context: fork in document step" || echo "FAIL: context: fork missing from document step"
   ```

6. Verify no context field in regular steps
   ```bash
   grep -q "context:" "$SESSION_DIR/jobs/010-prepare.j.md" && echo "FAIL: prepare step should not have context field" || echo "PASS: prepare step has no context field"
   grep -q "context:" "$SESSION_DIR/jobs/030-verify.j.md" && echo "FAIL: verify step should not have context field" || echo "PASS: verify step has no context field"
   ```

**Expected:**
- Exit code: 0
- `020-implement.j.md` contains `context: fork` in frontmatter
- `040-document.j.md` contains `context: fork` in frontmatter
- `010-prepare.j.md` does NOT contain `context:` field
- `030-verify.j.md` does NOT contain `context:` field

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Regular Step Shows Raw Instructions

**Objective:** Verify that a regular step (no fork context) shows raw instructions directly in status output.

**Steps:**
1. Check status output for first step (regular, no fork)
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

3. Verify current step is prepare (regular step)
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*prepare" && echo "PASS: Current step is prepare" || echo "FAIL: Current step is not prepare"
   ```

4. Verify instructions shown directly (not Task tool format)
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Instructions:" && echo "PASS: Raw instructions header shown" || echo "FAIL: Instructions header missing"
   echo "$STATUS_OUTPUT" | grep -q "Load project context" && echo "PASS: Raw instruction content shown" || echo "FAIL: Raw instruction content missing"
   ```

5. Verify no Task tool instructions for regular step
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "FAIL: Task tool shown for regular step" || echo "PASS: No Task tool for regular step"
   echo "$STATUS_OUTPUT" | grep -q "forked context" && echo "FAIL: Fork instructions shown for regular step" || echo "PASS: No fork instructions for regular step"
   ```

**Expected:**
- Exit code: 0
- Current step is "prepare"
- Output contains "Instructions:" header
- Output contains raw instruction text
- Output does NOT contain "Task tool" or "forked context"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Fork Step Shows Task Tool Instructions

**Objective:** Verify that a fork context step shows Task tool invocation instructions instead of raw instructions.

**Steps:**
1. Complete the prepare step to advance to implement (fork step)
   ```bash
   cat > "$TEST_DIR/prepare-report.md" << 'EOF'
# Prepare Report

Context loaded, requirements reviewed.
EOF
   $ACE_COWORKER report "$TEST_DIR/prepare-report.md"
   ```

2. Check status for implement step (fork context)
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   STATUS_EXIT=$?
   echo "Exit code: $STATUS_EXIT"
   echo "Output:"
   echo "$STATUS_OUTPUT"
   ```

3. Verify current step is implement
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*implement" && echo "PASS: Current step is implement" || echo "FAIL: Current step is not implement"
   ```

4. Verify context field displayed
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Context: fork" && echo "PASS: Context: fork displayed" || echo "FAIL: Context: fork not displayed"
   ```

5. Verify Task tool instructions shown
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "forked context" && echo "PASS: Fork execution instructions shown" || echo "FAIL: Fork execution instructions missing"
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "PASS: Task tool mentioned" || echo "FAIL: Task tool not mentioned"
   ```

6. Verify prompt section present
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Prompt for forked agent" && echo "PASS: Prompt section shown" || echo "FAIL: Prompt section missing"
   ```

7. Verify job content is in prompt
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "## Onboard" && echo "PASS: Onboard section in prompt" || echo "FAIL: Onboard section missing"
   echo "$STATUS_OUTPUT" | grep -q "## Work" && echo "PASS: Work section in prompt" || echo "FAIL: Work section missing"
   echo "$STATUS_OUTPUT" | grep -q "## Report" && echo "PASS: Report section in prompt" || echo "FAIL: Report section missing"
   ```

**Expected:**
- Current step is "implement"
- Output shows "Context: fork"
- Output contains "forked context" and "Task tool" instructions
- Output contains "Prompt for forked agent" section
- Prompt includes "## Onboard", "## Work", "## Report" sections

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Fork Prompt Includes Working Directory

**Objective:** Verify that fork instructions include the working directory for the forked agent.

**Steps:**
1. Check status output for working directory
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   ```

2. Verify working directory shown
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Working directory:" && echo "PASS: Working directory line present" || echo "FAIL: Working directory line missing"
   ```

3. Verify directory path is absolute (starts with /)
   ```bash
   WORK_DIR=$(echo "$STATUS_OUTPUT" | grep "Working directory:" | sed 's/.*Working directory: //')
   echo "Working directory: $WORK_DIR"
   [ "${WORK_DIR:0:1}" = "/" ] && echo "PASS: Path is absolute" || echo "FAIL: Path is not absolute"
   ```

**Expected:**
- Output contains "Working directory:" line
- Directory path is absolute (starts with /)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Fork Prompt Includes Session ID

**Objective:** Verify that fork instructions include the session ID for context.

**Steps:**
1. Check status output for session ID
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   ```

2. Verify session ID in fork instructions
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Session:" && echo "PASS: Session line present" || echo "FAIL: Session line missing"
   ```

3. Verify session ID format (should be non-empty)
   ```bash
   SESSION_LINE=$(echo "$STATUS_OUTPUT" | grep "Session:" | tail -1)
   echo "Session line: $SESSION_LINE"
   [ -n "$SESSION_LINE" ] && echo "PASS: Session ID present" || echo "FAIL: Session ID empty"
   ```

**Expected:**
- Output contains "Session:" line with session ID
- Session ID is non-empty

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Mixed Workflow Transitions (Regular -> Fork -> Regular)

**Objective:** Verify that a workflow with mixed regular and fork steps transitions correctly.

**Steps:**
1. Complete the implement step (fork)
   ```bash
   cat > "$TEST_DIR/implement-report.md" << 'EOF'
# Implementation Report

- Status: completed
- Changes: src/feature.rb added
- Commits: abc123
EOF
   $ACE_COWORKER report "$TEST_DIR/implement-report.md"
   ```

2. Check status for verify step (regular, should show raw instructions)
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "Output:"
   echo "$STATUS_OUTPUT"
   ```

3. Verify current step is verify (regular step)
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*verify" && echo "PASS: Current step is verify" || echo "FAIL: Current step is not verify"
   ```

4. Verify raw instructions shown (not fork format)
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Instructions:" && echo "PASS: Instructions header shown" || echo "FAIL: Instructions header missing"
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "FAIL: Task tool shown for regular step" || echo "PASS: No Task tool for regular step"
   ```

5. Verify no Context field for regular step
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Context:" && echo "FAIL: Context shown for regular step" || echo "PASS: No Context field for regular step"
   ```

**Expected:**
- Current step is "verify" (regular)
- Output shows "Instructions:" header with raw content
- Output does NOT show "Task tool" or "Context:"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Second Fork Step Works Correctly

**Objective:** Verify that multiple fork steps in the same workflow work correctly.

**Steps:**
1. Complete the verify step
   ```bash
   cat > "$TEST_DIR/verify-report.md" << 'EOF'
# Verification Report

All tests pass.
EOF
   $ACE_COWORKER report "$TEST_DIR/verify-report.md"
   ```

2. Check status for document step (second fork)
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "Output:"
   echo "$STATUS_OUTPUT"
   ```

3. Verify current step is document
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*document" && echo "PASS: Current step is document" || echo "FAIL: Current step is not document"
   ```

4. Verify fork context displayed
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Context: fork" && echo "PASS: Context: fork displayed" || echo "FAIL: Context: fork not displayed"
   ```

5. Verify Task tool instructions shown
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "forked context" && echo "PASS: Fork instructions shown" || echo "FAIL: Fork instructions missing"
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "PASS: Task tool mentioned" || echo "FAIL: Task tool not mentioned"
   ```

6. Verify document step content in prompt
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "Update documentation" && echo "PASS: Document instructions in prompt" || echo "FAIL: Document instructions missing"
   ```

**Expected:**
- Current step is "document"
- Output shows "Context: fork"
- Output contains fork execution instructions
- Prompt includes document step content

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Complete Fork Workflow

**Objective:** Verify that the workflow completes successfully after all fork and regular steps.

**Steps:**
1. Complete the document step (second fork)
   ```bash
   cat > "$TEST_DIR/document-report.md" << 'EOF'
# Documentation Report

Updated:
- README.md
- docs/feature.md
EOF
   $ACE_COWORKER report "$TEST_DIR/document-report.md"
   ```

2. Check final status
   ```bash
   FINAL_STATUS=$($ACE_COWORKER status 2>&1)
   FINAL_EXIT=$?
   echo "Exit code: $FINAL_EXIT"
   echo "Output:"
   echo "$FINAL_STATUS"
   ```

3. Verify session completed
   ```bash
   echo "$FINAL_STATUS" | grep -q "Session completed!" && echo "PASS: Session completed" || echo "FAIL: Session not completed"
   ```

4. Find session directory and verify all steps done
   ```bash
   SESSION_DIR=$(find "$TEST_DIR/.cache/ace-coworker" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
   DONE_COUNT=$(grep -rl "status: done" "$SESSION_DIR/jobs/" 2>/dev/null | wc -l | tr -d ' ')
   [ "$DONE_COUNT" -eq 4 ] && echo "PASS: All 4 steps done" || echo "FAIL: Expected 4 done steps, found $DONE_COUNT"
   ```

**Expected:**
- Exit code: 0
- Output contains "Session completed!"
- All 4 steps marked as done

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

- [ ] TC-001: Fork context parsed from job frontmatter into step files
- [ ] TC-002: Regular step shows raw instructions directly
- [ ] TC-003: Fork step shows Task tool invocation instructions
- [ ] TC-004: Fork prompt includes working directory
- [ ] TC-005: Fork prompt includes session ID
- [ ] TC-006: Mixed workflow transitions correctly (regular -> fork -> regular)
- [ ] TC-007: Second fork step in same workflow works correctly
- [ ] TC-008: Complete workflow with fork steps succeeds

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

### Fork Context Feature (task 237.02)

The fork context feature enables job files to run in isolated agent contexts:

- **Frontmatter**: `context: fork` triggers Task tool output format
- **Output format**: Instead of raw instructions, status shows Task tool parameters
- **Session context**: Working directory and session ID are included for the forked agent
- **Mixed workflows**: Regular and fork steps can be intermixed in the same workflow

### Key Implementation Details

- Fork detection uses `Step#fork?` method checking `context == "fork"`
- Task tool instructions printed by `Status#print_fork_instructions`
- Working directory derived from session cache directory
- Regular steps continue to show raw instructions via "Instructions:" header
