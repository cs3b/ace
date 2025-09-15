---
id: v.0.5.0+task.047
status: done
priority: high
estimate: 12h
dependencies: [v.0.5.0+task.045]
---

# Improve integrate command with positional arguments and configuration support

## Review Questions (All Resolved)

### [HIGH] Critical Implementation Questions
- [x] Should we deprecate --only flag with warnings or remove it immediately?
  - **Research conducted**: Checked for usage patterns in existing commands
  - **Similar implementations**: Most commands don't have backward compatibility flags
  - **Suggested default**: Deprecate with warning for 2 releases, then remove
  - **Decision**: Remove immediately - no backward compatibility needed (single developer usage)

### [MEDIUM] Enhancement Questions
- [x] Should config subcommand be part of integrate or separate command?
  - **Research conducted**: Analyzed existing command structure patterns
  - **Similar implementations**: task-manager has subcommands, llm has models subcommand
  - **Suggested default**: Make it subcommand of integrate (integrate config)
  - **Decision**: No config subcommand needed - use template from .ace/handbook/.meta/tpl/dotfiles

- [x] What should happen when user has both project and user config with conflicting module defaults?
  - **Research conducted**: Standard precedence is CLI > Project > User > System
  - **Suggested default**: Show warning message about which config is being used
  - **Decision**: Project config always takes precedence silently (no warning needed)

## Behavioral Specification

### User Experience
- **Input**: Users run `coding-agent-tools integrate [TYPE]` with optional module flags
- **Process**: Command loads configuration, determines modules to install based on config and flags, performs integration
- **Output**: Selected modules are integrated with clear feedback about what was installed/skipped

### Expected Behavior

The integrate command should provide an intuitive interface for setting up AI assistant development environments with smart defaults and flexible configuration:

1. **Default behavior**: Running `coding-agent-tools integrate` without arguments integrates all Claude modules
2. **Positional type selection**: Users can specify integration type as positional argument (claude/opencode)
3. **Smart module selection**:
   - No flags → Install all modules (from config or defaults)
   - Positive flags only → Install ONLY specified modules
   - Negative flags only → Install all EXCEPT specified modules
   - Mixed flags → Error with clear message
4. **Configuration hierarchy**: Settings loaded from project, user, and system configs with CLI overrides
5. **Clear feedback**: Users see exactly what modules are being installed and why

### Interface Contract

```bash
# CLI Interface
coding-agent-tools integrate [TYPE] [OPTIONS]

# Default (integrate everything for claude)
coding-agent-tools integrate
# Output: Installing all modules for Claude integration...

# Positional type argument
coding-agent-tools integrate claude    # Explicit claude
coding-agent-tools integrate opencode  # Coming soon message

# Module selection patterns
coding-agent-tools integrate --agents --commands
# Output: Installing ONLY: agents, commands

coding-agent-tools integrate --no-hooks --no-docs
# Output: Installing all modules EXCEPT: hooks, docs

# Configuration is managed via .coding-agent/integrate.yml file
# (copied from template during --dotfiles integration)

# Options
--agents              # Include agent definitions
--commands            # Include command files
--dotfiles            # Include configuration dotfiles
--docs                # Update documentation
--submodules          # Setup git submodules
--config              # Include config files
--hooks               # Include git hooks
--force               # Force overwrite (creates backup)
--no-backup           # Skip backup when using --force
--dry-run             # Preview changes without applying
--verbose             # Show detailed output
```

**Error Handling:**
- Mixed positive/negative flags: "Cannot mix --module and --no-module flags. Use either positive flags to specify what to install, or negative flags to specify what to skip."
- Invalid type: "Unknown integration type 'xyz'. Available: claude, opencode"
- Missing submodule: Automatically setup from configuration
- Existing files without --force: Skip with message "Skipping existing: [file]"

**Edge Cases:**
- No configuration file: Use built-in defaults
- Empty configuration: Treat as "install all"
- Conflicting configs: CLI > Project > User > System precedence

### Success Criteria

- [ ] **Intuitive defaults**: `coding-agent-tools integrate` works without any flags
- [ ] **Clear module selection**: Users can easily select or exclude specific modules
- [ ] **Configuration support**: Users can set defaults in config files
- [ ] **Helpful error messages**: Mixed flags produce clear guidance
- [ ] **Predictable behavior**: Flag logic is consistent and documented

