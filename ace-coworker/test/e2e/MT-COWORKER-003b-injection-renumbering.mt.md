---
test-id: MT-COWORKER-003b
title: Hierarchical Jobs - Injection and Renumbering
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

# Hierarchical Jobs - Injection and Renumbering

## Objective

Verify that ace-coworker correctly handles child injection via `add --after X --child`, sibling injection with renumbering, and cascade renumbering of descendants when parent jobs are shifted.

## Prerequisites

- Ruby >= 3.0 installed
- ace-coworker package available (via bundle exec or installed)

## Environment Setup

```bash
```

## Test Data

```bash
ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
# Create job.yaml and session with flat steps + initial children for injection testing
cat > "job.yaml" << 'EOF'
name: hierarchical-test
description: Test nested jobs and completion

steps:
  - name: implement-feature
    instructions: Implement the main feature

  - name: document
    instructions: Write documentation
EOF

CREATE_OUTPUT=$($ACE_COWORKER create "job.yaml" 2>&1)
CREATE_EXIT=$?
echo "Exit code: $CREATE_EXIT"
[ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Session creation failed"
SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)
echo "Session directory: $SESSION_DIR"

# Add two initial children under 010 (needed by TC-003, TC-004, TC-005)
$ACE_COWORKER add write-unit-tests --after 010 --child -i "Write unit tests for the feature" > /dev/null 2>&1
$ACE_COWORKER add write-integration-tests --after 010 --child -i "Write integration tests" > /dev/null 2>&1

[ -f "$SESSION_DIR/jobs/010.01-write-unit-tests.j.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Child 010.01 missing"
[ -f "$SESSION_DIR/jobs/010.02-write-integration-tests.j.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Child 010.02 missing"
SANDBOX
```

## Test Cases

### TC-003: Create Child Job with --after --child

**Objective:** Verify that `add --after X --child` creates a child job with correct numbering and metadata.

