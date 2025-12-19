---
id: v.0.9.0+task.136
status: in-progress
priority: medium
estimate: 4h
dependencies: []
worktree:
  branch: 136-ace-test-should-allow-running-whole-package-from-any-directory
  path: "../ace-task.136"
  created_at: '2025-12-19 16:15:00'
  updated_at: '2025-12-19 16:15:00'
---

# ace-test should allow running whole package from any directory

## 0. Directory Audit

_Command run:_

```bash
ace-nav guide://
```

_Result excerpt:_

```
ace-test-runner/
  lib/ace/test_runner/
    atoms/
      test_detector.rb
      command_builder.rb
      result_parser.rb
      test_folder_detector.rb
    molecules/
      pattern_resolver.rb
      config_loader.rb
      test_executor.rb
    organisms/
      test_orchestrator.rb
  exe/ace-test
  test/
```

## Objective

Enable developers to run tests for any package in the mono-repo from any directory, eliminating the need to navigate to each package directory before running tests. This improves developer convenience and workflow efficiency in the multi-gem mono-repo environment.

## Scope of Work

- Add package name/path resolution to ace-test CLI
- Create new atom for package discovery and resolution
- Modify test orchestrator to handle package context switching
- Ensure configuration loading uses package-local configs
- Maintain backward compatibility with existing behavior

### Deliverables

#### Create

- `ace-test-runner/lib/ace/test_runner/atoms/package_resolver.rb`
  - Purpose: Resolve package names or paths to absolute package directories
  - Key components: Package name lookup, path resolution, validation

- `ace-test-runner/test/atoms/package_resolver_test.rb`
  - Purpose: Unit tests for package resolution logic

- `ace-test-runner/test/integration/package_argument_test.rb`
  - Purpose: Integration tests for running tests with package argument

#### Modify

- `ace-test-runner/exe/ace-test`
  - Changes: Add package argument parsing before target/file detection
  - Impact: First non-option argument checked as potential package name
  - Integration: Pass package_dir to orchestrator options

- `ace-test-runner/lib/ace/test_runner/organisms/test_orchestrator.rb`
  - Changes: Handle package_dir option, change working directory
  - Impact: Config loading and test discovery use package directory
  - Integration: Reports saved to package's test-reports/

- `ace-test-runner/lib/ace/test_runner/molecules/config_loader.rb`
  - Changes: Accept base_dir parameter for config discovery
  - Impact: Load configuration from specified package directory

- `ace-test-runner/README.md` (or docs/usage.md)
  - Changes: Document package argument feature
  - Impact: Users know how to use new functionality

## Technical Approach

### Architecture Pattern

- **Pattern selection**: Extend existing ATOM architecture with new PackageResolver atom
- **Integration with existing architecture**: PackageResolver sits alongside TestDetector, both used by TestOrchestrator
- **Impact on system design**: Minimal - adds optional path before existing flow

### Technology Stack

- **Libraries/frameworks needed**: Uses existing ace-support-core ProjectRootFinder
- **Version compatibility checks**: Compatible with all current Ruby versions (tested in CI)
- **Performance implications**: Negligible - single directory lookup at startup
- **Security considerations**: Path validation prevents directory traversal

### Implementation Strategy

1. Create PackageResolver atom for package name/path resolution
2. Update exe/ace-test to detect package argument
3. Modify TestOrchestrator to use package_dir for context
4. Update ConfigLoader to support base directory
5. Add comprehensive tests

## Implementation Plan

### Planning Steps

* [ ] Analyze current argument parsing in exe/ace-test to understand precedence rules
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Documented flow from CLI args to orchestrator
  > Command: # Review exe/ace-test line 180-210 for argument handling

* [ ] Research how ProjectRootFinder discovers the mono-repo root
  > TEST: Pattern Understanding
  > Type: Pre-condition Check
  > Assert: Clear understanding of root detection for package lookup

### Execution Steps

- [ ] Create `PackageResolver` atom in `ace-test-runner/lib/ace/test_runner/atoms/package_resolver.rb`
  - Implement `resolve(name_or_path)` method returning absolute path or nil
  - Implement `available_packages` method listing all ace-* packages
  - Use ProjectRootFinder to locate mono-repo root
  - Handle: package name (ace-context), relative path (./ace-context), absolute path
  - Validate resolved path has test/ directory
  > TEST: PackageResolver Creation
  > Type: Action Validation
  > Assert: File exists with resolve method
  > Command: # ace-test test/atoms/package_resolver_test.rb

- [ ] Create unit tests for PackageResolver in `test/atoms/package_resolver_test.rb`
  - Test package name resolution (ace-context -> full path)
  - Test relative path resolution
  - Test absolute path resolution
  - Test invalid package handling
  - Test package without test directory
  > TEST: Unit Tests Pass
  > Type: Action Validation
  > Assert: All unit tests pass
  > Command: # cd ace-test-runner && ace-test test/atoms/package_resolver_test.rb

