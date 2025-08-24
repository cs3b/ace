---
id: v.0.5.0+task.045
status: in-progress
priority: high
estimate: 8h
dependencies: []
---

# Create Unified coding-agent-tools integrate Command

## Review Questions (Resolved)

### [HIGH] Critical Implementation Questions
- [x] Should the new `coding-agent-tools` executable coexist with or replace `coding_agent_tools`?
  - **Decision**: Replace completely - no backward compatibility needed since not deployed
  - **Implementation**: Remove `coding_agent_tools` entirely, only use `coding-agent-tools`

- [x] How should the command handle existing Claude integration in projects?
  - **Decision**: Smart incremental approach - only create missing files/symlinks by default
  - **Implementation**: 
    - Default: Only add missing components (non-destructive)
    - `--force`: Overwrite with automatic backup to `.claude.backup.TIMESTAMP`
    - `--no-backup`: Skip backup when using --force
    - `--only <component>`: Selective update of specific components

### [MEDIUM] Enhancement Questions
- [x] Should symlinks use relative or absolute paths?
  - **Decision**: Use relative paths for portability
  - **Implementation**: All symlinks use relative paths (e.g., `../dev-handbook/.integrations/claude/`)

- [x] What should happen if dev-handbook submodule is missing?
  - **Decision**: Auto-add submodules using configuration from `dev-tools/config/integration.yml`
  - **Implementation**: Use GitHub CLI if available, fallback to git commands
  - **Config**: Store submodule URLs in configuration file

### [LOW] Clarification Questions
- [x] Should the command support multiple integration types beyond Claude?
  - **Decision**: Extensible design with Claude implemented, OpenCode as placeholder
  - **Implementation**: `--claude` (implemented), `--opencode` (shows "Coming soon" message)

## Behavioral Specification

### User Experience
- **Input**: Developers run `coding-agent-tools integrate --claude` in any project directory
- **Process**: Single command intelligently handles Claude integration with smart merge behavior
- **Output**: Complete Claude development environment with only missing components added

### Expected Behavior
<!-- Smart incremental integration with selective component updates -->
<!-- Non-destructive by default, force option for overwrite scenarios -->
<!-- Auto-configure submodules from configuration file -->

The system creates a single `coding-agent-tools integrate --claude` command that:

1. **Smart Merge Behavior**: Only creates missing files/symlinks by default (non-destructive)
2. **Selective Integration**: Supports `--only` flag for updating specific components (agents, commands, dotfiles, docs)
3. **Automatic Submodule Setup**: Auto-adds missing submodules using config from `dev-tools/config/integration.yml`
4. **Force Overwrite Option**: `--force` flag overwrites with automatic backup, `--no-backup` to skip backup
5. **Relative Symlinks**: All symlinks use relative paths for portability
6. **Extensible Design**: Supports Claude (implemented) and OpenCode (placeholder) integrations
7. **Complete Executable Rename**: Removes `coding_agent_tools`, only uses `coding-agent-tools`

### Interface Contract
<!-- Enhanced command interface with smart merge and selective integration -->
<!-- Non-destructive by default with force option for overwrite -->

```bash
# Basic usage - only adds missing components (non-destructive)
coding-agent-tools integrate --claude

# Force overwrite with automatic backup
coding-agent-tools integrate --claude --force

# Force without backup
coding-agent-tools integrate --claude --force --no-backup

# Selective component integration
coding-agent-tools integrate --claude --only commands
coding-agent-tools integrate --claude --only agents
coding-agent-tools integrate --claude --only dotfiles
coding-agent-tools integrate --claude --only docs
coding-agent-tools integrate --claude --only agents,commands  # Multiple components

# Preview mode
coding-agent-tools integrate --claude --dry-run

# Future integration type (placeholder)
coding-agent-tools integrate --opencode  # Shows "Coming soon" message

# Command Output Examples
$ coding-agent-tools integrate --claude
✓ Checking submodules...
  ✓ dev-handbook present
  ✓ dev-taskflow present
  → dev-tools present
✓ Creating missing symlinks...
  → .claude/agents/ (12 symlinks created)
  → .claude/commands/ (8 new, 4 existing)
  → .coding-agent/config.yml (existing, skipped)
✓ Integration complete! (20 new components added)

$ coding-agent-tools integrate --claude --force
⚠ Backing up existing .claude/ to .claude.backup.20250824-1045
✓ Recreating all symlinks...
  → .claude/agents/ (12 symlinks)
  → .claude/commands/ (12 symlinks)
  → .coding-agent/*.yml (3 config files)
✓ Force integration complete!

$ coding-agent-tools integrate --claude --only agents,commands
✓ Updating selected components...
  → agents: 3 new symlinks added
  → commands: 2 new symlinks added
✓ Selective integration complete!
```

