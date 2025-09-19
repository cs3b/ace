---
id: v.0.4.0+task.020
status: pending
priority: high
estimate: 4h
dependencies: []
needs_review: false
---

# Configuration-Based Repository Filtering for Git Commands

## Review Summary

**Questions Resolved:** 7 total (3 HIGH, 3 MEDIUM, 1 LOW)
**Critical Blockers:** None - All questions answered
**Implementation Readiness:** Ready for implementation with clear specifications

**Key Clarifications Made:**
- Configuration always applies (even with explicit flags) unless --skip-repo-config used
- All commands respect configuration including git-status (no exceptions)
- Always display which repositories were skipped (not just in verbose mode)
- Simple command patterns only (no groups or aliases)
- Fail-safe error handling with user notifications

**Recommended Next Steps:** 
1. Implement command name passing from GitOrchestrator to MultiRepoCoordinator
2. Create repository filter configuration loader following existing patterns
3. Add --skip-repo-config flag support to all git commands
4. Ensure skip notifications are always displayed

## Review Questions - RESOLVED

### Implementation Decisions (User Confirmed)

- [x] **Configuration Architecture**: Create a new atom `repository_filter_config_loader.rb` that loads `.coding-agent/git.yml` following existing pattern
  - **Decision**: Use suggested approach with separate config file
  
- [x] **Flag Interaction**: Configuration filtering applies even with explicit flags (--repository, --main-only, --submodules-only)
  - **Decision**: Config restrictions always apply unless --skip-repo-config flag is used
  - **Implementation Note**: Add new --skip-repo-config flag to bypass configuration
  
- [x] **Command Coverage**: All git commands follow configuration without exceptions
  - **Decision**: If blacklisted, command does not run on that repo (including git-status)
  
- [x] **Command Groups**: No command groups or aliases in initial implementation
  - **Decision**: Keep it simple with individual command patterns only
  
- [x] **Error Handling**: Display warnings to user and continue without filtering on config errors
  - **Decision**: Fail-safe approach with user notification
  
- [x] **Skip Feedback**: Always show which repositories/submodules were skipped
  - **Decision**: Clear indication of filtered repos in output (not just with --verbose)
  
- [x] **Environment Settings**: No environment-specific configurations
  - **Decision**: Single configuration applies to all environments

## Implementation Requirements (From Review)

### Critical Discovery: Command Name Passing
- **Issue**: GitOrchestrator methods don't currently pass command name to MultiRepoCoordinator
- **Solution**: Need to add `command_name` to options hash in each GitOrchestrator method
- **Alternative**: Extract command name from executable wrapper context (available as `executable_name`)
- **Implementation**: Each git command method in GitOrchestrator needs to include `command_name: 'git-tag'` etc. in options

## Research Findings

### Codebase Analysis Completed

1. **Configuration Pattern Analysis**:
   - Existing configuration files in `.coding-agent/`: lint.yml, path.yml, task-manager.yml, tools.yml, tree.yml
   - All configuration loaders follow similar pattern: find_config_path, load_yaml_file, validate_structure, deep_merge with defaults
   - ConfigurationLoader atom provides good template for new repository filter config loader

2. **Git Command Architecture**:
   - All git commands flow through GitOrchestrator → MultiRepoCoordinator
   - MultiRepoCoordinator.filter_repositories method is the central filtering point
   - Current filtering supports: --repository (specific), --main-only, --submodules-only
   - Integration point identified: enhance filter_repositories method

3. **Repository Discovery**:
   - RepositoryScanner.discover_repositories finds all git repositories
   - Returns array of hashes with :name, :path, :exists, :is_git_repo
   - Submodules are discovered and treated as separate repositories

4. **Command Pattern Matching**:
   - Ruby's File.fnmatch can handle glob patterns like "git-*"
   - Existing codebase uses glob patterns in path configuration

## Behavioral Specification

