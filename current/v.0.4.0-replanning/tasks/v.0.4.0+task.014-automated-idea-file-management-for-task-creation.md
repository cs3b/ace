---
id: v.0.4.0+task.014
status: pending
priority: high
estimate: 4h
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
# 2. Gets current release path: release-manager current
# 3. Moves idea: git-commit old-path new-path --intention "Move idea file to current release after task creation"
#    Destination: dev-taskflow/current/vX.Y.Z-release/docs/ideas/NNN-YYYY-MMDD-HHMM-idea-name.md

# Expected outputs:
# - "Draft task created: [task-path]"
# - "Idea file moved: [old-path] -> [new-path]"
# - Task file maintains original idea reference (no update needed)

# Workflow integration (no create-path changes needed):
# draft-task workflow handles file movement after task creation
```

**Error Handling:**
- **Source idea file not found**: Clear error message indicating file path doesn't exist, workflow continues without file operations
- **Destination directory doesn't exist**: Automatically create `../docs/ideas/` directory structure
- **File already exists at destination**: Append version suffix (e.g., `NNN-idea-name-v2.md`) and notify user
- **Insufficient permissions**: Clear error message with suggested resolution, task creation continues

**Edge Cases:**
- **Task number not yet assigned**: Wait for task creation completion before file operations
- **Multiple tasks from same idea**: Use combined task number prefix (e.g., 009-010-012-original-name.md)
- **Idea file in different release folder**: Support cross-release idea referencing with clear path handling
- **No current release defined**: Skip file movement with warning, continue task creation

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

- [x] **File Conflict Resolution**: Should existing files be overwritten, versioned, or should the operation fail with user notification?
  - **Decision**: Append task number to existing prefix (creating combined prefixes like 009-010-filename.md)
- [ ] **Cross-Repository Operations**: Should the system support idea files from different repositories or maintain strict repository boundaries?
  - **Assumption**: Maintain repository boundaries - only move files within same repository
- [ ] **Rollback Behavior**: If task creation fails after idea file movement, should the file movement be automatically reversed?
  - **Assumption**: No rollback - file movement is housekeeping, task creation failure doesn't invalidate the move

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
- **Workflow Enhancement**: Modify draft-task workflow to handle idea file movement after task creation
- **No CLI Changes**: Use existing tools (release-manager, git-commit) without modifying create-path
- **Path Resolution**: Use `release-manager current` to determine destination path dynamically

### Technology Stack
- **Existing Tools**: release-manager, git-commit with file movement support
- **Workflow Script**: Enhanced draft-task.wf.md with file movement logic
- **Git Integration**: Use `git-commit old-path new-path --intention` for atomic moves
- **Path Standards**: Follow existing project conventions for docs/ideas/ structure

### Implementation Strategy
- **Workflow-Level Integration**: All logic in draft-task workflow, no tool modifications
- **Graceful Degradation**: Task creation continues if file movement fails
- **Conflict Resolution**: Combined task number prefixes (009-010-012-filename.md)

## Tool Selection

| Criteria | git-commit move | Shell mv | Ruby FileUtils | Selected |
|----------|----------------|----------|----------------|----------|
| Git Integration | Excellent | Poor | Fair | git-commit |
| Atomic Operations | Excellent | Poor | Good | git-commit |
| Error Handling | Excellent | Poor | Good | git-commit |
| Workflow Integration | Excellent | Good | Poor | git-commit |
| Existing Tool | Yes | Yes | No (new code) | git-commit |

**Selection Rationale:** Using `git-commit old-path new-path --intention` provides atomic git-aware file movement without requiring new code, maintaining consistency with existing project practices.

### Dependencies
- **Existing**: release-manager, git-commit, draft-task workflow
- **New**: None - uses only existing tools
- **Compatibility**: No changes to existing tools, only workflow enhancement

## File Modifications

### Create
- None: No new files needed, using existing tools

### Modify
- dev-handbook/workflow-instructions/draft-task.wf.md
  - Changes: Add step 7.5 for idea file movement after task creation
  - Impact: Automated idea file organization during task drafting
  - Integration points: Between task creation (step 7) and completion verification (step 8)
  - Key logic:
    - Extract task number from created task path
    - Get current release path via `release-manager current`
    - Build destination path: `current-release/docs/ideas/NNN-original-name.md`
    - Execute: `git-commit old-path new-path --intention "Move idea file to current release after task NNN creation"`
    - Handle multi-task prefixes by checking if file already exists with prefix

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

* [ ] Analyze draft-task workflow to identify optimal insertion point for file movement
  > TEST: Workflow Understanding
  > Type: Pre-condition Check
  > Assert: Identify point after task creation but before completion
  > Command: grep -n "create-path task-new" dev-handbook/workflow-instructions/draft-task.wf.md

* [ ] Study git-commit command's file movement capabilities
  > TEST: Tool Capability Check
  > Type: Research Validation
  > Assert: Confirm git-commit supports "old-path new-path" pattern
  > Command: git-commit --help | grep -A5 "file movement"

* [ ] Verify release-manager output format for path extraction
  > TEST: Output Format Verification
  > Type: Integration Check
  > Assert: release-manager current provides parseable path output
  > Command: release-manager current | grep "Path:"

### Execution Steps

*Use hyphen markers (`- [ ]`) for concrete implementation actions.*

- [ ] Add idea file movement logic to draft-task workflow after step 7
  > TEST: Workflow Enhancement
  > Type: Implementation Validation
  > Assert: New step 7.5 added with proper file movement logic
  > Command: grep -A10 "Create Draft Task Files" dev-handbook/workflow-instructions/draft-task.wf.md

- [ ] Implement task number extraction from created task path
  > TEST: Pattern Extraction
  > Type: Functional Validation
  > Assert: Extract NNN from path like "v.0.4.0+task.NNN-title.md"
  > Command: echo "v.0.4.0+task.014-title.md" | grep -oE "task\.([0-9]{3})" | cut -d. -f2

- [ ] Add release-manager integration for current release path
  > TEST: Tool Integration
  > Type: Integration Validation
  > Assert: Workflow correctly calls release-manager current and extracts path
  > Command: release-manager current | grep "Path:" | awk '{print $2}'

- [ ] Implement git-commit file movement with proper intention message
  > TEST: Git Integration
  > Type: Command Validation
  > Assert: git-commit correctly moves files with intention
  > Command: git-commit --dry-run old-path new-path --intention "Move idea file to current release"

- [ ] Add multi-task prefix handling for existing files
  > TEST: Conflict Resolution
  > Type: Edge Case Validation
  > Assert: Properly handles 009-010-012-filename.md pattern
  > Command: ls dev-taskflow/current/*/docs/ideas/ | grep -E "[0-9]{3}(-[0-9]{3})*-.*\.md"

- [ ] Implement error handling for missing release or failed moves
  > TEST: Error Handling
  > Type: Reliability Validation
  > Assert: Workflow continues if file movement fails
  > Command: Test with non-existent idea file path

- [ ] Test complete workflow with real idea file
  > TEST: End-to-End Validation
  > Type: Integration Test
  > Assert: Idea file correctly moved after task creation
  > Command: Execute draft-task workflow with test idea file

- [ ] Document the enhanced workflow behavior
  > TEST: Documentation Update
  > Type: Usability Validation
  > Assert: Workflow documentation includes file movement behavior
  > Command: grep -A5 "idea file movement" dev-handbook/workflow-instructions/draft-task.wf.md

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

- ❌ **Tool Modifications**: No changes to existing CLI tools (create-path, release-manager, git-commit)
- ❌ **Batch Processing**: Single idea file per task creation, no bulk operations
- ❌ **Reference Updates**: Task files maintain original idea references (housekeeping only)
- ❌ **Cross-Repository Operations**: Idea files must be within the same repository structure
- ❌ **Complex Conflict Resolution**: Simple prefix combination only (009-010-012-filename.md)

## References

- Source idea file: `dev-taskflow/backlog/ideas/20250731-0753-draft-task-move.md`
- Draft-task workflow: `dev-handbook/workflow-instructions/draft-task.wf.md`
- ATOM Architecture patterns: `dev-tools/lib/coding_agent_tools/molecules/`
- Existing security framework: `dev-tools/lib/coding_agent_tools/molecules/secure_path_validator.rb`
- CLI command patterns: `dev-tools/lib/coding_agent_tools/cli/`
- FileIoHandler implementation: `dev-tools/lib/coding_agent_tools/molecules/file_io_handler.rb`
- **[REVIEW FINDING]** Existing moved idea files: `dev-taskflow/current/v.0.4.0-replanning/docs/ideas/`
- **[REVIEW FINDING]** TaskIdGenerator: `dev-tools/lib/coding_agent_tools/molecules/taskflow_management/task_id_generator.rb`
- **[REVIEW FINDING]** ReleaseManager: `dev-tools/lib/coding_agent_tools/organisms/taskflow_management/release_manager.rb`

