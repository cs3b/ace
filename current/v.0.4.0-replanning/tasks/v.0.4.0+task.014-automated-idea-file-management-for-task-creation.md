---
id: v.0.4.0+task.014
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Automated Idea File Management for Task Creation

## Behavioral Specification

### User Experience
- **Input**: AI agents or developers execute draft-task workflow with an idea file path (e.g., `dev-taskflow/backlog/ideas/20250730-2327-auto-commit-ideas.md`)
- **Process**: System creates new task file and automatically moves/renames original idea file to organized location with task-numbered prefix
- **Output**: New draft task created, original idea file moved to `../docs/ideas/` with task number prefix for clear traceability

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

When users create a draft task from an idea file, the system automatically manages the lifecycle of the original idea file to maintain clear traceability and organization. The idea file is moved from its original location in the backlog to a structured location within the current release folder, renamed with the task number prefix to establish permanent linkage between the idea and its resulting task.

Users experience seamless task creation without manual file management overhead, while maintaining complete traceability between ideas and their implementation tasks. The system handles all file operations transparently, ensuring no ideas are lost or orphaned after task creation.

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# Enhanced draft-task workflow integration
# When executing: draft-task dev-taskflow/backlog/ideas/YYYY-MMDD-HHMM-idea-name.md
# System behavior:
# 1. Creates task: dev-taskflow/current/vX.Y.Z-release/tasks/vX.Y.Z+task.NNN-task-title.md
# 2. Moves idea: dev-taskflow/current/vX.Y.Z-release/docs/ideas/NNN-YYYY-MMDD-HHMM-idea-name.md

# Expected outputs:
# - "Draft task created: [task-path]"
# - "Idea file moved: [old-path] -> [new-path]"
# - Task file contains reference to moved idea file

