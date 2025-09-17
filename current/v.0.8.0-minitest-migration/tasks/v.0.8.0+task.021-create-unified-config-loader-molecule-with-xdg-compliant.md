---
id: v.0.8.0+task.021
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# Create unified config loader molecule with XDG-compliant priority resolution

## Behavioral Specification

### User Experience
- **Input**: Developer runs any ace-tools command requiring configuration (e.g., `ace-test`, `code-review`)
- **Process**: System automatically discovers config files using consistent priority order without developer intervention
- **Output**: Command uses the highest-priority available configuration file transparently

### Expected Behavior

**Consistent Config Discovery**: All ace-tools commands should discover configuration files using identical logic and priority ordering. Developers should never need to understand different config loading behaviors for different commands.

**XDG Compliance**: Configuration file discovery should respect the XDG Base Directory Specification, allowing users to control config locations through standard environment variables (XDG_CONFIG_HOME, etc.).

**Priority-Based Resolution**: The system should check for configuration files in order of decreasing priority:
1. **Project Root**: `.coding-agent/{config-type}.yml` (highest priority for local development)
2. **System Config**: System-wide configuration directory via XDG
3. **Home Config**: User-specific configuration via XDG (lowest priority)

**Graceful Fallbacks**: If no configuration file exists at any priority level, commands should either use embedded defaults or clearly indicate missing configuration.

### Interface Contract

```ruby
# ConfigLoader Interface
# Returns path to highest-priority existing config file, or nil if none found
config_path = AceTools::Molecules::ConfigLoader.load(:ace_test)
config_path = AceTools::Molecules::ConfigLoader.load(:code_review)
config_path = AceTools::Molecules::ConfigLoader.load(:custom_config)

# Alternative interface for loading and parsing
config_data = AceTools::Molecules::ConfigLoader.load_and_parse(:ace_test)

# Discovery information for debugging
info = AceTools::Molecules::ConfigLoader.discovery_info(:ace_test)
# Returns: { checked_paths: [...], found_path: "...", priority_level: "project" }
```

**Error Handling:**
- Invalid config type: Return nil and optionally log warning
- Permission denied: Skip inaccessible files, continue with lower priority
- Malformed config files: Allow caller to handle parsing errors

**Edge Cases:**
- No configuration files exist: Return nil (caller handles defaults)
- Multiple valid configs: Return highest priority only
- Symlinks and aliases: Follow symlinks to actual file locations

### Success Criteria

- [ ] **Unified Interface**: Single ConfigLoader.load(type) method works for all config types
- [ ] **Priority Resolution**: Project configs override system configs override home configs
- [ ] **XDG Compliance**: Respects XDG_CONFIG_HOME and standard XDG directory structure
- [ ] **Command Migration**: ace-test and other commands use ConfigLoader instead of manual loading
- [ ] **Backward Compatibility**: Existing config file locations continue to work
- [ ] **Performance**: Config discovery is efficient and caches results when appropriate

### Validation Questions

- [ ] **Config Type Naming**: Should config types use symbols (:ace_test) or strings ("ace-test")?
- [ ] **Caching Strategy**: Should config paths be cached for performance, or discovered fresh each time?
- [ ] **Error Reporting**: How should config discovery errors be communicated to calling commands?
- [ ] **File Extensions**: Should the system support both .yml and .yaml extensions automatically?

## Objective

Create a ConfigLoader molecule that provides unified, XDG-compliant configuration file discovery with clear priority ordering, enabling consistent config loading behavior across all ace-tools commands. This eliminates duplicated config loading logic, ensures consistent user experience, and follows XDG Base Directory Specification standards.

## Scope of Work

- **User Experience Scope**: Unified config loading experience across all ace-tools commands
- **System Behavior Scope**: XDG-compliant config discovery with clear priority resolution
- **Interface Scope**: Simple ConfigLoader.load(type) interface for all commands

### Deliverables

#### Behavioral Specifications
- User experience flow definitions
- System behavior specifications
- Interface contract definitions

#### Validation Artifacts
- Success criteria validation methods
- User acceptance criteria
- Behavioral test scenarios

#### Create
- `lib/ace_tools/molecules/config_loader.rb` - Unified config loading molecule

#### Modify
- `exe/ace-test` - Update to use ConfigLoader instead of manual config loading
- Other commands identified during implementation that use hardcoded config paths

