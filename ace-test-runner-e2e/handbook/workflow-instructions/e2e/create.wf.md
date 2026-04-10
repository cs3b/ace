---
name: e2e-create
description: Create a new E2E test scenario from template
allowed-tools:
- Bash(ace-bundle:*)
- Read
- Write
- Glob
- Grep
doc-type: workflow
title: Create E2E Test Workflow
purpose: Create a new E2E test scenario from template
ace-docs:
  last-updated: 2026-03-12
  last-checked: 2026-03-21
---

# Create E2E Test Workflow

This workflow guides an agent through creating a new E2E test scenario.

## Arguments

- `PACKAGE` (required) - The package for the test (e.g., `ace-lint`)
- `AREA` (required) - The test area code (e.g., `LINT`, `REVIEW`, `GIT`)
- `--format ts` (optional, default) - Test format. Creates a directory with `scenario.yml`, `runner.yml.md`, `verifier.yml.md`, and TC runner/verifier pairs (TS-format). This is the only supported format.
- `--context <description>` (optional) - Description of what the test should verify

## Canonical Conventions

- Scenario ID format: `TS-<PACKAGE_SHORT>-<NNN>[-slug]`
- Standalone files: `TC-*.runner.md` and `TC-*.verify.md`
- TC artifact layout: `results/tc/{NN}/`
- Summary counters: `tcs-passed`, `tcs-failed`, `tcs-total`, `failed[].tc`
- CLI split reminder:

  - `ace-test-e2e` for single-package execution
  - `ace-test-e2e-suite` for suite-level execution

## Authoring Contract

- Runner files (`runner.yml.md`, `TC-*.runner.md`) are execution-only.
- Verifier files (`verifier.yml.md`, `TC-*.verify.md`) are verdict-only with impact-first evidence order:

  1. sandbox/project state impact
  2. explicit artifacts
  3. debug captures as fallback

- Setup belongs to `scenario.yml` `setup:` and fixtures; do not duplicate setup in runner TC instructions.

## Workflow Steps

### 1. Validate Inputs

**Check package exists:**

```bash
test -d "{PACKAGE}" && echo "Package exists" || echo "Package not found"
```

If package doesn't exist, list available packages:

```bash
ls -d */ | grep -E "^ace-" | sed 's/\/$//'
```

**Normalize area code:**

- Convert to uppercase (e.g., `lint` -> `LINT`)
- Verify it's a valid area name (2-10 alphanumeric characters)

### 2. Generate Test ID

Find the next available test ID:

```bash
# Search TS-format directories
find {PACKAGE}/test-e2e/scenarios -maxdepth 1 -type d -name "TS-{AREA}-*" 2>/dev/null | \
  sed 's/.*TS-{AREA}-\([0-9]*\).*/\1/'
```

Sort and take the highest number:

- If no existing tests: use `001`
- Otherwise: increment the highest number by 1
- Format as three digits (e.g., `001`, `002`, `015`)

Result: `TS-{AREA}-{NNN}` (e.g., `TS-LINT-003`)

### 3. Create Directory

Ensure the E2E test directory exists:

```bash
mkdir -p {PACKAGE}/test-e2e/scenarios
```

### 4. Generate Test Slug

Create a kebab-case slug:

**If --context provided:**

- Extract key words from the context description
- Convert to lowercase
- Replace spaces with hyphens
- Limit to 5-6 words

**If no context:**

- Use a placeholder: `new-test-scenario`

Example: "Test config file validation" -> `config-file-validation`

The slug is the directory name suffix: `TS-LINT-003-config-file-validation/`

### 5. Load Template

Load the test template:

```bash
ace-bundle tmpl://test-e2e
```

Or read directly:

```
ace-test-runner-e2e/handbook/templates/test-e2e.template.md
```

### 6. Populate Template

Replace template placeholders with actual values:

| Placeholder | Value |
|-------------|-------|
| `{AREA}` | Area code (uppercase) |
| `{NNN}` | Sequential number (3 digits) |
| `{short-pkg}` | Package name without `ace-` prefix (e.g., `git-commit`) |
| `{short-id}` | Lowercase test number (e.g., `ts001`) |
| `{Descriptive Title}` | Generated from context or area |
| `{area-name}` | Area code (lowercase) |