### User Experience
- **Input**: Users provide a `.coding-agent/git.yml` configuration file that defines repository filtering rules for git commands
- **Process**: When executing `git-*` commands without explicit repository paths, the system reads the configuration and applies filtering logic to determine which repositories to operate on
- **Output**: Git commands execute only on allowed repositories, preventing unintended operations while providing clear feedback about what was executed or skipped

### Expected Behavior

The system should provide configuration-driven control over git command execution scope in multi-repository environments. When users execute git commands like `git-tag` or `git-commit` without specifying an explicit repository path, the system should:

1. **Configuration Discovery**: Automatically locate and parse the `.coding-agent/git.yml` file from the project root
2. **Repository Filtering**: Apply include/exclude rules based on repository paths and command patterns
3. **Selective Execution**: Only execute commands on repositories that pass the filtering rules
4. **Clear Feedback**: Provide informative output about which repositories were processed or skipped
5. **Safe Defaults**: When configuration is missing or malformed, default to operating on all repositories (current behavior)
6. **Override Capability**: Allow explicit repository paths to bypass configuration filtering

### Interface Contract

```yaml
# .coding-agent/git.yml configuration format
repositories:
  .ace/tools:
    blacklist:
      - "git-tag"      # Block git-tag on .ace/tools repo
      - "git-*"        # Block all git commands (glob pattern)
  .ace/handbook:
    whitelist:
      - "git-commit"   # Only allow git-commit
      - "git-status"   # And git-status
  .ace/taskflow:
    # No restrictions - all commands allowed
```

```bash
# CLI Interface - commands respect configuration automatically
git-tag --version v1.0.0
# Skips: .ace/tools (blacklisted)
# Executes: .ace/handbook, .ace/taskflow

git-commit --intention "update docs"
# Executes: .ace/handbook (whitelisted), .ace/taskflow (no restrictions)
# Skips: .ace/tools (not in whitelist if whitelist exists)

# Explicit path overrides configuration
git-tag .ace/tools --version v1.0.0
# Executes on .ace/tools despite blacklist
```

**Error Handling:**
- Missing configuration file: Continue with default behavior (all repositories)
- Malformed YAML: Log warning and use default behavior
- Invalid repository path in config: Skip that entry, continue with others
- Non-existent repository: Skip silently in filtering

**Edge Cases:**
- Both whitelist and blacklist present: Whitelist takes precedence
- Empty configuration: Use default behavior
- Glob patterns in command names: Support standard glob matching
- Submodule repositories: Treat as separate repositories in filtering

### Success Criteria

- [ ] **Configuration Loading**: System successfully loads and parses `.coding-agent/git.yml` when present
- [ ] **Repository Filtering**: Git commands correctly filter repositories based on whitelist/blacklist rules
- [ ] **Command Pattern Matching**: Glob patterns in command filters work correctly (e.g., `git-*`)
- [ ] **Override Functionality**: --skip-repo-config flag bypasses configuration filtering
- [ ] **Safe Defaults**: Missing or malformed configuration defaults to current behavior
- [ ] **User Feedback**: Clear output shows which repositories were processed or skipped
- [ ] **Multi-Repo Support**: Filtering works correctly across all submodules

### Validation Questions

- [x] **Configuration Location**: Should `.coding-agent/git.yml` support multiple locations (user home, project root)?
  - **Research Finding**: All existing configs use project root `.coding-agent/` directory only
  - **Decision**: Follow existing pattern - project root only for consistency

- [ ] **Rule Precedence**: When both whitelist and blacklist exist, should whitelist always win or should we support priority levels?
  - **Note**: Interface contract states "Whitelist takes precedence" but needs confirmation

- [ ] **Command Aliases**: Should the configuration support command aliases or groups (e.g., "dangerous-commands": [git-tag, git-release])?
  - **Note**: Covered in Review Questions as MEDIUM priority

