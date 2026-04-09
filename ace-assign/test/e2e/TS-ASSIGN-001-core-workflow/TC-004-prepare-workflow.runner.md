# Goal 4 — Prepare Workflow

## Goal

Validate prepare preset fixtures for single-task and multi-task workflows using declared CLI tools only (no internal Ruby API calls).

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/work-on-task.yml` — copied unified fixture (single + multi support)
- `results/tc/04/fixture-checks.stdout` — command-based checks over fixture content

Optional capture:
- `results/tc/04/analysis.md` — summary of unified fixture capabilities

## Constraints

- Do not call internal Ruby classes/modules (for example `Ace::Assign::Atoms::PresetExpander`).
- Copy the canonical fixture from `fixtures/prepare/` into `results/tc/04/` via:
  - `ace-bundle fixtures/prepare/work-on-task.yml --output results/tc/04/work-on-task.yml`
- Validate single-task compatibility in `work-on-task.yml`:
  - contains `name: work-on-task`
  - supports shorthand usage with `--taskref`
  - contains `steps:`
  - contains expected step/skill references (for example `work-on-task`, `create-pr`)
- Validate multi-task capability in `work-on-task.yml`:
  - contains `name: work-on-task`
  - contains `taskrefs` parameter definition
  - contains `expansion:`
  - contains expected batch/child markers (for example `batch-tasks`, `work-on-{{item}}`)
- Save command evidence in `fixture-checks.stdout` using `ace-search` queries over copied files. `analysis.md` may summarize findings, but it is support evidence only.
- All artifacts must come from real tool execution.
