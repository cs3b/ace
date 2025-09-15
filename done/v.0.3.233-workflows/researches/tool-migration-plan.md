# Tool Migration Plan: exe-old to coding_agent_tools Integration

## Executive Summary

This document outlines the comprehensive migration plan to integrate task management tools from `.ace/tools/exe-old/` into the `coding_agent_tools` Ruby gem architecture. The migration addresses security/stability risks identified in the Google Pro review while supporting the architectural evolution toward a unified gem-based approach.

## Current State Analysis

### exe-old Tools Inventory

Based on analysis of `.ace/tools/exe-old/`, the following tools are currently in use:

#### Core Task Management Tools

- **get-next-task** - Finds next actionable task (not done, deps met)
- **get-recent-tasks** - Summarizes recently updated tasks  
- **get-all-tasks** - Lists all tasks across releases
- **get-next-task-id** - Generates next available task ID
- **get-current-release-path.sh** - Determines current release directory

#### Git and Project Tools  

- **get-recent-git-log** - Shows recent git log for multiple repos
- **diff-list-modified-files.rb** - Analyzes diffs and lists modified files
- **fetch-github-pr-data.rb** - Fetches GitHub PR data

#### Documentation and Quality Tools

- **markdown-sync-embedded-documents** - Syncs XML-embedded template content
- **lint-md-links.rb** - Validates markdown links
- **lint-task-metadata** - Validates task metadata format
- **show-directory-tree** - Enhanced tree command with project filters

#### Test and Utility Tools

- **test-get-current-release-path.sh** - Test script for release path tool

### Current bin/ Dependencies

Analysis shows 12 bin/ scripts depend on exe-old tools:

```bash
bin/cr-docs -> .ace/tools/exe-old/generate-doc-review-prompt
bin/tree -> .ace/tools/exe-old/show-directory-tree  
bin/lint -> .ace/tools/exe-old/lint-md-links.rb + lint-task-metadata
bin/tal -> .ace/tools/exe-old/get-all-tasks
bin/gl -> .ace/tools/exe-old/get-recent-git-log
bin/tnid -> .ace/tools/exe-old/get-next-task-id
bin/rc -> .ace/tools/exe-old/get-current-release-path.sh
bin/tr -> .ace/tools/exe-old/get-recent-tasks
handbook sync-templates -> .ace/tools/exe-old/markdown-sync-embedded-documents
bin/tn -> .ace/tools/exe-old/get-next-task
```

### Current coding_agent_tools Architecture

The gem follows ATOM architecture:

- **Atoms** (`atoms/`) - Basic utilities (env_reader, http_client, json_formatter, etc.)
- **Molecules** (`molecules/`) - Composed operations (api_credentials, file_io_handler, etc.)
- **Organisms** (`organisms/`) - Business logic (LLM clients, prompt_processor, etc.)
- **Ecosystems** (`ecosystems/`) - Complete subsystems

Current CLI structure uses Dry::CLI with LLM-focused commands:

- `llm models` - List available LLM models
- `llm query` - Query LLM providers
- `llm usage_report` - Generate usage reports

## Migration Strategy

### Architecture Integration Design

#### 1. New CLI Command Categories

Add task management commands under `task` namespace:

```
coding_agent_tools task next                    # equivalent to bin/tn
coding_agent_tools task recent [--last N.days] # equivalent to bin/tr  
coding_agent_tools task all                     # equivalent to bin/tal
coding_agent_tools task generate-id VERSION    # equivalent to bin/tnid
coding_agent_tools task current-release        # equivalent to bin/rc
```

Add project management commands under `project` namespace:

```
coding_agent_tools project tree [options]      # equivalent to bin/tree
coding_agent_tools project lint                # equivalent to bin/lint  
coding_agent_tools project git-log [options]   # equivalent to bin/gl
coding_agent_tools project sync-templates      # equivalent to handbook sync-templates
```

#### 2. ATOM Integration Plan

**New Atoms (atoms/task_management/)**:

- `task_parser.rb` - Parse task metadata from markdown files
- `release_detector.rb` - Detect current/backlog release directories
- `dependency_resolver.rb` - Resolve task dependencies
- `file_scanner.rb` - Scan directories for task files
- `yaml_frontmatter_parser.rb` - Parse YAML frontmatter

**New Molecules (molecules/task_management/)**:

