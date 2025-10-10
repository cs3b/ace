---
id: v.0.9.0+task.066
status: pending
priority: medium
estimate: 8-12h
dependencies: []
---

# Add ace-taskflow doctor command for comprehensive health checks

## Behavioral Specification

### User Experience
- **Input**: Users run `ace-taskflow doctor` with optional flags for specific checks, auto-fix mode, or output formats
- **Process**: The system scans the entire `.ace-taskflow/` directory, validating tasks, ideas, releases, and retrospectives. It detects issues like missing frontmatter delimiters, malformed YAML, mislocated files, and broken references. Users see a progress indicator during scanning and receive categorized results (errors, warnings, info)
- **Output**: A comprehensive health report showing system overview, detected issues with file locations, auto-fix suggestions, and an overall health score (0-100)

### Expected Behavior

The ace-taskflow doctor command provides a comprehensive health check for the entire taskflow ecosystem. It validates the structural integrity and data consistency of all taskflow components including releases, tasks, ideas, and retrospectives.

The system gracefully handles malformed files (especially missing frontmatter closing delimiters), providing clear diagnostics without crashing. It categorizes issues by severity (critical, warning, informational) and suggests automated fixes for safe corrections.

Key behaviors include:
- Auto-discovery of all taskflow components across active, backlog, and done directories
- Robust parsing that recovers from common frontmatter errors
- Validation of cross-component references and dependencies
- Detection of status-location mismatches (e.g., done tasks in active directories)
- Identification of orphaned files and directories
- Health scoring to track overall system quality over time

### Interface Contract

```bash
# CLI Interface
ace-taskflow doctor [OPTIONS]

# Basic usage - full system check
ace-taskflow doctor

# Component-specific checks
ace-taskflow doctor --component tasks
ace-taskflow doctor --component ideas
ace-taskflow doctor --component releases

# Release-specific check
ace-taskflow doctor --release v.0.9.0

# Auto-fix mode
ace-taskflow doctor --fix
ace-taskflow doctor --fix --dry-run  # Preview fixes without applying

# Output formats
ace-taskflow doctor --format json    # For CI/CD integration
ace-taskflow doctor --format summary # Brief overview only
ace-taskflow doctor --verbose        # Detailed diagnostic output

# Severity filtering
ace-taskflow doctor --errors-only    # Only show critical issues
ace-taskflow doctor --quiet          # Exit code only (0=healthy, 1=issues)

# Specific validation types
ace-taskflow doctor --check frontmatter
ace-taskflow doctor --check dependencies
ace-taskflow doctor --check structure
```

**Output Format (Default):**
```
🏥 Taskflow Health Check
========================
[System overview with counts]
[Progress bars for each component]
[Categorized issues with file paths]
[Auto-fix suggestions]
[Health score and summary]
```

