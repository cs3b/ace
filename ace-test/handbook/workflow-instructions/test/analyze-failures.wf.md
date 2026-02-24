---
name: test/analyze-failures
description: Analyze failing automated tests and classify root cause before fixing
allowed-tools: Read, Bash, Grep, Glob
argument-hint: '[optional test-file-pattern]'
doc-type: workflow
purpose: analyze-test-failures workflow instruction
update:
  frequency: on-change
  last-updated: '2026-02-24'
---

# Analyze Test Failures Workflow

## Goal

Analyze failing automated tests and classify each failure before any fix is applied.

This workflow produces a decision report that answers:
- Is this failure caused by implementation code?
- Is this failure caused by test code/spec?
- Is this failure caused by test infrastructure/environment?

## Hard Rule

- Do not edit application code or test files in this workflow.
- Do not run formatting/autofix commands in this workflow.
- This workflow ends with an analysis report only.

## Prerequisites

- Failing tests have already been executed
- Failure output is available (logs, stack traces, failing test list)
- Project context can be loaded

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`
- Check recent changes: `git log --oneline -10`

## Classification Categories

Use exactly one category per failing test:

1. `implementation-bug`
- Product/runtime behavior is wrong
- Test expectation is valid

2. `test-defect`
- Test assertion/setup/fixture is stale or incorrect
- Product behavior appears correct for current requirements

3. `test-infrastructure`
- Environment/tooling/framework/configuration/isolation issue
- Failure is not specific to business behavior

## Analysis Procedure

1. Collect failing tests
- Identify failing file/test IDs from latest run output
- Capture exact error signatures

2. Gather evidence per failure
- Primary stacktrace line
- Related test file and assertion context
- Related implementation file/entrypoint context
- Environment/tooling context (timeouts, missing deps, DB state, network/mocks)

3. Classify each failure
- Assign one category (`implementation-bug`, `test-defect`, `test-infrastructure`)
- Add confidence: `high`, `medium`, or `low`
- Record one disconfirming check (what could prove this classification wrong)

4. Determine fix target
- `implementation code`
- `test code`
- `test infrastructure`

## Required Output Contract

Produce this section before exiting:

```markdown
## Failure Analysis Report

| Failure | Category | Evidence | Fix Target | Confidence | Disconfirming Check |
|---|---|---|---|---|---|
| path/to/test_file.rb:TestName | implementation-bug | stacktrace + behavior mismatch summary | implementation code | high | run related tests after patch |
```

Then include:

```markdown
### Execution Plan Input
- Primary failure to fix first: ...
- Why first: ...
- Required verification commands: ...
```

## Success Criteria

- Every failing test is classified
- Evidence is concrete and traceable
- Fix target is explicit per failure
- A prioritized first failure is selected
- No code/test edits were made in this workflow
