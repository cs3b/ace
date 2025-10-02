---
id: v.0.9.0+task.049
status: pending
priority: high
estimate: 12h
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
- ❌ **Ruby CLI Implementation**: Full `ace-taskflow test` command implementation (deferred to future task)

## Technical Approach

### Three-Layer Architecture

**IMPORTANT DISTINCTION:** This migration implements a clear separation between Claude commands and CLI tools:

**Layer 1: Workflows** (.wf.md files)
- Self-contained workflow instructions in `ace-taskflow/handbook/workflow-instructions/`
- Discoverable via `ace-nav wfi://` protocol
- Core logic shared by both Claude commands and CLI tools

**Layer 2: Claude Commands** (.claude/commands/ace/)
- Bridge files that invoke workflows via `ace-nav wfi://`
- **ONLY executable from Claude Code/agents**
- **NOT runnable from bash command line**
- Examples: `/ace:fix-tests`, `/ace:create-test-cases`

**Layer 3: CLI Tools** (ace-taskflow gem - future)
- Direct bash commands: `ace-taskflow test fix`, `ace-taskflow test create`
- **Executable from terminal/shell**
- Delegate to same workflows via `ace-nav wfi://`
- For automation, scripts, and CI/CD integration

### Architecture Pattern

Following task 048 roadmap migration pattern:

1. **Workflow Migration:**
   - Copy workflows from `dev-handbook/` to `ace-taskflow/handbook/`
   - Update internal references to use relative paths
   - Embed templates using ADR-002 XML format
   - Update context loading to use `ace-nav wfi://` protocol

2. **Claude Command Integration:**
   - Create `.claude/commands/ace/*.md` files
   - Each command calls `ace-nav wfi://[workflow-name]`
   - Set appropriate allowed-tools and descriptions
   - **Document that these are Claude-only commands**

3. **CLI Integration (Future):**
   - Add `test` subcommand to `ace-taskflow/lib/ace/taskflow/cli.rb`
   - Create `test_command.rb` with sub-commands (fix, create, coverage, lint)
   - Delegate to workflows via `ace-nav wfi://` protocol

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

- `fix-linting-issue-from.wf.md`
  - Purpose: Migrate linting fix workflow
  - Key components: Linter output parsing, automated fixes, validation
  - Dependencies: ace-nav, project linter

**Claude Command Files (.claude/commands/ace/):**
- `fix-tests.md`
  - Purpose: Bridge to fix-tests workflow
  - Content: `read and run \`ace-nav wfi://fix-tests\``
  - Metadata: allowed-tools, description, argument-hint

- `create-test-cases.md`
  - Purpose: Bridge to create-test-cases workflow
  - Content: `read and run \`ace-nav wfi://create-test-cases\``
  - Metadata: allowed-tools, description, argument-hint

- `improve-code-coverage.md`
  - Purpose: Bridge to improve-code-coverage workflow
  - Content: `read and run \`ace-nav wfi://improve-code-coverage\``
  - Metadata: allowed-tools, description, argument-hint

- `fix-linting-issue-from.md`
  - Purpose: Bridge to fix-linting-issue-from workflow
  - Content: `read and run \`ace-nav wfi://fix-linting-issue-from\``
  - Metadata: allowed-tools, description, argument-hint

**UX Documentation:**
- `ux/usage.md` ✅ (already created)
  - Purpose: User guide distinguishing Claude commands vs CLI tools
  - Key sections: Command types, usage scenarios, migration notes
  - Emphasizes: Claude-only vs bash-runnable distinction

### Modify

- `ace-taskflow/lib/ace/taskflow/cli.rb` (future - out of current scope)
  - Changes: Add `when "test"` case to route to test command
  - Impact: Enables `ace-taskflow test <subcommand>` CLI access
  - Integration: Delegates to Commands::TestCommand.new.execute(args)

### Delete

- None (legacy workflows remain for backward compatibility)

### Command Structure Reference

```ruby
# Future CLI routing (not in current scope)
when "test"
  require_relative "commands/test_command"
  Commands::TestCommand.new.execute(args)
```

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

- [ ] Migrate fix-tests workflow to ace-taskflow/handbook/workflow-instructions/
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

- [ ] Migrate create-test-cases workflow to ace-taskflow/handbook/workflow-instructions/
  - Copy from dev-handbook/workflow-instructions/create-test-cases.wf.md
  - Add YAML front matter metadata
  - Update context loading to use ace-nav protocol
  - Embed test case template using XML <documents><template> format
  - Update test implementation examples for multiple frameworks
  > TEST: Workflow Migration Validation
  > Type: Content Validation
  > Assert: Workflow self-contained, test case template embedded
  > Command: ace-nav wfi://create-test-cases --verify

- [ ] Migrate improve-code-coverage workflow to ace-taskflow/handbook/workflow-instructions/
  - Copy from dev-handbook/workflow-instructions/improve-code-coverage.wf.md
  - Add YAML front matter metadata
  - Update context loading references
  - Embed coverage analysis templates using XML format
  - Update coverage tool references (SimpleCov, Jest coverage, pytest-cov)
  > TEST: Workflow Migration Validation
  > Type: Content Validation
  > Assert: Workflow self-contained, coverage templates embedded
  > Command: ace-nav wfi://improve-code-coverage --verify

