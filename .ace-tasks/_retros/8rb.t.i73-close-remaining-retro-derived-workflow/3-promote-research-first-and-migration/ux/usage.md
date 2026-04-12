# Research-First Execution Checks - Draft Usage

## API Surface

- [ ] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (execution/review workflow expectations)

## Usage Scenarios

### Scenario 1: Execute a migration-style task
**Goal**: An implementer works on a rename or interface migration and needs explicit execution-time audit expectations.

`ace-bundle wfi://task/work`

**Expected Output**: The execution workflow requires evidence of existing-pattern checks, flag/API verification where relevant, and stale-reference audit behavior rather than leaving those steps implied.

### Scenario 2: Review a shared-surface change
**Goal**: A reviewer checks whether the implementer audited old names, paths, or references after a migration.

`ace-bundle wfi://task/review-work`

**Expected Output**: The review workflow has concrete criteria for missing preflight research or incomplete migration audits.

## Notes for Implementer

- Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