- [ ] Update exe/ace-test to detect and handle package argument
  - Add package detection logic after option parsing
  - Check if first non-option arg is a valid package (before target check)
  - Pass package_dir in options hash to TestRunner.run()
  - Update help text with package usage examples
  > TEST: CLI Accepts Package
  > Type: Action Validation
  > Assert: ace-test ace-context --help shows valid usage
  > Command: # ace-test ace-context --help (should not error on package name)

- [ ] Modify TestOrchestrator to handle package_dir option
  - Accept package_dir in options
  - Change working directory if package_dir specified
  - Ensure config loading, test discovery, report saving use package context
  - Restore original directory on completion (for clean state)
  > TEST: Orchestrator Context Switch
  > Type: Action Validation
  > Assert: Tests run in package directory
  > Command: # ace-test ace-support-core atoms (from repo root)

- [ ] Update ConfigLoader to accept optional base_dir parameter
  - Modify find_and_load_config to search from base_dir
  - Fall back to current directory if base_dir not provided
  - Maintain backward compatibility for existing callers
  > TEST: Config Loading
  > Type: Action Validation
  > Assert: Package-local config used when package specified
  > Command: # Verify config path in verbose output

- [ ] Create integration tests in `test/integration/package_argument_test.rb`
  - Test running tests for a package by name from repo root
  - Test running tests for a package from different directory
  - Test combining package with target (ace-test ace-nav atoms)
  - Test combining package with options (ace-test ace-lint --fail-fast)
  - Test error handling for invalid packages
  > TEST: Integration Tests
  > Type: Action Validation
  > Assert: All integration scenarios work
  > Command: # cd ace-test-runner && ace-test test/integration/package_argument_test.rb

- [ ] Update documentation with package argument usage
  - Add section to README.md or docs/usage.md
  - Include examples for common use cases
  - Document error messages and troubleshooting
  > TEST: Documentation
  > Type: Action Validation
  > Assert: Documentation reflects new capability
  > Command: # Review updated docs

- [ ] Run full test suite to verify no regressions
  > TEST: Full Test Suite
  > Type: Action Validation
  > Assert: All existing tests still pass
  > Command: # cd ace-test-runner && ace-test

## Test Case Planning

### Happy Path Scenarios

| Scenario | Input | Expected Output |
|----------|-------|-----------------|
| Package by name | `ace-test ace-context` | Runs ace-context tests |
| Package + target | `ace-test ace-nav atoms` | Runs only atoms tests |
| Package + options | `ace-test ace-lint --profile 5` | Shows slowest 5 tests |
| Relative path | `ace-test ./ace-search` | Runs ace-search tests |
| Absolute path | `ace-test /path/to/ace-docs` | Runs ace-docs tests |

### Edge Case Scenarios

| Scenario | Input | Expected Behavior |
|----------|-------|-------------------|
| Invalid package | `ace-test nonexistent` | Error with available packages list |
| No test directory | `ace-test ace-support-mac-clipboard` | Error: no test directory |
| Ambiguous arg | `ace-test atoms` | Treated as target (existing behavior) |
| Current package | `ace-test .` | Runs tests in current directory |

### Error Condition Scenarios

| Scenario | Input | Expected Error |
|----------|-------|----------------|
| Package not found | `ace-test foo` | "Package not found: foo. Available: ..." |
| Path not directory | `ace-test /file.txt` | "Not a directory: /file.txt" |
| No tests in package | `ace-test pkg-without-tests` | "No test directory found in ..." |

## Risk Assessment

### Technical Risks

- **Risk:** Breaking existing argument parsing logic
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Comprehensive tests, preserve all existing behavior
  - **Rollback:** Revert changes to exe/ace-test

- **Risk:** Working directory changes affecting test isolation
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Use Dir.chdir with block to restore state, or explicit restore
  - **Rollback:** N/A - part of design

### Integration Risks

- **Risk:** Config cascade behavior differs in package context
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Test config loading explicitly, use existing ConfigLoader patterns
  - **Monitoring:** Check verbose output for config path

## Acceptance Criteria

- [ ] AC 1: `ace-test <package-name>` runs all tests for the specified package from any directory
- [ ] AC 2: `ace-test <package-path>` accepts both relative and absolute paths
- [ ] AC 3: Behavior identical to running `ace-test` from within package directory
- [ ] AC 4: Works with all existing ace-test options and arguments
- [ ] AC 5: Helpful error messages for invalid packages
- [ ] AC 6: Documentation updated
- [ ] AC 7: All new and existing tests pass

## Out of Scope

- Package-specific test configuration defaults (each package manages its own .ace/test/runner.yml)
- Multi-package test execution in single command (use ace-test-suite for that)
- Package dependency resolution (tests run independently)

## References

- `ace-test-runner/exe/ace-test` - Current CLI implementation
- `ace-test-runner/lib/ace/test_runner/organisms/test_orchestrator.rb` - Core orchestration
- `ace-support-core/lib/ace/core/molecules/project_root_finder.rb` - Root detection pattern
- `ace-test-runner/lib/ace/test_runner/suite/orchestrator.rb` - Suite package handling pattern
- Task UX documentation: `ux/usage.md`