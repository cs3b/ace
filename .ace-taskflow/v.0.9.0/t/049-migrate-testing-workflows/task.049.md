---
id: v.0.9.0+task.049
status: in-progress
priority: high
estimate: 8h
dependencies: []
---

# Migrate testing workflows to ace-taskflow

## 0. Directory Audit ✅

_Command run:_

```bash
ace-nav guide://
```

_Result excerpt:_

```
ace-taskflow/
├── handbook/
│   └── workflow-instructions/    # Target location for migrated workflows
├── lib/ace/taskflow/
│   ├── cli.rb                     # CLI routing - add 'test' subcommand
│   └── commands/                  # Command implementations
.claude/
└── commands/ace/                  # Claude command bridge files
dev-handbook/
└── workflow-instructions/         # Source workflows (legacy)
    ├── fix-tests.wf.md
    ├── create-test-cases.wf.md
    ├── improve-code-coverage.wf.md
    └── fix-linting-issue-from.wf.md
```

## Behavioral Specification

### User Experience
- **Input**: User invokes testing commands via Claude Code (e.g., `/ace:fix-tests`, `/ace:create-test-cases`, `/ace:improve-code-coverage`)
- **Process**: System executes test-related workflows, running tests, generating test cases, fixing failures, or improving coverage
- **Output**: Updated test files, test reports, coverage metrics, and actionable feedback on test quality

### Expected Behavior

Users experience comprehensive testing workflows accessible through Claude Code commands. The system provides:

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

All workflows maintain project-specific testing conventions and integrate with existing test frameworks.

### Interface Contract

**Claude Code Commands** (thin wrappers to workflows):

```
# Fix failing tests
/ace:fix-tests
# Executes: ace-nav wfi://fix-tests
# Output: Fixed test files, test run results

# Create test cases for code
/ace:create-test-cases
# Executes: ace-nav wfi://create-test-cases
# Output: Generated test files following project conventions

# Improve code coverage
/ace:improve-code-coverage
# Executes: ace-nav wfi://improve-code-coverage
# Output: New tests for uncovered code, updated coverage report
```

**Error Handling:**
- Test framework not detected: Report error and suggest configuration
- Cannot fix test: Provide detailed explanation and manual fix suggestions
- Coverage tool unavailable: Report error and suggest installation

**Edge Cases:**
- No failing tests: Report success, suggest coverage improvements
- All code covered: Report achievement, suggest increasing threshold
- Complex test failures: Break down into simpler sub-problems

### Success Criteria

- [ ] **Automated Test Fixing**: System successfully identifies and fixes common test failures
- [ ] **Test Generation**: Generated tests follow project conventions and provide meaningful coverage
- [ ] **Coverage Improvement**: System identifies and tests previously uncovered code paths
- [ ] **Framework Agnostic**: Works with multiple testing frameworks (RSpec, Jest, pytest, etc.)
- [ ] **Claude Integration**: Commands work seamlessly as thin wrappers to workflows

### Validation Questions

- [ ] **Framework Detection**: How should system detect which testing framework is in use?
- [ ] **Test Conventions**: How to ensure generated tests match project style and patterns?
- [ ] **Coverage Thresholds**: What default coverage targets should be used?
- [ ] **Fix Safety**: What validation ensures fixes don't break other tests?
- [ ] **Workflow Integration**: How to ensure workflows are self-contained per ADR-001?

## Objective

Provide comprehensive testing automation through Claude Code commands, enabling users to maintain high-quality test suites with automated fixing, generation, and coverage improvement capabilities. Commands act as thin wrappers that delegate to self-contained workflows.

## Scope of Work

### Workflows to Migrate
1. **fix-tests** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/fix-tests.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/fix-tests.wf.md`
   - Claude Command: `/ace:fix-tests`

2. **create-test-cases** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-test-cases.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/create-test-cases.wf.md`
   - Claude Command: `/ace:create-test-cases`

