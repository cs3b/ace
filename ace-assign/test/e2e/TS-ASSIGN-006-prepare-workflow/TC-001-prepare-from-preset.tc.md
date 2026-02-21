---
tc-id: TC-001
title: Prepare From Preset
---

## Objective

Verify deterministic preset expansion for `work-on-task` generates a valid job YAML with resolved placeholders and expected phase/skill structure.

## Steps

### Phase 1: Generate Job From Preset

1. Expand the `work-on-task` preset with taskref `001` and write `jobs/tc001-work-on-task-001-job.yml`
   ```bash
   mkdir -p jobs
   ruby <<'RUBY'
   require "yaml"
   require "ace/assign/atoms/preset_expander"

   preset = YAML.safe_load(File.read("fixtures/work-on-task.yml"))
   steps = Ace::Assign::Atoms::PresetExpander.expand(preset, { "taskref" => "001" })

   job = {
     "session" => {
       "name" => "tc001-work-on-task-001",
       "description" => "Deterministic preset expansion for work-on-task"
     },
     "phases" => steps
   }

   File.write("jobs/tc001-work-on-task-001-job.yml", YAML.dump(job))
   puts "PASS: Generated jobs/tc001-work-on-task-001-job.yml"
   RUBY
   ```

### Phase 2: Verify job.yaml exists

2. Confirm the generated file exists
   ```bash
   JOB_FILE="jobs/tc001-work-on-task-001-job.yml"
   [ -f "$JOB_FILE" ] && echo "PASS: job.yaml found at $JOB_FILE" || echo "FAIL: No job.yaml generated"
   ```

### Phase 3: Validate structure

3. Verify top-level keys
   ```bash
   JOB_FILE="jobs/tc001-work-on-task-001-job.yml"
   grep -q "^session:" "$JOB_FILE" && echo "PASS: session: key present" || echo "FAIL: session: key missing"
   grep -q "^phases:" "$JOB_FILE" && echo "PASS: phases: key present" || echo "FAIL: phases: key missing"
   ```

4. Verify placeholder resolution and taskref injection
   ```bash
   JOB_FILE="jobs/tc001-work-on-task-001-job.yml"
   grep -q "{{" "$JOB_FILE" && echo "FAIL: Unresolved {{placeholders}} remain" || echo "PASS: All placeholders resolved"
   grep -q "task 001" "$JOB_FILE" && echo "PASS: taskref 001 appears in job" || echo "FAIL: taskref 001 not found in job"
   ```

5. Verify expected phases exist
   ```bash
   JOB_FILE="jobs/tc001-work-on-task-001-job.yml"
   grep -q "name: work-on-task" "$JOB_FILE" && echo "PASS: work-on-task phase present" || echo "FAIL: work-on-task phase missing"
   grep -q "name: create-pr" "$JOB_FILE" && echo "PASS: create-pr phase present" || echo "FAIL: create-pr phase missing"
   grep -q "name: review-valid-1" "$JOB_FILE" && echo "PASS: review-valid-1 phase present" || echo "FAIL: review-valid-1 phase missing"
   ```

6. Verify skill references use current namespaced format
   ```bash
   JOB_FILE="jobs/tc001-work-on-task-001-job.yml"
   grep "skill:" "$JOB_FILE" | head -8
   grep -q "skill: ace_task_work" "$JOB_FILE" && echo "PASS: ace_task_work skill present" || echo "FAIL: ace_task_work skill missing"
   grep -q "skill: ace_git_create-pr" "$JOB_FILE" && echo "PASS: ace_git_create-pr skill present" || echo "FAIL: ace_git_create-pr skill missing"
   grep -q "skill: ace_review_pr" "$JOB_FILE" && echo "PASS: ace_review_pr skill present" || echo "FAIL: ace_review_pr skill missing"
   ```

## Expected

- `jobs/tc001-work-on-task-001-job.yml` is generated deterministically
- `session:` and `phases:` top-level keys are present
- No unresolved `{{placeholder}}` tokens remain
- Taskref `001` appears in generated instructions
- `work-on-task`, `create-pr`, and review phases exist
- Skill references include `ace_task_work`, `ace_git_create-pr`, and `ace_review_pr`
