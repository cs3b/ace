---
doc-type: workflow
title: Run Lint Workflow
purpose: lint workflow instruction
ace-docs:
  last-updated: 2026-02-23
  last-checked: 2026-03-21
---

# Run Lint Workflow

## Purpose

Execute ace-lint on project files with intelligent file selection, optional autofix coordination, and structured report generation for AI-assisted code quality improvement.

## Context

ace-lint automatically:
- Detects file types from extensions (.md, .yml, .yaml)
- Validates markdown frontmatter and structure
- Checks YAML syntax
- Reports errors in structured format

## Variables

- `$file_pattern`: Optional glob pattern or file paths (from argument)
- `$fix`: Whether to attempt autofixes (from --fix flag)
- `$report`: Whether to generate JSON report (from --report flag)

## Instructions

1. **Review embedded repository status** in `<current_repository_status>`:
   - Which files have been modified?
   - What types of files are involved?
   - Is this a targeted lint or full project scan?

2. **Select files to lint** based on context:
   - If file pattern provided: Use that pattern
   - If recent changes: Focus on changed files
   - Otherwise: Lint project-wide

3. **Execute lint command**:

   **Basic lint (all markdown/yaml):**
   ```bash
   ace-lint "**/*.md" "**/*.yml"
   ```

   **Lint specific files:**
   ```bash
   ace-lint path/to/file.md path/to/other.yml
   ```

   **Lint with glob pattern:**
   ```bash
   ace-lint "**/*.md"
   ```

   **Lint changed files only:**
   ```bash
   git diff --name-only --diff-filter=AM | grep -E '\.(md|ya?ml)$' | xargs ace-lint
   ```

4. **Handle results**:
   - **Exit code 0**: All files pass - report success
   - **Exit code 1**: Errors found - analyze and fix or generate report
   - **Exit code 2**: Fatal error - investigate and report

5. **If errors found and --fix requested**:
   - Analyze each error type
   - Apply safe autofixes where possible
   - Re-run lint to verify fixes
   - Report remaining manual-fix issues

6. **If --report requested**, generate JSON report:
   ```bash
   # Create report directory if needed
   mkdir -p .ace-lint/reports

   # Generate timestamped report
   REPORT_FILE=".ace-lint/reports/lint-$(date +%Y%m%d-%H%M%S).json"
   ```

   Report structure:
   ```json
   {
     "timestamp": "2026-01-08T16:30:00Z",
     "files_checked": 42,
     "errors": [
       {
         "file": "path/to/file.md",
         "line": 10,
         "severity": "error",
         "rule": "frontmatter-required",
         "message": "Missing required frontmatter field: doc-type",
         "fix_proposal": "Add 'doc-type: workflow' to frontmatter"
       }
     ],
     "summary": {
       "total_errors": 5,
       "by_severity": {"error": 3, "warning": 2},
       "by_rule": {"frontmatter-required": 2, "yaml-syntax": 3}
     }
   }
   ```

## Options Reference

ace-lint CLI options:
- `--quiet`: Suppress detailed output
- `--version`: Show version
- File types auto-detected from extensions

## Common Error Patterns

### Markdown Issues
- Missing frontmatter → Add required YAML block
- Invalid frontmatter syntax → Fix YAML structure
- Broken internal links → Update path references

### YAML Issues
- Indentation errors → Fix spacing (2 spaces)
- Missing quotes → Add quotes around special characters
- Invalid syntax → Check colons, dashes, brackets

### Frontmatter Issues
- Missing required fields → Add doc-type, purpose, etc.
- Invalid date format → Use YYYY-MM-DD
- Type mismatches → Ensure correct value types

## Success Criteria

- All specified files linted
- Errors clearly reported with file:line format
- Autofixes applied safely (if requested)
- JSON report generated (if requested)
- Clear summary of remaining issues

## Response Template

**Files Linted:** [count] files
**Result:** ✓ All pass | ✗ [N] errors found
**Autofixes Applied:** [count] (if --fix)
**Report Generated:** [path] (if --report)
**Manual Fixes Needed:** [list of issues requiring human intervention]