3. **improve-code-coverage** (dev-handbook → ace-taskflow)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/improve-code-coverage.wf.md`
   - Destination: `ace-taskflow/handbook/workflow-instructions/improve-code-coverage.wf.md`
   - Claude Command: `/ace:improve-code-coverage`

### Interface Scope
- Claude Code commands as thin wrappers to workflows
- wfi:// protocol integration for workflow delegation
- Test framework detection and integration
- Coverage metric analysis
- **Note**: Linting workflows moved to ace-handbook package (task 052)

## Out of Scope

- ❌ **Implementation Details**: Test runner integration code, parsing logic, fix algorithms
- ❌ **New Testing Features**: Test parallelization, test prioritization, flaky test detection
- ❌ **CI/CD Integration**: Pipeline configuration, automated test runs on commit
- ❌ **Test Framework Development**: Creating new testing frameworks or runners
- ❌ **CLI Tools**: No `ace-taskflow test *` bash commands (only Claude commands as thin wrappers)
- ❌ **Linting Workflows**: `fix-linting-issue-from` migrated to ace-handbook package (task 052)

## Technical Approach

### Two-Layer Architecture

**IMPORTANT:** This migration implements Claude commands as thin wrappers to workflows only. No CLI tools.

**Layer 1: Workflows** (.wf.md files)
- Self-contained workflow instructions in `ace-taskflow/handbook/workflow-instructions/`
- Discoverable via `ace-nav wfi://` protocol
- Complete testing logic and framework detection

**Layer 2: Claude Commands** (.claude/commands/ace/)
- Thin wrapper files that invoke workflows via `ace-nav wfi://`
- **ONLY executable from Claude Code/agents**
- **NOT runnable from bash command line**
- Examples: `/ace:fix-tests`, `/ace:create-test-cases`, `/ace:improve-code-coverage`

### Architecture Pattern

Following task 048 roadmap migration pattern:

1. **Workflow Migration:**
   - Copy workflows from `dev-handbook/` to `ace-taskflow/handbook/`
   - Update internal references to use relative paths
   - Embed templates using ADR-002 XML format
   - Update context loading to use `ace-nav wfi://` protocol

2. **Claude Command Integration:**
   - Create `.claude/commands/ace/*.md` files (thin wrappers)
   - Each command calls `ace-nav wfi://[workflow-name]`
   - Set appropriate allowed-tools and descriptions
   - **Commands are Claude-only, NOT bash runnable**

### Workflow Self-Containment (ADR-001)

Each workflow must include:
- All necessary templates embedded using XML format (ADR-002)
- Complete instructions without external dependencies
- Context loading via `ace-nav wfi://load-project-context`
- Project-agnostic framework detection logic

### Testing Framework Detection

Workflows must detect testing framework dynamically:
- Ruby: RSpec, Minitest (check Gemfile, test/ vs spec/ directories)
- JavaScript: Jest, Mocha, Jasmine (check package.json, test files)
- Python: pytest, unittest (check requirements.txt, test files)
- Go: testing package (check *_test.go files)

## File Modifications

### Create

**Workflow Files (ace-taskflow/handbook/workflow-instructions/):**
- `fix-tests.wf.md`
  - Purpose: Migrate fix-tests workflow with YAML front matter
  - Key components: Framework detection, iterative fixing process, embedded templates
  - Dependencies: ace-nav, project test framework

- `create-test-cases.wf.md`
  - Purpose: Migrate test case creation workflow
  - Key components: Test scenario identification, embedded test case template
  - Dependencies: ace-nav, test case template

- `improve-code-coverage.wf.md`
  - Purpose: Migrate coverage improvement workflow
  - Key components: Coverage analysis, test gap identification, task creation
  - Dependencies: ace-nav, coverage tools

**Claude Command Files (.claude/commands/ace/):**
- `fix-tests.md`
  - Purpose: Thin wrapper to fix-tests workflow
  - Content: `read and run \`ace-nav wfi://fix-tests\``
  - Metadata: allowed-tools, description, argument-hint

- `create-test-cases.md`
  - Purpose: Thin wrapper to create-test-cases workflow
  - Content: `read and run \`ace-nav wfi://create-test-cases\``
  - Metadata: allowed-tools, description, argument-hint

- `improve-code-coverage.md`
  - Purpose: Thin wrapper to improve-code-coverage workflow
  - Content: `read and run \`ace-nav wfi://improve-code-coverage\``
  - Metadata: allowed-tools, description, argument-hint

**UX Documentation:**
- `ux/usage.md` ✅ (already created)
  - Purpose: User guide for Claude commands
  - Key sections: Command types, usage scenarios, migration notes
  - Emphasizes: Claude commands as thin wrappers to workflows

