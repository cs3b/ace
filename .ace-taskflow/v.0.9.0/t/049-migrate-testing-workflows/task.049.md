---
id: v.0.9.0+task.049
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Migrate testing workflows to ace-taskflow

## Behavioral Specification

### User Experience
- **Input**: User invokes testing commands via ace-taskflow CLI (e.g., `ace-taskflow test fix`, `ace-taskflow test create`, `ace-taskflow test coverage`)
- **Process**: System executes test-related workflows, running tests, generating test cases, fixing failures, or improving coverage
- **Output**: Updated test files, test reports, coverage metrics, and actionable feedback on test quality

### Expected Behavior

Users experience comprehensive testing workflows accessible through the ace-taskflow command. The system provides:

**Fix Tests**: Automatically identifies failing tests, analyzes failure reasons, and applies fixes
- Runs test suite to identify failures
- Analyzes error messages and stack traces
- Suggests or implements fixes
- Re-runs tests to verify fixes

**Create Test Cases**: Generates test cases for specified code
- Analyzes target code structure and behavior
- Identifies test scenarios (happy path, edge cases, errors)
- Generates test files with appropriate assertions
- Follows project testing conventions

**Improve Code Coverage**: Identifies untested code paths and generates tests
- Analyzes current coverage metrics
- Identifies uncovered code paths
- Prioritizes coverage improvements
- Generates tests for uncovered areas

**Fix Linting Issues**: Addresses code quality issues from linter output
- Parses linter output from specified file
- Categorizes issues by severity and type
- Applies automated fixes where possible
- Reports unfixable issues with context

All workflows maintain project-specific testing conventions and integrate with existing test frameworks.

### Interface Contract

```bash
# Fix failing tests
ace-taskflow test fix [--path <test-file>] [--pattern <test-pattern>]
# Executes: wfi://fix-tests
# Output: Fixed test files, test run results

# Create test cases for code
ace-taskflow test create --target <code-file> [--type <unit|integration|e2e>]
# Executes: wfi://create-test-cases
# Output: Generated test files following project conventions

# Improve code coverage
ace-taskflow test coverage [--threshold <percentage>] [--path <directory>]
# Executes: wfi://improve-code-coverage
# Output: New tests for uncovered code, updated coverage report

# Fix linting issues from file
ace-taskflow test lint --from <linter-output-file>
# Executes: wfi://fix-linting-issue-from
# Output: Fixed code files, remaining issues report
```

**Error Handling:**
- Test framework not detected: Report error and suggest configuration
- Cannot fix test: Provide detailed explanation and manual fix suggestions
- Linter output malformed: Parse available data, warn about unparseable sections
- Coverage tool unavailable: Report error and suggest installation

**Edge Cases:**
- No failing tests: Report success, suggest coverage improvements
- All code covered: Report achievement, suggest increasing threshold
- Complex test failures: Break down into simpler sub-problems
- Conflicting linter rules: Report conflicts, prioritize by severity

### Success Criteria

- [ ] **Automated Test Fixing**: System successfully identifies and fixes common test failures
- [ ] **Test Generation**: Generated tests follow project conventions and provide meaningful coverage
- [ ] **Coverage Improvement**: System identifies and tests previously uncovered code paths
- [ ] **Linter Integration**: Successfully parses linter output and applies fixes
- [ ] **Framework Agnostic**: Works with multiple testing frameworks (RSpec, Jest, pytest, etc.)

### Validation Questions

- [ ] **Framework Detection**: How should system detect which testing framework is in use?
- [ ] **Test Conventions**: How to ensure generated tests match project style and patterns?
- [ ] **Coverage Thresholds**: What default coverage targets should be used?
- [ ] **Linter Formats**: Which linter output formats need to be supported?
- [ ] **Fix Safety**: What validation ensures fixes don't break other tests?

## Objective

Provide comprehensive testing automation through ace-taskflow CLI, enabling users to maintain high-quality test suites with automated fixing, generation, coverage improvement, and linting capabilities.

## Scope of Work

### Workflows to Migrate
1. **fix-tests** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/fix-tests.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/fix-tests.wf.md`
   - Command: `ace-taskflow test fix`

2. **create-test-cases** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-test-cases.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/create-test-cases.wf.md`
   - Command: `ace-taskflow test create`

3. **improve-code-coverage** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/improve-code-coverage.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/improve-code-coverage.wf.md`
   - Command: `ace-taskflow test coverage`

4. **fix-linting-issue-from** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/fix-linting-issue-from.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/fix-linting-issue-from.wf.md`
   - Command: `ace-taskflow test lint --from`

### Interface Scope
- CLI commands under `ace-taskflow test` namespace
- wfi:// protocol integration for workflow delegation
- Test framework detection and integration
- Linter output parsing
- Coverage metric analysis

## Out of Scope

- ❌ **Implementation Details**: Test runner integration code, parsing logic, fix algorithms
- ❌ **New Testing Features**: Test parallelization, test prioritization, flaky test detection
- ❌ **CI/CD Integration**: Pipeline configuration, automated test runs on commit
- ❌ **Test Framework Development**: Creating new testing frameworks or runners

## References

- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/fix-tests.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-test-cases.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/improve-code-coverage.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/fix-linting-issue-from.wf.md`
- Template: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`