**Exit Codes:**
- 0: System healthy (no errors, warnings allowed)
- 1: Issues detected (errors or warnings based on flags)
- 2: Doctor command failed (couldn't complete scan)

**Error Handling:**
- Malformed YAML: Parse what's possible, report specific syntax errors
- Missing files: Note as warning, continue scanning
- Permission errors: Skip with warning, don't fail entire scan
- Corrupted files: Report as critical, suggest manual intervention

**Edge Cases:**
- Empty taskflow directory: Report as info, suggest initialization
- Circular dependencies: Detect and report with full cycle path
- Future-dated items: Flag as warnings with timestamps
- Duplicate IDs: Critical error with all occurrence locations

### Success Criteria

- [ ] **Comprehensive Scanning**: Validates entire taskflow ecosystem including releases, tasks, ideas, and retrospectives
- [ ] **Malformed File Handling**: Gracefully processes files with missing frontmatter delimiters and YAML syntax errors
- [ ] **Clear Diagnostics**: Provides specific file paths and line numbers for all detected issues
- [ ] **Auto-Fix Capability**: Safely corrects common issues like missing closing delimiters with --fix flag
- [ ] **Health Scoring**: Generates 0-100 health score based on issue severity and count
- [ ] **CI/CD Integration**: Provides JSON output and proper exit codes for automation
- [ ] **Component Isolation**: Can check specific components or releases independently
- [ ] **Performance**: Completes full scan of typical repository (100+ files) within 5 seconds

### Validation Questions

- [ ] **Scope Boundaries**: Should doctor check git status (uncommitted changes) or purely file structure?
- [ ] **Auto-Fix Limits**: Which corrections are safe for automatic fixing vs requiring manual intervention?
- [ ] **Health Score Algorithm**: How should different issue types weight the overall health score?
- [ ] **Performance Thresholds**: What's acceptable scan time for large repositories (1000+ files)?
- [ ] **Integration Points**: Should doctor integrate with existing validation in task/idea commands?
- [ ] **Reporting Granularity**: How much detail in default output vs verbose mode?

## Objective

Provide a comprehensive health check tool for ace-taskflow that helps users maintain a clean, consistent, and valid taskflow structure. The doctor command addresses the common issue of malformed frontmatter (especially missing closing delimiters) and other structural problems that can break taskflow operations.

## Scope of Work

- **User Experience Scope**: Command-line interface for health checks, auto-fix operations, and reporting
- **System Behavior Scope**: Full validation of taskflow file structure, frontmatter integrity, and cross-references
- **Interface Scope**: CLI command with multiple output formats, component filtering, and auto-fix capabilities

### Deliverables

#### Behavioral Specifications
- Health check workflow from invocation to report
- Issue categorization and severity definitions
- Auto-fix behavior for safe corrections

#### Validation Artifacts
- Test scenarios for various malformation types
- Health score calculation criteria
- Performance benchmarks for large repositories

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby class structures or module organization
- ❌ **Technology Decisions**: Choice of YAML parser or validation libraries
- ❌ **Performance Optimization**: Specific caching or parallel processing strategies
- ❌ **Future Enhancements**: Integration with external monitoring tools or web UI

## References

- Current ace-taskflow validation issues and bug reports
- Existing ace-taskflow loader components (TaskLoader, IdeaLoader)
- YAML parsing standards and error recovery patterns

## Technical Research

### Architecture Analysis

The doctor command will integrate with existing ace-taskflow architecture:
- Leverage existing loaders (TaskLoader, IdeaLoader, ReleaseResolver) for file discovery
- Follow ATOM pattern: atoms for pure validation, molecules for composed checks, organisms for orchestration
- Use existing YamlParser as baseline, extend with SafeYamlParser for error recovery

### Key Technical Insights

1. **Frontmatter Recovery**: Most common issue is missing closing `---`. Can detect by looking for first blank line or `#` heading after opening delimiter
2. **Validation Layers**: Separate structural validation (files exist) from semantic validation (IDs match)
3. **Performance**: Use lazy loading and early exit strategies for large repositories
4. **Error Collection**: Accumulate all errors before reporting rather than fail-fast

## Implementation Plan

### Planning Steps

* [ ] Research YAML error recovery patterns in Ruby ecosystem
* [ ] Analyze existing validation logic in TaskLoader/IdeaLoader
* [ ] Design health score algorithm based on issue severity
* [ ] Investigate Ruby libraries for progress bars and colored output
* [ ] Plan test fixtures for various malformation scenarios
* [ ] Define auto-fixable vs manual intervention criteria

### Execution Steps

#### 1. Create SafeYamlParser Atom
- [ ] Create `lib/ace/taskflow/atoms/safe_yaml_parser.rb`
  - Implement `parse_with_recovery` method
  - Handle missing closing delimiter detection
  - Recover partial YAML when possible
  - Return structured error/warning information
  > TEST: SafeYamlParser Recovery
  > Type: Unit Test
  > Assert: Correctly identifies and recovers from missing closing delimiter
  > Command: `ace-test ace-taskflow atoms/safe_yaml_parser_test.rb`

#### 2. Implement Validation Molecules
- [ ] Create `lib/ace/taskflow/molecules/frontmatter_validator.rb`
  - Validate YAML structure and required fields
  - Check for missing delimiters
  - Validate field value formats

- [ ] Create `lib/ace/taskflow/molecules/structure_validator.rb`
  - Validate directory structure compliance
  - Check file naming conventions
  - Detect orphaned files and directories

- [ ] Create `lib/ace/taskflow/molecules/integrity_validator.rb`
  - Validate ID uniqueness across components
  - Check dependency references exist
  - Detect circular dependencies

- [ ] Create `lib/ace/taskflow/molecules/release_validator.rb`
  - Validate release naming and versioning
  - Check release status matches location
  - Verify required directories exist

#### 3. Build Doctor Orchestrator
- [ ] Create `lib/ace/taskflow/organisms/taskflow_doctor.rb`
  - Coordinate all validators
  - Collect and categorize issues
  - Calculate health score
  - Implement component filtering
  > TEST: Full System Scan
  > Type: Integration Test
  > Assert: Doctor scans entire taskflow and reports all issue types
  > Command: `ace-test ace-taskflow organisms/taskflow_doctor_test.rb`

#### 4. Implement Auto-Fix Capabilities
- [ ] Create `lib/ace/taskflow/molecules/doctor_fixer.rb`
  - Add missing closing delimiters
  - Move mislocated files
  - Add default values for missing fields
  - Implement dry-run mode
  > TEST: Auto-Fix Safety
  > Type: Integration Test
  > Assert: Only safe fixes are applied, no data loss
  > Command: `ace-test ace-taskflow molecules/doctor_fixer_test.rb`

#### 5. Create Reporter Module
- [ ] Create `lib/ace/taskflow/molecules/doctor_reporter.rb`
  - Format output for terminal (default)
  - Implement JSON output for CI/CD
  - Add progress bars for scanning
  - Color code issues by severity

#### 6. Implement CLI Command
- [ ] Create `lib/ace/taskflow/commands/doctor_command.rb`
  - Parse command-line arguments
  - Handle component filtering options
  - Implement format selection
  - Set proper exit codes

- [ ] Update `lib/ace/taskflow/cli.rb`
  - Add doctor command to CLI router
  - Include help documentation

#### 7. Create Test Fixtures
- [ ] Create malformed test files in `test/fixtures/doctor/`
  - Missing closing delimiter cases
  - Invalid YAML syntax examples
  - Mislocated files
  - Circular dependencies
  - Orphaned directories

#### 8. Write Comprehensive Tests
- [ ] Create test files following flat structure:
  - `test/atoms/safe_yaml_parser_test.rb`
  - `test/molecules/frontmatter_validator_test.rb`
  - `test/molecules/structure_validator_test.rb`
  - `test/molecules/integrity_validator_test.rb`
  - `test/organisms/taskflow_doctor_test.rb`
  - `test/commands/doctor_command_test.rb`
  > TEST: Test Coverage
  > Type: Coverage Analysis
  > Assert: >90% code coverage for doctor functionality
  > Command: `ace-test ace-taskflow --coverage`

#### 9. Create Usage Documentation
- [ ] Create `ux/usage.md` in task directory
  - Document all command options
  - Provide real-world usage examples
  - Show sample output for each format
  - Include troubleshooting guide

#### 10. Integration and Validation
- [ ] Run doctor on actual ace-meta repository
- [ ] Verify performance with 100+ files
- [ ] Test auto-fix on real malformed files
- [ ] Validate JSON output for CI integration
- [ ] Ensure backward compatibility with existing commands
  > TEST: Real-World Validation
  > Type: System Test
  > Assert: Doctor successfully analyzes ace-meta repository
  > Command: `ace-taskflow doctor --verbose`

### Test Case Planning

#### Happy Path Scenarios
- Clean repository with no issues
- Repository with minor warnings only
- Successful auto-fix of common issues
- Component-specific checks returning clean

#### Edge Cases
- Empty `.ace-taskflow` directory
- Repository with 1000+ files
- Deeply nested directory structures
- Files with multiple YAML documents
- Binary files in task directories

#### Error Conditions
- Missing `.ace-taskflow` directory
- Permission denied on files
- Corrupted/truncated files
- Invalid UTF-8 encoding
- Symbolic links and circular references

#### Integration Points
- Compatibility with existing TaskLoader
- Integration with ace-test for validation
- CI/CD pipeline integration via JSON output
- Git hooks for pre-commit validation