- `task_finder.rb` - Find tasks by criteria (status, priority, etc.)
- `task_id_generator.rb` - Generate next available task IDs
- `release_path_resolver.rb` - Resolve current release paths
- `task_dependency_checker.rb` - Check if task dependencies are met
- `git_log_formatter.rb` - Format git log output

**New Organisms (organisms/task_management/)**:

- `task_manager.rb` - Main task management orchestrator
- `release_manager.rb` - Release directory management
- `project_linter.rb` - Project quality checking
- `template_synchronizer.rb` - Template synchronization logic

#### 3. CLI Command Implementation

Create new CLI command files:

- `lib/coding_agent_tools/cli/commands/task/next.rb`
- `lib/coding_agent_tools/cli/commands/task/recent.rb`
- `lib/coding_agent_tools/cli/commands/task/all.rb`
- `lib/coding_agent_tools/cli/commands/task/generate_id.rb`
- `lib/coding_agent_tools/cli/commands/task/current_release.rb`
- `lib/coding_agent_tools/cli/commands/project/tree.rb`
- `lib/coding_agent_tools/cli/commands/project/lint.rb`
- `lib/coding_agent_tools/cli/commands/project/git_log.rb`
- `lib/coding_agent_tools/cli/commands/project/sync_templates.rb`

#### 4. Binstub Preservation Strategy

Update bin/ scripts to use unified gem access while preserving current interfaces:

**Before:**

```bash
#!/usr/bin/env ruby
exec(File.expand_path('../.ace/tools/exe-old/get-next-task', __dir__))
```

**After:**

```bash  
#!/usr/bin/env ruby
exec(File.expand_path('../.ace/tools/exe/coding_agent_tools', __dir__), 'task', 'next', *ARGV)
```

This approach:

- Maintains exact same bin/ script names and interfaces
- Provides seamless user experience during migration
- Allows gradual migration without breaking existing workflows
- Enables easy rollback if needed

## Implementation Timeline

### Phase 1: Foundation (1-2 weeks)

1. **Create ATOM components for task management**
   - Implement basic atoms for task parsing and file operations
   - Create molecules for task finding and ID generation  
   - Build core organisms for task and release management

2. **Implement core CLI commands**
   - `task next` command with same interface as `bin/tn`
   - `task recent` command with same interface as `bin/tr`
   - `task current-release` command with same interface as `bin/rc`

3. **Update bin/ scripts for core tools**
   - Update bin/tn, bin/tr, bin/rc to use gem commands
   - Test functionality preservation

### Phase 2: Extended Commands (1-2 weeks)

1. **Implement remaining task commands**
   - `task all` command (bin/tal equivalent)
   - `task generate-id` command (bin/tnid equivalent)

2. **Implement project management commands**
   - `project tree` command (bin/tree equivalent)
   - `project lint` command (bin/lint equivalent)
   - `project git-log` command (bin/gl equivalent)

3. **Update corresponding bin/ scripts**

### Phase 3: Advanced Features (1-2 weeks)  

1. **Template synchronization**
   - `project sync-templates` command
   - Update handbook sync-templates

2. **Documentation and quality tools**
   - Integrate markdown link checking
   - Integrate task metadata validation

3. **Testing and validation**
   - Comprehensive test suite for all migrated functionality
   - Integration tests with existing workflows

### Phase 4: Documentation and Cleanup (1 week)

1. **Update documentation**
   - Update workflow instructions to reference new gem commands
   - Document migration for users

2. **Deprecation planning**
   - Plan gradual deprecation of exe-old tools
   - Provide migration notices

## Development Phases

### Phase 1 Development Details

#### Atoms Layer Implementation

```ruby
# atoms/task_management/task_parser.rb
module CodingAgentTools
  module Atoms
    module TaskManagement
      class TaskParser
        def self.parse_file(file_path)
          # Parse YAML frontmatter and content
        end
        
        def self.extract_metadata(content)
          # Extract task metadata from YAML frontmatter
        end
      end
    end
  end
end
```

#### CLI Command Registration

```ruby
# lib/coding_agent_tools/cli.rb - additions
def self.register_task_commands
  require_relative "cli/commands/task/next"
  require_relative "cli/commands/task/recent"
  # ... other requires
  
  register "task", aliases: [] do |prefix|
    prefix.register "next", Commands::Task::Next
    prefix.register "recent", Commands::Task::Recent
    # ... other registrations
  end
end
```

#### Binstub Update Pattern

