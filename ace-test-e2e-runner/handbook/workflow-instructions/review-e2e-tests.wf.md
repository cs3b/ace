---
workflow-id: wfi-review-e2e-tests
name: Review E2E Tests
description: Analyze E2E test health, coverage gaps, and outdated scenarios
version: "1.0"
source: ace-test-e2e-runner
---

# Review E2E Tests Workflow

This workflow guides an agent through reviewing E2E test health and coverage.

## Arguments

- `PACKAGE` (optional) - The package to review (e.g., `ace-lint`). If omitted, reviews all packages.
- `--all` - Review all packages in the repository

## Workflow Steps

### 1. Discover Tests

**Single package:**
```bash
find {PACKAGE}/test/e2e -name "*.mt.md" 2>/dev/null | sort
```

**All packages (--all or no args):**
```bash
find . -path "*/test/e2e/*.mt.md" -type f 2>/dev/null | sort
```

If no tests found and a package was specified, report that the package has no E2E tests.

### 2. Parse Test Metadata

For each test file found, read the file and extract frontmatter:

Required fields:
- `test-id` - Test identifier (e.g., MT-LINT-001)
- `title` - Test title
- `area` - Test area code
- `package` - Package name
- `priority` - high/medium/low

Optional fields:
- `last-verified` - Date of last verification (YYYY-MM-DD)
- `verified-by` - Agent/person who last verified
- `duration` - Expected duration
- `automation-candidate` - Boolean

Build a list of tests with their metadata for analysis.

### 3. Analyze Health

Evaluate each test against these health criteria:

**Outdated Tests** (last-verified > 30 days ago):
- Compare `last-verified` date to today
- Mark as outdated if older than 30 days

**Never-Verified Tests** (no last-verified date):
- Check if `last-verified` field is missing or null
- Mark as never-verified

**Structure Validation:**
Check each test file contains required sections:
- `## Objective`
- `## Prerequisites`
- `## Environment Setup`
- `## Test Cases`
- `## Success Criteria`

Report any tests with missing required sections.

### 4. Analyze Coverage Gaps

**Compare package commands vs test areas:**

For each package with E2E tests:
1. List CLI commands available:
   ```bash
   ls {PACKAGE}/lib/{package}/commands/ 2>/dev/null
   # or
   grep -r "def run" {PACKAGE}/lib/{package}/commands/ 2>/dev/null
   ```
2. List existing test areas (from test-id prefixes)
3. Identify commands without corresponding tests

**Check recent changes for untested features:**
```bash
git log --oneline --since="30 days ago" -- {PACKAGE}/lib/ {PACKAGE}/bin/
```

Look for:
- New files without corresponding tests
- Significant changes to existing functionality
- New features mentioned in commit messages

### 5. Generate Health Report

Create a comprehensive health report:

```markdown
## E2E Test Health Report

**Reviewed:** {timestamp}
**Scope:** {package or "All packages"}

### Summary

| Category | Count |
|----------|-------|
| Total Tests | {n} |
| Healthy | {n} |
| Outdated | {n} |
| Never Verified | {n} |
| Structure Issues | {n} |

### Health Status by Package

#### {package-name}

| Test ID | Title | Last Verified | Status |
|---------|-------|---------------|--------|
| MT-LINT-001 | ... | 2026-01-18 | Healthy |
| MT-LINT-002 | ... | 2025-12-01 | Outdated |
| MT-LINT-003 | ... | - | Never Verified |

### Outdated Tests (> 30 days)

{List of outdated tests with last-verified dates}

**Recommended Action:** Re-verify these tests with `/ace:run-e2e-test`

### Never-Verified Tests

{List of tests without last-verified date}

**Recommended Action:** Run initial verification with `/ace:run-e2e-test`

### Structure Issues

{List of tests with missing required sections}

**Recommended Action:** Update test files to include missing sections

### Coverage Gaps

#### {package-name}

**Commands without tests:**
- `{command}` - No E2E test coverage

**Recent changes without test coverage:**
- `{commit}` - {description}

**Recommended Action:** Create new tests with `/ace:create-e2e-test`

### Recommendations

1. {Priority recommendation based on findings}
2. {Additional recommendations}
```

## Example Invocations

**Review tests for a specific package:**
```
/ace:review-e2e-tests ace-lint
```

**Review all packages:**
```
/ace:review-e2e-tests --all
```

## Health Thresholds

- **Healthy:** last-verified within 30 days, all required sections present
- **Outdated:** last-verified > 30 days ago
- **Never Verified:** no last-verified date
- **Structure Issues:** missing required sections
