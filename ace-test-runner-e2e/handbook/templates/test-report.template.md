---
doc-type: template
title: "E2E Test Report: {test-id}"
purpose: Documentation for ace-test-runner-e2e/handbook/templates/test-report.template.md
ace-docs:
  last-updated: 2026-02-24
  last-checked: 2026-03-21
---

# E2E Test Report: {test-id}

## Test Information

| Field | Value |
|-------|-------|
| Test ID | {test-id} |
| Title | {test-title} |
| Package | {package} |
| Agent | {agent-name} |
| Executed | {timestamp} |
| Duration | {duration} | <!-- Format: "1m 23s" or "45s" -->

## Results Summary

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-001 | {description} | Pass/Fail |
| TC-002 | {description} | Pass/Fail |
| TC-003 | {description} | Pass/Fail |

## Overall Status: {PASS/FAIL/PARTIAL}

**Passed:** {count} | **Failed:** {count} | **Total:** {count}

## Failed Test Details

```yaml
failed:
  - tc: TC-{NNN}
    category: tool-bug|runner-error|test-spec-error|infrastructure-error
    evidence: "{Brief description of failure and supporting artifacts}"
```

### TC-{NNN}: {Test Case Name}

**Objective:** {What this test case was verifying}

**Expected:**
- {Expected result 1}
- {Expected result 2}

**Actual:**
- {Actual result 1}
- {Actual result 2}

**Error Output:**
```
{Captured error output if any}
```

**Analysis:** {Brief analysis of why the test failed}

## Test Environment

{Record environment details relevant to test execution.}

| Component | Version/Value |
|-----------|---------------|
| Ruby | {version} |
| Tool 1 | {version} |
| Tool 2 | {version} |

## Observations

{Any observations, edge cases, or issues discovered during test execution that aren't failures but worth noting.}

- {Observation 1}
- {Observation 2}

## Artifacts

{List any artifacts created during test execution.}

| Artifact | Path | Description |
|----------|------|-------------|
| Test data | `artifacts/` | Test input files |
| Logs | `artifacts/output.log` | Command output logs |

## Next Steps

{Recommendations based on test results.}

- [ ] {Action item if tests failed}
- [ ] {Follow-up investigation if needed}