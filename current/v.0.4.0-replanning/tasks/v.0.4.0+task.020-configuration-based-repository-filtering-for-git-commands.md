---
id: v.0.4.0+task.020
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Configuration-Based Repository Filtering for Git Commands

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
  dev-tools:
    blacklist:
      - "git-tag"      # Block git-tag on dev-tools repo
      - "git-*"        # Block all git commands (glob pattern)
  dev-handbook:
    whitelist:
      - "git-commit"   # Only allow git-commit
      - "git-status"   # And git-status
  dev-taskflow:
    # No restrictions - all commands allowed
```

```bash
# CLI Interface - commands respect configuration automatically
git-tag --version v1.0.0
# Skips: dev-tools (blacklisted)
# Executes: dev-handbook, dev-taskflow

git-commit --intention "update docs"
# Executes: dev-handbook (whitelisted), dev-taskflow (no restrictions)
# Skips: dev-tools (not in whitelist if whitelist exists)

# Explicit path overrides configuration
git-tag dev-tools --version v1.0.0
# Executes on dev-tools despite blacklist
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
- [ ] **Override Functionality**: Explicit repository paths bypass configuration filtering
- [ ] **Safe Defaults**: Missing or malformed configuration defaults to current behavior
- [ ] **User Feedback**: Clear output shows which repositories were processed or skipped
- [ ] **Multi-Repo Support**: Filtering works correctly across all submodules

### Validation Questions

- [ ] **Configuration Location**: Should `.coding-agent/git.yml` support multiple locations (user home, project root)?
- [ ] **Rule Precedence**: When both whitelist and blacklist exist, should whitelist always win or should we support priority levels?
- [ ] **Command Aliases**: Should the configuration support command aliases or groups (e.g., "dangerous-commands": [git-tag, git-release])?
- [ ] **Inheritance**: Should submodules inherit parent configuration or have their own?
- [ ] **Dry Run**: Should we add a --dry-run flag to preview what would be filtered?

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

## References

- Source idea: dev-taskflow/backlog/ideas/20250803-2145-git-config-filter.md
- Related patterns: Multi-Repository Coordination, CLI Tool Patterns, Configuration Management
- Existing tools: dev-tools/exe/git-* commands