## Implementation Summary

### Current State Analysis

**ace-test Manual Loading**:
- Hardcoded paths: `.coding-agent/ace-test.yml`, `~/.config/ace-tools/ace-test.yml`
- Manual XDG_CONFIG_HOME handling
- Custom project root detection logic
- Embedded fallback defaults

**XDGDirectoryResolver Atom**:
- Provides XDG-compliant cache directory resolution
- Has methods for home directory, XDG variables, and path validation
- Currently focused on cache directories, needs extension for config directories

### Design Strategy

**ConfigLoader Molecule Architecture**:
```ruby
# Molecule composing XDGDirectoryResolver atom
class ConfigLoader
  # Uses XDGDirectoryResolver for home/system paths
  # Adds project root detection for highest priority
  # Implements config-specific file discovery

  def self.load(config_type)
    # 1. Check project root: {project}/.coding-agent/{type}.yml
    # 2. Check system config: {system}/ace-tools/{type}.yml
    # 3. Check home config: {xdg_config}/ace-tools/{type}.yml
    # Return first existing file or nil
  end
end
```

**Priority Resolution Logic**:
1. **Project Priority**: Use existing project root detection, look in `.coding-agent/`
2. **System Priority**: Extend XDGDirectoryResolver to handle system config directories
3. **Home Priority**: Use XDGDirectoryResolver for user config directories

**Migration Strategy**:
- Update ace-test first as primary example
- Identify other commands with hardcoded config loading
- Preserve all existing config file locations for compatibility
- Add optional caching for performance if needed

### Integration Points

**XDGDirectoryResolver Extension**:
- Add config directory methods alongside existing cache directory methods
- Maintain consistent API patterns with existing atom functionality
- Ensure security validations apply to config paths

**Command Integration**:
- Replace manual config loading in ace-test
- Provide clear migration examples for other commands
- Maintain identical behavior during transition

**Testing Strategy**:
- Test priority resolution with multiple config files present
- Verify XDG environment variable handling
- Confirm project root detection accuracy
- Validate permission handling and error cases

## Technical Approach

### Architecture Pattern
- [x] **ATOM/Molecule Pattern**: Create ConfigLoader as a molecule that composes the existing XDGDirectoryResolver atom
- [x] **Single Responsibility**: ConfigLoader focuses only on configuration file discovery and resolution
- [x] **Integration Strategy**: Extend XDGDirectoryResolver patterns for config directories alongside cache directories

### Technology Stack
- [x] **Ruby Standard Library**: File, Dir, Pathname for file system operations
- [x] **Existing Atoms**: XDGDirectoryResolver for XDG-compliant directory resolution
- [x] **YAML Support**: Built-in Ruby YAML for configuration parsing (optional)
- [x] **No New Dependencies**: Uses only existing project dependencies

### Implementation Strategy
- [x] **Composition over Inheritance**: Molecule composes XDGDirectoryResolver functionality
- [x] **Backward Compatibility**: Preserve all existing config file locations
- [x] **Incremental Migration**: Update ace-test first, then other commands
- [x] **Performance Optimization**: Optional caching for repeated config lookups

## Tool Selection

| Criteria | Extend XDG Atom | New Standalone | Library-based | Selected |
|----------|----------------|----------------|---------------|----------|
| Performance | Excellent | Good | Good | Extend XDG Atom |
| Integration | Excellent | Fair | Poor | Extend XDG Atom |
| Maintenance | Excellent | Fair | Poor | Extend XDG Atom |
| Security | Excellent | Good | Fair | Extend XDG Atom |
| Learning Curve | Low | Medium | High | Extend XDG Atom |

**Selection Rationale:** Extending the existing XDGDirectoryResolver atom provides the best integration with current architecture, maintains security standards, and leverages existing XDG compliance logic. This approach minimizes new code while maximizing consistency.

### Dependencies
- [x] **No New Dependencies**: Uses existing Ruby standard library and project atoms
- [x] **XDGDirectoryResolver**: Existing atom provides foundation for config directory resolution
- [x] **ProjectRootDetector**: Existing atom provides project root detection for highest priority configs

## File Modifications

### Create
- `lib/ace_tools/molecules/config_loader.rb`
  - Purpose: Unified configuration file discovery and loading across all ace-tools commands
  - Key components: XDG-compliant priority resolution, project root detection, caching support
  - Dependencies: XDGDirectoryResolver atom, ProjectRootDetector atom, Ruby standard library

