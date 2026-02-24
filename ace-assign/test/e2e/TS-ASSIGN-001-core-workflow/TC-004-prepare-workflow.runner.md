# Goal 4 — Prepare Workflow

## Goal

Test preset expansion: (1) expand `work-on-task` preset with a single taskref, verify resolved placeholders and expected phases/skills; (2) expand `work-on-tasks` preset with multiple taskrefs, verify batch parent/children structure.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/single-task-job.yml` — generated job from work-on-task preset
- `results/tc/04/single-task-expansion.stdout` — expansion output
- `results/tc/04/multi-task-job.yml` — generated job from work-on-tasks preset
- `results/tc/04/multi-task-expansion.stdout` — expansion output
- `results/tc/04/analysis.md` — analysis of both expansions

## Setup

Environment provides:
- `PROJECT_ROOT_PATH=.`
- Fixtures: `fixtures/prepare/work-on-task.yml`, `fixtures/prepare/work-on-tasks.yml`
- Minimal taskflow structure (created during setup):
  ```
  .ace-taskflow/v.0.1.0/t/001-test-task/001-test-task.s.md
  .ace-taskflow/v.0.1.0/t/002-test-task/002-test-task.s.md
  ```

## Constraints

- Use Ruby to expand presets via `Ace::Assign::Atoms::PresetExpander.expand`.
- For single task: expand `work-on-task` preset with `{ "taskref" => "001" }`.
  - Verify: job.yaml generated with resolved placeholders, no `{{...}}` tokens remain.
  - Verify: taskref "001" appears in generated instructions.
  - Verify: phases include work-on-task, create-pr, review-valid-1.
  - Verify: skill references include ace-task-work, ace-git-create-pr, ace-review-pr.
- For multi task: expand `work-on-tasks` preset with `{ "taskrefs" => "001,002" }`.
  - Verify: batch parent "batch-tasks" at 010, children 010.01 and 010.02.
  - Verify: children include work-on-001 and work-on-002.
  - Verify: review/apply phases (review-valid-1, apply-valid-1, review-fit-1, etc.) present.
  - Verify: no unresolved placeholders, both taskrefs appear in output.
- All artifacts must come from real tool execution.
