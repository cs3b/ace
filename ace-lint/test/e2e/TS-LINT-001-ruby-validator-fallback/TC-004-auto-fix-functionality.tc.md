---
tc-id: TC-004
title: Auto-fix Functionality
---

## Objective

Verify that ace-lint can auto-fix style issues.

## Steps

1. Create a copy of the style issues file
   ```bash
   cp style_issues.rb style_issues_copy.rb
   ```

2. Run linting with auto-fix
   ```bash
   ace-lint lint --fix style_issues_copy.rb
   ```

3. Verify file was modified
   ```bash
   diff style_issues.rb style_issues_copy.rb
   ```

4. Re-lint the fixed file
   ```bash
   ace-lint lint style_issues_copy.rb
   ```

## Expected

- File is modified after --fix
- Re-linting shows fewer or no issues
- Original file unchanged
