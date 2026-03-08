---
workflow-id: wfi-run-e2e-test
name: e2e/run
description: Execute an E2E test scenario with full agent guidance
version: "2.0"
source: ace-test-runner-e2e
---

# Run E2E Test Workflow

This workflow guides an agent through executing an E2E test scenario. It supports two execution modes: **standard mode** (agent manages sandbox setup and full execution) and **TC-level mode** (sandbox pre-populated by `SetupExecutor`, single TC execution).

## Arguments

- `PACKAGE` (optional) - Package containing the test (e.g., `ace-lint`). If omitted, looks for `test/e2e/` in project root.
- `TEST_ID` (optional) - Test identifier (e.g., `TS-LINT-001`). If omitted, runs all tests.
- `--run-id RUN_ID` (optional) - Pre-generated timestamp ID for deterministic report paths.
- `--report-dir PATH` (optional) - Explicit report directory path (skips computed `${TEST_DIR}-reports`).
- `--tags TAG,...` (optional) - Include only scenarios matching any of the specified tags (OR semantics).
- `--exclude-tags TAG,...` (optional) - Exclude scenarios matching any of the specified tags (OR semantics).
- `TEST_CASES` (optional) - Comma-separated TC IDs to execute (e.g., `TC-001,tc-003,002`). Normalized to `TC-NNN` format automatically.

  **TC ID normalization:** `TC-001` (unchanged), `tc-001` → `TC-001`, `001` → `TC-001`, `1` → `TC-001`, `TC-1` → `TC-001`

## Command Context

- `/as-e2e-run ...` is a chat slash command — invoke in agent chat, not bash.
- If slash commands are unavailable, stop and report that limitation in the `Issues` field.

## Canonical Conventions

- `ace-test-e2e` runs single-package scenarios; `ace-test-e2e-suite` runs suite-level execution
- Scenario IDs: `TS-<PACKAGE_SHORT>-<NNN>[-slug]`
- Standalone TC pairs: `TC-*.runner.md` + `TC-*.verify.md`
- TC artifacts: `results/tc/{NN}/`
- Summary counters: `tcs-passed`, `tcs-failed`, `tcs-total`, `failed[].tc`
- Tag filtering happens at discovery time (before sandbox setup)

## Execution Contract

- Runner instructions are execution-only: perform actions and write evidence.
- Verifier instructions are verification-only: assign verdicts using impact-first checks:
  1. sandbox/project state impact
  2. explicit artifacts
  3. debug captures as fallback
- Do not place ad-hoc setup logic in TC runner files; sandbox setup belongs to `scenario.yml` and fixtures.

## Execution Environment Guardrail

- Do **not** run `ace-test-e2e` / `ace-test-e2e-suite` autonomously in constrained or uncertain environments.
- Provide exact run commands for the user unless explicit user request and confirmed environment fidelity.

## Pipeline Context

For CLI providers (`ace-test-e2e`), the deterministic 6-phase pipeline handles execution automatically:

1. **Setup** — `SetupExecutor` creates sandbox (git init, mise.toml, .ace symlinks, `results/tc/{NN}/` dirs)
2. **Runner prompt** — `SkillPromptBuilder` assembles context from `runner.yml.md` + `TC-*.runner.md`
3. **Runner LLM** — Agent executes TC steps in sandbox, produces artifacts
4. **Verifier prompt** — `SkillPromptBuilder` assembles context from `verifier.yml.md` + `TC-*.verify.md`
5. **Verifier LLM** — Independent agent evaluates artifacts against expectations
6. **Report** — `PipelineReportGenerator` produces deterministic summary

When this workflow is invoked directly (not via CLI pipeline), the agent performs steps 1-6 manually using the workflow steps below.

---

## Subagent Mode

When invoked as a subagent (via a batch orchestrator such as `/as-assign-run-in-batches`):

- Each subagent runs in a clean context with no shared state
- Timestamp IDs ensure unique report paths (no collisions)
- All reports are written to disk, not returned inline

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

Do NOT return full report contents, detailed TC output, or setup logs.

---

## TC-Level Execution Mode