# Integration with create-path tool:
create-path task-new --title "Task Title" --status draft
# Automatically detects if created from idea file context
# Performs file management operations transparently
```

**Error Handling:**
- **Source idea file not found**: Clear error message indicating file path doesn't exist, workflow continues without file operations
- **Destination directory doesn't exist**: Automatically create `../docs/ideas/` directory structure
- **File already exists at destination**: Append version suffix (e.g., `NNN-idea-name-v2.md`) and notify user
- **Insufficient permissions**: Clear error message with suggested resolution, task creation continues

**Edge Cases:**
- **Task number not yet assigned**: Wait for task creation completion before file operations
- **Multiple ideas for same task**: Support multiple idea file references in task metadata
- **Idea file in different release folder**: Support cross-release idea referencing with clear path handling
- **No current release defined**: Default to backlog location with clear notification

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Automated File Organization**: Original idea files are automatically moved and renamed with task number prefix after task creation
- [ ] **Complete Traceability**: Clear linkage between draft tasks and their source idea files through organized file structure
- [ ] **Zero Manual Overhead**: Users create tasks without manual file management, system handles all file operations transparently
- [ ] **Consistent Naming Convention**: All processed idea files follow `NNN-original-filename.md` pattern in `../docs/ideas/` directory
- [ ] **Error Resilience**: File operation failures don't prevent task creation, with clear error reporting and graceful degradation

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [ ] **Current Release Detection**: How should the system determine the "current release folder" path when multiple releases exist?
- [ ] **Task Number Availability**: At what point in the task creation process is the task number available for file renaming?
- [ ] **File Conflict Resolution**: Should existing files be overwritten, versioned, or should the operation fail with user notification?
- [ ] **Cross-Repository Operations**: Should the system support idea files from different repositories or maintain strict repository boundaries?
- [ ] **Rollback Behavior**: If task creation fails after idea file movement, should the file movement be automatically reversed?

## Objective

Establish clear traceability and organization for idea files throughout their lifecycle from conception to task implementation. This ensures no ideas are lost or orphaned, provides clear audit trails for decision-making, and reduces manual overhead in task management workflows.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Enhanced draft-task workflow execution, transparent file management operations, clear feedback and error reporting
- **System Behavior Scope**: Automatic idea file movement and renaming, directory creation, conflict resolution, task-idea linkage establishment
- **Interface Scope**: Integration with existing `create-path task-new` command, enhanced draft-task workflow, file system operations with proper error handling

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
- **ATOM Architecture Integration**: New IdeaFileManager molecule integrating with existing FileIoHandler and SecurePathValidator molecules
- **CLI Command Enhancement**: Extend create-path command with --idea-source option for transparent file management
- **Path Resolution Integration**: Leverage existing PathResolver for consistent path handling across the system

### Technology Stack
- **Ruby FileUtils**: Core file operations (move, copy, rename) with proper error handling
- **Existing Security Framework**: Leverage SecurePathValidator and FileIoHandler for consistent security
- **CLI Framework Integration**: Extend dry-cli command structure with idea file management options
- **Path Standards**: Follow XDG-compliant path handling and project path conventions

### Implementation Strategy
- **Transparent Integration**: File operations occur automatically during task creation without additional user commands
- **Graceful Degradation**: Task creation continues successfully even if idea file operations fail
- **Conflict Resolution**: Automatic versioning (v2.md, v3.md) for destination file conflicts

## Tool Selection

| Criteria | Ruby FileUtils | Shell Commands | Custom Implementation | Selected |
|----------|---------------|----------------|---------------------|----------|
| Security | Good (with validation) | Poor (injection risks) | Excellent | Ruby FileUtils |
| Integration | Excellent | Poor | Good | Ruby FileUtils |
| Error Handling | Excellent | Fair | Good | Ruby FileUtils |
| Maintainability | Excellent | Poor | Fair | Ruby FileUtils |
| ATOM Compliance | Excellent | Poor | Good | Ruby FileUtils |

**Selection Rationale:** Ruby FileUtils provides the best balance of security, integration with existing ATOM architecture, and maintainability while leveraging existing security validation infrastructure.

### Dependencies
- **Existing**: FileUtils (Ruby stdlib), FileIoHandler, SecurePathValidator, PathResolver
- **New**: None - leverages existing infrastructure
- **Compatibility**: Full compatibility with existing CLI command structure

## File Modifications

### Create
- dev-tools/lib/coding_agent_tools/molecules/idea_file_manager.rb
  - Purpose: ATOM molecule for idea file operations (move, rename, organize)
  - Key components: File movement, conflict resolution, path generation
  - Dependencies: FileIoHandler, SecurePathValidator, FileUtils

- dev-tools/spec/coding_agent_tools/molecules/idea_file_manager_spec.rb
  - Purpose: Comprehensive test coverage for idea file management molecule
  - Key components: Unit tests for all file operations and edge cases
  - Dependencies: RSpec, temporary file fixtures

### Modify
- dev-tools/lib/coding_agent_tools/cli/create_path_command.rb
  - Changes: Add --idea-source option, integrate IdeaFileManager molecule
  - Impact: Enhanced task creation with transparent idea file management
  - Integration points: Connects to IdeaFileManager after successful task creation

- dev-tools/lib/coding_agent_tools/molecules/path_resolver.rb
  - Changes: Add current release detection and idea destination path generation
  - Impact: Consistent path resolution for idea file destinations
  - Integration points: Used by IdeaFileManager for destination path calculation

### Delete
- None: All changes are additive to maintain backward compatibility

## Risk Assessment

### Technical Risks
- **Risk:** File move operations fail due to permissions or filesystem issues
  - **Probability:** Medium
  - **Impact:** Low (task creation continues)
  - **Mitigation:** Comprehensive error handling with graceful degradation
  - **Rollback:** No rollback needed - original file remains untouched on failure

- **Risk:** Path traversal or security vulnerabilities in file operations
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Leverage existing SecurePathValidator for all path operations
  - **Rollback:** Security logging and immediate operation termination

### Integration Risks
- **Risk:** Breaking existing create-path command functionality
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Additive changes only, comprehensive test coverage
  - **Monitoring:** Existing CLI test suite validates backward compatibility

- **Risk:** Inconsistent behavior across different operating systems
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Use Ruby FileUtils cross-platform abstractions
  - **Monitoring:** Multi-platform test execution in CI

### Performance Risks
- **Risk:** File operations slow down task creation process
  - **Mitigation:** Asynchronous file operations after task creation success
  - **Monitoring:** Performance benchmarks for create-path command execution time
  - **Thresholds:** <200ms additional overhead for file operations

## Implementation Plan

*This section details the specific steps required to complete the task, divided into planning activities and implementation work.*

### Planning Steps

*Use asterisk markers (`* [ ]`) for research, analysis, and design activities.*

* [ ] Analyze current create-path command structure and integration points
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Command flow and extension points are identified
  > Command: grep -r "create_path" dev-tools/lib/ --include="*.rb"

* [ ] Research FileUtils cross-platform compatibility for file move operations
  > TEST: Compatibility Verification
  > Type: Research Validation
  > Assert: FileUtils.mv behavior consistent across target platforms
  > Command: ruby -e "require 'fileutils'; puts FileUtils.respond_to?(:mv)"

* [ ] Design IdeaFileManager molecule interface following ATOM architecture patterns
  > TEST: Architecture Compliance
  > Type: Design Validation
  > Assert: Interface follows established molecule patterns in codebase
  > Command: find dev-tools/lib/coding_agent_tools/molecules/ -name "*.rb" | head -3 | xargs grep -l "def initialize"

### Execution Steps

*Use hyphen markers (`- [ ]`) for concrete implementation actions.*

- [ ] Create IdeaFileManager molecule with core file operations
  > TEST: Molecule Creation
  > Type: Implementation Validation
  > Assert: IdeaFileManager class created with required methods (move_idea_file, generate_destination_path, handle_conflicts)
  > Command: ruby -c dev-tools/lib/coding_agent_tools/molecules/idea_file_manager.rb

- [ ] Implement secure file movement with conflict resolution
  > TEST: File Operations
  > Type: Functional Validation
  > Assert: Files moved correctly with version suffixes for conflicts
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/idea_file_manager_spec.rb -t file_movement

- [ ] Enhance create-path command with --idea-source option and integration
  > TEST: CLI Integration
  > Type: Integration Validation
  > Assert: create-path command accepts --idea-source and processes files
  > Command: cd dev-tools && bundle exec exe/create-path task-new --title "test-task" --idea-source "/tmp/test-idea.md" --help | grep "idea-source"

- [ ] Add current release detection to PathResolver molecule
  > TEST: Path Resolution
  > Type: Component Validation
  > Assert: PathResolver correctly identifies current release directory
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/path_resolver_spec.rb -t current_release

- [ ] Implement comprehensive error handling and logging for file operations
  > TEST: Error Handling
  > Type: Reliability Validation
  > Assert: All error conditions handled gracefully with appropriate logging
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/idea_file_manager_spec.rb -t error_handling

- [ ] Create complete test suite covering all scenarios and edge cases
  > TEST: Test Coverage
  > Type: Quality Validation
  > Assert: Test coverage >95% for all new code with edge case coverage
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/molecules/idea_file_manager_spec.rb --format progress

- [ ] Update CLI help documentation and command examples
  > TEST: Documentation Update
  > Type: Usability Validation
  > Assert: Help text includes --idea-source option with clear examples
  > Command: cd dev-tools && bundle exec exe/create-path --help | grep -A5 "idea-source"

- [ ] Validate integration with existing draft-task workflow
  > TEST: Workflow Integration
  > Type: End-to-End Validation
  > Assert: Draft-task workflow can use enhanced create-path with idea file management
  > Command: create-path task-new --title "integration-test" --idea-source "test-idea.md" --status draft

## Acceptance Criteria

- [ ] **Automated File Organization**: Original idea files are automatically moved and renamed with task number prefix after task creation
- [ ] **Complete Traceability**: Clear linkage between draft tasks and their source idea files through organized file structure
- [ ] **Zero Manual Overhead**: Users create tasks without manual file management, system handles all file operations transparently
- [ ] **Consistent Naming Convention**: All processed idea files follow `NNN-original-filename.md` pattern in `../docs/ideas/` directory
- [ ] **Error Resilience**: File operation failures don't prevent task creation, with clear error reporting and graceful degradation
- [ ] **CLI Integration**: create-path command enhanced with --idea-source option for seamless integration
- [ ] **Security Compliance**: All file operations use existing security validation framework
- [ ] **Cross-Platform Compatibility**: File operations work consistently across different operating systems
- [ ] **Comprehensive Testing**: >95% test coverage with full edge case validation
- [ ] **Performance Acceptable**: <200ms additional overhead for idea file management operations

## Out of Scope

- ❌ **GUI Interface**: Command-line only, no graphical user interface for file management
- ❌ **Batch Processing**: Single idea file per task creation, no bulk operations
- ❌ **Version Control Integration**: File operations are filesystem-only, no automatic git operations
- ❌ **Cross-Repository Operations**: Idea files must be within the same repository structure
- ❌ **Advanced Conflict Resolution**: Simple versioning (v2, v3) only, no merge strategies

## References

- Source idea file: `dev-taskflow/backlog/ideas/20250731-0753-draft-task-move.md`
- Draft-task workflow: `dev-handbook/workflow-instructions/draft-task.wf.md`
- ATOM Architecture patterns: `dev-tools/lib/coding_agent_tools/molecules/`
- Existing security framework: `dev-tools/lib/coding_agent_tools/molecules/secure_path_validator.rb`
- CLI command patterns: `dev-tools/lib/coding_agent_tools/cli/`
- FileIoHandler implementation: `dev-tools/lib/coding_agent_tools/molecules/file_io_handler.rb`