---
id: v.0.5.0+task.045
status: pending
priority: high
estimate: 8h
dependencies: []
---

# Create Unified coding-agent-tools integrate Command

## Behavioral Specification

### User Experience
- **Input**: Developers run `coding-agent-tools integrate --claude` in any project directory
- **Process**: Single command handles all Claude integration setup, replacing multiple fragmented commands
- **Output**: Complete Claude development environment with agents, commands, and tools properly linked

### Expected Behavior
<!-- Consolidate all project integration functionality into a unified command -->
<!-- Replace fragmented integration commands with single comprehensive solution -->
<!-- Handle dev-taskflow as empty submodule within existing repositories -->

The system creates a single `coding-agent-tools integrate --claude` command that:

1. **Fixes executable naming**: Changes from `coding_agent_tools` to `coding-agent-tools` throughout
2. **Handles submodule integration**: Creates empty dev-taskflow submodule when needed within existing repos
3. **Uses symlinks by default**: Creates symlinks for all Claude files (agents, commands, configs) instead of copying
4. **Development-focused**: Optimized for development environment setup only
5. **Replaces old commands**: Completely removes deprecated integration commands
6. **No backward compatibility**: Clean break from old fragmented approach

### Interface Contract
<!-- Single unified command with comprehensive functionality -->
<!-- Replaces multiple separate integration commands -->

```bash
# Primary Integration Command
coding-agent-tools integrate --claude
# Comprehensive setup: fixes executables, creates submodules, symlinks all files
# No additional flags needed - development-focused setup is default

# Command Output Examples
$ coding-agent-tools integrate --claude
✓ Fixed executable naming: coding_agent_tools → coding-agent-tools
✓ Created dev-taskflow submodule (empty) 
✓ Created .claude/agents/ symlinks → dev-handbook/.integrations/claude/agents/
✓ Created .claude/commands/ symlinks → dev-handbook/.integrations/claude/commands/
✓ Configured Claude development environment
✓ Integration complete!

# Removed Commands (no longer available)
# handbook claude integrate      # ❌ REMOVED
# install-dotfiles               # ❌ REMOVED  
# initialize-project-structure   # ❌ REMOVED
```

**Error Handling:**
- **Existing .claude directory**: Backup and recreate with symlinks
- **Missing dev-handbook submodule**: Error with clear setup instructions
- **Permission issues**: Clear error messages with resolution steps
- **Git repository not found**: Error requiring git repository

**Edge Cases:**
- **Partial existing setup**: Clean existing setup before creating new
- **Broken symlinks**: Remove and recreate all symlinks
- **Multiple integration attempts**: Idempotent operation, safe to re-run

### Success Criteria
<!-- Measurable outcomes that define completion -->
<!-- Focus on behavioral outcomes and user experience -->

- [ ] **Single Command Functionality**: `coding-agent-tools integrate --claude` performs complete setup
- [ ] **Executable Name Fix**: All references to `coding_agent_tools` changed to `coding-agent-tools`
- [ ] **Symlink Integration**: All Claude files linked via symlinks, not copied
- [ ] **Dev-taskflow Handling**: Empty dev-taskflow submodule created when needed
- [ ] **Old Command Removal**: All deprecated integration commands completely removed
- [ ] **Development Focus**: Setup optimized for development environment only

### Validation Questions
<!-- Questions to clarify requirements and validate understanding -->

- [ ] **Naming Consistency**: Should all dev-tools library references also change from coding_agent_tools?
- [ ] **Submodule Behavior**: How should dev-taskflow integration work in existing vs new repos?
- [ ] **Symlink Strategy**: Should symlinks be relative or absolute paths?
- [ ] **Error Recovery**: What should happen if integration partially fails?
- [ ] **Idempotency**: Should running integrate multiple times be safe?

## Objective

Consolidate fragmented project integration approach into single unified command that provides complete Claude development environment setup. Eliminate confusion from multiple integration commands and ensure consistent development experience.

## Scope of Work

- Create new unified `coding-agent-tools integrate --claude` command
- Fix executable naming throughout codebase (coding_agent_tools → coding-agent-tools)
- Implement symlink-based Claude file integration
- Handle dev-taskflow as empty submodule creation
- Remove all deprecated integration commands
- Update related documentation and workflows

### Deliverables

#### Create

- lib/coding_agent_tools/cli/commands/integrate.rb - New unified integrate command class
- exe/coding-agent-tools - Renamed main executable (from coding_agent_tools)
- dev-handbook/.integrations/claude/agents/ symlinks in .claude/agents/
- dev-handbook/.integrations/claude/commands/ symlinks in .claude/commands/

