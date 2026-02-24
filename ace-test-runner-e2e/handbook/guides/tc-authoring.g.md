---
guide-id: g-tc-authoring
title: Test Case Authoring Guide
description: Guide for writing TC-*.tc.md test case files for TS-format E2E scenarios
version: "1.2"
source: ace-test-runner-e2e
---

# Test Case Authoring Guide

## Overview

TC (Test Case) files are the individual test units in TS-format E2E scenarios.

ACE supports two goal-based authoring formats:
- Inline goal mode in `TC-*.tc.md` (`mode: goal`)
- Standalone goal-mode pairs (`TC-*.runner.md` + `TC-*.verify.md`)

Procedural mode remains supported as the default.

## Canonical Conventions

- Scenario IDs: `TS-<PACKAGE_SHORT>-<NNN>[-slug]`
- Standalone goal mode uses `TC-*.runner.md` and `TC-*.verify.md`
- TC artifacts write to `results/tc/{NN}/`
- Summary counters use `tcs-passed`, `tcs-failed`, and `tcs-total`

## File Naming

### Inline / Procedural TC Files

```
TC-{NNN}-{slug}.tc.md
```

- `TC-{NNN}` — Test case number (e.g., TC-001, TC-002)
- `{slug}` — Descriptive kebab-case identifier
- `.tc.md` — Required extension

Examples:
- `TC-001-valid-file-lint.tc.md`
- `TC-002-fix-mode-modifies-file.tc.md`
- `TC-003-syntax-error-handling.tc.md`

### Standalone Goal-Mode Pairs

- `TC-{NNN}-{slug}.runner.md`
- `TC-{NNN}-{slug}.verify.md`
- `runner.yml.md`
- `verifier.yml.md`

## Location

TC files are placed in the scenario directory alongside `scenario.yml`:

```
{package}/test/e2e/TS-{AREA}-{NNN}-{slug}/
├── scenario.yml
├── TC-001-{slug}.tc.md
├── TC-002-{slug}.tc.md
└── fixtures/
```

## Frontmatter

Required fields:

```yaml
---
tc-id: TC-001
title: Valid File Lint and Report Generation
mode: procedural
---
```

| Field | Type | Description |
|-------|------|-------------|
| `tc-id` | string | Test case identifier (TC-NNN format) |
| `title` | string | Descriptive title for this test case |
| `mode` | string | `procedural` (default) or `goal` |

## Inline TC Structure

### Procedural Mode (`mode: procedural`)

Procedural TCs follow the classic structure:

### 1. Objective

Clear statement of what this test case verifies (1-2 sentences).

```markdown
## Objective

Verify that linting a valid Ruby file exits 0, generates a well-structured
report.json, and produces ok.md with correct format.
```

### 2. Steps

Numbered steps with code blocks for commands.

```markdown
## Steps

1. Lint the valid file and capture output
   ```bash
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint valid.rb 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```
```

### 3. Expected

Bulleted list of expected outcomes.

```markdown
## Expected

- Exit code: 0
- report.json exists with top-level keys: `["report_metadata", "results", "summary"]`
- ok.md exists with "# Lint: Passed Files" header
```

### Inline Goal Mode (`mode: goal`)

Inline goal mode is outcome-based and self-assessed by the executing agent.

Required sections:
- `## Objective`
- `## Available Tools`
- `## Success Criteria`

Optional sections:
- `## Hints`
- `## Constraints`

Prohibited sections:
- `## Steps` (goal mode must not prescribe step-by-step procedure)

Example:

```yaml
---
tc-id: TC-003
title: Generate commit message from staged changes
mode: goal
---
```

```markdown
## Objective

Generate a meaningful commit message for staged changes.

## Available Tools

- `ace-git-commit`
- `git`
- standard shell utilities

## Success Criteria

- [ ] A commit is created in the sandbox repository
- [ ] Message reflects the nature of staged changes
- [ ] `git log --oneline -1` shows the new commit
```

## Standalone Goal-Mode Pair Structure

Use this format when you need independent verifier evaluation or multi-goal context sharing.

`TC-*.runner.md`:
- `# Goal N — Title`
- `## Goal`
- `## Workspace`
- `## Constraints`

`TC-*.verify.md`:
- `# Goal N — Title`
- `## Expectations`
- `## Verdict`

## Complete Example

```yaml
---
tc-id: TC-001
title: Valid File Lint and Report Generation
---
```

```markdown
## Objective

Verify that linting a valid Ruby file exits 0, generates a well-structured
report.json, and produces ok.md with correct format.

## Steps

1. Lint the valid file and capture output
   ```bash
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint valid.rb 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify report.json structure
   ```bash
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   REPORT_PATH="$REPORT_DIR/report.json"
   test -f "$REPORT_PATH" && echo "PASS: report.json exists" || echo "FAIL: report.json not found"
   cat "$REPORT_PATH" | jq 'keys'
   ```

