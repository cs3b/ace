---
id: v.0.9.0+task.019
status: pending
priority: high
estimate: 3d
dependencies: [v.0.9.0+task.006]
---

# Implement ace-taskflow Release and Task Management Commands

## Behavioral Specification

### User Experience
- **Input**: Command-line invocations like `ace-taskflow release`, `ace-taskflow task next`, `ace-taskflow idea "content"`
- **Process**: Seamless navigation between releases, task lifecycle management, and idea capture with context awareness
- **Output**: Clear status information, task listings, release statistics, and confirmation of actions

### Expected Behavior

The ace-taskflow tool provides a unified interface for managing releases, tasks, and ideas within a development workflow. Users experience:

1. **Release Management**: Navigate between backlog, current, and done releases with clear visibility of release status
2. **Task Lifecycle**: Move tasks through draft → planned → in-progress → done states naturally
3. **Idea Capture**: Quick, frictionless capture of ideas to appropriate locations (backlog or release-specific)
4. **Context Awareness**: Commands respect current release context with ability to override via flags

The system maintains separation between ideas (captured thoughts) and tasks (actionable work items), with a clear promotion path from ideas to tasks when ready.

### Interface Contract

```bash
# Release Management
ace-taskflow release                      # Show current release info
ace-taskflow release list                 # List all releases
ace-taskflow release switch <name>        # Switch to different release
ace-taskflow release create <name>        # Create new release
ace-taskflow release complete             # Move current to done
ace-taskflow release status               # Detailed statistics

# Task Management
ace-taskflow task                         # Show next actionable task
ace-taskflow task next [--limit N]        # Next N tasks
ace-taskflow task list [filters]          # List all tasks
ace-taskflow task create <title>          # Create new task
ace-taskflow task start <task-id>         # Mark as in-progress
ace-taskflow task done <task-id>          # Mark as completed
ace-taskflow task from-idea <idea-file>   # Convert idea to task

# Context switches for tasks
ace-taskflow task --backlog               # Work with backlog
ace-taskflow task --current               # Current release (default)
ace-taskflow task --release <name>        # Specific release

# Idea Management (simplified, no task subcommand)
ace-taskflow idea <content>               # Capture to backlog/ideas
ace-taskflow idea <content> --current     # To current release
ace-taskflow idea list                    # List all ideas
ace-taskflow idea show <idea-id>          # Display idea
```

