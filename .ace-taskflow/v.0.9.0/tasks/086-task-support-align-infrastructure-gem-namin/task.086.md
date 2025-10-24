---
id: v.0.9.0+task.086
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Align infrastructure gem naming to ace-support-* pattern

## Behavioral Specification

### User Experience
- **Input**: Current ACE ecosystem with mixed naming conventions for infrastructure gems (`ace-core`, `ace-test-support`) versus support gems (`ace-support-mac-clipboard`, `ace-support-markdown`)
- **Process**: Developers and AI agents interact with a consistently named ecosystem where infrastructure/support gems are clearly distinguished from functional capability gems through naming
- **Output**: Unified `ace-support-*` naming pattern for all infrastructure and support gems, improved discoverability in RubyGems listings, clearer ecosystem organization

### Expected Behavior

The ACE ecosystem should present a consistent naming convention that helps users understand the role and purpose of each gem at a glance:

**Current State:**
- `ace-core` - Foundational configuration cascade (15+ gems depend on it)
- `ace-test-support` - Shared test utilities (development dependency)
- `ace-support-mac-clipboard` - Platform-specific clipboard support
- `ace-support-markdown` - Markdown editing support

**Desired State:**
- `ace-support-core` - Foundational configuration cascade (renamed from ace-core)
- `ace-support-test-helpers` - Shared test utilities (renamed from ace-test-support)
- `ace-support-mac-clipboard` - Platform-specific clipboard support (no change)
- `ace-support-markdown` - Markdown editing support (no change)

**Ecosystem Organization Principle:**
- `ace-*` - Functional capability gems providing specific features with direct CLI tools (ace-search, ace-lint, ace-docs, etc.)
- `ace-support-*` - Infrastructure and support gems without direct CLI tools (libraries that other gems depend on)

**User-Facing Impact:**
- RubyGems search results show clearer organization
- Gemfile dependencies are more self-documenting
- AI agents can better understand gem roles through naming
- New contributors can quickly identify infrastructure vs feature gems

### Interface Contract

**Package Installation:**
```bash
# New names (after rename)
gem install ace-support-core          # Core config cascade
gem install ace-support-test-helpers  # Test utilities

# Old names (deprecated but functional during transition)
gem install ace-core          # Redirects or shows deprecation warning
gem install ace-test-support  # Redirects or shows deprecation warning
```

**Gemspec Dependencies:**
```ruby
# All ace-* gems will be updated to use new names
Gem::Specification.new do |spec|
  # Runtime dependency (formerly ace-core)
  spec.add_dependency "ace-support-core", "~> 0.9"

  # Development dependency (formerly ace-test-support)
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.9"
end
```

**Ruby Requires (Backward Compatible):**
```ruby
# Internal module structure remains unchanged for compatibility
require 'ace/core'          # Still works - maps to ace-support-core gem
require 'ace/test_support'  # Still works - maps to ace-support-test-helpers gem

# Module namespaces unchanged
Ace::Core.config             # Works as before
Ace::TestSupport::VERSION    # Works as before
```

**CLI/Tool Behavior:**
```bash
# No CLI changes - these gems have no executables
# Only package names and dependencies change
```

**Error Handling:**
- **Old gem installed with new code**: Clear error message indicating gem rename and migration path
- **Missing dependency during transition**: Helpful error suggesting the new gem name
- **Version conflicts**: Standard RubyGems version conflict resolution with clear gem names

**Edge Cases:**
- **Existing projects with old gem names**: Gradual migration path with deprecation warnings
- **Mixed old/new dependencies**: RubyGems should handle gracefully with proper gem metadata
- **Cached gems**: Bundler cache invalidation and rebuild instructions

### Success Criteria

- [ ] **Package Renamed and Published**: Both `ace-support-core` and `ace-support-test-helpers` gems are published to RubyGems with proper metadata
- [ ] **Ecosystem Updated**: All 15+ dependent ace-* gems updated to reference new gem names in their gemspecs
- [ ] **Backward Compatibility**: Existing code using `require 'ace/core'` and `require 'ace/test_support'` continues to work without modification
- [ ] **Documentation Updated**: README, guides, and docs across all gems reference new gem names
- [ ] **Pattern Documented**: `docs/ace-gems.g.md` updated to formalize the naming convention (gems without CLI tools = ace-support-*)
- [ ] **Clear Migration Path**: Users have clear instructions for updating their Gemfiles and dependencies
- [ ] **RubyGems Listings**: New gems appear in RubyGems with correct metadata, old gems marked as deprecated or redirecting
- [ ] **CI/CD Validation**: All gem test suites pass with new dependencies
- [ ] **No Breaking Changes**: Existing users can upgrade without code changes (only Gemfile updates needed)