### Validation Questions (Resolved Through Research)

- [x] **Config file format**: Should we use YAML or TOML for configuration files?
  - **Resolution**: Use YAML - project already uses YAML extensively (integration.yml, fallback_models.yaml)
  - **Evidence**: Found existing YAML files and deep_merge implementation for YAML in config_extractor.rb
  
- [x] **Module granularity**: Are the current modules (agents, commands, etc.) the right level of granularity?
  - **Resolution**: Current granularity is appropriate - matches existing config structure
  - **Evidence**: Existing integration.yml already defines these modules as components
  
- [ ] **Backward compatibility**: Should we maintain support for `--only` flag alongside new logic?
  - **Moved to Review Questions** - Needs human decision on migration strategy
  
- [x] **Config locations**: Are the XDG paths correct for all platforms?
  - **Resolution**: Yes, project already has XDGDirectoryResolver atom with proper implementation
  - **Evidence**: Found XDGDirectoryResolver in atoms/ with cache_directory method

## Objective

Improve the user experience of the integrate command by making it more intuitive with smart defaults, clear module selection logic, and configuration file support. Users should be able to run the command without remembering complex flag combinations.

## Scope of Work

- **User Experience Scope**: Command-line interface improvements, configuration file management, clear feedback messages
- **System Behavior Scope**: Module selection logic, configuration loading and merging, error handling
- **Interface Scope**: CLI arguments and flags, configuration file format, output messages

### Deliverables

#### Behavioral Specifications
- Positional argument handling for integration type
- Module selection logic based on flag patterns
- Configuration file loading hierarchy
- Error message specifications

#### Validation Artifacts
- Command usage examples for all patterns
- Configuration file template
- Test scenarios for flag combinations

## Out of Scope

- ❌ **Implementation Details**: Ruby class structure, file organization
- ❌ **Technology Decisions**: Specific YAML parsing libraries
- ❌ **Performance Optimization**: Caching strategies for config files
- ❌ **Future Enhancements**: Additional integration types beyond claude/opencode

## Technical Approach

### Architecture Pattern
- **Command Pattern**: Enhanced integrate command with positional arguments
- **Strategy Pattern**: Module selection logic based on flag patterns
- **Chain of Responsibility**: Configuration loading hierarchy
- **Template Method**: Systematic module integration with hooks

### Technology Stack
- **CLI Framework**: dry-cli (existing) with argument support - CONFIRMED via llm/query.rb
- **Configuration**: YAML format with deep_merge method from config_extractor.rb
- **Path Resolution**: XDGDirectoryResolver atom (existing) for config paths
- **Module Management**: Dynamic module detection and selection

### Implementation Strategy
- **Incremental Enhancement**: Build on existing integrate command
- **Backward Compatibility**: Remove --only flag after new logic works
- **Configuration First**: Load config before processing CLI flags
- **Clear Precedence**: CLI > Project > User > System configs

## File Modifications

### Create
- **dev-handbook/.meta/tpl/dotfiles/.coding-agent/integrate.yml**
  - Purpose: Default configuration template for projects
  - Key components: Module defaults, preferences, integration overrides
  - Note: Gets copied during --dotfiles integration, not a subcommand

### Modify
- **lib/coding_agent_tools/cli/commands/integrate.rb**
  - Changes: Add positional argument, update option definitions, implement new logic
  - Impact: Core command behavior and user interface
  
- **dev-tools/config/integration.yml**
  - Changes: Add hooks and config module definitions
  - Impact: System default configuration

### Delete
- **--only option** from integrate.rb (after new logic is tested)
  - Reason: Redundant with new module selection logic

## Implementation Plan

### Planning Steps (Completed During Review)
* [x] **Research CLI argument patterns**: Confirmed dry-cli supports arguments via llm/query.rb example
* [x] **Design configuration hierarchy**: Defined CLI > Project > User > System precedence
* [x] **Plan module selection logic**: Created clear decision tree for flag combinations
* [x] **Identify XDG paths**: Found existing XDGDirectoryResolver atom with proper implementation

### Execution Steps
- [x] **Update Command Structure**: Add positional argument support
  > TEST: Positional Argument Parsing
  > Type: Structural Validation
  > Assert: TYPE argument correctly parsed and defaults to "claude"
  > Command: coding-agent-tools integrate opencode --dry-run | grep "Coming soon"