4. Verify ok.md exists with correct format
   ```bash
   test -f "$REPORT_DIR/ok.md" && echo "PASS: ok.md exists" || echo "FAIL: ok.md not found"
   grep -q "^# Lint: Passed Files" "$REPORT_DIR/ok.md" && echo "PASS: Header found" || echo "FAIL: Header missing"
   ```

## Expected

- Exit code: 0
- report.json exists with top-level keys: `["report_metadata", "results", "summary"]`
- Metadata contains: `compact_id`, `generated_at`, `ace_lint_version`, `scan_options`
- Summary contains: `total_files`, `scanned`, `skipped`, `fixed`, `failed`, `passed`
- ok.md exists with "# Lint: Passed Files" header, Generated timestamp, and file list
```

## Best Practices

### Record Why This TC Is E2E

For each TC, keep a short trace back to the scenario's Value Gate evidence:
- What this TC validates that unit tests cannot
- Which unit test files were reviewed before keeping/adding this TC

This evidence is tracked at scenario level via `unit-coverage-reviewed` and `e2e-justification` in `scenario.yml`.

### Use Explicit PASS/FAIL Patterns

Every verification step should produce explicit output:

```bash
# Good: Explicit binary outcome
[ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"

# Bad: Agent can interpret anything as success
echo "Exit code: $EXIT_CODE"
```

### Discover Paths at Runtime

Don't hardcode internal paths; discover them from CLI output:

```bash
# Good: Discover from output
REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //')

# Bad: Hardcoded assumption
REPORT_DIR="$TEST_DIR/.cache/ace-lint/reports"
```

### Capture Both stdout and stderr

Use `2>&1` to capture all output:

```bash
OUTPUT=$(ace-lint file.rb 2>&1)
```

### Include Negative Assertions

Verify what should NOT exist as well as what should:

```bash
test ! -f "$CACHE_DIR/old-format.yaml" && echo "PASS: Old format not present" || echo "FAIL: Old format should not exist"
```

### Test Error Cases (When They Add E2E Value)

Include an error/negative test case when it validates behavior that unit tests cannot fully prove (real CLI parsing, real external tool failures, real filesystem state transitions). If unit tests already cover the error behavior comprehensively, do not duplicate it in E2E.

```yaml
---
tc-id: TC-001
title: Error — Missing Required File
---
```

```markdown
## Objective

Verify that the tool handles missing files with a clear error message and
correct exit code.

## Steps

1. Run with nonexistent file
   ```bash
   OUTPUT=$(ace-lint nonexistent.rb 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify error behavior
   ```bash
   [ "$EXIT_CODE" -eq 3 ] && echo "PASS: Correct exit code" || echo "FAIL: Expected 3, got $EXIT_CODE"
   echo "$OUTPUT" | grep -qi "file not found" && echo "PASS: Error message correct" || echo "FAIL: Wrong error message"
   ```

## Expected

- Exit code: 3
- Output contains: "file not found" or similar error message
```

## TC Sequencing

### Sequential vs Independent

By default, TCs within a scenario are executed in order and may share state:

- **Sequential**: TC-002 depends on state from TC-001 (e.g., a session created)
- **Independent**: Each TC can run in isolation

If TCs are independent, consider noting this in the scenario or TC files.

### Ordering Convention

- **Error TCs first**: Test error conditions before any state is created
- **Happy path**: Then test success scenarios in workflow order
- **Cleanup**: Final TC may clean up resources

Example ordering:
- TC-001: Error — Missing config
- TC-002: Error — Invalid arguments
- TC-003: Create session (happy path)
- TC-004: Query session (depends on TC-003)
- TC-005: Cleanup session

## Working with Fixtures

When `copy-fixtures` is in the scenario setup, fixture files are available at the sandbox root:

```markdown
## Steps

1. Lint the fixture file
   ```bash
   # valid.rb was copied from fixtures/ by copy-fixtures
   ace-lint valid.rb
   ```
```

## Common Patterns

### Exit Code Verification

```bash
[ "$EXIT_CODE" -eq 0 ] && echo "PASS" || echo "FAIL: Expected 0, got $EXIT_CODE"
```

### Output Contains Check

```bash
echo "$OUTPUT" | grep -q "expected text" && echo "PASS" || echo "FAIL: Text not found"
```

### File Exists Check

```bash
test -f "$FILE" && echo "PASS: File exists" || echo "FAIL: File not found"
```

### Directory Exists Check

```bash
test -d "$DIR" && echo "PASS: Directory exists" || echo "FAIL: Directory not found"
```

### JSON Key Verification

```bash
cat "$JSON_FILE" | jq -e '.results | keys' && echo "PASS" || echo "FAIL: JSON structure invalid"
```

## Related

- [E2E Testing Guide](e2e-testing.g.md) — Overview of E2E testing conventions
- [scenario.yml Reference](scenario-yml-reference.g.md) — Scenario configuration
- [TC File Template](../templates/tc-file.template.md) — Starting template