### Validation Questions

- [ ] **Deprecation Strategy**: Should we maintain `ace-core` and `ace-test-support` as deprecated shim gems that depend on the new gems, or use RubyGems metadata redirection?
- [ ] **Version Bump Strategy**: Is this a major version bump (breaking change in packaging) or minor (backward compatible rename)?
- [ ] **Transition Timeline**: How long should we maintain both old and new gem names? Immediate deprecation or gradual transition?
- [ ] **Rollout Approach**: Should all gems be updated simultaneously in a single coordinated release, or staged rollout by dependency tier?
- [ ] **Existing Projects**: What's the recommended upgrade path for projects currently using ace-core and ace-test-support?
- [ ] **Documentation Timing**: When do we update external documentation (guides, blog posts, examples) - before or after the rename?

## Objective

**Why are we doing this?**

Establish consistent naming conventions across the ACE ecosystem that clearly distinguish infrastructure/support gems from functional capability gems. This improves:

1. **Ecosystem Clarity**: Users can immediately identify whether a gem is infrastructure (ace-support-*) or a functional capability (ace-*)
2. **Better Organization**: RubyGems listings and package searches show logical grouping of related gems
3. **Self-Documenting Dependencies**: Gemfile dependencies become more readable and their purpose clearer
4. **AI Agent Understanding**: Naming patterns help AI agents better understand gem roles and relationships
5. **Consistency**: Aligns with already-established pattern from ace-support-mac-clipboard and ace-support-markdown

This is a foundation-level improvement that benefits all current and future ACE users.

## Scope of Work

### User Experience Scope
- **Package Discovery**: How developers find and understand gems in RubyGems listings
- **Dependency Management**: How developers specify and understand dependencies in Gemfiles
- **Migration Experience**: How existing users transition from old to new gem names
- **Documentation Access**: How users find and understand updated documentation

### System Behavior Scope
- **Gem Publishing**: Publishing renamed gems to RubyGems with proper metadata
- **Dependency Resolution**: Ensuring RubyGems and Bundler correctly resolve new names
- **Backward Compatibility**: Maintaining require paths and module namespaces
- **Deprecation Handling**: Managing transition from old to new gem names
- **Pattern Documentation**: Update `docs/ace-gems.g.md` to formalize the naming convention (gems without direct CLI tools should be ace-support-*)

### Interface Scope
- **RubyGems API**: Gem metadata, dependencies, and version specifications
- **Bundler Integration**: Gemfile dependency specifications
- **Ruby Requires**: Module loading and namespace resolution
- **Documentation**: README files, guides, and reference documentation

### Deliverables

#### Behavioral Specifications
- Detailed rename execution plan with rollback strategy
- Dependency update strategy across 15+ gems
- Backward compatibility preservation approach
- User migration guide and timeline

#### Validation Artifacts
- Pre-rename validation checklist
- Post-rename verification tests
- Dependency resolution validation
- User acceptance criteria for smooth transition

## Out of Scope

- ❌ **Implementation Details**: Specific file renaming sequences, directory restructuring, or gemspec modification order
- ❌ **Technology Decisions**: Choice of deprecation mechanisms, specific bundler features to use, or CI/CD tooling
- ❌ **Performance Optimization**: Gem download size, installation speed, or dependency resolution performance
- ❌ **Future Enhancements**: Additional gem renames, further ecosystem reorganization, or new support gems
- ❌ **Module/Code Restructuring**: Internal code organization remains unchanged - only package names change
- ❌ **New Features**: No new functionality added, purely organizational/naming change

## References

- Source Ideas:
  - `.ace-taskflow/v.0.9.0/ideas/done/20251007-220339-rename-this-pacage-to-ace-support-test-helpers.md`
  - `.ace-taskflow/v.0.9.0/ideas/done/20251007-220406-rename-this-pacage-to-ace-support-core.md`
- Existing ace-support-* gems:
  - `ace-support-mac-clipboard` - Platform support pattern (no CLI)
  - `ace-support-markdown` - Functional support pattern (no CLI)
- Core gem dependencies:
  - 15+ ace-* gems depend on ace-core
  - All ace-* gems use ace-test-support in development
- Documentation to update:
  - `docs/ace-gems.g.md` - Formalize naming convention rule