### Modify
- `exe/ace-test`
  - Changes: Replace manual config loading logic (lines 39-59) with ConfigLoader.load(:ace_test) call
  - Impact: Simplifies config loading, improves consistency, maintains backward compatibility
  - Integration points: Demonstrates ConfigLoader usage pattern for other commands

- `lib/ace_tools/atoms/xdg_directory_resolver.rb` (optional enhancement)
  - Changes: Add config directory methods alongside existing cache directory methods
  - Impact: Provides XDG-compliant config directory resolution for ConfigLoader
  - Integration points: Extends existing XDG compliance patterns

### Additional Files to Identify and Modify
- Other ace-tools commands with hardcoded config loading (to be discovered during implementation)
  - Changes: Migrate to ConfigLoader.load(config_type) pattern
  - Impact: Unified config loading experience across all commands
  - Integration points: Consistent configuration discovery behavior

## Implementation Plan

### Planning Steps

- [x] **System Analysis**: Analyzed existing config loading patterns in ace-test and XDGDirectoryResolver atom
  > Analysis Complete: Found manual config loading in exe/ace-test lines 39-59, existing XDG patterns in XDGDirectoryResolver
- [x] **Architecture Design**: Designed ConfigLoader molecule composition approach using existing atoms
  > Design Complete: Molecule will compose XDGDirectoryResolver and ProjectRootDetector for unified config resolution
- [x] **Implementation Strategy**: Planned incremental approach starting with ConfigLoader creation, then ace-test migration
  > Strategy Complete: Create molecule → migrate ace-test → identify other commands → migrate additional commands
- [x] **Dependency Analysis**: Validated all dependencies are existing atoms and Ruby standard library
  > Dependencies Validated: XDGDirectoryResolver, ProjectRootDetector, File, Dir, Pathname - all existing
- [x] **Risk Assessment**: Identified backward compatibility and performance as primary risks with mitigation strategies
  > Risks Assessed: Compatibility (preserve existing paths), Performance (optional caching), Migration (incremental)

### Execution Steps

- [ ] **Create ConfigLoader Molecule**: Implement unified config loading molecule with XDG-compliant priority resolution
  > TEST: ConfigLoader Creation Validation
  > Type: Structural Validation
  > Assert: ConfigLoader class exists with load, load_and_parse, and discovery_info methods
  > Command: ruby -e "require_relative 'lib/ace_tools/molecules/config_loader'; puts AceTools::Molecules::ConfigLoader.methods.include?(:load)"

- [ ] **Implement Priority Resolution Logic**: Add project root → system config → home config priority ordering
  > TEST: Priority Resolution Validation
  > Type: Functional Validation
  > Assert: Higher priority configs override lower priority configs when multiple exist
  > Command: ruby -e "require_relative 'lib/ace_tools/molecules/config_loader'; puts AceTools::Molecules::ConfigLoader.load(:test_config)"

- [ ] **Add XDG Compliance**: Integrate XDGDirectoryResolver for system and home config directory resolution
  > TEST: XDG Compliance Check
  > Type: Integration Test
  > Assert: Config discovery respects XDG_CONFIG_HOME and standard XDG directory structure
  > Command: XDG_CONFIG_HOME=/tmp/test ruby -e "require_relative 'lib/ace_tools/molecules/config_loader'; puts AceTools::Molecules::ConfigLoader.discovery_info(:test)"

- [ ] **Migrate ace-test Command**: Replace manual config loading in exe/ace-test with ConfigLoader.load(:ace_test)
  > TEST: ace-test Migration Validation
  > Type: Integration Test
  > Assert: ace-test continues to find configs in same locations as before migration
  > Command: ./exe/ace-test --verbose | grep -i config || echo "No config output"

- [ ] **Add Error Handling and Edge Cases**: Implement graceful handling for missing configs, permission errors, invalid paths
  > TEST: Error Handling Validation
  > Type: Edge Case Validation
  > Assert: ConfigLoader handles missing files, permission denials, and invalid config types gracefully
  > Command: ruby -e "require_relative 'lib/ace_tools/molecules/config_loader'; puts AceTools::Molecules::ConfigLoader.load(:nonexistent_config).nil?"

