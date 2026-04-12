# Draft-Time Spec Guardrails - Draft Usage

## API Surface

- [ ] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (task draft structure / required sections)

## Usage Scenarios

### Scenario 1: Draft a workflow-changing task
**Goal**: A drafter creates a task spec for a workflow or output-format change without leaving downstream consumers implicit.

`ace-bundle wfi://task/draft`

**Expected Output**: The resulting draft prompts for affected consumers, removal intent where replacement is planned, and artifact-chain/public handoff behavior before the task reaches review.

### Scenario 2: Catch contradiction before review
**Goal**: A drafter notices the task says both “replace” and “preserve” the same behavior.

`ace-bundle wfi://task/draft`

**Expected Output**: The draft structure or checklist forces the contradiction to be resolved during authoring rather than relying on `task/review` as the first detection point.

## Notes for Implementer

- Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
