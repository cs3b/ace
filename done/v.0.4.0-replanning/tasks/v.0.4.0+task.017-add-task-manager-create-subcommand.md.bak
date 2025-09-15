---
id: v.0.4.0+task.017
status: done
priority: high
estimate: 4h
dependencies: []
---

# Add task-manager create subcommand

## Review Questions (Resolved)

### [HIGH] Critical Implementation Questions
- [x] Should we remove create-path task-new immediately or maintain it for backward compatibility during a transition period?
  - **Research conducted**: Found user note in idea file stating "just gone (we are prealpha, we can break the api)"
  - **Suggested default**: Remove immediately as we're pre-alpha
  - **Why needs human input**: This contradicts the task specification which mentions "backwards compatibility maintained"

  > remove and update docs, and anything that is it in the code to the new tool

- [x] Should the old implementation in CreatePathCommand be fully deleted or just the task-new case?
  - **Research conducted**: CreatePathCommand handles multiple types (file, directory, docs-new, template)
  - **Suggested default**: Only remove task-new case, keep other functionality
  - **Why needs human input**: User note says "ensure we delete the old implementation" - unclear if entire class or just task-new

  > only crate-path task-new (the rest of the create-path stays as it is)

### [MEDIUM] Enhancement Questions  
- [x] Should task-manager create use release-manager for path resolution as mentioned in the idea?
  - **Research conducted**: Currently create-path uses PathResolver and nav-path integration
  - **Suggested default**: Use ReleasePathManager for consistency with other task-manager commands
  - **Why needs human input**: Architecture decision that affects dependency structure

  > yes, definitely