- [x] **Implement Module Flag Logic**: Change options to default nil
  > TEST: Module Selection Logic
  > Type: Behavioral Test
  > Assert: Correct modules selected based on flag patterns
  > Command: coding-agent-tools integrate --agents --commands --dry-run | grep "ONLY"

- [x] **Add Configuration Loading**: Implement config hierarchy
  > TEST: Configuration Loading
  > Type: Integration Test
  > Assert: Config files loaded in correct order (CLI > Project > User > System)
  > Command: coding-agent-tools integrate --verbose --dry-run | grep "Loading config"

- [x] **Create Config Template**: Add integrate.yml to .ace/handbook/.meta/tpl/dotfiles
  > TEST: Template Installation
  > Type: File Operation Test
  > Assert: Config template installed with dotfiles
  > Command: test -f .coding-agent/integrate.yml

- [x] **Implement Module Determination**: Smart flag interpretation
  > TEST: Mixed Flag Prevention
  > Type: Error Handling Test
  > Assert: Mixed flags produce clear error
  > Command: coding-agent-tools integrate --agents --no-commands 2>&1 | grep "Cannot mix"

- [x] **Update Help Text**: Clear documentation of new behavior
  > TEST: Help Documentation
  > Type: Documentation Test
  > Assert: Help shows module flags without defaults
  > Command: coding-agent-tools integrate --help | grep -v "default: true"

- [x] **Test All Patterns**: Verify all usage patterns work
  > TEST: Integration Patterns
  > Type: End-to-End Test
  > Assert: All documented patterns work correctly
  > Command: # Run comprehensive test suite

## Risk Assessment

### Technical Risks
- **Risk:** Positional arguments may not be fully supported in dry-cli
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Fall back to required --type option if needed
  - **Rollback:** Keep current boolean flags temporarily

- **Risk:** Configuration merge complexity with deep nesting
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Use robust deep merge library
  - **Rollback:** Simplify to single-level configuration

### Integration Risks
- **Risk:** Breaking existing user workflows using --only
  - **Probability:** High
  - **Impact:** Medium
  - **Mitigation:** Deprecate --only gradually with warnings
  - **Monitoring:** Track usage of deprecated flag

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [x] **Default behavior works**: `coding-agent-tools integrate` installs all Claude modules
- [x] **Positional type works**: `coding-agent-tools integrate claude` explicitly specifies type
- [x] **Module selection works**: Positive and negative flags work as specified
- [x] **Configuration loads**: Config files are found and merged correctly
- [x] **Error messages help**: Mixed flags produce actionable guidance

### Implementation Quality Assurance
- [x] **Code follows patterns**: Implementation matches existing codebase style
- [x] **Tests cover scenarios**: All flag combinations tested
- [x] **Documentation complete**: Help text and config template clear
- [x] **Performance acceptable**: Config loading doesn't slow command

### Documentation and Validation
- [x] **Help text updated**: Shows new usage patterns clearly
- [x] **Config template created**: Includes all options with documentation
- [x] **Examples provided**: Common usage patterns documented
- [x] **Migration path clear**: Users know how to update from --only

## References

- Previous task: v.0.5.0+task.045 (Create unified coding-agent-tools integrate command)
- XDG Base Directory Specification
- Common CLI patterns for module selection (npm, cargo, etc.)
- dry-cli documentation for argument support

## Review Summary

**Date**: 2025-01-30
**Questions Resolved**: All 3 questions answered
**Implementation Readiness**: Fully ready - all decisions made

### Decisions Made
1. **--only flag**: Remove immediately, no backward compatibility needed
2. **Config management**: Use template file from .ace/handbook/.meta/tpl/dotfiles (no subcommand)
3. **Config precedence**: Project config takes precedence silently over user config

### Research Completed
- Confirmed dry-cli supports positional arguments (found in llm/query.rb)
- Verified YAML is the standard config format in project
- Located existing XDGDirectoryResolver for config paths
- Found deep_merge implementation for config merging

### Recommended Next Steps
1. Proceed with implementation immediately
2. Create config template in .ace/handbook/.meta/tpl/dotfiles/.coding-agent/integrate.yml
3. Remove --only flag completely from integrate command

The task is now fully ready for implementation with all decisions made.