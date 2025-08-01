---
id: v.0.4.0+task.017
status: pending
priority: high
estimate: 4h
dependencies: []
needs_review: true
---

# Add task-manager create subcommand

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] Should we remove create-path task-new immediately or maintain it for backward compatibility during a transition period?
  - **Research conducted**: Found user note in idea file stating "just gone (we are prealpha, we can break the api)"
  - **Suggested default**: Remove immediately as we're pre-alpha
  - **Why needs human input**: This contradicts the task specification which mentions "backwards compatibility maintained"

- [ ] Should the old implementation in CreatePathCommand be fully deleted or just the task-new case?
  - **Research conducted**: CreatePathCommand handles multiple types (file, directory, docs-new, template)
  - **Suggested default**: Only remove task-new case, keep other functionality
  - **Why needs human input**: User note says "ensure we delete the old implementation" - unclear if entire class or just task-new

### [MEDIUM] Enhancement Questions
- [ ] Should task-manager create use release-manager for path resolution as mentioned in the idea?
  - **Research conducted**: Currently create-path uses PathResolver and nav-path integration
  - **Suggested default**: Use ReleasePathManager for consistency with other task-manager commands
  - **Why needs human input**: Architecture decision that affects dependency structure

- [ ] How should we handle the migration of dynamic flag handling feature (task 015)?
  - **Research conducted**: Task 015 enables create-path task-new to accept undefined flags
  - **Suggested default**: Implement same capability in task-manager create
  - **Why needs human input**: Feature is still pending, affects implementation approach

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
- **Code Reuse**: Leverage existing create-path task-new functionality through delegation
- **ATOM Integration**: Create new CLI command class in organisms layer, delegate to existing molecules
- **Backwards Compatibility**: Maintain create-path task-new during transition period

### Technology Stack
- **CLI Framework**: dry-cli (already in use by task-manager)
- **Implementation Pattern**: Command delegation to existing CreatePathCommand
- **File Operations**: Reuse existing FileIoHandler and PathResolver molecules
- **Configuration**: Extend task-manager configuration if needed

### Implementation Strategy
- **Phase 1**: Create new task-manager create command that delegates to create-path
- **Phase 2**: Add command to task-manager registry and executable
- **Phase 3**: Test integration and validate identical functionality
- **Phase 4**: Update documentation and help text

## Tool Selection

| Criteria | create-path delegation | Direct implementation | Selected |
|----------|------------------------|----------------------|----------|
| Development Speed | Excellent | Fair | create-path delegation |
| Code Consistency | Excellent | Good | create-path delegation |
| Maintenance | Good | Fair | create-path delegation |
| Risk Level | Low | Medium | create-path delegation |

**Selection Rationale:** Delegating to existing create-path task-new functionality ensures identical behavior, reduces development time, and minimizes risk of introducing bugs. This approach allows immediate user benefit while providing foundation for future consolidation.

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
  - Purpose: New CLI command class that delegates to create-path task-new
  - Key components: Dry::CLI::Command subclass with identical interface
  - Dependencies: Existing CreatePathCommand, standard CLI patterns

### Modify
- `dev-tools/exe/task-manager`
  - Changes: Add require statement for new create command
  - Impact: Loads new command class for registry
  - Integration points: Existing CLI command loading pattern

- `dev-tools/exe/task-manager` (registry section)
  - Changes: Add "create" command registration to TaskManagerCli::Commands
  - Impact: Makes create subcommand available in task-manager CLI
  - Integration points: Existing command registry pattern

### Delete/Remove (if breaking change approved)
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

* [ ] Analyze existing create-path task-new command interface and behavior
  > TEST: Interface Analysis Complete
  > Type: Pre-condition Check
  > Assert: All CLI options, arguments, and behaviors documented
  > Command: grep -r "option\|argument" dev-tools/lib/coding_agent_tools/cli/create_path_command.rb
* [ ] Review task-manager CLI command patterns and registry structure
* [ ] Plan CLI command class structure following ATOM architecture