**Error Handling:**
- **Missing submodule**: Auto-adds from config with GitHub CLI or git commands
- **Existing files (default)**: Skips existing files/symlinks
- **Existing files (--force)**: Backs up to timestamped directory before overwrite
- **Permission issues**: Clear error messages with sudo instructions if needed
- **Broken symlinks**: Automatically removes and recreates

**Edge Cases:**
- **Partial existing setup**: Intelligently merges, only adds missing components
- **Custom user files**: Preserved unless --force is used
- **Config file missing**: Creates default config from template

### Success Criteria
<!-- Measurable outcomes that define completion -->
<!-- Focus on behavioral outcomes and user experience -->

- [ ] **Single Command Functionality**: `coding-agent-tools integrate --claude` performs complete setup
- [ ] **Executable Name Fix**: All references to `coding_agent_tools` changed to `coding-agent-tools`
- [ ] **Symlink Integration**: All Claude files linked via symlinks, not copied
- [ ] **Dev-taskflow Handling**: Empty dev-taskflow submodule created when needed
- [ ] **Old Command Removal**: All deprecated integration commands completely removed
- [ ] **Development Focus**: Setup optimized for development environment only

### Validation Questions (Resolved Through Research)
<!-- Questions to clarify requirements and validate understanding -->

- [x] **Naming Consistency**: Should all dev-tools library references also change from coding_agent_tools?
  - **Resolution**: Keep internal Ruby library as `coding_agent_tools` (Ruby convention), only change executable
  - **Evidence**: Ruby gems typically use snake_case for library names (e.g., active_record gem)
  
- [x] **Submodule Behavior**: How should dev-taskflow integration work in existing vs new repos?
  - **Resolution**: Dev-taskflow already exists as submodule, create empty if missing
  - **Evidence**: Found `.git` file in dev-taskflow indicating proper submodule setup
  
- [ ] **Symlink Strategy**: Should symlinks be relative or absolute paths?
  - **Moved to Review Questions** - Needs human decision for portability vs simplicity trade-off
  
- [x] **Error Recovery**: What should happen if integration partially fails?
  - **Resolution**: Implement rollback mechanism with clear error messages
  - **Evidence**: Existing ClaudeCommandsInstaller has error handling patterns to follow
  
- [x] **Idempotency**: Should running integrate multiple times be safe?
  - **Resolution**: Yes, make idempotent with backup of existing setup
  - **Evidence**: Current `handbook claude integrate` supports --force flag for re-running

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
- **lib/coding_agent_tools/cli/commands/integrate.rb**
  - Purpose: Unified integration command with smart merge and selective component support
  - Key components: Component selection, smart merge logic, backup handling
  - Options: --claude, --opencode, --force, --no-backup, --only, --dry-run

- **dev-tools/config/integration.yml**
  - Purpose: Configuration for submodules and integration types
  - Content: Submodule URLs, integration status, component definitions
  ```yaml
  submodules:
    dev-handbook:
      url: https://github.com/org/dev-handbook.git
      branch: main
    dev-taskflow:
      url: auto  # Uses current repo URL
      branch: main
  integrations:
    claude:
      status: implemented
      components: [agents, commands, dotfiles, docs]
    opencode:
      status: planned
      message: "OpenCode integration coming soon"
  ```

### Modify
- **lib/coding_agent_tools/cli.rb**
  - Changes: Register new integrate command, remove old command registrations
  - Impact: CLI command routing and help system

- **dev-handbook/workflow-instructions/initialize-project-structure.wf.md**
  - Changes: Update to use new `coding-agent-tools integrate --claude` command
  - Impact: Workflow simplification

