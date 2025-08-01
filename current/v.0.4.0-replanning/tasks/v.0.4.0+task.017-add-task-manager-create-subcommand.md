---
id: v.0.4.0+task.017
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Add task-manager create subcommand

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

## References

- Original idea file: dev-taskflow/backlog/ideas/20250731-0828-task-create-migrate.md
- Existing create-path task-new command behavior and implementation
- Task-manager CLI architecture and subcommand patterns
- ATOM architecture principles for dev-tools Ruby gem