---
workflow-id: wfi-manage-e2e-tests
name: e2e/manage
description: Orchestrate the 3-stage E2E test lifecycle pipeline (review → plan → rewrite)
version: "2.0"
source: ace-test-runner-e2e
---

# Manage E2E Tests Workflow

This workflow is a lightweight orchestrator that chains the 3-stage E2E test pipeline. It delegates all logic to the specialized stage workflows.

```text
ace-bundle wfi://e2e/manage
         │
         ├─► Stage 1: ace-bundle wfi://e2e/review   (explore)
         │        └─► Coverage matrix
         │
         ├─► Stage 2: ace-bundle wfi://e2e/plan-changes    (decide)
         │        └─► Change plan
         │
         ├─► User confirmation gate
         │
         ├─► Stage 3: ace-bundle wfi://e2e/rewrite   (execute)
         │        └─► Updated test files
         │
         └─► (optional) `ace-test-e2e` verification     (verify)
```

## Arguments

- `PACKAGE` (required) - The package to manage (e.g., `ace-lint`)
- `--dry-run` (optional) - Stop after presenting the change plan (skip execution)
- `--run-tests` (optional) - Run all E2E tests after rewriting
- `--tags TAG,...` (optional) - Include only scenarios matching any specified tag (OR semantics)
- `--exclude-tags TAG,...` (optional) - Exclude scenarios matching any specified tag (OR semantics)

## Guardrail

- Do not execute `ace-test-e2e` / `ace-test-e2e-suite` autonomously in constrained or uncertain environments.
- When verification is requested, provide exact commands for user execution unless the user explicitly requests local execution and confirms environment fidelity.

## Workflow Steps

### 1. Invoke Stage 1: Review

Run the exploration stage to produce a coverage matrix:

```bash
ace-bundle wfi://e2e/review
```

Capture the full review report output including coverage matrix, overlap analysis, gap analysis, and health status.

If the review finds no E2E tests and no features worth testing, report this and stop.

### 2. Invoke Stage 2: Plan

Run the decision stage to produce a concrete change plan:

```bash
ace-bundle wfi://e2e/plan-changes
```

Capture the change plan with its REMOVE / KEEP / MODIFY / CONSOLIDATE / ADD classifications and the proposed scenario structure.

### 3. Present Plan for Confirmation

Display the change plan from Stage 2 to the user. The plan includes:
- Impact summary (current vs proposed scenarios/TCs/cost)
- Classified actions for each TC
- Proposed scenario structure

**If `--dry-run`:** Stop here after presenting the plan. Do not execute.

**If not dry-run:** Wait for user confirmation before proceeding to Stage 3.

If the user requests modifications, re-run Stage 2 with their feedback incorporated.

### 4. Invoke Stage 3: Rewrite

After user confirms the plan, execute it:

```bash
ace-bundle wfi://e2e/rewrite
```

Capture the execution summary with files created, modified, and deleted.

### 5. Run Tests (if --run-tests)

If `--run-tests` flag is provided, verify the rewritten tests:

```bash
ace-test-e2e {PACKAGE} {TEST_ID_1}
ace-test-e2e {PACKAGE} {TEST_ID_2}
```

Provide an explicit `--items` list from the scenarios you want to verify.

Capture test results for the final summary.

### 6. Report Final Summary

Produce a combined summary of the full pipeline run:

```markdown
## E2E Management Summary: {package}

**Executed:** {timestamp}
**Pipeline:** review → plan → rewrite {→ test}

### Pipeline Results

| Stage | Status | Key Output |
|-------|--------|------------|
| Review | Done | {n} features, {n} unit tests, {n} E2E TCs mapped |
| Plan | Done | {n} REMOVE, {n} KEEP, {n} MODIFY, {n} CONSOLIDATE, {n} ADD |
| Rewrite | Done | {n} files created, {n} modified, {n} deleted |
| Test | {Done/Skipped} | {n}/{n} passed or "not run" |

### Final State

| Metric | Before | After |
|--------|--------|-------|
| Scenarios | {n} | {n} |
| Test Cases | {n} | {n} |

### Next Steps

1. {If tests not run: run `ace-test-e2e {PACKAGE} {TEST_ID}` to verify}
2. {If tests failed: Investigate failures}
3. Commit changes with `ace-git-commit`
```

## Example Invocations

**Full lifecycle (review → plan → confirm → rewrite):**
```bash
ace-bundle wfi://e2e/manage
```

**Dry-run (review → plan → stop):**
```bash
ace-bundle wfi://e2e/manage
```

**Full lifecycle with test verification:**
```bash
ace-bundle wfi://e2e/manage
```

## Error Handling

### No Tests Found

If Stage 1 finds no E2E tests:
```
No E2E tests found for {package}.

Use `ace-bundle wfi://e2e/create` to create the first test,
or load `ace-bundle wfi://e2e/review` to see the unit test coverage.
```

### User Cancellation

If the user declines the plan at step 3:
1. Ask what they want to change
2. Re-invoke Stage 2 with their feedback
3. Present the updated plan
4. Or exit if the user wants to stop entirely

### Stage Failure

If any stage fails:
1. Report which stage failed and why
2. Show any partial output from the failed stage
3. Suggest running the failed stage individually for debugging