Initial values for optional fields:

- `priority: medium`
- `duration: ~10min`
- `automation-candidate: false`
- `cost-tier: smoke`
- `tags: [{cost-tier}, "use-case:{area}"]`
- `e2e-justification:` (brief statement of why this cannot be unit-only)
- `unit-coverage-reviewed:` (list of unit test files checked during Value Gate)
- `last-verified:` (leave empty)
- `verified-by:` (leave empty)

### 7. E2E Value Gate Check

Before generating test cases, verify the proposed test has genuine E2E value.

**Check unit test coverage:**

```bash
# Search for existing unit tests covering this area
find {PACKAGE}/test/atoms {PACKAGE}/test/molecules {PACKAGE}/test/organisms \
  -name "*_test.rb" 2>/dev/null | head -20
```

Read the relevant test files and count assertions covering the behavior described in `--context`.

**Apply the gate per TC:**
For each proposed TC, answer: **"Does this require the full CLI binary + real external tools + real filesystem I/O?"**

- If **YES**: proceed to TC generation
- If **NO**: note that unit tests cover this behavior and skip the TC
- If **PARTIAL**: create the TC but scope it to only the E2E-exclusive aspects

**Example decisions:**

- "Test that invalid YAML config produces error" -- check if `atoms/config_parser_test.rb` already asserts this. If so, **skip** (unit test covers it). If unit test checks parsing but not the full CLI exit code path, **create** a TC scoped to just the exit code.
- "Test that StandardRB subprocess executes and returns results" -- unit tests stub the subprocess. **Create** this as E2E because it requires the real tool.

If all proposed TCs fail the gate, report to the user:

```
All proposed behaviors are already covered by unit tests in {PACKAGE}/test/.
No E2E test needed. Consider adding unit tests instead if coverage gaps exist.
```

### 7a. Evidence-Gate Review Before Writing Files

Before finalizing the test plan, block weak coverage patterns:

- **Existence-only TC**:

  - only checks directory/file existence
  - no command output/content assertion
  - missing `*.exit` capture for the executed command

- **Duplicate-invocation TC**:

  - same command invocation, same purpose, split across multiple TCs

| TC ID | Decision (KEEP/ADD/SKIP) | Evidence Strength | E2E-only reason | Unit tests reviewed |
|-------|---------------------------|------------------|-----------------|--------------------|
| {tc-id} | {decision} | `command-output` | {why this needs real CLI/tools/fs} | {path1,path2} |

Rules:

- `existence-only` is never valid for KEEP/ADD. Use it only for SKIP rows with explicit unit-test replacement.
- `SKIP` rows must include replacement unit-test evidence.
- Non-skipped rows must include command-level artifacts (`stdout`, `stderr`, `exit`, and/or explicit proof files).
- At least one `unit tests reviewed` path is required for every row.
- The scenario-level `unit-coverage-reviewed` field must include the union of all referenced unit test files.

### 7b. E2E Decision Record (Required)

Before writing files, produce a decision record table for every candidate TC:

| TC ID | Decision (KEEP/ADD/SKIP) | E2E-only reason | Unit tests reviewed |
|-------|---------------------------|-----------------|---------------------|
| {tc-id} | {decision} | {why this needs real CLI/tools/fs} | {path1,path2} |

Rules:

- No TC may be created without a row in this table.
- If decision is `SKIP`, include the unit-test evidence that replaces it.
- At least one `unit tests reviewed` path is required for each row.
- The scenario-level `unit-coverage-reviewed` field must include the union of all referenced unit test files.

### 8. Context-Based Generation (if --context)

If a context description was provided, enhance the test with:

**Research the package:**
1. **Run unit tests first** (`ace-test` in the package) -- they are the ground truth for implemented behavior
2. Examine the relevant code in `{PACKAGE}/lib/`
3. Check existing unit tests for expected behavior patterns
4. Understand the feature being tested
5. **Run the tool** to observe actual behavior, output format, file paths, and exit codes
6. **Verify config/input formats** by reading the actual parsing code -- never assume formats from design specs or task descriptions