- [ ] **Add Discovery Information Method**: Implement discovery_info method for debugging config resolution
  > TEST: Discovery Information Check
  > Type: Functional Validation
  > Assert: discovery_info returns checked paths, found path, and priority level information
  > Command: ruby -e "require_relative 'lib/ace_tools/molecules/config_loader'; puts AceTools::Molecules::ConfigLoader.discovery_info(:ace_test).keys"

- [ ] **Add Optional Caching**: Implement optional result caching for performance optimization
  > TEST: Caching Performance Check
  > Type: Performance Validation
  > Assert: Subsequent config lookups for same type return cached results
  > Command: ruby -e "require 'benchmark'; require_relative 'lib/ace_tools/molecules/config_loader'; puts Benchmark.measure { 10.times { AceTools::Molecules::ConfigLoader.load(:ace_test) } }"

- [ ] **Validate Backward Compatibility**: Ensure all existing config file locations continue to work
  > TEST: Backward Compatibility Check
  > Type: Regression Test
  > Assert: All previously working config file locations still work after migration
  > Command: touch .coding-agent/ace-test.yml && ./exe/ace-test --verbose && rm .coding-agent/ace-test.yml

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing config file discovery for ace-test or other commands
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Preserve exact same config paths and priority order, comprehensive testing with existing configs
  - **Rollback:** Revert to manual config loading logic in affected commands

- **Risk:** XDG environment variable handling differences
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Use existing XDGDirectoryResolver patterns, test with various XDG_CONFIG_HOME values
  - **Rollback:** Add fallback to manual XDG handling if needed

### Integration Risks
- **Risk:** ConfigLoader interface not matching command needs
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Design interface based on ace-test patterns, allow for extensions
  - **Monitoring:** Test with ace-test migration, gather feedback from other command migrations

- **Risk:** Performance degradation from additional method calls
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Implement optional caching, minimize file system calls
  - **Monitoring:** Benchmark config loading times before and after migration

### Performance Risks
- **Risk:** Repeated file system checks slowing down command startup
  - **Mitigation:** Implement intelligent caching with cache invalidation based on file modification times
  - **Monitoring:** Measure command startup times, especially for frequently used commands
  - **Thresholds:** Config loading should add <10ms to command startup time

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [ ] **Unified Interface**: ConfigLoader.load(type) method works for all config types and returns correct file paths
- [ ] **Priority Resolution**: Project configs override system configs override home configs in all test scenarios
- [ ] **XDG Compliance**: Respects XDG_CONFIG_HOME and follows XDG Base Directory Specification correctly
- [ ] **Command Migration**: ace-test successfully uses ConfigLoader and maintains identical config discovery behavior
- [ ] **Backward Compatibility**: All existing config file locations (.coding-agent/, ~/.config/ace-tools/) continue to work
- [ ] **Performance**: Config discovery completes within acceptable time limits (<10ms additional startup time)

### Implementation Quality Assurance
- [ ] **Code Quality**: ConfigLoader molecule follows ATOM architecture patterns and project coding standards
- [ ] **Test Coverage**: All embedded tests in Implementation Plan pass and demonstrate correct behavior
- [ ] **Integration Verification**: ConfigLoader properly composes XDGDirectoryResolver and ProjectRootDetector atoms
- [ ] **Error Handling**: Graceful handling of missing configs, permission errors, and invalid config types

### Documentation and Validation
- [ ] **Interface Documentation**: ConfigLoader methods are properly documented with usage examples
- [ ] **Migration Examples**: ace-test migration demonstrates clear pattern for other commands to follow
- [ ] **Discovery Information**: discovery_info method provides useful debugging information for config resolution

## Out of Scope

- ❌ **Configuration Parsing**: ConfigLoader only discovers files, does not parse YAML content
- ❌ **Configuration Validation**: No validation of config file contents or schema
- ❌ **Multiple File Formats**: Only supports .yml/.yaml files, not .json, .toml, etc.
- ❌ **Configuration Merging**: No merging of multiple config files, returns single highest-priority file
- ❌ **Environment Variable Substitution**: No variable interpolation within config files
- ❌ **Configuration Watching**: No file system watching for config file changes

## References

- Current ace-test implementation: `exe/ace-test:39-59` (manual config loading)
- XDGDirectoryResolver atom: `lib/ace_tools/atoms/xdg_directory_resolver.rb`
- ATOM architecture: Molecule should compose existing Atom functionality
- XDG Base Directory Specification for standardized config discovery