- [x] How should we handle the migration of dynamic flag handling feature (task 015)?
  - **Research conducted**: Task 015 enables create-path task-new to accept undefined flags
  - **Suggested default**: Implement same capability in task-manager create
  - **Why needs human input**: Feature is still pending, affects implementation approach

  > this the feature that should be moved to task-manager create (we should be able to use dynamic tags, exactly as it was implemented in #15 but in the new part of the system). the implementation of dynamic flags from create-path should be removed (it stays only in context of task-manager create)

## Behavioral Specification

### User Experience
- **Input**: Users provide task title and optional metadata (priority, estimate, status) via command line arguments
- **Process**: Users experience immediate task creation with clear feedback about the created task file location and ID
- **Output**: Users receive confirmation of task creation with the full path to the created task file

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

Developers and AI agents can create new tasks using an intuitive, discoverable command under the task-manager CLI tool. The command provides the same functionality as the existing create-path task-new command but with better discoverability and consistent command organization. Users experience seamless task creation with automatic ID generation, proper template application, and immediate feedback about the created task.

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# CLI Interface
task-manager create --title "Task Title" [--priority high|medium|low] [--estimate TBD] [--status draft]

# Expected outputs
# Success: "File created successfully\nCreated: /path/to/task/file.md"
# Error: Clear error messages for missing title, invalid priority, etc.
# Status codes: 0 for success, 1 for error

# Command behavior identical to create-path task-new
# - Automatic task ID generation and sequencing
# - Template application with behavioral specification structure
# - File creation in current release task directory
# - Validation of required arguments
```

**Error Handling:**
- Missing --title argument: Display clear error message "Error: --title is required for task creation"
- Invalid priority value: Display error with valid options "Error: Priority must be one of: high, medium, low"
- File system errors: Display helpful error message with suggestion to check permissions

**Edge Cases:**
- Duplicate task titles: Allow creation with unique IDs, warn user about potential duplication
- Very long titles: Truncate filename but preserve full title in task content
- Special characters in title: Sanitize filename while preserving original title in metadata

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Command Discoverability**: task-manager create command is available and listed in task-manager --help output
- [ ] **Functional Parity**: All functionality from create-path task-new is preserved in the new command
- [ ] **User Experience Consistency**: Command follows same argument patterns and output format as existing task-manager subcommands

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [ ] **Configuration Migration**: Should the new command use .coding-agent/task-manager.yml instead of .coding-agent/path.yml for configuration?
- [ ] **Backward Compatibility**: How long should we maintain create-path task-new before complete removal?
- [ ] **Command Aliases**: Should we provide short aliases like 'tm create' for frequently used commands?
- [ ] **Integration Testing**: How will we validate that all existing workflows continue to work with the new command?

## Objective

Improve the discoverability and intuitive nature of task creation by moving the functionality to the logical home under task-manager. This reduces cognitive overhead for users trying to create tasks and provides a more consistent command structure that aligns with user expectations. The change specifically addresses the problem that create-path is primarily associated with file/directory creation, not task management.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Command line task creation workflow for developers and AI agents using task-manager create
- **System Behavior Scope**: Task file creation, ID generation, template application, validation, and user feedback
- **Interface Scope**: New task-manager create subcommand with identical functionality to create-path task-new

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- User experience flow definitions
- System behavior specifications
- Interface contract definitions

#### Validation Artifacts
- Success criteria validation methods
- User acceptance criteria
- Behavioral test scenarios

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: File structures, code organization, technical architecture
- ❌ **Technology Decisions**: Tool selections, library choices, framework decisions
- ❌ **Performance Optimization**: Specific performance improvement strategies
- ❌ **Future Enhancements**: Related features or capabilities not in current scope

## Technical Approach

### Architecture Pattern
- **CLI Command Extension**: Add new subcommand to existing task-manager CLI using dry-cli registry pattern
- **Direct Implementation**: Implement task creation logic directly in task-manager, no delegation
- **ATOM Integration**: Create new CLI command class in organisms layer, use ReleasePathManager
- **Breaking Change**: Remove create-path task-new immediately (pre-alpha status allows this)

### Technology Stack
- **CLI Framework**: dry-cli (already in use by task-manager)
- **Implementation Pattern**: Direct implementation with ReleasePathManager
- **File Operations**: Use existing FileIoHandler and TemplateRenderer molecules
- **Path Resolution**: Use ReleasePathManager instead of PathResolver
- **Dynamic Flags**: Migrate dynamic flag handling from task 015 implementation

### Implementation Strategy
- **Phase 1**: Implement task-manager create with dynamic flag handling
- **Phase 2**: Remove create-path task-new functionality
- **Phase 3**: Update all documentation and workflow references
- **Phase 4**: Update test suites to reflect new command structure

## Tool Selection

| Criteria | create-path delegation | Direct implementation | Selected |
|----------|------------------------|----------------------|----------|
| Development Speed | Good | Good | Direct implementation |
| Code Consistency | Poor (two places) | Excellent | Direct implementation |
| Maintenance | Poor (duplication) | Excellent | Direct implementation |
| Risk Level | Low | Low | Direct implementation |
| Path Resolution | PathResolver | ReleasePathManager | Direct implementation |

**Selection Rationale:** Direct implementation eliminates code duplication, uses consistent ReleasePathManager for path resolution (matching other task-manager commands), and allows proper integration of dynamic flag handling. Pre-alpha status permits breaking changes.

### Dependencies
- **No new dependencies**: Reuses existing dry-cli, create-path infrastructure
- **Compatibility verified**: All existing gems and versions remain unchanged

## File Modifications

### [Review Note] Comprehensive Scope Analysis
Based on research, the following additional files need modification:
- **Documentation updates** (33 files reference create-path task-new)
- **Test files**: 4 spec files test create-path behavior
- **Workflow instructions**: 4 workflow files use create-path task-new
- **Related systems**: nav-path command also recognizes task-new type

### Create
- `dev-tools/lib/coding_agent_tools/cli/commands/task/create.rb`
  - Purpose: New CLI command class implementing task creation logic
  - Key components: Dry::CLI::Command subclass with dynamic flag handling
  - Dependencies: ReleasePathManager, FileIoHandler, TemplateRenderer

### Modify
- `dev-tools/exe/task-manager`
  - Changes: Add require statement for new create command
  - Impact: Loads new command class for registry
  - Integration points: Existing CLI command loading pattern

- `dev-tools/exe/task-manager` (registry section)
  - Changes: Add "create" command registration to TaskManagerCli::Commands
  - Impact: Makes create subcommand available in task-manager CLI
  - Integration points: Existing command registry pattern

### Delete/Remove
- `dev-tools/lib/coding_agent_tools/cli/create_path_command.rb`
  - Changes: Remove 'task-new' case from switch statement (lines 201-202)
  - Impact: Breaking change - create-path task-new will no longer work
  - Migration: Users must use task-manager create instead

- `dev-tools/lib/coding_agent_tools/cli/commands/nav/path.rb`
  - Changes: Remove 'task-new', 'task_new' cases (lines 36-37)
  - Impact: nav-path task-new will no longer generate new paths
  - Migration: Not needed - nav-path should only find existing tasks

### Update Documentation
- `docs/tools.md`: Update all examples using create-path task-new
- `dev-tools/docs/tools.md`: Update CLI tool reference
- `dev-handbook/workflow-instructions/*.wf.md`: Update 4 workflow files
- `dev-taskflow/` various task files: Update references in documentation

### Test Coverage
- `dev-tools/spec/coding_agent_tools/cli/commands/task/create_spec.rb`
  - Purpose: Unit tests for new create command
  - Key components: Test identical behavior to create-path task-new
  - Dependencies: Existing test patterns and fixtures

### Update Existing Tests
- `dev-tools/spec/coding_agent_tools/cli/commands/create_path_spec.rb`
  - Changes: Remove tests for task-new functionality
  - Impact: Ensures create-path doesn't support task-new anymore

- `dev-tools/spec/coding_agent_tools/cli/commands/nav/path_spec.rb`
  - Changes: Remove tests for task-new path type
  - Impact: Ensures nav-path doesn't generate task-new paths

## Risk Assessment

### Technical Risks
- **Risk:** CLI argument parsing differences between commands
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Direct delegation ensures identical argument handling
  - **Rollback:** Remove command registration, no breaking changes

- **Risk:** Integration conflicts with existing task-manager commands
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Follow established patterns, comprehensive testing
  - **Rollback:** Simple removal from registry

### Integration Risks
- **Risk:** User confusion between create-path task-new and task-manager create
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Clear documentation, identical functionality
  - **Monitoring:** User feedback and support requests

## Implementation Plan

### Planning Steps

* [x] Analyze existing create-path task-new command interface and behavior
  > TEST: Interface Analysis Complete
  > Type: Pre-condition Check
  > Assert: All CLI options, arguments, and behaviors documented
  > Command: grep -r "option\|argument" dev-tools/lib/coding_agent_tools/cli/create_path_command.rb
* [x] Review task-manager CLI command patterns and registry structure
* [x] Plan CLI command class structure following ATOM architecture

### Execution Steps

- [x] Create new CLI command class at dev-tools/lib/coding_agent_tools/cli/commands/task/create.rb
  > TEST: Command Class Created
  > Type: Action Validation
  > Assert: File exists with proper class structure and dry-cli inheritance
  > Command: test -f dev-tools/lib/coding_agent_tools/cli/commands/task/create.rb
- [x] Implement task creation logic with ReleasePathManager integration
  > TEST: Path Resolution Working
  > Type: Functional Validation
  > Assert: Task files created in correct release directory
  > Command: task-manager create --title "test-task" && ls -la dev-taskflow/current/*/tasks/
- [x] Add dynamic flag handling to accept arbitrary metadata flags
  > TEST: Dynamic Flags Working
  > Type: Integration Validation
  > Assert: Undefined flags become task metadata
  > Command: task-manager create --title "test-task" --custom-field "value" --another "test"
- [x] Add require statement for create command in task-manager executable
  > TEST: Command Loading
  > Type: Action Validation
  > Assert: No require errors when starting task-manager
  > Command: task-manager --help | grep -q "create"
- [x] Register create command in TaskManagerCli::Commands registry
  > TEST: Command Registration
  > Type: Integration Validation
  > Assert: create command appears in task-manager help output
  > Command: task-manager --help | grep -A5 -B5 "create"
- [x] Create comprehensive unit tests for create command
  > TEST: Test Coverage
  > Type: Quality Validation
  > Assert: All create command scenarios covered by tests
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/task/create_spec.rb
- [x] Run integration tests to verify identical behavior
  > TEST: Behavioral Equivalence
  > Type: Integration Validation
  > Assert: task-manager create and create-path task-new produce identical results
  > Command: diff <(task-manager create --title "test1" --priority high 2>&1) <(create-path task-new --title "test1" --priority high 2>&1)
- [x] Remove create-path task-new functionality from CreatePathCommand
  > TEST: Task-New Removed
  > Type: Functional Validation
  > Assert: create-path task-new returns error
  > Command: create-path task-new --title "test" 2>&1 | grep -E "Unknown|Invalid|Error"
- [x] Remove nav-path task-new path generation capability
  > TEST: Nav-Path Updated
  > Type: Functional Validation
  > Assert: nav-path task-new only finds existing tasks
  > Command: nav-path task-new "test" 2>&1 | grep -v "Creating"
- [x] Update all documentation files to use task-manager create
  > TEST: Documentation Updated
  > Type: Quality Validation
  > Assert: No references to create-path task-new remain
  > Command: grep -r "create-path task-new" docs/ dev-handbook/ dev-taskflow/ | wc -l
- [x] Update workflow instructions to use new command
  > TEST: Workflows Updated
  > Type: Quality Validation
  > Assert: All workflows use task-manager create
  > Command: grep -r "task-manager create" dev-handbook/workflow-instructions/*.wf.md | wc -l

## Acceptance Criteria

- [x] AC 1: task-manager create command available and listed in help output
- [x] AC 2: All create-path task-new functionality preserved in task-manager create
- [x] AC 3: Identical command-line interface (arguments, options, output format)
- [x] AC 4: All existing task-manager commands continue to work unchanged
- [x] AC 5: Comprehensive test coverage for new create command
- [x] AC 6: No breaking changes to existing functionality

## Out of Scope

- ❌ **Maintaining create-path task-new**: Breaking change - command will be removed
- ❌ **Configuration Migration from path.yml**: Will use task-manager.yml configuration
- ❌ **Command Aliases**: tm create shorthand not included in initial implementation
- ❌ **Gradual Migration**: No transition period - immediate removal

## References

- Original idea file: dev-taskflow/backlog/ideas/20250731-0828-task-create-migrate.md
- Existing create-path task-new command behavior and implementation
- Task-manager CLI architecture and subcommand patterns
- ATOM architecture principles for dev-tools Ruby gem
- Dry-CLI command patterns in existing task commands

## Review Summary

**Questions Resolved:** All 4 questions answered
**Implementation Approach Clarified:**
1. Breaking change approved - remove create-path task-new immediately
2. Only remove task-new case from CreatePathCommand
3. Use ReleasePathManager for path resolution
4. Migrate dynamic flag handling to task-manager create

**Implementation Readiness:** Ready to proceed with clear direction

**Updated Implementation Plan:**
1. Direct implementation in task-manager (no delegation)
2. Remove create-path task-new functionality completely
3. Use ReleasePathManager for consistent path resolution
4. Include dynamic flag handling from task 015

**Comprehensive Scope Confirmed:**
- Documentation updates needed (33+ files)
- Test suite modifications required (4 spec files)  
- Workflow instruction updates needed (4 files)
- nav-path command updates to remove task-new support
- Dynamic flag handling migration from create-path
