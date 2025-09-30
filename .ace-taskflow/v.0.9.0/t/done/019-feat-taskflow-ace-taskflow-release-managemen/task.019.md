---
id: v.0.9.0+task.019
status: done
priority: high
estimate: 3d
dependencies: [v.0.9.0+task.006]
---

# Implement ace-taskflow Release and Task Management Commands

## Behavioral Specification

### User Experience
- **Input**: Command-line invocations like `ace-taskflow release`, `ace-taskflow task`, `ace-taskflow idea "content"`, with qualified task references (e.g., `v.0.9.0+018`, `backlog+025`)
- **Process**: Seamless navigation between releases, task lifecycle management across contexts (backlog/active/done), and idea capture with flexible targeting
- **Output**: Clear status information, task listings with context indicators, release state transitions, and confirmation of actions

### Expected Behavior

The ace-taskflow tool provides a unified interface for managing releases, tasks, and ideas within a development workflow. Users experience:

1. **Release Management**: Navigate between backlog, active, and done releases with promote/demote transitions
2. **Task Lifecycle**: Move tasks through states and between contexts (backlog/releases) using qualified references
3. **Idea Capture**: Quick, frictionless capture of ideas to backlog or release-specific locations
4. **Context Awareness**: Commands work within active release by default, with `--backlog`, `--release` overrides
5. **Simplified Structure**: Clean directory layout with `.ace-taskflow/v.X.Y.Z/t/NNN/task.md` paths

The system supports tasks in backlog (without release assignment), qualified task references (e.g., `v.0.9.0+018`, `backlog+025`), and multiple active releases with automatic primary selection.

### Interface Contract

```bash
# Task Management (Singular - operations on one)
ace-taskflow task                         # Show next task from active release
ace-taskflow task <ref>                   # Show task (018, v.0.9.0+018, backlog+025)
ace-taskflow task create <title>          # Create new task in active release
ace-taskflow task start <ref>             # Mark as in-progress
ace-taskflow task done <ref>              # Mark as completed
ace-taskflow task move <ref> <target>     # Move task (target: backlog, v.0.10.0)
ace-taskflow task update <ref>            # Update task metadata

# Qualified task references:
#   018 or task.018           - current context
#   current+018               - explicit current/active
#   backlog+018               - from backlog
#   v.0.9.0+018               - from specific release

# Task Collections (Plural - browse/list many)
ace-taskflow tasks                        # List tasks in active release
ace-taskflow tasks --all                  # List ALL tasks (backlog + releases)
ace-taskflow tasks --backlog              # List backlog tasks
ace-taskflow tasks --release <name>       # List tasks in specific release
ace-taskflow tasks --status <status>      # Filter by status
ace-taskflow tasks --priority <priority>  # Filter by priority
ace-taskflow tasks --recent [--days N]    # Recently modified tasks
ace-taskflow tasks --stats                # Task statistics with context breakdown

# Release Management (Singular - operations on one)
ace-taskflow release                      # Show active release(s)
ace-taskflow release <name>               # Show specific release info
ace-taskflow release create <name>        # Create new release in backlog
ace-taskflow release promote [<name>]     # Promote: backlog → active
ace-taskflow release demote [<name>]      # Demote: active → done (or --to backlog)
ace-taskflow release validate             # Validate active release
ace-taskflow release changelog            # Generate changelog

# Release transitions (no "complete", just promote/demote):
#   backlog → active (promote)
#   active → done (demote)
#   active → backlog (demote --to backlog, rare)

# Release Collections (Plural - browse/list many)
ace-taskflow releases                     # List all releases
ace-taskflow releases --backlog           # List backlog releases
ace-taskflow releases --active            # Show active release(s)
ace-taskflow releases --done              # List completed releases
ace-taskflow releases --stats             # Release statistics

# Idea Management (Singular - operations on one)
ace-taskflow idea <content>               # Capture to active release (default)
ace-taskflow idea <content> --backlog     # Capture to backlog
ace-taskflow idea <content> --release <n> # Capture to specific release
ace-taskflow idea <id>                    # Show specific idea
ace-taskflow idea to-task <id>            # Convert idea to task
ace-taskflow idea archive <id>            # Archive specific idea

# Idea Collections (Plural - browse/list many)
ace-taskflow ideas                        # List all ideas
ace-taskflow ideas --backlog              # List backlog ideas
ace-taskflow ideas --current              # List current release ideas
ace-taskflow ideas --release <name>       # List ideas in specific release
ace-taskflow ideas --search <term>        # Search ideas
ace-taskflow ideas --recent [--days N]    # Recently captured ideas
```

**Error Handling:**
- [No active release]: Clear message, suggest promoting from backlog
- [Invalid task reference]: Show valid formats (018, v.0.9.0+018, backlog+025)
- [Missing configuration]: Use defaults (.ace-taskflow/, sensible structure)
- [Invalid status transition]: Explain valid transitions
- [Multiple active releases]: Show all, indicate primary (lowest version)