### Execution Steps

- [ ] Create new CLI command class at dev-tools/lib/coding_agent_tools/cli/commands/task/create.rb
  > TEST: Command Class Created
  > Type: Action Validation
  > Assert: File exists with proper class structure and dry-cli inheritance
  > Command: test -f dev-tools/lib/coding_agent_tools/cli/commands/task/create.rb
- [ ] Implement command class with identical interface to create-path task-new
  > TEST: Interface Compatibility
  > Type: Functional Validation
  > Assert: All create-path task-new options available in task-manager create
  > Command: task-manager create --help | grep -E "title|priority|estimate|status"
- [ ] Add delegation logic to call existing CreatePathCommand functionality
  > TEST: Delegation Working
  > Type: Integration Validation
  > Assert: task-manager create produces same results as create-path task-new
  > Command: task-manager create --title "test-task" --priority high
- [ ] Add require statement for create command in task-manager executable
  > TEST: Command Loading
  > Type: Action Validation
  > Assert: No require errors when starting task-manager
  > Command: task-manager --help | grep -q "create"
- [ ] Register create command in TaskManagerCli::Commands registry
  > TEST: Command Registration
  > Type: Integration Validation
  > Assert: create command appears in task-manager help output
  > Command: task-manager --help | grep -A5 -B5 "create"
- [ ] Create comprehensive unit tests for create command
  > TEST: Test Coverage
  > Type: Quality Validation
  > Assert: All create command scenarios covered by tests
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/task/create_spec.rb
- [ ] Run integration tests to verify identical behavior
  > TEST: Behavioral Equivalence
  > Type: Integration Validation
  > Assert: task-manager create and create-path task-new produce identical results
  > Command: diff <(task-manager create --title "test1" --priority high 2>&1) <(create-path task-new --title "test1" --priority high 2>&1)
- [ ] Update task-manager help text and documentation
  > TEST: Documentation Updated
  > Type: Quality Validation
  > Assert: create command documented in help and tools reference
  > Command: task-manager --help | grep -A3 "create.*Create new task"

## Acceptance Criteria

- [ ] AC 1: task-manager create command available and listed in help output
- [ ] AC 2: All create-path task-new functionality preserved in task-manager create
- [ ] AC 3: Identical command-line interface (arguments, options, output format)
- [ ] AC 4: All existing task-manager commands continue to work unchanged
- [ ] AC 5: Comprehensive test coverage for new create command
- [ ] AC 6: No breaking changes to existing functionality

## Out of Scope

- ❌ **Removing create-path task-new**: Backwards compatibility maintained for transition period
- ❌ **Configuration Migration**: Will use existing .coding-agent/path.yml for consistency
- ❌ **Command Aliases**: tm create shorthand not included in initial implementation
- ❌ **UI/UX Changes**: Command behavior and output format remain identical

## References

- Original idea file: dev-taskflow/backlog/ideas/20250731-0828-task-create-migrate.md
- Existing create-path task-new command behavior and implementation
- Task-manager CLI architecture and subcommand patterns
- ATOM architecture principles for dev-tools Ruby gem
- Dry-CLI command patterns in existing task commands

## Review Summary

**Questions Generated:** 4 total (2 high, 2 medium)
**Critical Blockers:** 
1. Backward compatibility vs immediate removal decision
2. Scope of CreatePathCommand deletion

**Implementation Readiness:** Blocked on answers - significant scope differences between maintaining compatibility vs breaking change

**Recommended Next Steps:** 
1. Clarify breaking change approach (immediate removal vs transition)
2. Define exact scope of what to delete from CreatePathCommand
3. Decide on ReleasePathManager vs PathResolver for path generation
4. Coordinate with task 015 (dynamic flag handling) implementation

**Additional Findings:**
- Comprehensive documentation updates needed (33+ files)
- Test suite modifications required (4 spec files)
- Workflow instruction updates needed (4 files)
- nav-path command also needs updates to remove task-new support