**Steps:**
1. Add a third child under 010, verify number and relationship
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ADD_OUTPUT=$($ACE_COWORKER add setup-fixtures --after 010 --child -i "Set up test fixtures" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"

   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   echo "$ADD_OUTPUT" | grep -q "010.03" && echo "PASS: New job is 010.03" || echo "FAIL: Expected job number 010.03"
   echo "$ADD_OUTPUT" | grep -q "child of 010" && echo "PASS: Relationship shows 'child of 010'" || echo "FAIL: Relationship should show 'child of 010'"
   SANDBOX
   ```

2. Verify file created with correct parent and provenance metadata
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$SESSION_DIR/jobs/010.03-setup-fixtures.j.md" ] && echo "PASS: Job file 010.03-setup-fixtures.j.md created" || echo "FAIL: Job file not created"
   grep -q 'parent:.*"010"' "$SESSION_DIR/jobs/010.03-setup-fixtures.j.md" && echo "PASS: New job has parent: 010" || echo "FAIL: New job missing parent field"
   grep -q 'added_by:.*child_of:010' "$SESSION_DIR/jobs/010.03-setup-fixtures.j.md" && echo "PASS: added_by shows child_of:010" || echo "FAIL: added_by missing or incorrect"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- New job created as 010.03 (next child number)
- Job file contains `parent: "010"` and `added_by: child_of:010`

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Create Sibling Job with --after (Triggers Renumbering)

**Objective:** Verify that `add --after X` (without --child) creates a sibling job and renumbers existing siblings.

**Steps:**
1. Add sibling job after 010.01 and verify renumbering output
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ADD_OUTPUT=$($ACE_COWORKER add run-linter --after 010.01 -i "Run linter checks" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"

   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   echo "$ADD_OUTPUT" | grep -q "Number: 010.02" && echo "PASS: New job is 010.02" || echo "FAIL: Expected job number 010.02"
   echo "$ADD_OUTPUT" | grep -q "sibling after 010.01" && echo "PASS: Relationship shows 'sibling after 010.01'" || echo "FAIL: Relationship should show sibling"
   echo "$ADD_OUTPUT" | grep -q "Renumbered jobs:" && echo "PASS: Renumbering announced" || echo "FAIL: Renumbering not shown"
   echo "$ADD_OUTPUT" | grep -q "010.02 -> 010.03" && echo "PASS: 010.02 shifted to 010.03" || echo "FAIL: Renumbering shift not shown"
   SANDBOX
   ```

2. Verify new 010.02 is run-linter with correct provenance
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$SESSION_DIR/jobs/010.02-run-linter.j.md" ] && echo "PASS: 010.02-run-linter.j.md exists" || echo "FAIL: 010.02-run-linter.j.md missing"
   grep -q 'added_by:.*injected_after:010.01' "$SESSION_DIR/jobs/010.02-run-linter.j.md" && echo "PASS: added_by shows injected_after" || echo "FAIL: added_by missing or incorrect"
   SANDBOX
   ```

3. Verify old 010.02 renamed to 010.03 with audit trail
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$SESSION_DIR/jobs/010.03-write-integration-tests.j.md" ] && echo "PASS: Old 010.02 is now 010.03" || echo "FAIL: Old 010.02 not found at 010.03"
   [ ! -f "$SESSION_DIR/jobs/010.02-write-integration-tests.j.md" ] && echo "PASS: Old 010.02-write-integration-tests no longer exists" || echo "FAIL: Old file still exists"
   grep -q 'renumbered_from:.*010.02' "$SESSION_DIR/jobs/010.03-write-integration-tests.j.md" && echo "PASS: renumbered_from: 010.02 present" || echo "FAIL: renumbered_from missing"
   grep -q 'renumbered_at:' "$SESSION_DIR/jobs/010.03-write-integration-tests.j.md" && echo "PASS: renumbered_at timestamp present" || echo "FAIL: renumbered_at missing"
   SANDBOX
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

**Steps:**
1. Add a child under 010.03 (the shifted write-integration-tests)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ADD_OUTPUT=$($ACE_COWORKER add integration-db-tests --after 010.03 --child -i "Database integration tests" 2>&1)
   ADD_EXIT=$?
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Child created" || echo "FAIL: Child creation failed"
   [ -f "$SESSION_DIR/jobs/010.03.01-integration-db-tests.j.md" ] && echo "PASS: 010.03.01 created" || echo "FAIL: 010.03.01 not created"
   SANDBOX
   ```

2. Inject sibling after 010.02 to trigger cascade renumbering
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ADD_OUTPUT=$($ACE_COWORKER add static-analysis --after 010.02 -i "Run static analysis" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output:"
   echo "$ADD_OUTPUT"

   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   echo "$ADD_OUTPUT" | grep -q "010.03 -> 010.04" && echo "PASS: Parent 010.03 shifted to 010.04" || echo "FAIL: Parent shift not shown"
   SANDBOX
   ```

3. Verify files renamed correctly including cascaded child
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$SESSION_DIR/jobs/010.03-static-analysis.j.md" ] && echo "PASS: New 010.03-static-analysis.j.md exists" || echo "FAIL: New 010.03 missing"
   [ -f "$SESSION_DIR/jobs/010.04-write-integration-tests.j.md" ] && echo "PASS: Old 010.03 is now 010.04" || echo "FAIL: Old 010.03 not at 010.04"
   [ -f "$SESSION_DIR/jobs/010.04.01-integration-db-tests.j.md" ] && echo "PASS: Child cascaded to 010.04.01" || echo "FAIL: Child not cascaded"
   [ ! -f "$SESSION_DIR/jobs/010.03.01-integration-db-tests.j.md" ] && echo "PASS: Old 010.03.01 no longer exists" || echo "FAIL: Old child file still exists"
   grep -q 'renumbered_from:.*010.03.01' "$SESSION_DIR/jobs/010.04.01-integration-db-tests.j.md" && echo "PASS: Child has renumbered_from: 010.03.01" || echo "FAIL: Child missing renumbered_from"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Parent job 010.03 shifted to 010.04
- Child job 010.03.01 cascaded to 010.04.01
- All shifted jobs have `renumbered_from` and `renumbered_at` metadata

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

- [ ] TC-003: Create child job with --after --child creates correct X.0N job with parent metadata
- [ ] TC-004: Create sibling job with --after triggers renumbering with audit trail
- [ ] TC-005: Cascade renumbering shifts children of shifted jobs