**Generate test content:**
1. Write a clear objective based on the context
2. Identify prerequisites for the test
3. Create appropriate test data setup
4. Generate test cases following the rules below
5. Define success criteria

#### Test Case Generation Rules

**MUST (required for all E2E tests):**

- **Verify the feature is implemented** before writing the test -- read the actual implementation code, not just task specs or design documents
- **Verify config/input formats** by reading the parsing code -- never assume formats from BDD specs, task descriptions, or documentation
- Include an error/negative TC only when it validates E2E-exclusive behavior (real CLI parser/runtime/tooling/filesystem) or when unit coverage has a documented gap
- Verify actual file paths by running the tool first -- never hardcode paths from documentation or assumptions
- Use explicit `&& echo "PASS" || echo "FAIL"` patterns for every verification step
- Check specific exit codes for error commands (not just "non-zero")
- Add at least one output-content assertion for each command being verified

**SHOULD (strongly recommended):**

- Test the real user journey -- structure TCs as a sequential workflow, not isolated commands
- Verify exit codes for all commands, not just error cases
- Include negative assertions (files/directories that should NOT exist)
- Capture and retain command output for all assertions (`stdout`, `stderr`, and `*.exit`)
- Capture and check CLI output content, not just exit codes
- Verify that status values match actual implementation (e.g., `done` vs `completed`)

**COST-AWARE (reduce LLM invocations):**

- Consolidate assertions that share the same CLI invocation into a single TC. For example, after running `ace-lint file.rb`, check exit code, report.json structure, and ok.md existence in ONE TC -- not three.
- Target 2-5 TCs per scenario. More than 5 suggests the scenario is too broad; split into focused scenarios. Fewer than 2 suggests merging with a related scenario.
- Never create a TC for a single assertion when that assertion could be appended to an existing TC that runs the same command.

#### Recommended TC Ordering

1. **Error paths first** -- wrong args, missing files, no prior state (run from clean state)
2. **Happy path start** -- create/init with correct args, verify output
3. **Structure verification** -- check actual on-disk file structure with negative assertions
4. **Lifecycle operations** -- status, advance, fail, retry in workflow order
5. **End state** -- verify completion message, all steps terminal

This ordering ensures error TCs run before any state is created (clean environment), and happy-path TCs build on each other sequentially.

See: **e2e-testing.g.md § "Avoiding False Positive Tests"** for the full list of anti-patterns and the reviewer checklist.

#### CLI-Based Testing Requirement

**E2E tests MUST test through the CLI interface, not library imports.**

**Valid approach:**

```bash
OUTPUT=$(ace-review --preset code --subject "diff:HEAD~1" --auto-execute 2>&1)
EXIT_CODE=$?
[ "$EXIT_CODE" -eq 0 ] && echo "PASS" || echo "FAIL"
```

**Invalid approach (this is integration/unit testing, not E2E):**

```bash
bundle exec ruby -e '
  require_relative "lib/ace/review"
  result = Ace::Review::SomeClass.method(args)
'
```

**For execution tests (LLM, API calls):**

- Use `--auto-execute` to make real API calls
- Using only `--dry-run` cannot verify actual execution behavior
- Keep costs minimal: cheap models, tiny prompts, small diffs

#### Common Anti-Patterns to Avoid

**Writing tests from design specs before implementation:**

- Task descriptions and BDD specs often describe *intended* behavior with *proposed* config formats
- The actual implementation may use different formats, different commands, or different workflows
- Example: A spec might describe `jobs:` with explicit `number:` and `parent:` fields, but implementation uses `steps:` with auto-generated numbers and dynamic hierarchy via `add --after --child`
- **Fix:** Always read the actual implementation code (especially config parsing) before writing test data

**Assuming static vs dynamic behavior:**

- Tests may assume features work at config-time (static) when they actually work at runtime (dynamic)
- Example: Assuming hierarchy is defined in config when it's actually built dynamically via commands
- **Fix:** Trace the actual code path for the feature being tested

