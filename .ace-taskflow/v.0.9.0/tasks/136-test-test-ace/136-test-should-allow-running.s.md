---
id: v.0.9.0+task.136
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# ace-test should allow running whole package from any directory

## Description

Enhance `ace-test` to allow running tests for any package from any directory by specifying the package name or path as an argument. Currently, users must navigate to the package directory before running `ace-test`. This feature will improve developer convenience in the mono-repo workflow.

## Acceptance Criteria

- [ ] `ace-test <package-name>` runs all tests for the specified package from any directory
  - Example: `ace-test ace-context` runs all tests in the ace-context package
- [ ] `ace-test <package-path>` accepts both relative and absolute paths to package directories
  - Example: `ace-test ./ace-context` or `ace-test /full/path/to/ace-context`
- [ ] Behavior is identical to running `ace-test` from within the package directory
  - Same test execution, output format, and exit codes
- [ ] Works with all existing ace-test options and arguments
  - Example: `ace-test ace-context --profile 10` profiles slowest tests in ace-context
  - Example: `ace-test ace-context atoms` runs only the atoms test group
- [ ] Package name validation: displays helpful error if package doesn't exist or has no tests
- [ ] Documentation updated to show package argument usage
- [ ] Tests added to verify package argument functionality

## Implementation Notes

**Current Behavior Analysis:**
- Investigate how ace-test currently resolves the package context
- Determine if it relies on current working directory (CWD)

**Proposed Solution:**
- Add optional package argument to ace-test command line interface
- Resolve package path from argument (handle both package names and paths)
- Validate that resolved path contains a tests directory
- Execute tests with proper context (as if running from package directory)

**Edge Cases to Consider:**
- Package argument combined with specific test file paths
- Invalid package names or paths
- Packages without test directories
- Relative vs absolute path handling

**Testing Strategy:**
- Unit tests for package path resolution
- Integration tests for running tests from different directories
- Verify all existing ace-test functionality still works
