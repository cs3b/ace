---
id: v.0.9.0+task.087
status: draft
priority: medium
estimate: 2-3 days
dependencies: []
---

# Create unified path resolution system for ACE config files and parameters

## Behavioral Specification

### User Experience
- **Input**: Users provide paths in config files, CLI arguments, or YAML using various formats:
  - Relative to config file: `./handbook/agents/`, `../templates/file.md`
  - Relative to project root: `ace-docs/README.md`, `docs/architecture.md`
  - Protocols: `wfi://workflow-name`, `guide://testing`, `tmpl://task-draft`, `task://083`
  - Environment variables: `$PROJECT_ROOT/docs`, `$HOME/.config/ace`
  - Absolute paths: `/opt/handbooks/custom.md`
- **Process**: Path expansion happens transparently when config files are loaded or CLI arguments are processed
- **Output**: Consistently expanded absolute paths or resolved file content, regardless of which ace-* gem or command is used

### Expected Behavior

Users need a unified way to specify paths across all ACE tools and config files. Currently, different gems handle path resolution inconsistently:
- ace-nav uses relative paths (`./handbook/`) in protocol source configs
- ace-taskflow uses project-relative paths (`.ace-taskflow/`)
- ace-docs references paths in frontmatter (`docs/*.md`)
- Protocol resolution (wfi://, guide://) works in some contexts but not others

**Desired behavior:**
1. All ace-* gems should support the same path specification formats
2. Path resolution should be handled by a single, well-tested atom in ace-core
3. Protocol URIs should delegate to ace-nav when detected
4. Context-aware resolution: relative paths resolve based on config file location OR project root
5. Clear precedence rules when paths could be ambiguous
6. Graceful error handling with helpful messages

**User experience goals:**
- Write config files once, work everywhere
- Mix path formats naturally based on use case
- Predictable, consistent behavior across all ACE tools
- No need to remember which gem uses which path format

### Interface Contract

```ruby
# Core API - PathExpander atom in ace-core
module Ace::Core::Atoms::PathExpander
  # Expand any path format to absolute path
  # @param path [String] Path in any supported format
  # @param context [Hash] Optional context for resolution
  #   - config_file_dir: Directory containing the config file (for ./ ../ resolution)
  #   - project_root: Project root directory (for project-relative resolution)
  # @return [String, nil] Expanded absolute path or nil if invalid
  def self.expand(path:, context: {})
    # Implementation handles all formats
  end

  # Check if path is a protocol URI
  # @param path [String] Path to check
  # @return [Boolean] true if protocol format detected
  def self.protocol?(path)
    path =~ %r{^[a-z]+://}
  end
end

# Example usage in config files
# .ace/nav/protocols/wfi-sources/ace-nav.yml
name: ace-nav
type: directory
path: ./handbook/workflow-instructions/  # Relative to this config file
priority: 100

# .ace/docs/config.yml
document_types:
  context:
    paths:
      - "docs/*.md"              # Relative to project root
      - wfi://load-context       # Protocol resolution via ace-nav
      - $HOME/shared/docs/*.md   # Environment variable expansion
```

**CLI integration:**
```bash
# All these should work consistently across ace-* gems
ace-context wfi://load-context                    # Protocol resolution
ace-context ./presets/project.yml                 # Relative to current dir
ace-context ace-context/presets/base.yml          # Relative to project root
ace-context $HOME/.ace/presets/custom.yml         # Env var expansion

# Same applies to config file paths
ace-docs update wfi://draft-task                  # Protocol in CLI
ace-docs update docs/architecture.md              # Project-relative in CLI
```

**Error Handling:**
- **Invalid protocol**: "Unknown protocol 'xyz://'. Available: wfi, guide, tmpl, task, prompt"
- **Protocol not resolved**: "Protocol 'wfi://missing' could not be resolved. Use 'ace-nav wfi://missing --list' to see available resources"
- **File not found**: "Path './missing.md' not found. Resolved to: /project/path/missing.md"
- **Ambiguous path**: (Optional) "Path 'docs/file.md' is ambiguous. Specify './docs/file.md' for config-relative or use project root notation"

**Edge Cases:**
- Protocol resolution fails (ace-nav not available): Fall back gracefully with clear error
- Circular protocol references: Detect and report error
- Symlinks in path: Follow symlinks during resolution
- Windows vs Unix paths: Handle both path separator styles
- Empty or nil paths: Return nil without error

### Success Criteria

#### Behavioral Outcomes
- [ ] **Unified Interface**: Single PathExpander atom handles all path formats consistently
- [ ] **Protocol Support**: wfi://, guide://, tmpl://, task://, prompt:// protocols resolve correctly
- [ ] **Relative Path Resolution**: ./ and ../ paths resolve relative to config file location
- [ ] **Project-Relative Paths**: Paths without ./ prefix resolve relative to project root
- [ ] **Environment Variables**: $VAR and ${VAR} expand correctly in paths
- [ ] **Cross-Gem Consistency**: All ace-* gems can use PathExpander for consistent behavior

#### User Experience Goals
- [ ] **Predictable Resolution**: Clear, documented precedence rules for ambiguous paths
- [ ] **Helpful Errors**: Error messages guide users to fix path issues
- [ ] **Backward Compatible**: Existing config files continue to work
- [ ] **Protocol Delegation**: Protocols delegate to ace-nav when available

#### System Performance
- [ ] **Fast Resolution**: Path expansion completes in < 5ms for typical paths
- [ ] **Cached Protocols**: Protocol resolution uses ace-nav caching (< 100ms after initial scan)

### Validation Questions

- [ ] **Ambiguous Path Resolution**: How should `docs/file.md` be resolved?
  - Option A: Always project-relative unless starts with ./ or ../
  - Option B: Check config file dir first, fall back to project root
  - Option C: Require explicit prefix for clarity (./docs/ or project:docs/)

- [ ] **Protocol Dependency**: Should PathExpander require ace-nav, or gracefully degrade?
  - Option A: Hard dependency - ace-nav must be available
  - Option B: Soft dependency - protocols return error if ace-nav not found
  - Option C: Plugin system - register protocol resolver if available

- [ ] **Error Handling Philosophy**: Strict mode vs permissive mode?
  - Option A: Strict - fail fast on any resolution error
  - Option B: Permissive - try multiple resolution strategies
  - Option C: Configurable - let gems choose their error handling

- [ ] **Caching Strategy**: Should PathExpander cache resolved paths?
  - Option A: No caching - always resolve fresh (simple, safe)
  - Option B: Cache within request - clear after operation
  - Option C: Process-level cache - faster but more complex

## Objective

**Why are we doing this?**

Currently, ACE gems use inconsistent path resolution approaches, leading to:
- Confusion for users writing config files
- Duplication of path resolution logic across gems
- Limited ability to use protocols in all contexts
- Maintenance burden when path resolution needs change

**User value:**
- **Consistency**: Write paths once, work everywhere across ACE ecosystem
- **Flexibility**: Choose the most natural path format for each use case
- **Power**: Use protocols to reference resources without knowing their location
- **Clarity**: Predictable, well-documented path resolution behavior

**System value:**
- **DRY**: Single source of truth for path resolution logic
- **Testability**: Comprehensive test coverage in ace-core atom
- **Maintainability**: Changes to resolution logic happen in one place
- **Extensibility**: Easy to add new path formats or protocols

## Scope of Work

### User Experience Scope
- **Config File Authoring**: All path specifications in .ace/ config files
- **CLI Arguments**: Path arguments to ace-* commands
- **Workflow Documents**: Path references in .wf.md and other embedded docs
- **Cross-Gem Consistency**: Same path formats work across all ace-* gems

### System Behavior Scope
- **Path Format Support**: ./, ../, project-relative, absolute, env vars, protocols
- **Protocol Resolution**: Delegation to ace-nav for wfi://, guide://, etc.
- **Context Awareness**: Resolution based on config file location or project root
- **Error Reporting**: Clear, actionable error messages for invalid paths

### Interface Scope
- **PathExpander Atom API**: Public interface in ace-core
- **Integration Points**: How gems should call PathExpander
- **Migration Guide**: How to update existing gems to use PathExpander

### Deliverables

#### Behavioral Specifications
- Path resolution precedence rules (documented in ace-core)
- Protocol delegation behavior (when and how ace-nav is called)
- Error handling contract (what errors, when, and what messages)
- Usage examples for common scenarios

#### Validation Artifacts
- Test suite covering all path formats and edge cases
- Integration tests showing cross-gem consistency
- Performance benchmarks for path resolution
- Migration validation (existing configs still work)

## Out of Scope

### Implementation Concerns (Reserved for Planning Phase)
- ❌ **Code Organization**: Whether to use module, class, or singleton pattern
- ❌ **File Structure**: Where to place PathExpander within ace-core
- ❌ **Refactoring Strategy**: Order of gem updates to adopt PathExpander
- ❌ **Performance Optimization**: Caching implementation details

### Technology Decisions (Reserved for Planning Phase)
- ❌ **Testing Framework**: Minitest patterns for PathExpander tests
- ❌ **Protocol Detection**: Regex vs parser approach for protocol URIs
- ❌ **Gem Dependencies**: How ace-core should interact with ace-nav

### Future Enhancements (Not in Current Scope)
- ❌ **Additional Protocols**: New protocol types beyond current set
- ❌ **Remote Resources**: HTTP/HTTPS URL support
- ❌ **Path Transformation**: Hooks for custom path processing
- ❌ **IDE Integration**: Language server support for path completion

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251018-143836-in-ace-config-files-params-we-use-different-way.md`
- Related: ace-core PathExpander atom (`ace-core/lib/ace/core/atoms/path_expander.rb`)
- Related: ace-nav protocol resolution (`ace-nav/README.md`)
- Related: ADR-004 Consistent Path Standards (`docs/decisions/ADR-004-consistent-path-standards.md`)