**Splitting one command into many redundant TCs:**

- Multiple TCs each validate one assertion after the same CLI invocation, creating overlap with unit tests and increasing run cost
- Example: TC-A checks exit code, TC-B checks report file, TC-C checks summary text for the same command run
- **Fix:** Consolidate those assertions into one TC and move formatter/parser details to unit tests

**Example for "Test config file validation":**

```markdown
## Test Cases

### TC-001: Error — Missing Config File
**Objective:** Verify that a nonexistent config file produces exit code 3 and a clear error

### TC-002: Error — Malformed YAML Config
**Objective:** Verify malformed YAML is handled gracefully with actionable error message

### TC-003: Valid Config File
**Objective:** Verify valid configuration files are accepted

### TC-004: Verify On-Disk Structure
**Objective:** Check actual file paths created, with negative assertions for wrong paths
```

### 9. Write Test Files

Create the scenario directory with separate files:

```bash
mkdir -p {PACKAGE}/test-e2e/scenarios/TS-{AREA}-{NNN}-{slug}
```

Write `scenario.yml` (metadata and setup):

```
{PACKAGE}/test-e2e/scenarios/TS-{AREA}-{NNN}-{slug}/scenario.yml
```

Write scenario pair configs:

```
{PACKAGE}/test-e2e/scenarios/TS-{AREA}-{NNN}-{slug}/runner.yml.md
{PACKAGE}/test-e2e/scenarios/TS-{AREA}-{NNN}-{slug}/verifier.yml.md
```

Write individual TC runner/verifier files for each test case:

```
{PACKAGE}/test-e2e/scenarios/TS-{AREA}-{NNN}-{slug}/TC-001-{tc-slug}.runner.md
{PACKAGE}/test-e2e/scenarios/TS-{AREA}-{NNN}-{slug}/TC-001-{tc-slug}.verify.md
```

Optionally create a fixtures directory if test data is needed:

```bash
mkdir -p {PACKAGE}/test-e2e/scenarios/TS-{AREA}-{NNN}-{slug}/fixtures
```

Example: `ace-lint/test-e2e/scenarios/TS-LINT-003-config-file-validation/scenario.yml`

### 10. Report Result

Output a summary:

```markdown
## E2E Test Created

**Test ID:** TS-{AREA}-{NNN}
**Format:** TS (directory-based)
**Package:** {package}
**Directory:** {PACKAGE}/test-e2e/scenarios/TS-{AREA}-{NNN}-{slug}/
**Files:**
- scenario.yml
- runner.yml.md
- verifier.yml.md
- TC-001-{tc-slug}.runner.md
- TC-001-{tc-slug}.verify.md

### Next Steps

1. Review and customize `scenario.yml` and TC files
2. Add fixtures to the `fixtures/` directory if needed
3. Review the E2E Decision Record and ensure `unit-coverage-reviewed` is populated
4. Run the test with `ace-test-e2e {package} TS-{AREA}-{NNN}`
5. Update `last-verified` after successful execution
```

## Example Invocations

**Create a test:**

```bash
ace-bundle wfi://e2e/create
```

Creates: `ace-lint/test-e2e/scenarios/TS-LINT-003-new-test-scenario/` with `scenario.yml` and TC files.

**Create a contextual test:**

```bash
ace-bundle wfi://e2e/create
```

Creates: `ace-lint/test-e2e/scenarios/TS-LINT-003-config-file-validation/` with `scenario.yml` and TC files for config validation.

**Create test for new area:**

```bash
ace-bundle wfi://e2e/create
```

Creates: `ace-review/test-e2e/scenarios/TS-COMMENT-001-pr-comment-threading/` with `scenario.yml` and TC files.

## Error Handling

### Package Not Found

```
Error: Package '{package}' not found.

Available packages:
- ace-lint
- ace-review
- ace-test-runner-e2e
```

### Invalid Area Code

```
Error: Invalid area code '{area}'.

Area codes must be:
- 2-10 characters
- Alphanumeric only
- Will be converted to uppercase
```
