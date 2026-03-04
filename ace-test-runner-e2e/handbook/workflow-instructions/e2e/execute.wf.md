---
workflow-id: wfi-execute-e2e-test
name: e2e/execute
description: Execute test cases in a pre-populated sandbox with reporting
version: "2.0"
source: ace-test-runner-e2e
---

# Execute E2E Test Workflow

This workflow guides an agent through executing test cases in a **pre-populated sandbox**. The sandbox was created by `SetupExecutor` — this workflow handles only execution and reporting.

## SetupExecutor Contract

Before this workflow is invoked, `SetupExecutor` has already:
- Created an isolated sandbox directory under `.ace-local/test-e2e/`
- Initialized git (`git init`, user config, `.gitignore`)
- Installed `mise.toml` for tool version management
- Created `.ace` symlinks for configuration access
- Created `results/tc/{NN}/` directories for each TC
- Copied fixtures from the scenario's `fixtures/` directory
- Placed `TC-*.runner.md` and `TC-*.verify.md` files in the sandbox

Tag filtering happens at discovery time (before `SetupExecutor` runs). By the time this workflow executes, only matching scenarios are included.

## Arguments

- `PACKAGE` (required) - Package containing the test (e.g., `ace-lint`)
- `TEST_ID` (required) - Test identifier (e.g., `TS-LINT-001`)
- `--sandbox SANDBOX_PATH` (required) - Path to pre-populated sandbox directory
- `--run-id RUN_ID` (optional) - Pre-generated timestamp ID for deterministic report paths
- `--env KEY=VALUE[,...]` (optional) - Comma-separated environment variables to set before execution
- `--verify` (optional) - Enable independent verifier mode (second agent pass with sandbox inspection)
- `TEST_CASES` (optional) - Comma-separated TC IDs to execute (e.g., `TC-001,tc-003,002`)

  **TC ID normalization:** `TC-001` (unchanged), `tc-001` → `TC-001`, `001` → `TC-001`, `1` → `TC-001`, `TC-1` → `TC-001`

## Canonical Conventions

- `ace-test-e2e` runs single-package scenarios; `ace-test-e2e-suite` runs suite-level execution
- Scenario IDs: `TS-<PACKAGE_SHORT>-<NNN>[-slug]`
- Standalone TC pairs: `TC-*.runner.md` + `TC-*.verify.md`
- TC artifacts: `results/tc/{NN}/`
- Summary counters: `tcs-passed`, `tcs-failed`, `tcs-total`, `failed[].tc`

## Execution Contract

- Runner is execution-only: execute declared TC actions and capture evidence.
- Verifier is verification-only: determine PASS/FAIL using impact-first ordering:
  1. sandbox/project state impact
  2. explicit artifacts
  3. debug captures (`stdout`/`stderr`/exit) as fallback
- Do not interpret setup ownership in runner TC files; setup is owned by `scenario.yml` + fixtures.

## Dual-Agent Verifier

When `--verify` is passed (or always-on for CLI pipeline runs), execution follows a dual-agent pattern:

1. **Runner agent** executes TC steps and produces artifacts in `results/tc/{NN}/`
2. **Verifier agent** independently inspects the sandbox and artifacts against `TC-*.verify.md` expectations
3. **Report generator** (`PipelineReportGenerator`) produces deterministic summary from verifier output

The verifier has no access to the runner's conversation — it evaluates purely from on-disk evidence. This prevents self-confirmation bias.

## Subagent Mode

When invoked as a subagent (via Task tool from orchestrator):

**Return contract:**
```markdown
- **Test ID**: {test-id}
- **Status**: pass | fail | partial
- **Passed**: {count}
- **Failed**: {count}
- **Total**: {count}
- **Report Paths**: {timestamp}-{short-pkg}-{short-id}.*
- **Issues**: Brief description or "None"
```

Do NOT return full report contents — they are on disk.

## TC-Level Execution Mode

When invoked with `--tc-mode`, only a single TC is executed.

**TC-Level Arguments:**
- `PACKAGE` (required), `TEST_ID` (required), `TC_ID` (required)
- `--tc-mode` (required), `--sandbox SANDBOX_PATH` (required)
- `--run-id RUN_ID` (optional)

**TC-Level Steps:**
1. Verify `SANDBOX_PATH` exists
2. `cd SANDBOX_PATH`
3. Execute TC steps from the runner file
4. Write per-TC reports to `{RUN_ID}-{pkg}-{scenario}-{tc}-reports/`
5. Return TC-level contract