### Modify

- None

### Delete

- None (legacy workflows remain for backward compatibility)

## Risk Assessment

### Technical Risks

- **Risk:** Workflow dependencies on project-specific tools
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Implement dynamic framework detection in workflows
  - **Rollback:** Use legacy workflows if framework not detected

- **Risk:** Template embedding complexity with ADR-002 XML format
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Follow ADR-002 strictly, validate XML structure
  - **Rollback:** Use external templates if embedding fails

- **Risk:** Path reference issues across environments
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Use relative paths and ace-nav protocol exclusively
  - **Rollback:** Update paths to absolute if relative fails

### Integration Risks

- **Risk:** Users confusing Claude commands with CLI tools
  - **Probability:** High
  - **Impact:** Medium
  - **Mitigation:** Clear documentation in usage.md and command descriptions
  - **Monitoring:** User feedback on command usage patterns

- **Risk:** Framework detection fails for unknown test frameworks
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Fallback to generic test commands, clear error messages
  - **Monitoring:** Track framework detection failures

### Performance Risks

- **Risk:** Workflow execution overhead from ace-nav delegation
  - **Mitigation:** Benchmark workflow execution time
  - **Monitoring:** Track workflow response times
  - **Thresholds:** < 2s for workflow load, < 10s for execution

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work.*

### Planning Steps

*Research and analysis activities to clarify the approach before implementation begins.*

- [x] Analyze existing test workflows and their dependencies
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All four workflows analyzed for structure, dependencies, and templates
  > Command: # Verify workflows: fix-tests, create-test-cases, improve-code-coverage, fix-linting-issue-from

- [x] Research testing framework detection patterns across languages
  > TEST: Framework Detection Research
  > Type: Analysis Validation
  > Assert: Detection patterns identified for Ruby, JavaScript, Python, Go
  > Command: # Verify Gemfile, package.json, requirements.txt, *_test.go patterns documented

- [x] Design workflow self-containment strategy per ADR-001
  > TEST: Self-Containment Design
  > Type: Architecture Validation
  > Assert: Template embedding plan using ADR-002 XML format, no external dependencies
  > Command: # Verify XML template structure and workflow independence

- [x] Analyze task 048 roadmap migration pattern
  > TEST: Migration Pattern Analysis
  > Type: Reference Implementation Review
  > Assert: Three-layer architecture understood (workflow → Claude command → CLI)
  > Command: # Review update-roadmap.wf.md and .claude/commands/ace/update-roadmap.md

- [x] Design CLI command structure following ace-taskflow patterns
  > TEST: CLI Design Validation
  > Type: Architecture Review
  > Assert: Test subcommand design matches existing task/release/idea patterns
  > Command: # Review ace-taskflow/lib/ace/taskflow/cli.rb structure

### Execution Steps

*Concrete implementation actions that modify code, create files, or change the system state.*

- [x] Migrate fix-tests workflow to ace-taskflow/handbook/workflow-instructions/
  - Copy from dev-handbook/workflow-instructions/fix-tests.wf.md
  - Add YAML front matter (name, allowed-tools, description, argument-hint)
  - Update context loading: `ace-nav wfi://load-project-context`
  - Embed necessary templates using ADR-002 XML format
  - Add framework detection logic (RSpec, Jest, pytest, Go testing)
  - Update all internal paths to be relative to project root
  > TEST: Workflow Migration Validation
  > Type: Content Validation
  > Assert: Workflow self-contained, discoverable via ace-nav wfi://fix-tests
  > Command: ace-nav wfi://fix-tests --verify

- [x] Migrate create-test-cases workflow to ace-taskflow/handbook/workflow-instructions/
  - Copy from dev-handbook/workflow-instructions/create-test-cases.wf.md
  - Add YAML front matter metadata
  - Update context loading to use ace-nav protocol
  - Embed test case template using XML <documents><template> format
  - Update test implementation examples for multiple frameworks
  > TEST: Workflow Migration Validation
  > Type: Content Validation
  > Assert: Workflow self-contained, test case template embedded
  > Command: ace-nav wfi://create-test-cases --verify