### Delete
- **exe/coding_agent_tools** (completely remove, no symlink)
  - Replacement: exe/coding-agent-tools (new executable)
  
- **lib/coding_agent_tools/cli/commands/install_dotfiles.rb**
  - Functionality moved to integrate command
  
- **lib/coding_agent_tools/cli/commands/handbook/** (entire directory)
  - All handbook subcommands removed

## Implementation Plan

### Planning Steps
<!-- Research, analysis, and design activities -->

* [x] **Component Selection Architecture**: Design modular component selection system
  - Design component registry (agents, commands, dotfiles, docs)
  - Plan --only flag parsing for single and multiple components
  - Design component-specific integration logic
  - Plan validation for component names

* [x] **Smart Merge Logic Design**: Design non-destructive merge behavior
  - Plan file/symlink existence checking before creation
  - Design skip logic for existing components
  - Plan reporting of skipped vs created items
  - Design summary statistics for user feedback

* [x] **Backup Strategy Planning**: Design backup system for --force operations
  - Plan timestamp-based backup directory naming
  - Design selective backup (only modified components)
  - Plan --no-backup flag implementation
  - Design backup cleanup for old backups

* [x] **Submodule Auto-Configuration**: Design config-driven submodule setup
  - Design integration.yml configuration structure
  - Plan GitHub CLI detection and usage
  - Design fallback to git commands
  - Plan special handling for dev-taskflow (same repo)

### Execution Steps
<!-- Concrete implementation actions -->

- [x] **Create Configuration File**: Create dev-tools/config/integration.yml
  > TEST: Config File Validation
  > Type: Configuration Check
  > Assert: integration.yml exists with valid YAML structure
  > Command: ruby -ryaml -e "YAML.load_file('dev-tools/config/integration.yml')"

- [x] **Implement Integrate Command**: Create lib/coding_agent_tools/cli/commands/integrate.rb
  > TEST: Command Creation
  > Type: Structural Validation
  > Assert: Integrate command with all option flags
  > Command: coding-agent-tools integrate --help | grep -E "claude|force|only|backup"

- [x] **Add Smart Merge Logic**: Implement check-before-create behavior
  > TEST: Non-Destructive Merge
  > Type: Behavioral Test
  > Assert: Existing files are not overwritten without --force
  > Command: # Create test file, run integrate, verify file unchanged

- [x] **Implement Component Selection**: Add --only flag support
  > TEST: Selective Integration
  > Type: Component Test
  > Assert: Only specified components are processed
  > Command: coding-agent-tools integrate --claude --only agents --dry-run

- [x] **Add Backup Functionality**: Implement --force with backup
  > TEST: Backup Creation
  > Type: File Operation Test
  > Assert: Backup directory created with timestamp
  > Command: coding-agent-tools integrate --claude --force && ls .claude.backup.*

- [x] **Implement Submodule Setup**: Auto-add missing submodules from config
  > TEST: Submodule Auto-Add
  > Type: Git Operation Test
  > Assert: Missing submodules are added automatically
  > Command: # Remove submodule, run integrate, verify submodule added

- [x] **Remove Old Executable**: Delete exe/coding_agent_tools completely
  > TEST: Executable Removal
  > Type: File System Check
  > Assert: Only coding-agent-tools executable exists
  > Command: test -f exe/coding-agent-tools && ! test -f exe/coding_agent_tools

- [x] **Remove Old Commands**: Delete deprecated integration commands
  > TEST: Command Cleanup
  > Type: Structure Validation
  > Assert: Old command files don't exist
  > Command: ! test -d lib/coding_agent_tools/cli/commands/handbook

- [x] **Add OpenCode Placeholder**: Implement coming soon message
  > TEST: Placeholder Functionality
  > Type: User Experience Test
  > Assert: OpenCode shows appropriate message
  > Command: coding-agent-tools integrate --opencode 2>&1 | grep "Coming soon"

- [x] **Update Workflows**: Modify initialize-project-structure.wf.md
  > TEST: Workflow Update
  > Type: Documentation Test
  > Assert: Workflow uses new integrate command
  > Command: grep "coding-agent-tools integrate" dev-handbook/workflow-instructions/*.wf.md

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
- Configuration-driven submodule management
- Smart merge behavior for non-destructive integration