- [ ] Migrate fix-linting-issue-from workflow to ace-taskflow/handbook/workflow-instructions/
  - Copy from dev-handbook/workflow-instructions/fix-linting-issue-from.wf.md
  - Add YAML front matter metadata
  - Update context loading references
  - Add linter format detection (StandardRB, ESLint, Rubocop, Pylint)
  - Embed error file format templates using XML
  > TEST: Workflow Migration Validation
  > Type: Content Validation
  > Assert: Workflow self-contained, linter format templates embedded
  > Command: ace-nav wfi://fix-linting-issue-from --verify

- [ ] Create Claude command for fix-tests
  - Create .claude/commands/ace/fix-tests.md
  - Add YAML front matter: description, allowed-tools, argument-hint
  - Add command body: `read and run \`ace-nav wfi://fix-tests\``
  - Document: "IMPORTANT: Claude-only command, not runnable from bash"
  > TEST: Command Integration
  > Type: Integration Validation
  > Assert: Command file exists, references wfi://fix-tests protocol
  > Command: cat .claude/commands/ace/fix-tests.md | grep "wfi://fix-tests"

- [ ] Create Claude command for create-test-cases
  - Create .claude/commands/ace/create-test-cases.md
  - Add YAML front matter metadata
  - Add command body: `read and run \`ace-nav wfi://create-test-cases\``
  - Document Claude-only usage
  > TEST: Command Integration
  > Type: Integration Validation
  > Assert: Command file exists, references wfi://create-test-cases protocol
  > Command: cat .claude/commands/ace/create-test-cases.md | grep "wfi://create-test-cases"

- [ ] Create Claude command for improve-code-coverage
  - Create .claude/commands/ace/improve-code-coverage.md
  - Add YAML front matter metadata
  - Add command body: `read and run \`ace-nav wfi://improve-code-coverage\``
  - Document Claude-only usage
  > TEST: Command Integration
  > Type: Integration Validation
  > Assert: Command file exists, references wfi://improve-code-coverage protocol
  > Command: cat .claude/commands/ace/improve-code-coverage.md | grep "wfi://improve-code-coverage"

- [ ] Create Claude command for fix-linting-issue-from
  - Create .claude/commands/ace/fix-linting-issue-from.md
  - Add YAML front matter metadata
  - Add command body: `read and run \`ace-nav wfi://fix-linting-issue-from\``
  - Document Claude-only usage
  > TEST: Command Integration
  > Type: Integration Validation
  > Assert: Command file exists, references wfi://fix-linting-issue-from protocol
  > Command: cat .claude/commands/ace/fix-linting-issue-from.md | grep "wfi://fix-linting-issue-from"

- [ ] Validate all workflows are discoverable via ace-nav
  - Test fix-tests workflow discovery
  - Test create-test-cases workflow discovery
  - Test improve-code-coverage workflow discovery
  - Test fix-linting-issue-from workflow discovery
  - Verify wfi:// protocol resolution
  > TEST: Workflow Discovery
  > Type: Integration Validation
  > Assert: All workflows discoverable through ace-nav wfi:// protocol
  > Command: ace-nav 'wfi://*test*' --list | grep -E "(fix-tests|create-test-cases|improve-code-coverage|fix-linting-issue-from)"

- [ ] Validate workflow self-containment per ADR-001
  - Verify no external workflow dependencies except core docs
  - Check all templates embedded using XML format
  - Confirm context loading uses ace-nav protocol
  - Validate relative path usage throughout
  > TEST: Self-Containment Validation
  > Type: Compliance Check
  > Assert: Workflows self-contained, templates embedded, no external deps
  > Command: # Manual review of workflows against ADR-001 checklist

- [ ] Test Claude commands invoke workflows correctly
  - Test /ace:fix-tests command execution
  - Test /ace:create-test-cases command execution
  - Test /ace:improve-code-coverage command execution
  - Test /ace:fix-linting-issue-from command execution
  > TEST: Command Execution
  > Type: End-to-End Validation
  > Assert: All Claude commands successfully invoke their workflows
  > Command: # Test each command in Claude Code environment

- [ ] Document CLI implementation plan for future task
  - Document test command structure in implementation notes
  - List required changes to cli.rb
  - Define test_command.rb interface and subcommands
  - Create task outline for ace-taskflow test implementation
  > TEST: Documentation Complete
  > Type: Documentation Validation
  > Assert: CLI implementation roadmap documented for future task
  > Command: # Verify documentation includes CLI routing and command structure

## Acceptance Criteria

- [x] AC 1: UX/usage documentation created at `ux/usage.md` with command type distinctions
- [ ] AC 2: Four workflow files migrated to `ace-taskflow/handbook/workflow-instructions/`
- [ ] AC 3: All workflows self-contained with embedded templates (ADR-002 XML format)
- [ ] AC 4: Four Claude command files created in `.claude/commands/ace/`
- [ ] AC 5: All Claude commands correctly reference `ace-nav wfi://[workflow-name]`
- [ ] AC 6: Workflows discoverable via `ace-nav wfi://` protocol
- [ ] AC 7: Documentation clearly distinguishes Claude commands (agent-only) from CLI tools (bash)
- [ ] AC 8: No external dependencies except core docs (ADR-001 compliance)
- [ ] AC 9: Framework detection logic included for multiple test frameworks
- [ ] AC 10: All workflows validated against self-containment principle
- [ ] AC 11: CLI implementation plan documented for future task
- [ ] AC 12: Migration follows task 048 three-layer architecture pattern

## References

- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/fix-tests.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/create-test-cases.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/improve-code-coverage.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/fix-linting-issue-from.wf.md`
- Template: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`
