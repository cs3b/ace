---
tc-id: TC-002
title: Prepare From Informal Instructions
---

## Objective

Verify that `/ace:assign-prepare` with informal text instructions generates a valid job.yaml
with correctly identified phases, loop expansion, and skill mapping from natural language.

## Steps

### Phase 1: Invoke Prepare with Informal Instructions

1. Run prepare with informal instructions describing a multi-cycle workflow
   ```
   /ace:assign-prepare "Work on task 001, create a PR, then do 2 review cycles"
   ```

### Phase 2: Verify job.yaml generated

2. Confirm job.yaml was generated
   ```bash
   JOB_FILE=$(ls jobs/*-job.yml 2>/dev/null | tail -1)
   [ -f "$JOB_FILE" ] && echo "PASS: job.yaml found at $JOB_FILE" || echo "FAIL: No job.yaml generated"
   ```

### Phase 3: Validate inferred structure

3. Verify session and phases keys present
   ```bash
   JOB_FILE=$(ls jobs/*-job.yml 2>/dev/null | tail -1)
   grep -q "^session:" "$JOB_FILE" && echo "PASS: session: key present" || echo "FAIL: session: key missing"
   grep -q "^phases:" "$JOB_FILE" && echo "PASS: phases: key present" || echo "FAIL: phases: key missing"
   ```

4. Verify "work on task" mapped to a work/implement phase
   ```bash
   JOB_FILE=$(ls jobs/*-job.yml 2>/dev/null | tail -1)
   grep -qi "work-on\|implement\|task-work" "$JOB_FILE" && echo "PASS: Work phase identified" || echo "FAIL: No work phase found"
   ```

5. Verify "create a PR" mapped to a PR creation phase
   ```bash
   JOB_FILE=$(ls jobs/*-job.yml 2>/dev/null | tail -1)
   grep -qi "create-pr\|git-create-pr\|pull-request" "$JOB_FILE" && echo "PASS: PR phase identified" || echo "FAIL: No PR phase found"
   ```

6. Verify "2 review cycles" expanded to at least 4 phases (2 review + 2 apply)
   ```bash
   JOB_FILE=$(ls jobs/*-job.yml 2>/dev/null | tail -1)
   REVIEW_COUNT=$(grep -c "review" "$JOB_FILE" || true)
   APPLY_COUNT=$(grep -c "apply" "$JOB_FILE" || true)
   echo "Review phases: $REVIEW_COUNT"
   echo "Apply phases: $APPLY_COUNT"
   [ "$REVIEW_COUNT" -ge 2 ] && echo "PASS: At least 2 review phases" || echo "FAIL: Expected >=2 review phases, found $REVIEW_COUNT"
   [ "$APPLY_COUNT" -ge 2 ] && echo "PASS: At least 2 apply phases" || echo "FAIL: Expected >=2 apply phases, found $APPLY_COUNT"
   ```

7. Verify no unresolved placeholders
   ```bash
   JOB_FILE=$(ls jobs/*-job.yml 2>/dev/null | tail -1)
   grep -q "{{" "$JOB_FILE" && echo "FAIL: Unresolved {{placeholders}} remain" || echo "PASS: No unresolved placeholders"
   ```

## Expected

- `jobs/` directory contains a new `*-job.yml` file
- `session:` and `phases:` keys present
- Work/implement phase present (from "work on task 001")
- PR creation phase present (from "create a PR")
- At least 2 review phases + at least 2 apply phases (from "2 review cycles")
- No `{{placeholder}}` tokens remaining
