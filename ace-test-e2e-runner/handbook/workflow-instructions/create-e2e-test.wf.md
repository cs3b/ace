---
workflow-id: wfi-create-e2e-test
name: Create E2E Test
description: Create a new E2E test scenario from template
version: "1.0"
source: ace-test-e2e-runner
---

# Create E2E Test Workflow

This workflow guides an agent through creating a new E2E test scenario.

## Arguments

- `PACKAGE` (required) - The package for the test (e.g., `ace-lint`)
- `AREA` (required) - The test area code (e.g., `LINT`, `REVIEW`, `GIT`)
- `--context <description>` (optional) - Description of what the test should verify

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
find {PACKAGE}/test/e2e -name "MT-{AREA}-*.mt.md" 2>/dev/null | \
  sed 's/.*MT-{AREA}-\([0-9]*\).*/\1/' | \
  sort -n | \
  tail -1
```

- If no existing tests: use `001`
- Otherwise: increment the highest number by 1
- Format as three digits (e.g., `001`, `002`, `015`)

Result: `MT-{AREA}-{NNN}` (e.g., `MT-LINT-003`)

### 3. Create Directory

Ensure the E2E test directory exists:

```bash
mkdir -p {PACKAGE}/test/e2e
```

### 4. Generate Test Slug

Create a kebab-case slug for the filename:

**If --context provided:**
- Extract key words from the context description
- Convert to lowercase
- Replace spaces with hyphens
- Limit to 5-6 words

**If no context:**
- Use a placeholder: `new-test-scenario`

Example: "Test config file validation" -> `config-file-validation`

### 5. Load Template

Load the test template:
```bash
ace-bundle tmpl://test-e2e
```

Or read directly:
```
ace-test-e2e-runner/handbook/templates/test-e2e.template.md
```

### 6. Populate Template

Replace template placeholders with actual values:

| Placeholder | Value |
|-------------|-------|
| `{AREA}` | Area code (uppercase) |
| `{NNN}` | Sequential number (3 digits) |
| `{package-name}` | Package name |
| `{Descriptive Title}` | Generated from context or area |
| `{area-name}` | Area code (lowercase) |

Initial values for optional fields:
- `priority: medium`
- `duration: ~10min`
- `automation-candidate: false`
- `last-verified:` (leave empty)
- `verified-by:` (leave empty)

### 7. Context-Based Generation (if --context)

If a context description was provided, enhance the test with:

**Research the package:**
1. Examine the relevant code in `{PACKAGE}/lib/`
2. Check existing tests for patterns
3. Understand the feature being tested

**Generate test content:**
1. Write a clear objective based on the context
2. Identify prerequisites for the test
3. Create appropriate test data setup
4. Generate test cases:
   - **TC-001:** Happy path (expected success)
   - **TC-002:** Error handling (expected failure)
   - **TC-003:** Edge cases (boundary conditions)
5. Define success criteria

**Example for "Test config file validation":**
```markdown
## Objective

Verify that the config file validation correctly identifies valid and invalid configuration files, providing appropriate error messages for malformed configs.

## Test Cases

### TC-001: Valid Config File
**Objective:** Verify valid configuration files are accepted

### TC-002: Invalid Config - Missing Required Field
**Objective:** Verify missing required fields produce clear errors

### TC-003: Invalid Config - Malformed YAML
**Objective:** Verify malformed YAML is handled gracefully
```

### 8. Write Test File

Write the populated template to:
```
{PACKAGE}/test/e2e/MT-{AREA}-{NNN}-{slug}.mt.md
```

Example: `ace-lint/test/e2e/MT-LINT-003-config-file-validation.mt.md`

### 9. Report Result

Output a summary:

```markdown
## E2E Test Created

**Test ID:** MT-{AREA}-{NNN}
**Package:** {package}
**File:** {PACKAGE}/test/e2e/MT-{AREA}-{NNN}-{slug}.mt.md

### Next Steps

1. Review and customize the test scenario
2. Add specific test data for your use case
3. Run the test with: `/ace:run-e2e-test {package} MT-{AREA}-{NNN}`
4. Update `last-verified` after successful execution
```

## Example Invocations

**Create a basic test:**
```
/ace:create-e2e-test ace-lint LINT
```

Creates: `ace-lint/test/e2e/MT-LINT-003-new-test-scenario.mt.md`

**Create a contextual test:**
```
/ace:create-e2e-test ace-lint LINT --context "Test config file validation"
```

Creates: `ace-lint/test/e2e/MT-LINT-003-config-file-validation.mt.md` with pre-populated test cases for config validation.

**Create test for new area:**
```
/ace:create-e2e-test ace-review COMMENT --context "Test PR comment threading"
```

Creates: `ace-review/test/e2e/MT-COMMENT-001-pr-comment-threading.mt.md`

## Error Handling

### Package Not Found

```
Error: Package '{package}' not found.

Available packages:
- ace-lint
- ace-review
- ace-test-e2e-runner
```

### Invalid Area Code

```
Error: Invalid area code '{area}'.

Area codes must be:
- 2-10 characters
- Alphanumeric only
- Will be converted to uppercase
```