- [x] **Inheritance**: Should submodules inherit parent configuration or have their own?
  - **Research Finding**: Submodules are treated as separate repositories by RepositoryScanner
  - **Decision**: Parent configuration applies to all discovered repositories (no separate configs)

- [ ] **Dry Run**: Should we add a --dry-run flag to preview what would be filtered?
  - **Note**: Useful for testing configuration before applying

## Objective

Provide users with centralized, configuration-driven control over git command execution scope in multi-repository projects, preventing unintended operations while maintaining flexibility for explicit overrides. This solves the problem of git commands executing on repositories even when there are no changes, reducing noise and potential errors in complex multi-repository setups.

## Scope of Work

- **User Experience Scope**: Configuration file creation, git command filtering, feedback messages
- **System Behavior Scope**: Configuration parsing, repository discovery, filtering logic, command interception
- **Interface Scope**: YAML configuration format, existing git-* command enhancement, diagnostic output

### Deliverables

#### Behavioral Specifications
- Configuration file format specification
- Filtering rule behavior definitions
- Command execution flow with filtering

#### Validation Artifacts
- Test scenarios for various configuration combinations
- User acceptance criteria for filtering behavior
- Edge case handling verification

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby modules, file organization, or code structure
- ❌ **Technology Decisions**: YAML parsing libraries, specific filtering algorithms
- ❌ **Performance Optimization**: Caching strategies, configuration reload mechanisms
- ❌ **Future Enhancements**: GUI configuration editor, web-based configuration management
- ❌ **Advanced Features**: Repository groups, conditional rules based on branch or status

## Technical Approach

### Architecture Pattern
- **Configuration-Driven Filtering**: Implement a new configuration loader atom similar to existing ConfigurationLoader patterns
- **Repository Filter Molecule**: Create a new molecule that applies filtering rules based on configuration
- **Integration Point**: Inject filtering logic into MultiRepoCoordinator's `filter_repositories` method (lines 58-73)
- **Safe Defaults**: When configuration is missing, behavior remains unchanged (current implementation)

### Technology Stack
- **YAML Parsing**: Use existing YAML.load_file pattern from ConfigurationLoader
- **Glob Matching**: Utilize Ruby's File.fnmatch for command pattern matching
- **Repository Discovery**: Leverage existing RepositoryScanner atom
- **Command Execution**: Integrate with existing GitCommandExecutor and MultiRepoCoordinator

### Implementation Strategy
- Start with configuration loading and validation following ConfigurationLoader pattern
- Build filtering logic as a separate, testable molecule
- Integrate into existing git command flow with minimal disruption
- Hook into MultiRepoCoordinator.filter_repositories before line 59
- Add configuration check that respects explicit options (--repository flag takes precedence)
- Add comprehensive test coverage for edge cases
- Ensure backward compatibility when configuration is absent

### Integration Details (from research)
- **Current filter_repositories flow**:
  1. Check for explicit --repository option (lines 59-64)
  2. Check for --main-only flag (line 66)
  3. Check for --submodules-only flag (line 68)
  4. Default to all repositories (line 71)
- **Proposed enhancement**:
  - Insert configuration-based filtering between steps 3 and 4
  - Only apply when no explicit options provided
  - Command name passed via options hash for filtering decisions

## File Modifications

### Create
- `lib/coding_agent_tools/atoms/git/repository_filter_config_loader.rb`
  - Purpose: Load and validate `.coding-agent/git.yml` configuration
  - Key components: YAML loading, config validation, default handling
  - Dependencies: yaml, pathname

- `lib/coding_agent_tools/molecules/git/repository_filter.rb`
  - Purpose: Apply filtering rules to repository list based on configuration
  - Key components: Whitelist/blacklist logic, glob pattern matching, rule precedence
  - Dependencies: repository_filter_config_loader, File.fnmatch

- `spec/coding_agent_tools/atoms/git/repository_filter_config_loader_spec.rb`
  - Purpose: Unit tests for configuration loading
  - Key components: Valid/invalid YAML tests, missing file handling
  - Dependencies: rspec, tempfile