**Error Handling:**
- [No current release]: Clear message with suggestion to create or switch release
- [Invalid task ID]: List available task IDs with fuzzy matching suggestions
- [Missing configuration]: Use sensible defaults with informative message
- [Invalid status transition]: Explain valid transitions (e.g., can't go from done to draft)

**Edge Cases:**
- [Multiple releases with same name]: Use full path or disambiguation prompt
- [Empty release]: Show helpful message about adding tasks or ideas
- [Concurrent modifications]: Detect and warn about conflicts

### Success Criteria

- [ ] **Release Navigation**: Users can list, switch, and create releases with clear feedback
- [ ] **Task Lifecycle**: Tasks progress through states with proper validation and tracking
- [ ] **Idea Capture**: Ideas captured quickly to correct location with minimal friction
- [ ] **Context Awareness**: Commands respect and display current context clearly
- [ ] **Configuration**: Paths and behavior configurable via `.ace/taskflow.yml`
- [ ] **Migration Path**: Existing task-manager/release-manager users can transition smoothly

### Validation Questions

- [ ] **Configuration Location**: Should `.ace/taskflow.yml` cascade like ace-core config?
- [ ] **Task ID Format**: Keep v.X.X.X+task.NNN format or simplify to task.NNN?
- [ ] **Idea Naming**: Timestamp-based or sequential numbering for idea files?
- [ ] **Release Switching**: Should it change working directory or just context?
- [ ] **Bulk Operations**: Support for moving multiple tasks at once?

## Objective

Provide a unified, intuitive interface for managing the complete development workflow from idea capture through task completion within release-based contexts. This consolidates functionality from separate task-manager and release-manager tools into ace-taskflow while maintaining backward compatibility.

## Scope of Work

- **User Experience Scope**: All interactions for release management, task lifecycle, and idea capture
- **System Behavior Scope**: Context-aware operations, state transitions, configuration handling
- **Interface Scope**: CLI commands with consistent flags and output formats

### Deliverables

#### Behavioral Specifications
- Complete command interface for release, task, and idea management
- State transition rules and validation logic
- Context switching and awareness behavior

#### Validation Artifacts
- Usage examples covering common workflows
- Success criteria validation methods
- Integration test scenarios

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby class structures or file organization
- ❌ **Technology Decisions**: Choice of parsing libraries or data storage formats
- ❌ **Performance Optimization**: Caching strategies or query optimization
- ❌ **Future Enhancements**: Git integration, team collaboration features

## Technical Approach

### Architecture Pattern
The implementation follows the ATOM architecture pattern established in ace-* gems:
- **Atoms**: Pure functions for parsing, validation, path manipulation
- **Molecules**: Task/release file loaders, configuration resolvers, formatters
- **Organisms**: Command orchestrators combining molecules for business logic
- **Models**: Data structures for tasks, releases, ideas, configuration

### Technology Stack
- Ruby 3.x (consistent with other ace-* gems)
- No external dependencies (following ace-core zero-dependency principle)
- YAML for configuration and metadata
- Markdown for task/idea content

### Implementation Strategy
Port and refactor existing functionality from dev-tools while:
- Maintaining backward compatibility with existing file formats
- Using ace-core for configuration management
- Following established patterns from ace-context and ace-test-runner

## File Modifications

### Create
- ace-taskflow/lib/ace/taskflow/commands/release_command.rb
  - Purpose: Release subcommand orchestrator
  - Key components: current, list, switch, create, complete, status actions
  - Dependencies: Release organisms and molecules

- ace-taskflow/lib/ace/taskflow/commands/task_command.rb
  - Purpose: Task subcommand orchestrator
  - Key components: next, list, create, start, done, from-idea actions
  - Dependencies: Task organisms and molecules

- ace-taskflow/lib/ace/taskflow/organisms/release_manager.rb
  - Purpose: Release business logic orchestration
  - Key components: Release resolution, navigation, statistics
  - Dependencies: Release molecules and models

- ace-taskflow/lib/ace/taskflow/organisms/task_manager.rb
  - Purpose: Task business logic orchestration
  - Key components: Task lifecycle, filtering, sorting
  - Dependencies: Task molecules and models

- ace-taskflow/lib/ace/taskflow/molecules/release_resolver.rb
  - Purpose: Resolve release paths and contexts
  - Key components: Current/backlog/done resolution
  - Dependencies: Configuration and file system

- ace-taskflow/lib/ace/taskflow/molecules/task_loader.rb
  - Purpose: Load and parse task files
  - Key components: YAML frontmatter parsing, content extraction
  - Dependencies: File system operations

- ace-taskflow/lib/ace/taskflow/molecules/task_filter.rb
  - Purpose: Filter tasks by status, priority, release
  - Key components: Filter criteria parsing and application
  - Dependencies: Task models

- ace-taskflow/lib/ace/taskflow/molecules/idea_formatter.rb
  - Purpose: Format ideas with templates and metadata
  - Key components: Template interpolation, timestamp formatting
  - Dependencies: Configuration

- ace-taskflow/lib/ace/taskflow/atoms/yaml_parser.rb
  - Purpose: Parse YAML frontmatter from markdown files
  - Key components: Safe YAML parsing with validation
  - Dependencies: None (pure function)

- ace-taskflow/lib/ace/taskflow/atoms/path_builder.rb
  - Purpose: Build paths for tasks, ideas, releases
  - Key components: Path joining, validation
  - Dependencies: None (pure function)

- ace-taskflow/lib/ace/taskflow/models/task.rb
  - Purpose: Task data structure
  - Key components: id, status, priority, metadata
  - Dependencies: None (pure data)

- ace-taskflow/lib/ace/taskflow/models/release.rb
  - Purpose: Release data structure
  - Key components: name, path, status, statistics
  - Dependencies: None (pure data)

- ace-taskflow/lib/ace/taskflow/models/idea.rb
  - Purpose: Idea data structure
  - Key components: content, timestamp, location
  - Dependencies: None (pure data)

### Modify
- ace-taskflow/lib/ace/taskflow/cli.rb
  - Changes: Add release and task subcommand routing
  - Impact: Enables new command structure
  - Integration points: Command classes

- ace-taskflow/lib/ace/taskflow/configuration.rb
  - Changes: Add release and task configuration sections
  - Impact: Enables path and behavior configuration
  - Integration points: All commands use configuration

## Risk Assessment

### Technical Risks
- **Risk:** Migration from dev-tools might break existing workflows
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Maintain backward compatibility, provide migration guide
  - **Rollback:** Keep dev-tools functional during transition period

### Integration Risks
- **Risk:** Configuration cascade might conflict with project settings
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Use ace-core's proven cascade resolution
  - **Monitoring:** Log configuration source in debug mode

## Implementation Plan

### Planning Steps

* [ ] Analyze existing task-manager and release-manager implementations
  - Review command structures and options
  - Document current file formats and conventions
  - Identify reusable components

* [ ] Research ace-core configuration integration
  - Study configuration cascade pattern
  - Plan taskflow.yml structure
  - Define default configurations

* [ ] Design command interface consistency
  - Align with ace-context and ace-test patterns
  - Define common flags and options
  - Plan output formats

### Execution Steps

- [ ] Set up base command structure
  - [ ] Update CLI router for release and task subcommands
  - [ ] Create command class skeletons
  - [ ] Add help text and usage examples
  > TEST: Command routing validation
  > Type: Integration test
  > Assert: All subcommands route correctly
  > Command: bundle exec ace-taskflow release --help && bundle exec ace-taskflow task --help

- [ ] Implement release command functionality
  - [ ] Create release_manager organism
  - [ ] Implement current, list, and status actions
  - [ ] Add release creation and completion
  - [ ] Implement release switching logic
  > TEST: Release operations
  > Type: Integration test
  > Assert: Release commands work correctly
  > Command: bundle exec ace-taskflow release current

- [ ] Implement task command functionality
  - [ ] Create task_manager organism
  - [ ] Implement next and list actions
  - [ ] Add task creation and state transitions
  - [ ] Implement from-idea conversion
  - [ ] Add context switching (--backlog, --current, --release)
  > TEST: Task operations
  > Type: Integration test
  > Assert: Task commands work correctly
  > Command: bundle exec ace-taskflow task next

- [ ] Enhance idea command
  - [ ] Add --current flag for release-specific capture
  - [ ] Implement idea list and show actions
  - [ ] Update idea formatter with configuration
  > TEST: Idea capture
  > Type: Integration test
  > Assert: Ideas captured to correct location
  > Command: bundle exec ace-taskflow idea "Test idea" --current

- [ ] Implement ATOM components
  - [ ] Create atoms for parsing and path building
  - [ ] Create molecules for loading and filtering
  - [ ] Create models for data structures
  - [ ] Wire components together in organisms
  > TEST: Component integration
  > Type: Unit tests
  > Assert: All components work correctly
  > Command: bundle exec rake test

- [ ] Add configuration support
  - [ ] Extend configuration.rb for release/task settings
  - [ ] Implement configuration loading and validation
  - [ ] Add configuration cascade support
  > TEST: Configuration loading
  > Type: Integration test
  > Assert: Configuration loaded from .ace/taskflow.yml
  > Command: bundle exec ace-taskflow release --debug

- [ ] Create migration documentation
  - [ ] Document command mapping from old to new
  - [ ] Create migration guide for users
  - [ ] Add backward compatibility notes

- [ ] Write comprehensive tests
  - [ ] Unit tests for atoms and molecules
  - [ ] Integration tests for commands
  - [ ] End-to-end workflow tests
  > TEST: Full test suite
  > Type: Test execution
  > Assert: All tests pass
  > Command: bundle exec rake test

## Acceptance Criteria

- [ ] All release commands functional (current, list, create, complete, status)
- [ ] All task commands functional (next, list, create, start, done, from-idea)
- [ ] Context switching works (--backlog, --current, --release)
- [ ] Configuration loaded from .ace/taskflow.yml
- [ ] Backward compatibility maintained with existing file formats
- [ ] Comprehensive test coverage
- [ ] Migration documentation complete

## References

- Current task-manager implementation in dev-tools/exe/task-manager
- Current release-manager implementation in dev-tools/exe/release-manager
- Existing ace-taskflow idea command implementation
- Configuration structure in .ace/taskflow.yml
- ATOM architecture in ace-context and ace-test-runner