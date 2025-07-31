---
id: v.0.4.0+task.014
status: draft
priority: high
estimate: TBD
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

## References

- Source idea file: `dev-taskflow/backlog/ideas/20250731-0753-draft-task-move.md`
- Draft-task workflow: `dev-handbook/workflow-instructions/draft-task.wf.md`
- ATOM Architecture patterns for file operations
- XDG directory standards and project path conventions