#### Modify

- lib/coding_agent_tools/cli.rb - Update command registration for integrate
- lib/coding_agent_tools.rb - Update main module for renamed executable
- dev-tools/exe/* - All executable shebang references to use coding-agent-tools
- lib/coding_agent_tools/**/*.rb - All internal library references to new naming
- spec/**/*.rb - All test references to new naming
- docs/**/*.md - All documentation references to new naming

#### Delete

- lib/coding_agent_tools/cli/commands/install_dotfiles.rb - Remove deprecated command
- lib/coding_agent_tools/cli/commands/handbook/claude/integrate.rb - Remove old integrate
- Related workflow files using initialize-project-structure pattern
- All references to old command patterns in documentation

## Technical Approach

### Architecture Pattern
- **Command Pattern**: Unified integrate command following existing CLI structure
- **Facade Pattern**: Single command interface hiding complexity of multiple operations
- **Template Method**: Systematic integration steps with error handling
- **Integration Point**: Extends existing dry-cli framework in dev-tools

### Technology Stack
- **CLI Framework**: dry-cli (existing)
- **File Operations**: Ruby FileUtils with symlink support
- **Git Operations**: Ruby git library or shell commands
- **Path Resolution**: Existing path resolution atoms
- **Error Handling**: Existing ErrorReporter infrastructure

### Implementation Strategy
- **Incremental Migration**: Create new command, then remove old ones
- **Backward Compatibility**: None - clean break from old approach
- **Error Recovery**: Comprehensive rollback for partial failures
- **Idempotent Operations**: Safe to run multiple times

## File Modifications

### Create
- lib/coding_agent_tools/cli/commands/integrate.rb
  - Purpose: Unified integration command replacing fragmented approach
  - Key components: Claude setup, submodule creation, symlink management
  - Dependencies: Existing file operations, git commands, path resolution

### Modify
- lib/coding_agent_tools/cli.rb
  - Changes: Register new integrate command, remove old command registrations
  - Impact: CLI command routing and help system
  - Integration points: Command discovery and execution

### Rename
- exe/coding_agent_tools → exe/coding-agent-tools
  - Type: Executable file rename
  - Related renames:
    - Library directories: Keep lib/coding_agent_tools/ (Ruby convention)
    - Module names: Keep CodingAgentTools (Ruby convention)
    - Executable references: All shebang lines and documentation
  - Import updates: No Ruby require/import changes needed
  - Documentation updates: ~50 markdown files with executable references

### Delete
- lib/coding_agent_tools/cli/commands/install_dotfiles.rb
  - Reason: Functionality integrated into unified command
  - Dependencies: Remove from CLI command registry
  - Migration strategy: Functionality absorbed by integrate command

- lib/coding_agent_tools/cli/commands/handbook/claude/integrate.rb
  - Reason: Replaced by unified integrate command
  - Dependencies: Remove handbook claude subcommand structure
  - Migration strategy: Core logic moved to new integrate command

## Implementation Plan

### Planning Steps
<!-- Research, analysis, and design activities -->

* [ ] **Current Integration Analysis**: Map all existing integration commands and their functionality
  - Analyze install_dotfiles.rb functionality and file operations
  - Analyze handbook claude integrate functionality and ClaudeCommandsInstaller
  - Document all file patterns and directory structures created
  - Identify overlap and unique functionality in each approach

* [ ] **Naming Impact Assessment**: Comprehensive analysis of coding_agent_tools → coding-agent-tools impact
  - Search all files containing "coding_agent_tools" references
  - Categorize by type: executables, documentation, tests, library code
  - Plan systematic renaming approach maintaining Ruby module conventions
  - Validate that internal Ruby code keeps snake_case while executable uses kebab-case

* [ ] **Symlink Strategy Design**: Research and design symlink-based integration approach
  - Analyze relative vs absolute symlink implications
  - Design directory structure for .claude/ integration
  - Plan cleanup and recreation strategies for existing setups
  - Design error recovery for broken or partial symlinks

* [ ] **Submodule Integration Research**: Design dev-taskflow empty submodule creation
  - Research Git submodule commands and best practices
  - Design detection of existing vs new repository scenarios
  - Plan submodule initialization for empty repositories
  - Design error handling for submodule creation failures

### Execution Steps
<!-- Concrete implementation actions -->

- [ ] **Create Integrate Command**: Implement unified lib/coding_agent_tools/cli/commands/integrate.rb
  > TEST: Command Creation Verification
  > Type: Structural Validation
  > Assert: Integrate command class exists and is properly structured
  > Command: rspec spec/coding_agent_tools/cli/commands/integrate_spec.rb