**Edge Cases:**
- [Task not found]: Search across contexts, suggest qualified reference
- [Cross-release move]: Validate target exists, handle ID conflicts
- [Empty contexts]: Show helpful next steps for each context type

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
- Implementing new directory structure (.ace-taskflow/v.X.Y.Z/t/NNN/)
- Supporting qualified task references (v.0.9.0+018, backlog+025)
- Using ace-core for configuration management
- Following established patterns from ace-context and ace-test-runner

## File Modifications

### Create
- ace-taskflow/lib/ace/taskflow/commands/release_command.rb
  - Purpose: Release subcommand orchestrator
  - Key components: show, promote, demote, create, validate actions
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
  - Purpose: Build paths for new structure (.ace-taskflow/v.X.Y.Z/t/NNN/)
  - Key components: Path construction, context resolution
  - Dependencies: None (pure function)

- ace-taskflow/lib/ace/taskflow/atoms/task_reference_parser.rb
  - Purpose: Parse qualified task references (v.0.9.0+018, backlog+025)
  - Key components: Reference parsing, validation
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
  - Changes: Add root directory, context settings, reference patterns
  - Impact: Enables flexible directory structure and qualified references
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

* [ ] Design new directory structure
  - Define .ace-taskflow/ layout (backlog/, v.X.Y.Z/, done/)
  - Plan task organization (/t/NNN/task.md)
  - Design configuration for root directory

* [ ] Design qualified task reference system
  - Define reference formats (v.0.9.0+018, backlog+025, current+018)
  - Plan parsing and resolution logic
  - Handle cross-release references

* [ ] Plan release state transitions
  - Define promote/demote operations
  - Handle multiple active releases
  - Design primary active selection (lowest version)

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
  - [ ] Implement show active, promote, demote actions
  - [ ] Add release creation in backlog
  - [ ] Handle multiple active releases
  > TEST: Release operations
  > Type: Integration test
  > Assert: Release transitions work correctly
  > Command: bundle exec ace-taskflow release

- [ ] Implement task command functionality
  - [ ] Create task_manager organism
  - [ ] Implement qualified reference parsing
  - [ ] Add backlog task support
  - [ ] Enable cross-release task moves
  - [ ] Add context switching (--backlog, --release)
  > TEST: Task operations
  > Type: Integration test
  > Assert: Qualified references work correctly
  > Command: bundle exec ace-taskflow task v.0.9.0+018

- [ ] Enhance idea command
  - [ ] Default to active release (not backlog)
  - [ ] Add --backlog flag for backlog capture
  - [ ] Implement idea to-task conversion
  > TEST: Idea capture
  > Type: Integration test
  > Assert: Ideas captured to correct location
  > Command: bundle exec ace-taskflow idea "Test idea" --backlog

- [ ] Implement ATOM components
  - [ ] Create task_reference_parser atom
  - [ ] Update path_builder for new structure
  - [ ] Create context_resolver molecule
  - [ ] Wire components for qualified references
  > TEST: Component integration
  > Type: Unit tests
  > Assert: Reference parsing and resolution work
  > Command: bundle exec rake test

- [ ] Add configuration support
  - [ ] Define root directory configuration
  - [ ] Add context settings (active_strategy)
  - [ ] Enable qualified reference patterns
  > TEST: Configuration loading
  > Type: Integration test
  > Assert: Root directory configurable
  > Command: bundle exec ace-taskflow config show

- [ ] Create migration support
  - [ ] Build migration script for directory structure
  - [ ] Map old paths to new structure
  - [ ] Document breaking changes

- [ ] Write comprehensive tests
  - [ ] Unit tests for atoms and molecules
  - [ ] Integration tests for commands
  - [ ] End-to-end workflow tests
  > TEST: Full test suite
  > Type: Test execution
  > Assert: All tests pass
  > Command: bundle exec rake test

## Acceptance Criteria

- [x] New directory structure implemented (.ace-taskflow/v.X.Y.Z/t/NNN/)
- [x] Release transitions work (promote/demote, no complete)
- [x] Qualified task references functional (v.0.9.0+018, backlog+025)
- [x] Backlog supports tasks without release assignment
- [x] Multiple active releases handled with primary selection
- [x] Context switching works (--backlog, --release)
- [x] Configuration loaded from .ace/taskflow.yml with root directory setting
- [ ] Migration script for existing structure
- [x] Comprehensive test coverage

## References

- Current task-manager implementation in dev-tools/exe/task-manager
- Current release-manager implementation in dev-tools/exe/release-manager
- Existing ace-taskflow idea command implementation
- Configuration structure in .ace/taskflow.yml
- ATOM architecture in ace-context and ace-test-runner