---
test-id: MT-COWORKER-003
title: Hierarchical Jobs and Completion
area: coworker
package: ace-coworker
priority: high
duration: ~20min
automation-candidate: true
requires:
  tools: [ace-coworker]
  ruby: ">= 3.0"
last-verified: 2026-01-30
verified-by: claude-opus-4-5-20251101
---

# Hierarchical Jobs and Completion

## Objective

Verify that ace-coworker correctly handles hierarchical job structures including dynamic child injection via `add --after X --child`, sibling injection with cascade renumbering, and auto-completion of parent jobs when all children complete.

## Prerequisites

- Ruby >= 3.0 installed
- ace-coworker package available (via bundle exec or installed)

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="coworker"
SHORT_ID="mt003"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$TEST_DIR"

# Ensure cache base directory exists
CACHE_BASE="$TEST_DIR/.cache/ace-coworker"
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
# Create job.yaml with flat steps (hierarchy will be created dynamically)
cat > "$TEST_DIR/job.yaml" << 'EOF'
name: hierarchical-test
description: Test nested jobs and completion

steps:
  - name: implement-feature
    instructions: Implement the main feature

  - name: document
    instructions: Write documentation
EOF

echo "Test data created:"
cat "$TEST_DIR/job.yaml"
```

## Test Cases

### TC-001: Error - Advance Parent with Incomplete Children

**Objective:** Verify that attempting to complete a parent job while children are incomplete fails with a clear error listing the incomplete children.

**Steps:**
1. Create session from config
   ```bash
   CREATE_OUTPUT=$($ACE_COWORKER create "$TEST_DIR/job.yaml" 2>&1)
   CREATE_EXIT=$?
   echo "Exit code: $CREATE_EXIT"
   echo "Output:"
   echo "$CREATE_OUTPUT"
   ```

2. Verify session created successfully
   ```bash
   [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Session creation failed"
   ```

3. Find session directory
   ```bash
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)
   echo "Session directory: $SESSION_DIR"
   ```

4. Verify initial structure (flat: 010 and 020)
   ```bash
   [ -f "$SESSION_DIR/jobs/010-implement-feature.j.md" ] && echo "PASS: Step 010 exists" || echo "FAIL: Step 010 missing"
   [ -f "$SESSION_DIR/jobs/020-document.j.md" ] && echo "PASS: Step 020 exists" || echo "FAIL: Step 020 missing"
   ```

5. Add child jobs under 010 to create hierarchy dynamically
   ```bash
   ADD1_OUTPUT=$($ACE_COWORKER add write-unit-tests --after 010 --child -i "Write unit tests for the feature" 2>&1)
   ADD1_EXIT=$?
   echo "Exit code: $ADD1_EXIT"
   [ "$ADD1_EXIT" -eq 0 ] && echo "PASS: Child 010.01 created" || echo "FAIL: Child creation failed"

   ADD2_OUTPUT=$($ACE_COWORKER add write-integration-tests --after 010 --child -i "Write integration tests" 2>&1)
   ADD2_EXIT=$?
   echo "Exit code: $ADD2_EXIT"
   [ "$ADD2_EXIT" -eq 0 ] && echo "PASS: Child 010.02 created" || echo "FAIL: Child creation failed"
   ```

6. Verify hierarchical structure created
   ```bash
   [ -f "$SESSION_DIR/jobs/010.01-write-unit-tests.j.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Child 010.01 missing"
   [ -f "$SESSION_DIR/jobs/010.02-write-integration-tests.j.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Child 010.02 missing"
   ```

7. Verify parent field in child jobs
   ```bash
   grep -q 'parent:.*"010"' "$SESSION_DIR/jobs/010.01-write-unit-tests.j.md" && echo "PASS: Child 010.01 has parent field" || echo "FAIL: Child 010.01 missing parent field"
   grep -q 'parent:.*"010"' "$SESSION_DIR/jobs/010.02-write-integration-tests.j.md" && echo "PASS: Child 010.02 has parent field" || echo "FAIL: Child 010.02 missing parent field"
   ```

8. Check status to see which step is in_progress
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "implement-feature" && echo "INFO: Current step is implement-feature (parent)" || echo "INFO: Current step is not the parent"
   ```

9. Create dummy report
   ```bash
   cat > "$TEST_DIR/parent-report.md" << 'EOF'
# Parent Report

Attempting to complete parent with incomplete children.
EOF
   ```

10. Attempt to complete parent while children are incomplete
    ```bash
    ADVANCE_OUTPUT=$($ACE_COWORKER report "$TEST_DIR/parent-report.md" 2>&1)
    ADVANCE_EXIT=$?
    echo "Exit code: $ADVANCE_EXIT"
    echo "Output:"
    echo "$ADVANCE_OUTPUT"
    ```

11. Verify error exit code
    ```bash
    [ "$ADVANCE_EXIT" -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Expected non-zero exit code"
    ```

12. Verify error mentions incomplete children
    ```bash
    echo "$ADVANCE_OUTPUT" | grep -qi "incomplete children" && echo "PASS: Error mentions 'incomplete children'" || echo "FAIL: Error should mention 'incomplete children'"
    echo "$ADVANCE_OUTPUT" | grep -q "010.01" && echo "PASS: Error lists child 010.01" || echo "FAIL: Error should list child 010.01"
    echo "$ADVANCE_OUTPUT" | grep -q "010.02" && echo "PASS: Error lists child 010.02" || echo "FAIL: Error should list child 010.02"
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
   ADD_OUTPUT=$($ACE_COWORKER add test-step --after 999 -i "Test instructions" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"
   ```

2. Verify error exit code
   ```bash
   [ "$ADD_EXIT" -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Expected non-zero exit code"
   ```

3. Verify error shows available jobs
   ```bash
   echo "$ADD_OUTPUT" | grep -qi "not found" && echo "PASS: Error mentions 'not found'" || echo "FAIL: Error should mention 'not found'"
   echo "$ADD_OUTPUT" | grep -qi "available" && echo "PASS: Error mentions available jobs" || echo "FAIL: Error should mention available jobs"
   echo "$ADD_OUTPUT" | grep -q "010" && echo "PASS: Available jobs include 010" || echo "FAIL: Available jobs should include 010"
   ```

**Expected:**
- Exit code: non-zero (error)
- Error message contains "not found"
- Error message shows "Available jobs:" with existing job numbers

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Create Child Job with --after --child

**Objective:** Verify that `add --after X --child` creates a child job with correct numbering and metadata.

**Steps:**
1. Add a child job under 010 (already has 010.01 and 010.02 from TC-001)
   ```bash
   ADD_OUTPUT=$($ACE_COWORKER add setup-fixtures --after 010 --child -i "Set up test fixtures" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"
   ```

2. Verify success
   ```bash
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   ```

3. Verify new job number shown (should be 010.03 since 010.01 and 010.02 exist)
   ```bash
   echo "$ADD_OUTPUT" | grep -q "010.03" && echo "PASS: New job is 010.03" || echo "FAIL: Expected job number 010.03"
   echo "$ADD_OUTPUT" | grep -q "child of 010" && echo "PASS: Relationship shows 'child of 010'" || echo "FAIL: Relationship should show 'child of 010'"
   ```

4. Verify file created
   ```bash
   [ -f "$SESSION_DIR/jobs/010.03-setup-fixtures.j.md" ] && echo "PASS: Job file 010.03-setup-fixtures.j.md created" || echo "FAIL: Job file not created"
   ```

5. Verify parent field in new job
   ```bash
   grep -q 'parent:.*"010"' "$SESSION_DIR/jobs/010.03-setup-fixtures.j.md" && echo "PASS: New job has parent: 010" || echo "FAIL: New job missing parent field"
   ```

6. Verify added_by metadata
   ```bash
   grep -q 'added_by:.*child_of:010' "$SESSION_DIR/jobs/010.03-setup-fixtures.j.md" && echo "PASS: added_by shows child_of:010" || echo "FAIL: added_by missing or incorrect"
   ```

**Expected:**
- Exit code: 0
- New job created as 010.03 (next child number)
- Job file contains `parent: "010"`
- Job file contains `added_by: child_of:010`

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Create Sibling Job with --after (Triggers Renumbering)

**Objective:** Verify that `add --after X` (without --child) creates a sibling job and renumbers existing siblings.

**Steps:**
1. Add sibling job after 010.01 (should become 010.02, shifting existing 010.02 to 010.03)
   ```bash
   ADD_OUTPUT=$($ACE_COWORKER add run-linter --after 010.01 -i "Run linter checks" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"
   ```

2. Verify success
   ```bash
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   ```

3. Verify new job is 010.02
   ```bash
   echo "$ADD_OUTPUT" | grep -q "Number: 010.02" && echo "PASS: New job is 010.02" || echo "FAIL: Expected job number 010.02"
   echo "$ADD_OUTPUT" | grep -q "sibling after 010.01" && echo "PASS: Relationship shows 'sibling after 010.01'" || echo "FAIL: Relationship should show sibling"
   ```

4. Verify renumbering shown
   ```bash
   echo "$ADD_OUTPUT" | grep -q "Renumbered jobs:" && echo "PASS: Renumbering announced" || echo "FAIL: Renumbering not shown"
   echo "$ADD_OUTPUT" | grep -q "010.02 -> 010.03" && echo "PASS: 010.02 shifted to 010.03" || echo "FAIL: Renumbering shift not shown"
   ```

5. Verify new 010.02 is run-linter
   ```bash
   [ -f "$SESSION_DIR/jobs/010.02-run-linter.j.md" ] && echo "PASS: 010.02-run-linter.j.md exists" || echo "FAIL: 010.02-run-linter.j.md missing"
   grep -q 'added_by:.*injected_after:010.01' "$SESSION_DIR/jobs/010.02-run-linter.j.md" && echo "PASS: added_by shows injected_after" || echo "FAIL: added_by missing or incorrect"
   ```

6. Verify old 010.02 (write-integration-tests) is now 010.03
   ```bash
   [ -f "$SESSION_DIR/jobs/010.03-write-integration-tests.j.md" ] && echo "PASS: Old 010.02 is now 010.03" || echo "FAIL: Old 010.02 not found at 010.03"
   [ ! -f "$SESSION_DIR/jobs/010.02-write-integration-tests.j.md" ] && echo "PASS: Old 010.02-write-integration-tests no longer exists" || echo "FAIL: Old file still exists"
   ```

7. Verify renumbered job has audit trail metadata
   ```bash
   grep -q 'renumbered_from:.*010.02' "$SESSION_DIR/jobs/010.03-write-integration-tests.j.md" && echo "PASS: renumbered_from: 010.02 present" || echo "FAIL: renumbered_from missing"
   grep -q 'renumbered_at:' "$SESSION_DIR/jobs/010.03-write-integration-tests.j.md" && echo "PASS: renumbered_at timestamp present" || echo "FAIL: renumbered_at missing"
   ```

**Expected:**
- Exit code: 0
- New job created as 010.02
- Output shows "Renumbered jobs:" with 010.02 -> 010.03
- Old 010.02 renamed to 010.03 with `renumbered_from` and `renumbered_at` metadata

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Cascade Renumbering (Children of Shifted Job)

**Objective:** Verify that when a parent job is renumbered, all its descendants are also renumbered.

**Note:** First we need to add a child to a job, then shift that job to trigger cascade.

**Steps:**
1. Add a child under 010.03 (the shifted write-integration-tests)
   ```bash
   ADD_OUTPUT=$($ACE_COWORKER add integration-db-tests --after 010.03 --child -i "Database integration tests" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Child created" || echo "FAIL: Child creation failed"
   ```

2. Verify child created as 010.03.01
   ```bash
   [ -f "$SESSION_DIR/jobs/010.03.01-integration-db-tests.j.md" ] && echo "PASS: 010.03.01 created" || echo "FAIL: 010.03.01 not created"
   ```

3. Now add another sibling after 010.02, which should shift 010.03 to 010.04 AND cascade 010.03.01 to 010.04.01
   ```bash
   ADD_OUTPUT=$($ACE_COWORKER add static-analysis --after 010.02 -i "Run static analysis" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"
   ```

4. Verify success
   ```bash
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   ```

5. Verify cascade renumbering output
   ```bash
   echo "$ADD_OUTPUT" | grep -q "010.03 -> 010.04" && echo "PASS: Parent 010.03 shifted to 010.04" || echo "FAIL: Parent shift not shown"
   ```

6. Verify files renamed correctly
   ```bash
   [ -f "$SESSION_DIR/jobs/010.03-static-analysis.j.md" ] && echo "PASS: New 010.03-static-analysis.j.md exists" || echo "FAIL: New 010.03 missing"
   [ -f "$SESSION_DIR/jobs/010.04-write-integration-tests.j.md" ] && echo "PASS: Old 010.03 is now 010.04" || echo "FAIL: Old 010.03 not at 010.04"
   ```

7. Verify child job cascaded from 010.03.01 to 010.04.01
   ```bash
   [ -f "$SESSION_DIR/jobs/010.04.01-integration-db-tests.j.md" ] && echo "PASS: Child cascaded to 010.04.01" || echo "FAIL: Child not cascaded"
   [ ! -f "$SESSION_DIR/jobs/010.03.01-integration-db-tests.j.md" ] && echo "PASS: Old 010.03.01 no longer exists" || echo "FAIL: Old child file still exists"
   ```

8. Verify cascade audit trail (child should have been renumbered too)
   ```bash
   grep -q 'renumbered_from:.*010.03.01' "$SESSION_DIR/jobs/010.04.01-integration-db-tests.j.md" && echo "PASS: Child has renumbered_from: 010.03.01" || echo "FAIL: Child missing renumbered_from"
   ```

**Expected:**
- Exit code: 0
- Parent job 010.03 shifted to 010.04
- Child job 010.03.01 cascaded to 010.04.01
- All shifted jobs have `renumbered_from` and `renumbered_at` metadata

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Complete All Children - Parent Auto-Completes

**Objective:** Verify that a parent job auto-completes when all its children are done.

**Steps:**
1. Create a fresh session with clean structure for auto-complete testing
   ```bash
   # Clean up existing session
   rm -rf "$SESSION_DIR"

   # Create a clean job.yaml with two top-level steps
   cat > "$TEST_DIR/job2.yaml" << 'EOF'
name: auto-complete-test
description: Test auto-completion of parent jobs

steps:
  - name: parent-job
    instructions: This parent should auto-complete when children finish

  - name: final-step
    instructions: Final step after parent completes
EOF

   CREATE_OUTPUT=$($ACE_COWORKER create "$TEST_DIR/job2.yaml" 2>&1)
   CREATE_EXIT=$?
   echo "Exit code: $CREATE_EXIT"
   [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Session creation failed"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)
   ```

2. Add two children to parent-job (010) dynamically
   ```bash
   $ACE_COWORKER add child-one --after 010 --child -i "First child task" > /dev/null 2>&1
   $ACE_COWORKER add child-two --after 010 --child -i "Second child task" > /dev/null 2>&1

   # Verify structure
   [ -f "$SESSION_DIR/jobs/010.01-child-one.j.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Child 010.01 missing"
   [ -f "$SESSION_DIR/jobs/010.02-child-two.j.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Child 010.02 missing"
   ```

3. Check initial status - parent 010 should be in_progress
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*parent-job" && echo "INFO: Parent is current step" || echo "INFO: Parent is not current step"
   ```

4. Parent cannot complete with incomplete children - verify protection
   ```bash
   echo "# Attempting parent completion" > "$TEST_DIR/report.md"
   PROTECT_OUTPUT=$($ACE_COWORKER report "$TEST_DIR/report.md" 2>&1)
   PROTECT_EXIT=$?
   echo "$PROTECT_OUTPUT"
   [ "$PROTECT_EXIT" -ne 0 ] && echo "PASS: Parent completion blocked" || echo "FAIL: Parent should not complete"
   ```

5. Manually mark parent as pending and first child as in_progress (simulate workflow)
   ```bash
   # Mark parent as pending (so children can be worked on)
   sed -i.bak 's/status: in_progress/status: pending/' "$SESSION_DIR/jobs/010-parent-job.j.md"
   # Mark first child as in_progress
   sed -i.bak 's/status: pending/status: in_progress/' "$SESSION_DIR/jobs/010.01-child-one.j.md"
   ```

6. Complete first child
   ```bash
   cat > "$TEST_DIR/child1-report.md" << 'EOF'
# Child One Report

First child completed successfully.
EOF
   CHILD1_OUTPUT=$($ACE_COWORKER report "$TEST_DIR/child1-report.md" 2>&1)
   CHILD1_EXIT=$?
   echo "Exit code: $CHILD1_EXIT"
   [ "$CHILD1_EXIT" -eq 0 ] && echo "PASS: Child one completed" || echo "FAIL: Child one completion failed"
   ```

7. Verify child two is now in_progress (auto-advanced)
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*child-two" && echo "PASS: Child two is now current" || echo "FAIL: Child two should be current"
   ```

8. Verify parent is still pending (not all children done)
   ```bash
   grep -q "status: pending" "$SESSION_DIR/jobs/010-parent-job.j.md" && echo "PASS: Parent still pending" || echo "FAIL: Parent should still be pending"
   ```

9. Complete second child
   ```bash
   cat > "$TEST_DIR/child2-report.md" << 'EOF'
# Child Two Report

Second child completed successfully.
EOF
   CHILD2_OUTPUT=$($ACE_COWORKER report "$TEST_DIR/child2-report.md" 2>&1)
   CHILD2_EXIT=$?
   echo "Exit code: $CHILD2_EXIT"
   [ "$CHILD2_EXIT" -eq 0 ] && echo "PASS: Child two completed" || echo "FAIL: Child two completion failed"
   ```

10. Verify parent auto-completed
    ```bash
    grep -q "status: done" "$SESSION_DIR/jobs/010-parent-job.j.md" && echo "PASS: Parent auto-completed" || echo "FAIL: Parent should auto-complete"
    ```

11. Verify auto-complete report created
    ```bash
    [ -f "$SESSION_DIR/reports/010-parent-job.r.md" ] && echo "PASS: Auto-complete report created" || echo "FAIL: Auto-complete report missing"
    grep -q "Auto-completed" "$SESSION_DIR/reports/010-parent-job.r.md" && echo "PASS: Report indicates auto-completion" || echo "FAIL: Report should indicate auto-completion"
    ```

12. Verify final-step is now in_progress
    ```bash
    STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
    echo "$STATUS_OUTPUT"
    echo "$STATUS_OUTPUT" | grep -q "Current Step:.*final-step" && echo "PASS: Final step is now current" || echo "FAIL: Final step should be current"
    ```

**Expected:**
- Parent 010 cannot complete while children incomplete
- After completing all children, parent auto-completes
- Auto-completion creates report with "Auto-completed" message
- Workflow advances to next top-level job (020)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Multi-Level Auto-Completion (Grandparent Chain)

**Objective:** Verify that auto-completion cascades up multiple levels (grandchild -> parent -> grandparent).

**Steps:**
1. Create session with a flat structure, then build 3-level hierarchy dynamically
   ```bash
   cat > "$TEST_DIR/job3.yaml" << 'EOF'
name: multi-level-test
description: Test multi-level auto-completion

steps:
  - name: grandparent
    instructions: Top level job

  - name: next-task
    instructions: Should become current after auto-completion chain
EOF

   CREATE_OUTPUT=$($ACE_COWORKER create "$TEST_DIR/job3.yaml" 2>&1)
   CREATE_EXIT=$?
   [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Session creation failed"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)
   ```

2. Build 3-level hierarchy dynamically
   ```bash
   # Add parent as child of grandparent
   $ACE_COWORKER add parent --after 010 --child -i "Middle level job" > /dev/null 2>&1
   [ -f "$SESSION_DIR/jobs/010.01-parent.j.md" ] && echo "PASS: Parent 010.01 created" || echo "FAIL: Parent creation failed"

   # Add grandchild as child of parent
   $ACE_COWORKER add child --after 010.01 --child -i "Bottom level job (grandchild)" > /dev/null 2>&1
   [ -f "$SESSION_DIR/jobs/010.01.01-child.j.md" ] && echo "PASS: Grandchild 010.01.01 created" || echo "FAIL: Grandchild creation failed"
   ```

3. Set grandchild as in_progress (others pending)
   ```bash
   # Mark all as pending first
   sed -i.bak 's/status: in_progress/status: pending/' "$SESSION_DIR/jobs/010-grandparent.j.md"
   # Mark grandchild as in_progress
   sed -i.bak 's/status: pending/status: in_progress/' "$SESSION_DIR/jobs/010.01.01-child.j.md"
   ```

4. Verify initial state
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*child" && echo "PASS: Grandchild is current" || echo "FAIL: Grandchild should be current"
   ```

5. Complete the grandchild (only job at bottom level)
   ```bash
   cat > "$TEST_DIR/grandchild-report.md" << 'EOF'
# Grandchild Report

Grandchild completed - should trigger chain auto-completion.
EOF
   COMPLETE_OUTPUT=$($ACE_COWORKER report "$TEST_DIR/grandchild-report.md" 2>&1)
   COMPLETE_EXIT=$?
   echo "Exit code: $COMPLETE_EXIT"
   echo "Output:"
   echo "$COMPLETE_OUTPUT"
   [ "$COMPLETE_EXIT" -eq 0 ] && echo "PASS: Grandchild completed" || echo "FAIL: Grandchild completion failed"
   ```

6. Verify grandchild is done
   ```bash
   grep -q "status: done" "$SESSION_DIR/jobs/010.01.01-child.j.md" && echo "PASS: Grandchild is done" || echo "FAIL: Grandchild should be done"
   ```

7. Verify parent auto-completed (only child was the grandchild, which is done)
   ```bash
   grep -q "status: done" "$SESSION_DIR/jobs/010.01-parent.j.md" && echo "PASS: Parent auto-completed" || echo "FAIL: Parent should auto-complete"
   [ -f "$SESSION_DIR/reports/010.01-parent.r.md" ] && echo "PASS: Parent auto-complete report exists" || echo "FAIL: Parent report missing"
   ```

8. Verify grandparent auto-completed (only child was parent, which is done)
   ```bash
   grep -q "status: done" "$SESSION_DIR/jobs/010-grandparent.j.md" && echo "PASS: Grandparent auto-completed" || echo "FAIL: Grandparent should auto-complete"
   [ -f "$SESSION_DIR/reports/010-grandparent.r.md" ] && echo "PASS: Grandparent auto-complete report exists" || echo "FAIL: Grandparent report missing"
   ```

9. Verify next-task (020) is now in_progress
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*next-task" && echo "PASS: next-task is now current" || echo "FAIL: next-task should be current"
   grep -q "status: in_progress" "$SESSION_DIR/jobs/020-next-task.j.md" && echo "PASS: 020 is in_progress" || echo "FAIL: 020 should be in_progress"
   ```

**Expected:**
- Completing grandchild (010.01.01) triggers cascade:
  - Parent (010.01) auto-completes (all children done)
  - Grandparent (010) auto-completes (all children done)
- Next top-level job (020) becomes in_progress

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Status Shows Hierarchy (Tree Structure)

**Objective:** Verify that the status command displays jobs in a hierarchical tree structure.

**Steps:**
1. Create session with clear hierarchy for display testing
   ```bash
   cat > "$TEST_DIR/job4.yaml" << 'EOF'
name: tree-display-test
description: Test hierarchical status display

steps:
  - name: feature-a
    instructions: First feature

  - name: feature-b
    instructions: Second feature
EOF

   CREATE_OUTPUT=$($ACE_COWORKER create "$TEST_DIR/job4.yaml" 2>&1)
   [ "$?" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Session creation failed"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)
   ```

2. Build hierarchy dynamically
   ```bash
   # Add children to feature-a (010)
   $ACE_COWORKER add a-subtask-1 --after 010 --child -i "First subtask of A" > /dev/null 2>&1
   $ACE_COWORKER add a-subtask-2 --after 010 --child -i "Second subtask of A" > /dev/null 2>&1

   # Add child to feature-b (020)
   $ACE_COWORKER add b-subtask-1 --after 020 --child -i "First subtask of B" > /dev/null 2>&1

   # Verify files created
   [ -f "$SESSION_DIR/jobs/010.01-a-subtask-1.j.md" ] && echo "PASS: 010.01 created" || echo "FAIL: 010.01 missing"
   [ -f "$SESSION_DIR/jobs/010.02-a-subtask-2.j.md" ] && echo "PASS: 010.02 created" || echo "FAIL: 010.02 missing"
   [ -f "$SESSION_DIR/jobs/020.01-b-subtask-1.j.md" ] && echo "PASS: 020.01 created" || echo "FAIL: 020.01 missing"
   ```

3. Get status output
   ```bash
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "Status output:"
   echo "$STATUS_OUTPUT"
   ```

4. Verify all jobs shown
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "feature-a" && echo "PASS: feature-a shown" || echo "FAIL: feature-a missing"
   echo "$STATUS_OUTPUT" | grep -q "a-subtask-1" && echo "PASS: a-subtask-1 shown" || echo "FAIL: a-subtask-1 missing"
   echo "$STATUS_OUTPUT" | grep -q "a-subtask-2" && echo "PASS: a-subtask-2 shown" || echo "FAIL: a-subtask-2 missing"
   echo "$STATUS_OUTPUT" | grep -q "feature-b" && echo "PASS: feature-b shown" || echo "FAIL: feature-b missing"
   echo "$STATUS_OUTPUT" | grep -q "b-subtask-1" && echo "PASS: b-subtask-1 shown" || echo "FAIL: b-subtask-1 missing"
   ```

5. Verify hierarchical display (children indented under parents)
   ```bash
   # Check that child jobs are displayed with visual hierarchy indicators
   # Common patterns: indentation, tree characters, or "  " prefix
   echo "$STATUS_OUTPUT" | grep -E "^\s+.*a-subtask" && echo "PASS: Children appear indented" || echo "INFO: Checking for tree display pattern"
   echo "$STATUS_OUTPUT" | grep -E "(├|└|│).*subtask" && echo "PASS: Tree characters used for hierarchy" || echo "INFO: May use different hierarchy display"
   ```

6. Verify job numbers reflect hierarchy
   ```bash
   echo "$STATUS_OUTPUT" | grep -q "010\.01" && echo "PASS: Nested number 010.01 shown" || echo "FAIL: Nested number not shown"
   echo "$STATUS_OUTPUT" | grep -q "010\.02" && echo "PASS: Nested number 010.02 shown" || echo "FAIL: Nested number not shown"
   echo "$STATUS_OUTPUT" | grep -q "020\.01" && echo "PASS: Nested number 020.01 shown" || echo "FAIL: Nested number not shown"
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
1. Create session and inject jobs to generate audit trail
   ```bash
   cat > "$TEST_DIR/job5.yaml" << 'EOF'
name: audit-trail-test
description: Test audit trail metadata

steps:
  - name: initial-job
    instructions: Starting job

  - name: second-job
    instructions: Second job
EOF

   CREATE_OUTPUT=$($ACE_COWORKER create "$TEST_DIR/job5.yaml" 2>&1)
   [ "$?" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Session creation failed"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)
   ```

2. Add child job (generates child_of audit)
   ```bash
   ADD_OUTPUT=$($ACE_COWORKER add child-task --after 010 --child -i "Child task" 2>&1)
   [ "$?" -eq 0 ] && echo "PASS: Child added" || echo "FAIL: Child add failed"
   ```

3. Verify child_of audit trail
   ```bash
   grep -q 'added_by:.*child_of:010' "$SESSION_DIR/jobs/010.01-child-task.j.md" && echo "PASS: added_by: child_of:010 present" || echo "FAIL: child_of audit missing"
   grep -q 'parent:.*"010"' "$SESSION_DIR/jobs/010.01-child-task.j.md" && echo "PASS: parent: 010 present" || echo "FAIL: parent field missing"
   ```

4. Add sibling job that triggers renumbering (generates injected_after audit)
   ```bash
   # First add another child so there's something to renumber
   $ACE_COWORKER add another-child --after 010 --child -i "Another child" > /dev/null 2>&1
   # Now inject sibling after 010.01 to trigger renumbering of 010.02
   ADD_OUTPUT=$($ACE_COWORKER add injected-sibling --after 010.01 -i "Injected sibling" 2>&1)
   echo "$ADD_OUTPUT"
   [ "$?" -eq 0 ] && echo "PASS: Sibling injected" || echo "FAIL: Sibling injection failed"
   ```

5. Verify injected_after audit trail
   ```bash
   grep -q 'added_by:.*injected_after:010.01' "$SESSION_DIR/jobs/010.02-injected-sibling.j.md" && echo "PASS: added_by: injected_after:010.01 present" || echo "FAIL: injected_after audit missing"
   ```

6. Verify renumbering audit trail on shifted job
   ```bash
   # The original 010.02-another-child should now be 010.03-another-child
   RENAMED_FILE=$(ls "$SESSION_DIR/jobs/"*another-child*.j.md 2>/dev/null | head -1)
   echo "Renamed file: $RENAMED_FILE"
   [ -n "$RENAMED_FILE" ] && echo "PASS: Renamed file found" || echo "FAIL: Renamed file not found"

   grep -q 'renumbered_from:' "$RENAMED_FILE" && echo "PASS: renumbered_from present" || echo "FAIL: renumbered_from missing"
   grep -q 'renumbered_at:' "$RENAMED_FILE" && echo "PASS: renumbered_at present" || echo "FAIL: renumbered_at missing"
   ```

7. Verify renumbered_at is ISO8601 timestamp
   ```bash
   TIMESTAMP=$(grep 'renumbered_at:' "$RENAMED_FILE" | sed 's/renumbered_at: *//')
   echo "Timestamp: $TIMESTAMP"
   echo "$TIMESTAMP" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' && echo "PASS: ISO8601 format" || echo "FAIL: Not ISO8601 format"
   ```

8. Add dynamic job without --after (generates dynamic audit)
   ```bash
   # Mark current as done first to test dynamic add
   sed -i.bak 's/status: in_progress/status: done/' "$SESSION_DIR/jobs/010-initial-job.j.md"
   ADD_OUTPUT=$($ACE_COWORKER add dynamic-step -i "Dynamically added" 2>&1)
   echo "$ADD_OUTPUT"
   [ "$?" -eq 0 ] && echo "PASS: Dynamic step added" || echo "FAIL: Dynamic step add failed"
   ```

9. Verify dynamic audit trail
   ```bash
   DYNAMIC_FILE=$(ls "$SESSION_DIR/jobs/"*dynamic-step*.j.md 2>/dev/null | head -1)
   echo "Dynamic file: $DYNAMIC_FILE"
   grep -q 'added_by:.*dynamic' "$DYNAMIC_FILE" && echo "PASS: added_by: dynamic present" || echo "FAIL: dynamic audit missing"
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
# Clean up test sessions from project cache
find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
echo "Cleanup complete"
```

## Success Criteria

- [ ] TC-001: Advance parent with incomplete children fails with clear error listing children
- [ ] TC-002: Invalid --after reference fails with error showing available jobs
- [ ] TC-003: Create child job with --after --child creates correct X.0N job with parent metadata
- [ ] TC-004: Create sibling job with --after triggers renumbering with audit trail
- [ ] TC-005: Cascade renumbering shifts children of shifted jobs
- [ ] TC-006: Parent auto-completes when all children finish
- [ ] TC-007: Multi-level auto-completion cascades (grandchild -> parent -> grandparent)
- [ ] TC-008: Status shows hierarchical structure with nested job numbers
- [ ] TC-009: All audit trail fields present (added_by, parent, renumbered_from, renumbered_at)

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

### Hierarchical Job Structure (task 237.03)

The hierarchical job feature enables nested job structures via **dynamic injection**:

- **Parent-child relationships**: Created with `add --after X --child`, generating dotted numbers (010 -> 010.01, 010.02)
- **Blocking semantics**: Parent jobs cannot complete until all children are done
- **Auto-completion**: Parents auto-complete when all children finish, cascading up the hierarchy
- **Child injection**: `add --after X --child` creates child jobs with `parent` field
- **Sibling injection**: `add --after X` creates siblings with cascade renumbering

### Key Implementation Details

- Config format uses `steps:` with `name:` and `instructions:` (NOT `jobs:` with explicit `number:`)
- Job numbers are auto-generated via `NumberGenerator.from_index()` on session create
- Hierarchy is built dynamically via `add --after X --child` command, NOT from config
- Job numbers use dot notation: 010 (top-level), 010.01 (child), 010.01.01 (grandchild)
- `parent` field in frontmatter links children to parents
- `added_by` field tracks provenance: `child_of:X`, `injected_after:X`, `dynamic`
- `renumbered_from` and `renumbered_at` track renumbering history
- Cascade renumbering affects all descendants when a parent is shifted
- Auto-completion uses iterative algorithm to handle multi-level hierarchies

### Error Handling

- Attempting to complete a parent with incomplete children:
  - Exit code: non-zero
  - Error message lists incomplete child numbers
  - Suggests using 'fail' command if parent should fail

- Invalid --after reference:
  - Exit code: non-zero
  - Error shows "Job X not found"
  - Lists available job numbers for user reference
