---
tc-id: TC-002
title: Prepare From Multi-Task Expansion
---

## Objective

Verify deterministic multi-task preset expansion generates a valid job YAML with batch parent/children, resolved taskrefs, and expected review/apply phases.

## Steps

### Phase 1: Generate Multi-Task Job

1. Expand the `work-on-tasks` preset with taskrefs `001,002` and write `jobs/tc002-work-on-tasks-001-002-job.yml`
   ```bash
   mkdir -p jobs
   ruby <<'RUBY'
   require "yaml"
   require "ace/assign/atoms/preset_expander"

   preset = YAML.safe_load(File.read("fixtures/work-on-tasks.yml"))
   steps = Ace::Assign::Atoms::PresetExpander.expand(preset, { "taskrefs" => "001,002" })

   job = {
     "session" => {
       "name" => "tc002-work-on-tasks-001-002",
       "description" => "Deterministic expansion for two taskrefs"
     },
     "phases" => steps
   }

   File.write("jobs/tc002-work-on-tasks-001-002-job.yml", YAML.dump(job))
   puts "PASS: Generated jobs/tc002-work-on-tasks-001-002-job.yml"
   RUBY
   ```

### Phase 2: Verify job.yaml generated

2. Confirm generated file exists
   ```bash
   JOB_FILE="jobs/tc002-work-on-tasks-001-002-job.yml"
   [ -f "$JOB_FILE" ] && echo "PASS: job.yaml found at $JOB_FILE" || echo "FAIL: No job.yaml generated"
   ```

### Phase 3: Validate expanded structure

3. Verify session and phases keys
   ```bash
   JOB_FILE="jobs/tc002-work-on-tasks-001-002-job.yml"
   grep -q "^session:" "$JOB_FILE" && echo "PASS: session: key present" || echo "FAIL: session: key missing"
   grep -q "^phases:" "$JOB_FILE" && echo "PASS: phases: key present" || echo "FAIL: phases: key missing"
   ```

4. Verify batch parent and expanded children
   ```bash
   JOB_FILE="jobs/tc002-work-on-tasks-001-002-job.yml"
   grep -q "name: batch-tasks" "$JOB_FILE" && echo "PASS: Batch parent present" || echo "FAIL: Batch parent missing"
   grep -q "number: '010.01'" "$JOB_FILE" && echo "PASS: Child phase 010.01 present" || echo "FAIL: Child phase 010.01 missing"
   grep -q "number: '010.02'" "$JOB_FILE" && echo "PASS: Child phase 010.02 present" || echo "FAIL: Child phase 010.02 missing"
   grep -q "name: work-on-001" "$JOB_FILE" && echo "PASS: work-on-001 generated" || echo "FAIL: work-on-001 missing"
   grep -q "name: work-on-002" "$JOB_FILE" && echo "PASS: work-on-002 generated" || echo "FAIL: work-on-002 missing"
   ```

5. Verify expected review/apply phases from preset
   ```bash
   JOB_FILE="jobs/tc002-work-on-tasks-001-002-job.yml"
   grep -q "name: review-valid-1" "$JOB_FILE" && echo "PASS: review-valid-1 phase present" || echo "FAIL: review-valid-1 phase missing"
   grep -q "name: apply-valid-1" "$JOB_FILE" && echo "PASS: apply-valid-1 phase present" || echo "FAIL: apply-valid-1 phase missing"
   grep -q "name: review-fit-1" "$JOB_FILE" && echo "PASS: review-fit-1 phase present" || echo "FAIL: review-fit-1 phase missing"
   grep -q "name: apply-fit-1" "$JOB_FILE" && echo "PASS: apply-fit-1 phase present" || echo "FAIL: apply-fit-1 phase missing"
   grep -q "name: review-shine-1" "$JOB_FILE" && echo "PASS: review-shine-1 phase present" || echo "FAIL: review-shine-1 phase missing"
   grep -q "name: apply-shine-1" "$JOB_FILE" && echo "PASS: apply-shine-1 phase present" || echo "FAIL: apply-shine-1 phase missing"
   ```

6. Verify taskrefs resolved and no placeholders remain
   ```bash
   JOB_FILE="jobs/tc002-work-on-tasks-001-002-job.yml"
   grep -q "{{" "$JOB_FILE" && echo "FAIL: Unresolved {{placeholders}} remain" || echo "PASS: No unresolved placeholders"
   grep -q "task 001" "$JOB_FILE" && echo "PASS: taskref 001 appears in job" || echo "FAIL: taskref 001 missing"
   grep -q "task 002" "$JOB_FILE" && echo "PASS: taskref 002 appears in job" || echo "FAIL: taskref 002 missing"
   ```

## Expected

- `jobs/tc002-work-on-tasks-001-002-job.yml` is generated deterministically
- `session:` and `phases:` keys are present
- Expansion creates batch parent `010` and child phases `010.01` / `010.02`
- Expanded children include `work-on-001` and `work-on-002`
- Review/apply phases exist per preset definition
- No unresolved `{{placeholder}}` tokens remain