- `spec/coding_agent_tools/molecules/git/repository_filter_spec.rb`
  - Purpose: Unit tests for filtering logic
  - Key components: Whitelist/blacklist tests, glob pattern tests, precedence tests
  - Dependencies: rspec

- `spec/integration/git_repository_filtering_spec.rb`
  - Purpose: Integration tests for end-to-end filtering behavior
  - Key components: Multi-repo scenarios, command execution tests
  - Dependencies: rspec, tmpdir, git

### Modify
- `lib/coding_agent_tools/molecules/git/multi_repo_coordinator.rb`
  - Changes: Inject repository filtering based on configuration in `filter_repositories` method
  - Impact: All git commands will respect filtering rules
  - Integration points: Add configuration check between lines 68-71
  - Key modifications:
    - Add command name to options hash from GitOrchestrator
    - Load git.yml configuration if present
    - Apply whitelist/blacklist filtering when no explicit options
    - Maintain backward compatibility

## Test Case Planning

### Configuration Loading Tests

**Happy Path Scenarios:**
- Valid YAML with whitelist configuration
- Valid YAML with blacklist configuration
- Valid YAML with mixed whitelist/blacklist for different repos
- Configuration with glob patterns (e.g., "git-*")

**Edge Case Scenarios:**
- Missing configuration file (should use defaults)
- Empty configuration file
- Configuration with non-existent repository names
- Both whitelist and blacklist for same repository
- Invalid glob patterns

**Error Condition Scenarios:**
- Malformed YAML syntax
- Invalid data types in configuration
- Permission denied when reading config file
- Circular references in YAML

### Repository Filtering Tests

**Happy Path Scenarios:**
- Command matches exact blacklist entry
- Command matches glob pattern in blacklist
- Command allowed by whitelist
- Command with no restrictions

**Edge Case Scenarios:**
- Repository not in configuration (default behavior)
- Empty whitelist (blocks all)
- Empty blacklist (allows all)
- Case sensitivity in command names
- Submodule vs main repository filtering

**Integration Tests:**
- git-tag respects blacklist configuration
- git-commit respects whitelist configuration
- Explicit repository path overrides configuration
- Multi-repository operations with mixed rules

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing git command functionality
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Comprehensive test coverage, feature flag for rollback
  - **Rollback:** Remove configuration check, revert to original behavior

- **Risk:** Performance impact from configuration loading
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Cache configuration per command execution
  - **Monitoring:** Add timing metrics for configuration loading

### Integration Risks
- **Risk:** Unexpected interactions with concurrent execution
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Thread-safe configuration loading
  - **Monitoring:** Test with concurrent git operations

## Implementation Plan

### Planning Steps

* [x] Analyze existing configuration loading patterns in codebase
  > TEST: Configuration Pattern Analysis
  > Type: Pre-condition Check
  > Assert: Understanding of ConfigurationLoader, PathConfigLoader patterns
  > Command: grep -r "ConfigurationLoader\|config_loader" lib/ --include="*.rb"
  > **COMPLETED**: Found ConfigurationLoader in atoms/code_quality and PathConfigLoader in molecules

* [x] Research Ruby glob pattern matching capabilities
  > TEST: Glob Pattern Research
  > Type: Pre-condition Check
  > Assert: Understanding of File.fnmatch behavior with git command patterns
  > Command: ruby -e "puts File.fnmatch('git-*', 'git-tag')"
  > **COMPLETED**: File.fnmatch confirmed suitable for command pattern matching

* [ ] Design configuration schema with extensibility in mind
  > **NOTE**: Schema already defined in Interface Contract section

### Execution Steps

