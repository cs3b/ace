---
id: v.0.9.0+task.087
status: pending
priority: medium
estimate: 2-3 days
dependencies: []
sort: 996
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
  # @param context [Hash] Required context for resolution
  #   - project_root: Project root directory (REQUIRED)
  #   - source_dir: Directory containing the source document (REQUIRED)
  #                 Use Dir.pwd for CLI arguments when no source document exists
  # @return [String, Hash] Expanded absolute path, or Hash with error for protocols
  # @raise [ArgumentError] if context missing required keys
  def self.expand_with_context(path:, context:)
    # Validates context has both required keys
    # Implementation handles all formats
  end

  # Check if path is a protocol URI
  # @param path [String] Path to check
  # @return [Boolean] true if protocol format detected
  def self.protocol?(path)
    path =~ %r{^[a-z]+://}
  end

  # Register a protocol resolver (e.g., ace-nav)
  # @param resolver [Object] Resolver responding to #resolve(uri)
  def self.register_protocol_resolver(resolver)
    # Stores resolver for protocol URI delegation
  end
end

# Example usage in config files
# .ace/nav/protocols/wfi-sources/ace-nav.yml
name: ace-nav
type: directory
path: ./handbook/workflow-instructions/  # Relative to source document directory
priority: 100

# .ace/docs/config.yml
document_types:
  context:
    paths:
      - "docs/*.md"              # Relative to project root
      - wfi://load-context       # Protocol resolution via ace-nav
      - $HOME/shared/docs/*.md   # Environment variable expansion

# In gem code loading these configs:
config_path = ".ace/nav/protocols/wfi-sources/ace-nav.yml"
config = YAML.load_file(config_path)

resolved_path = PathExpander.expand_with_context(
  path: config['path'],
  context: {
    project_root: Ace::Core::Molecules::ProjectRootFinder.find,
    source_dir: File.dirname(config_path)
  }
)
# => "/project/.ace/nav/protocols/wfi-sources/handbook/workflow-instructions/"
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
- **Missing context**: "PathExpander requires both 'project_root' and 'source_dir' in context" (ArgumentError)
- **Invalid protocol**: "Unknown protocol 'xyz://'. Available: wfi, guide, tmpl, task, prompt"
- **Protocol not resolved**: "Protocol 'wfi://missing' could not be resolved. Use 'ace-nav wfi://missing --list' to see available resources"
- **File not found**: "Path './missing.md' not found. Resolved to: /project/path/missing.md"
- **Ambiguous path**: (Optional) "Path 'docs/file.md' is ambiguous. Specify './docs/file.md' for source-relative or use project root notation"

**Edge Cases:**
- Protocol resolution fails (ace-nav not available): Fall back gracefully with clear error
- Circular protocol references: Detect and report error
- Symlinks in path: Follow symlinks during resolution
- Windows vs Unix paths: Handle both path separator styles
- Empty or nil paths: Return nil without error

### Success Criteria

#### Behavioral Outcomes
- [ ] **Unified Interface**: Single PathExpander atom handles all path formats consistently
- [ ] **Required Context Validation**: ArgumentError raised when project_root or source_dir missing from context
- [ ] **Protocol Support**: wfi://, guide://, tmpl://, task://, prompt:// protocols resolve correctly
- [ ] **Relative Path Resolution**: ./ and ../ paths resolve relative to source document location
- [ ] **Project-Relative Paths**: Paths without ./ prefix resolve relative to project root
- [ ] **Environment Variables**: $VAR and ${VAR} expand correctly in paths
- [ ] **Cross-Gem Consistency**: All ace-* gems can use PathExpander for consistent behavior
- [ ] **CLI Support**: Dir.pwd used as source_dir for CLI arguments with no source document

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

## Implementation Plan

### Validation Question Decisions

**Q1: Ambiguous Path Resolution** - How should `docs/file.md` be resolved?
- **Decision: Option A** - Always project-relative unless starts with ./ or ../
- **Rationale**: Consistent with current ace-* gem behavior (ace-docs, ace-taskflow use project-relative), predictable, follows ADR-004 standards
- **Impact**: Users can rely on simple paths being project-relative, config-relative needs explicit ./ prefix

**Q2: Protocol Dependency** - Should PathExpander require ace-nav?
- **Decision: Option C** - Plugin system - register protocol resolver if available
- **Rationale**: Keeps ace-core lightweight, allows ace-nav to be optional, extensible for future protocol handlers
- **Impact**: PathExpander detects protocols but delegates to registered resolver (ace-nav when available)

**Q3: Error Handling Philosophy** - Strict mode vs permissive mode?
- **Decision: Option B** - Permissive - try multiple resolution strategies
- **Rationale**: Better UX - users don't need to know exact path format, graceful degradation when ace-nav not available
- **Impact**: Multiple resolution attempts logged but not fatal, clear error messages guide users

**Q4: Caching Strategy** - Should PathExpander cache resolved paths?
- **Decision: Option A** - No caching - always resolve fresh
- **Rationale**: Simple, safe, resolution is fast (<5ms), caching adds complexity without significant benefit
- **Impact**: Clean architecture, no cache invalidation concerns, relies on ace-nav's protocol caching for expensive operations

### Technical Approach

**Architecture Pattern:**
- Enhance existing `Ace::Core::Atoms::PathExpander` module with new methods
- Maintain module pattern (not class) - pure functions without state
- Add protocol detection and delegation capability
- Keep existing `expand()` method for backward compatibility

**Integration Strategy:**
- PathExpander detects protocol URIs (via pattern matching `protocol://`)
- Protocol resolution delegates to registered resolver (ace-nav when loaded)
- If no resolver registered: return clear error message
- Non-protocol paths: expand normally (env vars, tilde, relative)

**Technology Stack:**
- Ruby stdlib: `Pathname`, `File`, `Dir`
- Pattern matching: Regex for protocol detection (`%r{^[a-z]+://}`)
- Dependency injection: Protocol resolver registry (optional ace-nav integration)
- No new gem dependencies required

### Tool Selection

| Criteria | Built-in Ruby | External Gem (pathname-plus) | Selected |
|----------|---------------|------------------------------|----------|
| Path manipulation | stdlib Pathname | Enhanced features | **stdlib** |
| Env var expansion | ENV, gsub | Built-in | **stdlib** |
| Protocol detection | Regex | Not applicable | **Regex** |
| Performance | Excellent | Good | **stdlib** |
| Dependencies | None | Additional gem | **stdlib** |

**Selection Rationale:**
- Use Ruby stdlib exclusively - no new dependencies
- PathExpander already uses Pathname successfully
- Regex sufficient for protocol pattern detection
- Keep ace-core lightweight and portable

### File Modifications

**Modify:**
- `ace-core/lib/ace/core/atoms/path_expander.rb`
  - Add `expand_with_context(path:, context:)` method with required context validation
  - Add context validation: raise ArgumentError if project_root or source_dir missing
  - Add `protocol?(path)` method for detection
  - Add `register_protocol_resolver(resolver)` for ace-nav integration
  - Add `resolve_protocol(uri)` for delegation
  - Keep existing `expand(path)` unchanged for backward compatibility
  - Changes: ~120 LOC added (includes validation logic)
  - Impact: Extends existing module without breaking changes, enforces correct usage
  - Integration: All ace-* gems can use enhanced path resolution

**Create:**
- `ace-core/test/atoms/path_expander_protocol_test.rb`
  - Purpose: Test protocol detection and resolution
  - Key components: Protocol pattern tests, resolver registration, delegation tests
  - Dependencies: test_helper, minitest

- `ace-core/test/atoms/path_expander_context_test.rb`
  - Purpose: Test context-aware path resolution
  - Key components: Config-relative tests, project-relative tests, precedence tests
  - Dependencies: test_helper, minitest, tmpdir for fixtures

- `ace-core/test/integration/path_expander_nav_integration_test.rb`
  - Purpose: Test PathExpander + ace-nav integration
  - Key components: Protocol resolution via ace-nav, fallback behavior
  - Dependencies: ace-nav (optional), test_helper

**Documentation Updates:**
- `ace-core/README.md`
  - Section: PathExpander usage examples
  - Changes: Add protocol and context-aware examples

- `docs/decisions/ADR-004-consistent-path-standards.md`
  - Section: Evolution addendum
  - Changes: Document PathExpander as implementation of path standards

### Test Case Planning

**Test Scenarios:**

**1. Context Validation Tests (Unit):**
- Missing both fields: Raises ArgumentError with clear message
- Missing project_root only: Raises ArgumentError
- Missing source_dir only: Raises ArgumentError
- Both fields present: Proceeds with resolution
- Context with extra fields: Ignores extras, uses required fields

**2. Protocol Detection Tests (Unit):**
- Detect valid protocols: `wfi://`, `guide://`, `tmpl://`, `task://`, `prompt://`
- Reject invalid protocols: `xyz://`, `http://`, missing `://`
- Handle edge cases: empty string, nil, protocol-only `wfi://`

**3. Context-Aware Resolution Tests (Unit):**
- Source-relative (`./`): Resolve relative to `source_dir` in context
- Project-relative (no prefix): Resolve relative to `project_root` in context
- Absolute paths: Return as-is with expansion
- Parent references (`../`): Resolve correctly from source document location
- CLI arguments: Using Dir.pwd as source_dir works correctly

**4. Environment Variable Expansion Tests (Unit):**
- `$VAR` format: `$HOME/docs` → `/Users/user/docs`
- `${VAR}` format: `${PROJECT_ROOT}/config` → `/project/config`
- Undefined vars: Leave as literal string or error (TBD)
- Nested paths: `$HOME/projects/$PROJECT_NAME`

**5. Protocol Resolution Tests (Integration):**
- With ace-nav loaded: Successfully resolve `wfi://workflow-name`
- Without ace-nav: Return helpful error message
- Protocol not found: Clear error with suggestion
- Circular references: Detect and prevent infinite loops

**6. Precedence Tests (Unit):**
- Absolute > Project-relative > Source-relative
- Explicit context overrides defaults
- Protocol resolution takes priority when pattern matches

**7. Error Handling Tests (Unit):**
- Missing context fields: ArgumentError raised
- Invalid protocol: Clear error message
- Unresolved protocol: Suggestion to check ace-nav
- Nil/empty path: Return nil without error

**8. Backward Compatibility Tests (Integration):**
- Existing `expand(path)` behavior unchanged
- All current ace-* gem uses continue to work
- No breaking changes to existing path resolution

**9. Performance Tests (Unit):**
- Path expansion < 5ms for typical paths
- Protocol detection < 1ms (regex pattern matching)
- Context validation < 1ms (hash key checking)
- No performance regression vs current implementation

**Test Prioritization:**
- **High Priority:** Context validation, backward compatibility, protocol detection, context resolution, error handling
- **Medium Priority:** Environment variable expansion, precedence rules, integration tests, CLI argument handling
- **Low Priority:** Performance benchmarks, edge case combinations

### Implementation Steps

**Planning Steps:**

* [ ] Review existing PathExpander usage across all ace-* gems
  > TEST: Usage Audit Check
  > Type: Pre-condition Check
  > Assert: All current uses of PathExpander.expand() identified
  > Command: grep -r "PathExpander" ace-*/lib --include="*.rb" | wc -l

* [ ] Analyze ace-nav protocol resolution architecture
  > TEST: Architecture Understanding
  > Type: Pre-condition Check
  > Assert: Protocol resolution entry points and patterns documented
  > Command: # Review ace-nav/lib/ace/nav/molecules/resource_resolver.rb

* [ ] Design protocol resolver registry interface
  - Define callback signature for protocol resolvers
  - Plan registration and lookup mechanism
  - Document integration points for ace-nav

**Execution Steps:**

- [ ] Step 1: Enhance PathExpander with protocol detection
  - Add `protocol?(path)` method using regex pattern
  - Add protocol pattern constant (`PROTOCOL_PATTERN = %r{^[a-z]+://}`)
  - Implement simple pattern matching logic
  > TEST: Protocol Detection
  > Type: Unit Test
  > Assert: `protocol?("wfi://test")` returns true, `protocol?("./path")` returns false
  > Command: ruby -I test ace-core/test/atoms/path_expander_protocol_test.rb

- [ ] Step 2: Add protocol resolver registry
  - Create class variable `@@protocol_resolver` (default nil)
  - Add `register_protocol_resolver(resolver)` class method
  - Add `resolve_protocol(uri)` that delegates to registered resolver
  > TEST: Resolver Registration
  > Type: Unit Test
  > Assert: Resolver can be registered and protocol URIs delegate correctly
  > Command: ruby -I test ace-core/test/atoms/path_expander_protocol_test.rb -n test_resolver_registration

- [ ] Step 3: Implement `expand_with_context` method with validation
  - Accept `path:` and `context:` parameters (context required, not optional)
  - Validate context has both `project_root` and `source_dir` keys
  - Raise ArgumentError with clear message if validation fails
  - Extract `source_dir` and `project_root` from validated context
  - Implement resolution precedence logic
  - Handle `./ ../` as source-relative
  - Handle others as project-relative (default)
  > TEST: Context Validation and Resolution
  > Type: Unit Test
  > Assert: ArgumentError raised when context incomplete, paths resolve correctly when valid
  > Command: ruby -I test ace-core/test/atoms/path_expander_context_test.rb

- [ ] Step 4: Add protocol resolution to expand_with_context
  - Check if path matches protocol pattern
  - If protocol and resolver registered: delegate
  - If protocol but no resolver: return error hash
  - If not protocol: proceed with normal expansion
  > TEST: Protocol Integration
  > Type: Integration Test
  > Assert: Protocol paths delegate when resolver present, error when absent
  > Command: ruby -I test ace-core/test/atoms/path_expander_protocol_test.rb -n test_protocol_resolution

- [ ] Step 5: Write comprehensive test suite
  - Create `path_expander_protocol_test.rb` (protocol detection tests)
  - Create `path_expander_context_test.rb` (context-aware resolution tests)
  - Create `path_expander_backward_compat_test.rb` (ensure no breaking changes)
  - Add edge case coverage (nil, empty, whitespace, symlinks)
  > TEST: Test Suite Coverage
  > Type: Coverage Check
  > Assert: 100% coverage for new PathExpander methods
  > Command: cd ace-core && bundle exec rake test TESTOPTS="--name=/PathExpander/"

- [ ] Step 6: Document PathExpander enhancements
  - Update ace-core/README.md with usage examples
  - Add inline documentation for new methods
  - Document protocol resolver registration pattern
  > TEST: Documentation Complete
  > Type: Manual Check
  > Assert: README contains clear examples of protocol and context usage
  > Command: # Manual review of ace-core/README.md

- [ ] Step 7: Create ace-nav integration example
  - Write integration test showing ace-nav registration
  - Document how ace-nav should register its resolver
  - Test protocol resolution end-to-end
  > TEST: ace-nav Integration
  > Type: Integration Test
  > Assert: ace-nav can register and resolve protocols via PathExpander
  > Command: ruby -I test ace-core/test/integration/path_expander_nav_integration_test.rb

- [ ] Step 8: Validate backward compatibility
  - Run full ace-core test suite
  - Run ace-nav test suite
  - Run ace-docs, ace-context, ace-taskflow tests
  - Ensure no breaking changes
  > TEST: Backward Compatibility
  > Type: Integration Test
  > Assert: All existing tests pass, no regressions
  > Command: bundle exec rake test

### Risk Assessment

**Technical Risks:**

- **Risk:** Breaking changes to existing PathExpander usage
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Keep existing `expand()` method unchanged, add new methods only, comprehensive backward compatibility tests
  - **Rollback:** Revert PathExpander changes, gems continue using original implementation

- **Risk:** Protocol resolution performance impact
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Protocol detection via fast regex (< 1ms), delegation to ace-nav uses existing caching
  - **Rollback:** Disable protocol detection if performance issues detected

**Integration Risks:**

- **Risk:** ace-nav integration complexity
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Simple callback interface, ace-nav optional (soft dependency), clear error messages when unavailable
  - **Monitoring:** Integration test suite, manual testing of protocol resolution

- **Risk:** Inconsistent path resolution across gems
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Centralized implementation in ace-core, comprehensive test coverage, migration guide for gems
  - **Monitoring:** Integration tests across all ace-* gems

**Performance Risks:**

- **Risk:** Path resolution slower than current implementation
  - **Mitigation:** No caching overhead (resolution is fast), regex pattern matching is O(1)
  - **Monitoring:** Performance tests, benchmark comparisons
  - **Thresholds:** < 5ms for typical paths, < 100ms with ace-nav protocol resolution

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251018-143836-in-ace-config-files-params-we-use-different-way.md`
- Related: ace-core PathExpander atom (`ace-core/lib/ace/core/atoms/path_expander.rb`)
- Related: ace-nav protocol resolution (`ace-nav/README.md`)
- Related: ADR-004 Consistent Path Standards (`docs/decisions/ADR-004-consistent-path-standards.md`)
- Related task: v.0.8.0+task.016 (PathResolver consolidation - completed)