- [x] Migrate improve-code-coverage workflow to ace-taskflow/handbook/workflow-instructions/
  - Copy from dev-handbook/workflow-instructions/improve-code-coverage.wf.md
  - Add YAML front matter metadata
  - Update context loading references
  - Embed coverage analysis templates using XML format
  - Update coverage tool references (SimpleCov, Jest coverage, pytest-cov)
  > TEST: Workflow Migration Validation
  > Type: Content Validation
  > Assert: Workflow self-contained, coverage templates embedded
  > Command: ace-nav wfi://improve-code-coverage --verify

- [x] Create Claude command for fix-tests
  - Create .claude/commands/ace/fix-tests.md
  - Add YAML front matter: description, allowed-tools, argument-hint
  - Add command body: `read and run \`ace-nav wfi://fix-tests\``
  - Document: "IMPORTANT: Claude-only command, not runnable from bash"
  > TEST: Command Integration
  > Type: Integration Validation
  > Assert: Command file exists, references wfi://fix-tests protocol
  > Command: cat .claude/commands/ace/fix-tests.md | grep "wfi://fix-tests"

- [x] Create Claude command for create-test-cases
  - Create .claude/commands/ace/create-test-cases.md
  - Add YAML front matter metadata
  - Add command body: `read and run \`ace-nav wfi://create-test-cases\``
  - Document Claude-only usage
  > TEST: Command Integration
  > Type: Integration Validation
  > Assert: Command file exists, references wfi://create-test-cases protocol
  > Command: cat .claude/commands/ace/create-test-cases.md | grep "wfi://create-test-cases"

- [x] Create Claude command for improve-code-coverage
  - Create .claude/commands/ace/improve-code-coverage.md
  - Add YAML front matter metadata
  - Add command body: `read and run \`ace-nav wfi://improve-code-coverage\``
  - Document Claude-only usage
  > TEST: Command Integration
  > Type: Integration Validation
  > Assert: Command file exists, references wfi://improve-code-coverage protocol
  > Command: cat .claude/commands/ace/improve-code-coverage.md | grep "wfi://improve-code-coverage"

- [x] Validate all workflows are discoverable via ace-nav
  - Test fix-tests workflow discovery
  - Test create-test-cases workflow discovery
  - Test improve-code-coverage workflow discovery
  - Verify wfi:// protocol resolution
  > TEST: Workflow Discovery
  > Type: Integration Validation
  > Assert: All workflows discoverable through ace-nav wfi:// protocol
  > Command: ace-nav 'wfi://*test*' --list | grep -E "(fix-tests|create-test-cases|improve-code-coverage)"

- [x] Validate workflow self-containment per ADR-001
  - Verify no external workflow dependencies except core docs
  - Check all templates embedded using XML format
  - Confirm context loading uses ace-nav protocol
  - Validate relative path usage throughout
  > TEST: Self-Containment Validation
  > Type: Compliance Check
  > Assert: Workflows self-contained, templates embedded, no external deps
  > Command: # Manual review of workflows against ADR-001 checklist

- [x] Test Claude commands invoke workflows correctly
  - Test /ace:fix-tests command execution
  - Test /ace:create-test-cases command execution
  - Test /ace:improve-code-coverage command execution
  > TEST: Command Execution
  > Type: End-to-End Validation
  > Assert: All Claude commands successfully invoke their workflows
  > Command: # Test each command in Claude Code environment

## Acceptance Criteria

- [x] AC 1: UX/usage documentation created at `ux/usage.md` for Claude commands
- [x] AC 2: Three workflow files migrated to `ace-taskflow/handbook/workflow-instructions/`
- [x] AC 3: All workflows self-contained with embedded templates (ADR-002 XML format)
- [x] AC 4: Three Claude command files created in `.claude/commands/ace/`
- [x] AC 5: All Claude commands correctly reference `ace-nav wfi://[workflow-name]`
- [x] AC 6: Workflows discoverable via `ace-nav wfi://` protocol
- [x] AC 7: Commands are thin wrappers to workflows (no CLI tools)
- [x] AC 8: No external dependencies except core docs (ADR-001 compliance)
- [x] AC 9: Framework detection logic included for multiple test frameworks
- [x] AC 10: All workflows validated against self-containment principle
- [x] AC 11: Migration follows task 048 two-layer architecture pattern (workflows + commands)

## References

- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/fix-tests.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-test-cases.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/improve-code-coverage.wf.md`
- Template: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`
- Task 052: `ace-handbook` package creation (for linting workflows migration)