```bash
#!/usr/bin/env ruby
# bin/tn: Get next task (migrated to coding_agent_tools gem)

# Use coding_agent_tools gem for unified access
exec(File.expand_path('../.ace/tools/exe/coding_agent_tools', __dir__), 'task', 'next', *ARGV)
```

## Risk Mitigation

### Backward Compatibility

- Preserve exact same CLI interfaces for all bin/ scripts
- Maintain same output formats for downstream tools
- Keep exe-old tools during transition period

### Workflow Update Timing

**IMPORTANT**: Workflow instructions must NOT be updated until AFTER the gem implementation is complete and tested. This ensures:

- Current workflows continue to function during development
- No broken references to non-existent gem commands
- Proper testing of new gem commands before workflow integration

### Testing Strategy

- Unit tests for all ATOM components
- Integration tests for CLI commands
- End-to-end tests for complete workflows
- Regression tests against exe-old behavior

### Rollback Plan

- Keep exe-old tools intact during migration
- Simple bin/ script updates for easy rollback
- Document rollback procedures

## Success Criteria

1. **Functional Equivalence**: All migrated tools produce identical output to exe-old versions
2. **Performance**: Migration maintains or improves performance characteristics
3. **User Experience**: Zero disruption to existing bin/ script usage
4. **Architecture**: Clean integration following ATOM patterns
5. **Maintainability**: Improved code organization and testability
6. **Security**: Elimination of deprecated tool dependencies

## Implementation Timeline

### Phase 1: Core Task Management (Weeks 1-2)

**Target Completion**: 2 weeks  
**Priority**: Critical  
**Dependencies**: None

#### Week 1: Foundation Components

- **Day 1-2**: Implement Atoms layer
  - `file_system_scanner.rb`
  - `yaml_frontmatter_parser.rb`
  - `task_id_parser.rb`
  - `directory_navigator.rb`
- **Day 3-4**: Implement Molecules layer
  - `task_file_loader.rb`
  - `release_path_resolver.rb`
  - `task_dependency_checker.rb`
- **Day 5**: Implement TaskManager organism
  - Core task finding logic
  - Basic CLI integration

#### Week 2: CLI Commands and Integration

- **Day 1-2**: Implement CLI commands
  - `task next` command
  - `task recent` command  
  - `task current-release` command
- **Day 3-4**: Update bin/ scripts
  - Update bin/tn, bin/tr, bin/rc
  - Test functionality preservation
- **Day 5**: Testing and validation
  - Unit tests for all components
  - Integration testing with existing workflows

### Phase 2: Extended Task Management (Weeks 3-4)

**Target Completion**: 2 weeks  
**Priority**: High  
**Dependencies**: Phase 1 complete

#### Week 3: Additional Task Commands

- **Day 1-2**: Implement remaining task commands
  - `task all` command (bin/tal equivalent)
  - `task generate-id` command (bin/tnid equivalent)
- **Day 3-4**: Update corresponding bin/ scripts
  - Update bin/tal, bin/tnid
  - Ensure backward compatibility
- **Day 5**: Testing and documentation
  - Comprehensive testing of all task commands
  - Update CLI documentation

#### Week 4: Project Management Commands Foundation

- **Day 1-3**: Begin project management components
  - `project tree` command (bin/tree equivalent)
  - Basic project linting framework
- **Day 4-5**: Integration and testing
  - Update bin/tree script
  - Test project commands

### Phase 3: Advanced Project Tools (Weeks 5-6)  

**Target Completion**: 2 weeks  
**Priority**: Medium  
**Dependencies**: Phase 2 complete

#### Week 5: Git and Documentation Tools

- **Day 1-2**: Implement git log functionality
  - `project git-log` command (bin/gl equivalent)
  - Multi-repository support
- **Day 3-4**: Documentation tools
  - Markdown link checking integration
  - Task metadata validation
- **Day 5**: Update bin/gl and bin/lint scripts

#### Week 6: Template Synchronization

- **Day 1-3**: Template sync implementation
  - `project sync-templates` command
  - XML template parsing and synchronization
- **Day 4-5**: Integration and testing
  - Update handbook sync-templates
  - Comprehensive testing

### Phase 4: Documentation and Finalization (Week 7)

**Target Completion**: 1 week  
**Priority**: Medium  
**Dependencies**: Phase 3 complete

#### Week 7: Documentation and Finalization

