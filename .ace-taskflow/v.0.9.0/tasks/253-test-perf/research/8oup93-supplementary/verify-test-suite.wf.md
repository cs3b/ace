---
name: verify-test-suite
description: Profile and verify test suite performance and quality
allowed-tools: Bash, Read, Edit
doc-type: workflow
purpose: Maintenance workflow for keeping test suites fast and reliable
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Verify Test Suite Workflow

## Goal

Ensure the test suite remains performant (Fast Loop < 10s) and reliable (Slow Loop covers reality). Identify slow tests and "mocking leaks".

## Prerequisites

- Project must be an `ace-*` gem or compatible Ruby project.
- `ace-test` command available.

## Process Steps

### 1. Fast Loop Profiling

Run the test suite with the top 10 slowest tests profiled.

```bash
ace-test --profile 10
```

**Analysis:**
- **Unit Tests (Atoms)**: Should be < 10ms. If > 10ms, investigate.
- **Integration Tests (Molecules)**: Should be < 100ms. If > 100ms, investigate.
- **E2E Tests**: Ignored for this step (they are expected to be slow).

### 2. Slow Test Investigation

For each test identified as "Slow" in the Fast Loop:

1.  **Check for Subprocesses**: Does it call `system`, `Open3`, or backticks?
    -   *Action*: Stub the boundary (e.g., `Runner.stub(:available?, true)`).
2.  **Check for Real I/O**: Does it read/write real files?
    -   *Action*: Use `FakeFS` or mock `File` class.
3.  **Check for Network**: Does it make HTTP calls?
    -   *Action*: Stub with `webmock` or `Faraday` stubs.

### 3. "Zombie Mock" Hunting

**Definition**: A test that mocks a method no longer used, while the real code path runs (often slowly).

1.  **Identify Suspects**: Any unit test > 10ms that claims to be "fully mocked".
2.  **Break the Mock**: Change the mock expectation (e.g., raise an error or return garbage).
3.  **Verify**:
    -   If the test **fails**, the mock is working.
    -   If the test **passes** (but is slow), it's a **Zombie Mock**. It's running the real code!
4.  **Remediation**: Update the mock to match the *actual* code path being executed.

### 4. "Testing the Mock" Audit

Pick 3 random unit tests and verify:
1.  Are we testing the *logic* of the subject?
2.  Or are we just verifying that `mock.expect` was called?
3.  *Action*: If testing the mock, rewrite to test the *return value* or *state change* of the subject.

### 4. E2E Coverage Check

1.  List recent features (check `CHANGELOG.md`).
2.  Are there E2E scenarios for these features?
3.  *Action*: If missing, create a task to add E2E tests using `ace-create-test-cases`.

## Remediation

If you find issues, run the following to fix them:
1.  **Unit Test Optimization**: Refactor tests to mock/stub I/O.
2.  **Move to E2E**: If a test *must* do real I/O, move it to `test/e2e/`.

## Success Criteria

- [ ] Top 10 slowest unit/integration tests are all < 100ms.
- [ ] No unit tests make real subprocess calls.
- [ ] Recent features have at least one happy-path E2E test.
