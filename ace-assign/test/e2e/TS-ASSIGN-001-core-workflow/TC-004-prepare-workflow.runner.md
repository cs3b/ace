# Goal 4 — Prepare Workflow

## Goal

Validate prepare preset fixtures for single-task and multi-task workflows using declared CLI tools only (no internal Ruby API calls).

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/work-on-task.yml` — copied single-task fixture
- `results/tc/04/work-on-tasks.yml` — copied multi-task fixture
- `results/tc/04/fixture-checks.stdout` — command-based checks over fixture content
- `results/tc/04/analysis.md` — analysis of both fixture definitions

## Constraints

- Do not call internal Ruby classes/modules (for example `Ace::Assign::Atoms::PresetExpander`).
- Copy both fixtures from `fixtures/prepare/` into `results/tc/04/` via:
  - `ace-bundle fixtures/prepare/work-on-task.yml --output results/tc/04/work-on-task.yml`
  - `ace-bundle fixtures/prepare/work-on-tasks.yml --output results/tc/04/work-on-tasks.yml`
- Validate single-task fixture (`work-on-task.yml`):
  - contains `name: work-on-task`
  - contains `steps:`
  - contains expected step/skill references (for example `work-on-task`, `ace-task-work`, `create-pr`)
- Validate multi-task fixture (`work-on-tasks.yml`):
  - contains `name: work-on-tasks`
  - contains `expansion:`
  - contains expected batch/child markers (for example `batch-tasks`, `work-on-{{item}}`)
- Save command evidence in `fixture-checks.stdout` using `ace-search` queries over copied files, then summarize findings in `analysis.md`.
- All artifacts must come from real tool execution.