- **Day 1-2**: Final testing and validation
  - End-to-end workflow testing with gem commands
  - Performance benchmarking against exe-old tools
  - User acceptance testing
- **Day 3-4**: Post-Implementation Workflow Updates
  - Update `initialize-project-structure.wf.md` to use gem commands
  - Update other workflow instructions to reference new gem access
  - Update embedded binstub templates in workflows
- **Day 5**: Release preparation and documentation
  - Create migration guide for users
  - Final code review and deprecation notices
  - Document rollback procedures

## Development Phases

### Development Checklist by Phase

#### Phase 1 Deliverables

- [ ] All Atoms implemented and tested
- [ ] All Molecules implemented and tested  
- [ ] TaskManager organism functional
- [ ] CLI commands: `task next`, `task recent`, `task current-release`
- [ ] Updated bin/ scripts: bin/tn, bin/tr, bin/rc
- [ ] Unit tests achieving 90%+ coverage
- [ ] Integration tests passing
- [ ] Performance benchmarks established

#### Phase 2 Deliverables  

- [ ] Additional CLI commands: `task all`, `task generate-id`
- [ ] Updated bin/ scripts: bin/tal, bin/tnid
- [ ] Project management foundation started
- [ ] CLI help documentation complete
- [ ] User acceptance testing completed

#### Phase 3 Deliverables

- [ ] Git log functionality: `project git-log`
- [ ] Documentation tools integrated
- [ ] Template synchronization: `project sync-templates`
- [ ] All bin/ scripts updated to use gem
- [ ] Advanced feature testing complete

#### Phase 4 Deliverables

- [ ] All documentation updated
- [ ] Migration guide published
- [ ] End-to-end testing complete
- [ ] Performance optimization complete
- [ ] Deprecation strategy documented

## Next Steps

1. **✅ Review and approve this migration plan** - COMPLETED
2. **✅ Create detailed architectural integration design document** - COMPLETED  
3. **✅ Update workflow instructions to reference new gem-based access patterns** - COMPLETED
4. **🔄 Begin Phase 1 implementation with core task management commands** - READY TO START
5. **📋 Set up project tracking for implementation phases** - PENDING
6. **🧪 Establish testing infrastructure for new components** - PENDING

## Tool Mapping Reference

### Complete Migration Map

| Current bin/ Script | exe-old Tool | New Gem Command | Status |
|-------------------|--------------|-----------------|---------|
| bin/tn | get-next-task | `coding_agent_tools task next` | ✅ Planned |
| bin/tr | get-recent-tasks | `coding_agent_tools task recent` | ✅ Planned |
| bin/tal | get-all-tasks | `coding_agent_tools task all` | ✅ Planned |
| bin/tnid | get-next-task-id | `coding_agent_tools task generate-id` | ✅ Planned |
| bin/rc | get-current-release-path.sh | `coding_agent_tools task current-release` | ✅ Planned |
| bin/tree | show-directory-tree | `coding_agent_tools project tree` | ✅ Planned |
| bin/gl | get-recent-git-log | `coding_agent_tools project git-log` | ✅ Planned |
| bin/lint | lint-md-links.rb + lint-task-metadata | `coding_agent_tools project lint` | ✅ Planned |
| handbook sync-templates | markdown-sync-embedded-documents | `coding_agent_tools project sync-templates` | ✅ Planned |
| bin/cr-docs | generate-doc-review-prompt | `coding_agent_tools project review-prompt` | 📋 Future |

### Interface Compatibility Matrix

| Tool | Current Interface | New Interface | Compatibility |
|------|------------------|---------------|---------------|
| tn | No arguments | No arguments | ✅ Identical |
| tr | `--last N.days` | `--last N.days` | ✅ Identical |
| tal | No arguments | No arguments | ✅ Identical |
| tnid | `version` | `version` | ✅ Identical |
| rc | No arguments | No arguments | ✅ Identical |
| tree | tree options | tree options | ✅ Identical |
| gl | `--include-dev-handbook` etc | same options | ✅ Identical |
| lint | No arguments | No arguments | ✅ Enhanced |
| markdown-sync-embedded-documents | `--dry-run --verbose` etc | same options | ✅ Identical |

---

**Document Status**: Implementation-ready version  
**Last Updated**: 2025-01-07  
**Next Review**: Weekly during implementation phases  
**Implementation Start**: Ready to begin Phase 1