- [ ] Create repository filter configuration loader atom
  > TEST: Configuration Loader Creation
  > Type: File Validation
  > Assert: File exists at lib/coding_agent_tools/atoms/git/repository_filter_config_loader.rb
  > Command: test -f lib/coding_agent_tools/atoms/git/repository_filter_config_loader.rb

- [ ] Implement YAML loading and validation logic
  > TEST: YAML Loading Validation
  > Type: Unit Test
  > Assert: Configuration loader correctly parses valid YAML
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/git/repository_filter_config_loader_spec.rb -e "loads valid configuration"

- [ ] Create repository filter molecule with whitelist/blacklist logic
  > TEST: Filter Molecule Creation
  > Type: File Validation
  > Assert: File exists at lib/coding_agent_tools/molecules/git/repository_filter.rb
  > Command: test -f lib/coding_agent_tools/molecules/git/repository_filter.rb

- [ ] Implement glob pattern matching for command names
  > TEST: Glob Pattern Matching
  > Type: Unit Test
  > Assert: Filter correctly matches glob patterns like "git-*"
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/git/repository_filter_spec.rb -e "matches glob patterns"

- [ ] Integrate filter into MultiRepoCoordinator
  > TEST: Integration Point
  > Type: Integration Test
  > Assert: MultiRepoCoordinator uses RepositoryFilter when configuration exists
  > Command: bundle exec rspec spec/integration/git_repository_filtering_spec.rb -e "filters repositories based on configuration"

- [ ] Add configuration check with safe defaults
  > TEST: Safe Defaults
  > Type: Integration Test
  > Assert: Missing configuration doesn't break existing functionality
  > Command: bundle exec rspec spec/integration/git_repository_filtering_spec.rb -e "works without configuration"

- [ ] Implement override capability for explicit paths
  > TEST: Override Functionality
  > Type: Integration Test
  > Assert: Explicit repository paths bypass filtering
  > Command: bundle exec rspec spec/integration/git_repository_filtering_spec.rb -e "explicit paths override configuration"

- [ ] Add informative output about filtered repositories
  > TEST: User Feedback
  > Type: Integration Test
  > Assert: Commands show which repositories were skipped
  > Command: bundle exec rspec spec/integration/git_repository_filtering_spec.rb -e "provides feedback about skipped repositories"

- [ ] Create comprehensive test suite
  > TEST: Test Coverage
  > Type: Coverage Check
  > Assert: All new code has test coverage > 90%
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/git/repository_filter_config_loader_spec.rb spec/coding_agent_tools/molecules/git/repository_filter_spec.rb --format documentation

- [ ] Document configuration format and usage
  > TEST: Documentation
  > Type: File Validation
  > Assert: Configuration documentation exists in tools.md
  > Command: grep -q "coding-agent/git.yml" docs/tools.md

## Acceptance Criteria

- [ ] Configuration loader successfully loads and validates `.coding-agent/git.yml`
- [ ] Repository filter correctly applies whitelist/blacklist rules
- [ ] Glob patterns work for command filtering (e.g., `git-*`)
- [ ] Explicit repository paths override configuration filtering
- [ ] Missing configuration defaults to current behavior (no filtering)
- [ ] Commands provide clear feedback about filtered repositories
- [ ] All git commands respect the filtering configuration
- [ ] Test coverage exceeds 90% for new code
- [ ] Documentation updated with configuration examples

## Out of Scope

- ❌ GUI configuration editor
- ❌ Web-based configuration management
- ❌ Repository groups or complex conditional rules
- ❌ Branch-specific or status-based filtering
- ❌ Configuration inheritance from parent directories
- ❌ Real-time configuration reloading
- ❌ Migration tools for existing git hooks

## References

- Source idea: .ace/taskflow/backlog/ideas/20250803-2145-git-config-filter.md
- Related patterns: Multi-Repository Coordination, CLI Tool Patterns, Configuration Management
- Existing tools: .ace/tools/exe/git-* commands
- Similar implementations: ConfigurationLoader, PathConfigLoader, TreeConfigLoader