- [ ] **Implement Claude Integration Logic**: Add Claude file symlink creation functionality
  > TEST: Symlink Creation Validation
  > Type: File Operation Test
  > Assert: .claude directories created with proper symlinks to dev-handbook
  > Command: bin/test --verify-symlinks .claude/

- [ ] **Add Dev-taskflow Submodule Creation**: Implement empty submodule initialization
  > TEST: Submodule Creation Check
  > Type: Git Operation Validation
  > Assert: dev-taskflow submodule created when needed
  > Command: git submodule status | grep dev-taskflow

- [ ] **Rename Main Executable**: Rename exe/coding_agent_tools to exe/coding-agent-tools
  > TEST: Executable Rename Validation
  > Type: File System Check
  > Assert: New executable exists and old one is removed
  > Command: test -f exe/coding-agent-tools && ! test -f exe/coding_agent_tools

- [ ] **Update CLI Command Registration**: Modify lib/coding_agent_tools/cli.rb to register integrate command
  > TEST: Command Registration Check
  > Type: CLI Integration Test
  > Assert: integrate command appears in help and is executable
  > Command: exe/coding-agent-tools --help | grep "integrate"

- [ ] **Remove Deprecated Commands**: Delete install_dotfiles.rb and handbook/claude/integrate.rb
  > TEST: Deprecated Command Removal
  > Type: Cleanup Validation
  > Assert: Old command files are removed and not registered
  > Command: ! test -f lib/coding_agent_tools/cli/commands/install_dotfiles.rb

- [ ] **Update All Documentation References**: Change all executable references from coding_agent_tools to coding-agent-tools
  > TEST: Documentation Update Verification
  > Type: Content Validation
  > Assert: No documentation references to old executable name
  > Command: grep -r "coding_agent_tools" docs/ | wc -l | grep "0"

- [ ] **Run Integration Tests**: Execute comprehensive integration tests for new command
  > TEST: End-to-End Integration
  > Type: Full Workflow Test
  > Assert: coding-agent-tools integrate --claude works end-to-end
  > Command: rspec spec/integration/unified_integration_spec.rb

## Risk Assessment

### Technical Risks
- **Risk:** Symlink compatibility issues across different operating systems
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Test on macOS, Linux, and Windows; provide fallback copy mechanism
  - **Rollback:** Revert to copy-based approach if symlinks fail

- **Risk:** Git submodule creation failures in different repository states
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Comprehensive git state detection and error handling
  - **Rollback:** Skip submodule creation and continue with other integration steps

### Integration Risks
- **Risk:** Breaking existing workflows that depend on old commands
  - **Probability:** High
  - **Impact:** High
  - **Mitigation:** Update all known workflow references before removal
  - **Monitoring:** Monitor for error reports about missing commands

- **Risk:** Partial integration leaving development environment in broken state
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Implement comprehensive rollback mechanism
  - **Monitoring:** Validation checks at each integration step

### Performance Risks
- **Risk:** Symlink performance impact on large directory structures
  - **Mitigation:** Benchmark symlink vs copy performance
  - **Monitoring:** Integration time measurement
  - **Thresholds:** Integration should complete within 30 seconds

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [ ] **Single Command Success**: `coding-agent-tools integrate --claude` performs complete setup
- [ ] **Executable Rename Complete**: All references use coding-agent-tools naming
- [ ] **Symlink Integration Working**: Claude files properly linked via symlinks
- [ ] **Submodule Creation Success**: Dev-taskflow submodule created when appropriate
- [ ] **Old Command Removal**: Deprecated commands completely removed and non-functional

### Implementation Quality Assurance
- [ ] **Code Quality**: New integrate command follows project patterns and passes linting
- [ ] **Test Coverage**: All integration scenarios covered by automated tests
- [ ] **Error Handling**: Graceful error handling with clear user messages
- [ ] **Rollback Capability**: Failed integration can be cleanly rolled back

### Documentation and Validation
- [ ] **Documentation Updated**: All references to executable naming updated
- [ ] **Integration Guide**: Clear documentation for new unified command
- [ ] **Migration Path**: Clear instructions for users with existing setups

- ❌ **Production Mode**: Production deployment or enterprise configuration
- ❌ **Backward Compatibility**: Support for old integration commands
- ❌ **Custom Integration Modes**: Additional integration patterns beyond Claude
- ❌ **Cross-Platform GUI**: Graphical interface for integration process

## References

- Current fragmented commands: install_dotfiles.rb, handbook/claude/integrate.rb
- Existing ClaudeCommandsInstaller integration logic
- User requirement for unified integration approach
- Executable naming consistency requirement