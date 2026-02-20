---
tc-id: TC-001
title: Prepare From Preset
---

## Objective

Verify that `/ace:assign-prepare work-on-task --taskref 001` generates a valid job.yaml
with correct structure, resolved placeholders, and valid skill references.

## Steps

### Phase 1: Invoke Prepare

1. Run the prepare workflow with the `work-on-task` preset for taskref 001
   ```
   /ace:assign-prepare work-on-task --taskref 001
   ```

### Phase 2: Verify job.yaml exists

2. Confirm a job.yaml file was generated at the expected path
   ```bash
   JOB_FILE=$(find . -name "*.yml" -newer .cache/ace-assign -not -path "./.cache/*" 2>/dev/null | head -1)
   # Also check the conventional output path
   TASK_JOB=$(ls jobs/*-job.yml 2>/dev/null | head -1)
   FOUND=${JOB_FILE:-$TASK_JOB}
   [ -n "$FOUND" ] && echo "PASS: job.yaml found at $FOUND" || echo "FAIL: No job.yaml generated"
   echo "JOB_PATH=$FOUND"
   ```

### Phase 3: Validate structure

3. Verify job.yaml has required top-level keys
   ```bash
   JOB_FILE=$(ls jobs/*-job.yml 2>/dev/null | tail -1)
   [ -f "$JOB_FILE" ] || { echo "FAIL: job.yaml not found"; exit 1; }
   grep -q "^session:" "$JOB_FILE" && echo "PASS: session: key present" || echo "FAIL: session: key missing"
   grep -q "^phases:" "$JOB_FILE" && echo "PASS: phases: key present" || echo "FAIL: phases: key missing"
   ```

4. Verify taskref placeholder was resolved (no unresolved tokens)
   ```bash
   JOB_FILE=$(ls jobs/*-job.yml 2>/dev/null | tail -1)
   grep -q "{{" "$JOB_FILE" && echo "FAIL: Unresolved {{placeholders}} remain" || echo "PASS: All placeholders resolved"
   grep -q "001" "$JOB_FILE" && echo "PASS: taskref 001 appears in job" || echo "FAIL: taskref 001 not found in job"
   ```

5. Verify expected phase structure (work-on-task preset generates 010 work-on phase)
   ```bash
   JOB_FILE=$(ls jobs/*-job.yml 2>/dev/null | tail -1)
   grep -q "work-on" "$JOB_FILE" && echo "PASS: work-on phase present" || echo "FAIL: work-on phase missing"
   grep -q "create-pr\|git-create-pr" "$JOB_FILE" && echo "PASS: create-pr phase present" || echo "FAIL: create-pr phase missing"
   ```

6. Verify skill references use current namespaced format (ace:task-work, not old names)
   ```bash
   JOB_FILE=$(ls jobs/*-job.yml 2>/dev/null | tail -1)
   grep "skill:" "$JOB_FILE" | head -5
   grep -q "ace:task-work\|ace:git-create-pr\|ace:review-pr" "$JOB_FILE" && echo "PASS: Skill references present" || echo "FAIL: No skill references found"
   ```

## Expected

- Exit code from prepare: 0
- `jobs/` directory contains a new `*-job.yml` file
- `session:` and `phases:` top-level keys present
- No `{{placeholder}}` tokens remain
- `001` appears as the taskref value
- `work-on` and `create-pr` phases present
- Skill references follow `ace:` namespace format