When invoked with `--tc-mode`, the sandbox is pre-populated by `SetupExecutor` and only a single TC is executed. Steps 1-5 of standard mode are skipped.

**TC-Level Arguments:**
- `PACKAGE` (required), `TEST_ID` (required), `TC_ID` (required)
- `--tc-mode` (required), `--sandbox SANDBOX_PATH` (required)
- `--run-id RUN_ID` (optional), `--env KEY=VALUE,...` (optional)

**TC-Level Steps:**
1. Verify `SANDBOX_PATH` exists
2. `cd SANDBOX_PATH`
3. Export `--env` variables if provided
4. Execute TC steps from the runner file
5. Write per-TC reports to `{RUN_ID}-{pkg}-{scenario}-{tc}-reports/`
6. Return TC-level contract

**TC-Level Rules:**
- Do NOT create or modify sandbox — `SetupExecutor` already prepared it
- Always export `--env` variables before executing test steps
- Report actual results even if they differ from expected

---

## Workflow Steps (Standard Mode)

### 1. Locate Test Scenarios

Discover scenarios based on arguments:

```bash
# No arguments — project root
find test/e2e -name "scenario.yml" -path "*/TS-*" 2>/dev/null | sort

# PACKAGE only — all tests in package
find {PACKAGE}/test/e2e -name "scenario.yml" -path "*/TS-*" 2>/dev/null | sort

# PACKAGE + TEST_ID — specific test
find {PACKAGE}/test/e2e -path "*{TEST_ID}*/scenario.yml" 2>/dev/null | head -1
```

If `--tags` or `--exclude-tags` provided, filter discovered scenarios by reading each `scenario.yml` and checking the `tags` array. Tags use OR semantics: a scenario matches `--tags` if it has **any** listed tag, and is excluded by `--exclude-tags` if it has **any** listed tag.

If no tests found after filtering, report error and exit.

### 2. Read Test Scenario

For each scenario file, read and parse:
- `test-id`, `title`, `priority`, `duration`, `requires`, `tags`

**Multiple tests:** Execute steps 2-7 for each scenario sequentially, then generate a combined summary.

### 2.5. Parse and Filter Test Cases

If `TEST_CASES` argument was provided:

1. Split comma-separated list
2. Normalize each to `TC-NNN` format (uppercase, zero-padded to 3 digits)
3. Deduplicate
4. Validate each exists as a `TC-*.runner.md` file in the scenario directory

When `TEST_CASES` is not provided, all TCs execute (default).

### 3. Verify Prerequisites

1. Check each tool in `requires.tools` is available
2. Verify `ruby --version` meets requirement
3. Ensure package is installed

Report missing prerequisites before proceeding.

### 4. Execute Environment Setup

> **CRITICAL: SANDBOX REQUIRED**
> All E2E tests MUST run in an isolated sandbox under `.ace-local/test-e2e/`.
> NEVER execute test commands in the main repository.

**Reference:** `wfi://e2e/setup-sandbox` for the authoritative sandbox setup pattern.

**Pre-generated Run ID:** If `--run-id` was provided, set `TIMESTAMP_ID=$RUN_ID` instead of generating a new one.

**Directory naming convention:**
- `{timestamp}` — 6-char base36 timestamp
- `{short-pkg}` — package without `ace-` prefix (e.g., `lint`)
- `{short-id}` — lowercase prefix + number (e.g., `ts001`)

```
.ace-local/test-e2e/
├── 8osvnh-lint-ts001/          # Sandbox
├── 8osvnh-lint-ts001-reports/  # Reports (summary.r.md, experience.r.md, metadata.yml)
└── 8osynv-final-report.md     # Suite report (sibling)
```

**Expected variables after setup:**
- `PROJECT_ROOT` — Original project directory
- `TEST_DIR` — Sandbox directory (cwd after setup)
- `REPORTS_DIR` — Reports directory
- `TIMESTAMP_ID` — Unique run identifier

### 4.1 Sandbox Isolation Checkpoint (MANDATORY)

Before proceeding, verify sandbox isolation:

```bash
echo "=== SANDBOX ISOLATION CHECK ==="
CURRENT_DIR="$(pwd)"
[[ "$CURRENT_DIR" == *".ace-local/test-e2e/"* ]] && echo "PASS: In sandbox" || echo "FAIL: NOT in sandbox"
git rev-parse --git-dir >/dev/null 2>&1 && { [ -z "$(git remote -v 2>/dev/null)" ] && echo "PASS: No remotes" || echo "FAIL: Remotes found"; } || echo "PASS: No git"
[ -f "CLAUDE.md" ] || [ -f "Gemfile" ] || [ -d ".ace-taskflow" ] && echo "FAIL: Project markers found" || echo "PASS: No markers"
echo "=== END CHECK ==="
```

- **All PASS**: Continue to step 5
- **Any FAIL**: STOP, return to `$PROJECT_ROOT`, re-run setup, re-check

### 5. Create Test Data

> **Use `ace-test-e2e-sh "$TEST_DIR"` for ALL commands after setup.**
> Each bash block runs in a fresh shell — the wrapper ensures sandbox isolation.

Execute test data creation commands from the scenario, writing files inside `$TEST_DIR/`.

### 6. Execute Test Cases

> **Use `ace-test-e2e-sh "$TEST_DIR"` for ALL TC commands.**

If `FILTERED_CASES` is set, execute only matching TCs. Otherwise execute all.

For each TC (TC-NNN):
1. **Check filter** — skip if not in `FILTERED_CASES`
2. **Read** the runner file (`TC-NNN-*.runner.md`)
3. **Execute** runner steps, save artifacts to `results/tc/{NN}/`
4. **Verify** against paired `.verify.md` expectations
5. **Record** status (Pass/Fail) with evidence

Track friction points during execution for the experience report.

### 7. Write Reports

Write three report files to the reports directory.

**Report path setup:**
```bash
REPORT_DIR="${PROVIDED_REPORT_DIR:-${TEST_DIR}-reports}"
mkdir -p "$REPORT_DIR"
```

Replace all `{placeholder}` values with actual data.

#### 7.1 summary.r.md

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

Followed by test information table, results summary table, and TC evaluation details.

#### 7.2 experience.r.md

Agent experience report with friction points, root cause analysis, improvement suggestions, and positive observations.

#### 7.3 metadata.yml

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

### 8. Cleanup (Optional)

Controlled by `cleanup.enabled` in `.ace-defaults/e2e-runner/config.yml` (default: disabled).

Sandbox directories in `.ace-local/test-e2e/` are gitignored.

### 9. Generate Summary

Summarize execution in the response. Reports are persisted to disk.

**Single test:**
```markdown
## E2E Test Execution Report
**Test ID:** {test-id} | **Package:** {package} | **Status:** {PASS/FAIL}

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-001    | ...         | Pass   |

Reports: `.ace-local/test-e2e/{timestamp}-{short-pkg}-{short-id}-reports/`
```

### 10. Update Test Scenario

If all tests pass, update `scenario.yml`:
```yaml
last-verified: {today's date}
verified-by: claude-{model}
```

## Error Handling

| Failure | Action |
|---------|--------|
| Prerequisites not met | Report which failed, provide resolution steps, stop |
| TC fails | Record details, continue remaining TCs, include in report |
| Environment setup fails | Report error, attempt cleanup, suggest troubleshooting |
| Sandbox isolation fails | STOP immediately, return to `$PROJECT_ROOT`, re-run setup |
| TC filter mismatch | STOP, do not write reports, offer re-run |

## Example Invocations

```bash
# Specific test
/as-e2e-run ace-lint TS-LINT-001

# Single TC within a test
/as-e2e-run ace-lint TS-LINT-003 TC-002

# Multiple specific TCs
/as-e2e-run ace-lint TS-LINT-001 TC-001,tc-003,002

# All tests in a package
/as-e2e-run ace-lint

# Filter by tags
/as-e2e-run ace-lint --tags smoke
/as-e2e-run ace-lint --exclude-tags deep

# All tests in project root
/as-e2e-run
```
