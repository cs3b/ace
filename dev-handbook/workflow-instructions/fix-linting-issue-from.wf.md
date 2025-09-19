# Fix Linting Issue From Error File Workflow

**Goal:** Fix code quality issues listed in an assigned error file (.lint-errors-N.md)

## Prerequisites

* Assigned error file path (e.g., `.lint-errors-1.md`)
* Access to project source code
* Understanding of the linting rules being violated

## Process Steps

1. **Read Error File:**
   * Load the assigned error file (e.g., `.lint-errors-1.md`)
   * Parse and understand each error entry
   * Note the file paths, line numbers, and error descriptions

2. **Fix Each Issue:**
   * For each error in the file:
     * Navigate to the source file mentioned
     * Read the context around the error location
     * Understand why the linter flagged this issue
     * Apply the appropriate fix
     * Ensure the fix doesn't break existing functionality

3. **Validate Fixes:**
   * Run targeted linting on the fixed files
   * Ensure no new issues were introduced
   * Verify the original issues are resolved

4. **Report Completion:**
   * Mark the task as complete
   * Report any issues that couldn't be fixed
   * Note any concerns about the fixes applied

## Guidelines

### Do's
* Fix only issues listed in your assigned file
* Preserve code functionality when fixing style issues
* Follow project coding standards
* Test your changes if possible

### Don'ts
* Don't modify files not mentioned in your error list
* Don't make unrelated "improvements" while fixing
* Don't ignore error context - understand before fixing
* Don't apply unsafe fixes without understanding impact

## Common Fix Patterns

### Ruby Issues

**StandardRB Style Issues:**
* Missing/extra spaces: Add or remove as indicated
* Line too long: Break into multiple lines preserving logic
* Missing frozen_string_literal: Add at file top
* Unused variables: Remove or prefix with underscore

**Security Issues:**
* Exposed secrets: Move to environment variables
* Unsafe operations: Use safe alternatives

### Markdown Issues

**Formatting:**
* Inconsistent headers: Normalize header levels
* Missing blank lines: Add appropriate spacing
* Line length: Break long lines at sentence boundaries

**Broken Links:**
* Update paths to correct locations
* Remove links to deleted resources
* Fix typos in link targets

**Task Metadata:**
* Fix YAML frontmatter formatting
* Ensure required fields are present
* Use correct value formats

## Error File Format

Error files follow this structure:
```markdown
# Lint Errors - Group N

## path/to/file.rb

### ruby_standardrb

**Location:** `path/to/file.rb:42:15`
**Severity:** warning

**Issue:**
```
Layout/SpaceInsideHashLiteralBraces: Space inside { missing.
```
```

## Completion Criteria

* All errors in the assigned file are addressed
* No new linting errors introduced
* Code functionality preserved
* Changes are minimal and focused

## Input

* Error file path (e.g., `.lint-errors-1.md`)

## Output

* Fixed source files
* Completion status report
* Any unresolved issues noted