**TC-Level Rules:**
- Do NOT create or modify sandbox — `SetupExecutor` already prepared it
- Execute only the steps described in the TC content
- Report actual results even if they differ from expected

---

## Sandbox Rules

- Do NOT create or modify sandbox setup — it is already prepared
- Do NOT run environment setup, prerequisite checks, or test data creation
- Focus exclusively on TC execution and reporting

## Workflow Steps

### 1. Set Up Execution Environment

1. Parse `--env` and export each `KEY=VALUE`
2. `cd SANDBOX_PATH`
3. Set `TIMESTAMP_ID` from `--run-id` or generate with `ace-b36ts encode`

**Expected variables:**
- `SANDBOX_PATH` — Pre-populated sandbox (cwd)
- `TIMESTAMP_ID` — Unique run identifier
- Any variables from `--env`

### 2. Discover and Filter Test Cases

Find TC definitions in the sandbox:

```bash
find "${SANDBOX_PATH}" -name "TC-*.runner.md" -o -name "TC-*.verify.md" 2>/dev/null | sort
```

List all found TCs before proceeding:
```
Found N test case files:
- TC-001: {filename}
- TC-002: {filename}
```

> **TC FIDELITY RULE:** Execute ONLY discovered `TC-*.runner.md` + `TC-*.verify.md` pairs. Do NOT invent TCs. Every runner must have a matching verifier and vice versa. Missing pairs are errors — report them and skip the unmatched TC.

If `TEST_CASES` argument provided, normalize IDs to `TC-NNN` format and filter. Only execute matching TCs.

### 3. Execute Test Cases

> **Use `ace-test-e2e-sh "$SANDBOX_PATH"` for ALL commands.**

For each TC (TC-NNN):

1. **Check filter** — skip if `FILTERED_CASES` is set and TC not in list
2. **Read** the runner file objective
3. **Execute** runner steps, save artifacts to `results/tc/{NN}/`
4. **Capture** exit codes, output, error messages
5. **Evaluate** against verifier expectations
6. **Record** Pass/Fail with per-TC evidence

**Self-check:** Before writing reports, verify your result table has exactly N rows matching discovered TCs (or filtered subset).

Track friction points for the experience report.

### 4. Write Reports

Write three report files to `${SANDBOX_PATH}-reports/`.

```bash
REPORT_DIR="${SANDBOX_PATH}-reports"
mkdir -p "$REPORT_DIR"
```

Replace all `{placeholder}` values with actual data.

#### 4.1 summary.r.md

```yaml
---
test-id: {test-id}
package: {package}
agent: {agent-name}
executed: {timestamp}
status: pass|fail|partial|incomplete
tcs-passed: {count}
tcs-failed: {count}
tcs-total: {count}
score: "{passed}/{total}"
verdict: pass|fail|partial|incomplete
filtered: true|false
failed:
  - tc: TC-NNN
    category: tool-bug|runner-error|test-spec-error|infrastructure-error
    evidence: "brief evidence"
---
```

Followed by test information table, results summary, and TC evaluation details.

#### 4.2 experience.r.md

Agent experience report with friction points, root cause analysis, improvement suggestions, and positive observations.

#### 4.3 metadata.yml

```yaml
run-id: "{TIMESTAMP_ID}"
test-id: "{test-id}"
package: "{package}"
status: "{status}"
score: {0.0-1.0}
verdict: pass|partial|fail
tcs-passed: {count}
tcs-failed: {count}
tcs-total: {count}
failed:
  - tc: TC-NNN
    category: tool-bug|runner-error|test-spec-error|infrastructure-error
    evidence: "brief evidence"
test_cases:
  filtered: true|false
  executed: [TC-001, TC-003]
git:
  branch: "{branch}"
  commit: "{short-sha}"
```

#### 4.4 Report file paths

```
Reports written:
- ${REPORT_DIR}/summary.r.md
- ${REPORT_DIR}/experience.r.md
- ${REPORT_DIR}/metadata.yml
```

### 5. Return Summary

```markdown
## E2E Test Execution Report
**Test ID:** {test-id} | **Package:** {package} | **Status:** {PASS/FAIL}

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-001    | ...         | Pass   |

Reports: `.ace-local/test-e2e/{timestamp}-{short-pkg}-{short-id}-reports/`
```

## Error Handling

| Failure | Action |
|---------|--------|
| TC fails | Record details, continue remaining TCs, include in report |
| Sandbox missing/corrupted | Report error, do NOT recreate, return error summary |
| TC filter mismatch | STOP, do not write reports, offer re-run |
| Missing TC pair file | Report error for that TC, skip it, continue others |
