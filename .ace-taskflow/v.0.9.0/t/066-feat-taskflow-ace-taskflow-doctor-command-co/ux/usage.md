# ace-taskflow doctor - Usage Guide

## Overview

The `ace-taskflow doctor` command provides comprehensive health checks for your entire taskflow ecosystem, detecting and fixing common issues like missing frontmatter delimiters, malformed YAML, and structural problems.

## Quick Start

```bash
# Run a full system health check
ace-taskflow doctor

# Auto-fix common issues
ace-taskflow doctor --fix

# Check specific component
ace-taskflow doctor --component tasks

# Check specific release
ace-taskflow doctor --release v.0.9.0
```

## Command Structure

```bash
ace-taskflow doctor [OPTIONS]
```

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--component TYPE` | Check specific component (tasks, ideas, releases) | `--component ideas` |
| `--release VERSION` | Check specific release | `--release v.0.9.0` |
| `--fix` | Auto-fix safe issues | `--fix` |
| `--fix --dry-run` | Preview fixes without applying | `--fix --dry-run` |
| `--format FORMAT` | Output format (json, summary) | `--format json` |
| `--verbose` | Show detailed diagnostics | `--verbose` |
| `--errors-only` | Show only critical issues | `--errors-only` |
| `--quiet` | Exit code only (for scripts) | `--quiet` |
| `--check TYPE` | Specific validation (frontmatter, dependencies, structure) | `--check frontmatter` |

## Usage Scenarios

### Scenario 1: Daily Health Check

**Goal**: Regular validation of taskflow integrity

```bash
$ ace-taskflow doctor

🏥 Taskflow Health Check
========================

📊 System Overview
-----------------
  Releases:  3 active | 2 backlog | 5 done
  Tasks:     48 total (45 done, 2 pending, 1 draft)
  Ideas:     42 total (29 pending, 13 done)
  Retros:    47 entries

🔍 Checking Components...
✓ All components healthy

📈 Health Score: 100/100 (Excellent)
==============================
```

### Scenario 2: Fix Malformed Frontmatter

**Goal**: Automatically fix files with missing closing delimiters

```bash
$ ace-taskflow doctor --fix

🏥 Taskflow Health Check
========================

❌ Critical Issues (2)
----------------------
1. task.018.md: Missing closing '---' delimiter
2. idea-20251010.md: Missing closing '---' delimiter

🔧 Applying Auto-Fixes...
✓ Fixed: task.018.md - Added closing delimiter
✓ Fixed: idea-20251010.md - Added closing delimiter

📈 Health Score: 100/100 (Excellent)
==============================
2 issues fixed automatically
```

### Scenario 3: CI/CD Integration

**Goal**: Validate taskflow in continuous integration

```bash
$ ace-taskflow doctor --format json --errors-only

{
  "health_score": 92,
  "errors": [
    {
      "severity": "critical",
      "component": "task",
      "file": ".ace-taskflow/v.0.9.0/t/025-task/task.025.md",
      "issue": "Invalid YAML syntax",
      "message": "found unexpected ':' at line 3"
    }
  ],
  "warnings": [],
  "summary": {
    "total_files": 150,
    "files_with_errors": 1,
    "auto_fixable": 0
  }
}

$ echo $?
1  # Exit code indicates issues found
```

### Scenario 4: Pre-Commit Validation

**Goal**: Check for issues before committing

```bash
$ ace-taskflow doctor --component tasks --errors-only

✓ All tasks healthy
No critical issues found in 48 task files

$ git commit -m "feat: Add new task"
# Proceeds with commit
```

### Scenario 5: Debug Specific Component

**Goal**: Detailed analysis of idea files

```bash
$ ace-taskflow doctor --component ideas --verbose

🔍 Checking Ideas...
--------------------
✓ .ace-taskflow/v.0.9.0/ideas/20251001-feature.md
  - Has frontmatter: No (OK for ideas)
  - Timestamp valid: Yes
  - Location correct: Yes

⚠ .ace-taskflow/v.0.9.0/ideas/20251010-broken.md
  - File truncated at byte 245
  - Expected minimum 500 bytes
  - Suggestion: Check file integrity

✓ .ace-taskflow/v.0.9.0/ideas/done/20250930-completed.md
  - Status matches location: Yes
  - File complete: Yes

Summary: 41/42 ideas healthy, 1 warning
```

### Scenario 6: Preview Auto-Fix Changes

**Goal**: See what would be fixed without applying changes

```bash
$ ace-taskflow doctor --fix --dry-run

🏥 Taskflow Health Check (DRY RUN)
===================================

Would fix:
1. task.018.md - Add closing '---' delimiter
2. task.045.md - Add default estimate: "TBD"
3. v.0.8.0/ - Move to done/ directory

3 fixes available (not applied in dry-run mode)
Run without --dry-run to apply fixes
```

## Common Issues and Solutions

### Missing Closing Delimiter

**Issue**: Frontmatter missing closing `---`
```yaml
---
id: v.0.9.0+task.018
status: pending

# Task content starts here
```

**Solution**: Run `ace-taskflow doctor --fix` to add delimiter automatically

### Invalid YAML Syntax

**Issue**: Malformed YAML in frontmatter
```yaml
---
id: v.0.9.0+task.025
status: pending
dependencies: [task.001 task.002]  # Missing comma
---
```

**Solution**: Manual fix required - edit file to correct YAML syntax

### Mislocated Files

**Issue**: Done task in active directory
**Solution**: Run `ace-taskflow doctor --fix` to move automatically

## Exit Codes

- `0`: System healthy (no errors)
- `1`: Issues detected
- `2`: Doctor command failed

## Best Practices

1. **Regular Checks**: Run doctor daily or in CI/CD
2. **Fix Early**: Address issues promptly to prevent accumulation
3. **Dry Run First**: Use `--dry-run` before applying fixes
4. **Component Focus**: Check specific components when debugging
5. **Automation**: Include in git hooks and CI pipelines

## Troubleshooting

**Q: Doctor hangs on large repository**
A: Use `--component` to check specific parts individually

**Q: Auto-fix doesn't fix my issue**
A: Some issues require manual intervention. Check the specific error message for guidance.

**Q: JSON output is truncated**
A: Pipe to file: `ace-taskflow doctor --format json > doctor-report.json`