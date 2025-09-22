# ADR-015: Mono-Repo Migration to ace-* Gems

## Status
Accepted

## Context

The ACE project started with a multi-repository architecture using Git submodules to coordinate three separate repositories (dev-handbook, dev-tools, dev-taskflow). While this provided clear separation of concerns, it introduced several challenges:

1. **Submodule Complexity**: Managing Git submodules required careful coordination and was prone to synchronization issues
2. **Dependency Management**: Each submodule had its own Gemfile and dependencies, leading to duplication and version conflicts
3. **Testing Challenges**: Running tests across submodules required complex setup and coordination
4. **Development Friction**: Making changes that spanned multiple submodules was cumbersome
5. **CI/CD Complexity**: Setting up continuous integration across multiple repositories was complicated

The Ruby ecosystem has established patterns for mono-repos with multiple gems (Rails, dry-rb, etc.) that provide better developer experience while maintaining modularity.

## Decision

We will migrate from the multi-repository submodule architecture to a mono-repo structure with modular Ruby gems following these principles:

1. **Mono-Repo Structure**: All ace-* gems live at the repository root as siblings
2. **Gem Naming Convention**: All gems use the `ace-` prefix (ace-core, ace-context, ace-test-runner, etc.)
3. **Shared Workspace**: Single root Gemfile with path-based gem references for development
4. **ATOM Architecture**: All gems follow the same Atoms, Molecules, Organisms, Models structure
5. **Configuration Cascade**: Use .ace/ directories for hierarchical configuration with nearest/deepest wins
6. **Zero-Dependency Core**: ace-core has no external dependencies, using only Ruby standard library
7. **Incremental Migration**: Start with core gems, migrate remaining functionality incrementally

## Implementation Strategy

### Phase 1: Core Infrastructure (Completed)
- **ace-core**: Configuration management and shared primitives
- **ace-context**: Context loading with smart caching
- **ace-test-runner**: Test execution with parallel processing
- **ace-test-support**: Shared testing infrastructure

### Phase 2: Essential Tools (Planned)
- **ace-git**: Enhanced git operations (ace-gc, ace-commit, etc.)
- **ace-capture**: Idea capture functionality
- **ace-llm**: Multi-provider LLM integration

### Phase 3: Workflow Management (Future)
- **ace-handbook**: Workflows, guides, and templates
- **ace-taskflow**: Task and release management
- **ace-agents**: Specialized AI agent definitions

## Consequences

### Positive
- **Simplified Development**: Single repository clone, no submodule management
- **Better Testing**: Easy to run tests across all gems with single command
- **Unified CI/CD**: Single GitHub Actions workflow tests all gems
- **Consistent Dependencies**: Shared development dependencies via root Gemfile
- **Easier Refactoring**: Moving code between gems is straightforward
- **Clear Architecture**: ATOM pattern provides consistent structure across all gems
- **Incremental Value**: Each gem provides focused, testable functionality

### Negative
- **Migration Effort**: Requires careful migration of existing functionality
- **Temporary Duplication**: Legacy dev-* directories coexist during migration
- **Bundle Exec Requirement**: Commands need `bundle exec` prefix during development
- **Learning Curve**: Developers need to understand mono-repo gem structure

### Neutral
- **Repository Size**: All code in one repository (mitigated by good organization)
- **Gem Versioning**: Need to coordinate versions across related gems
- **Documentation Updates**: All references to dev-* structure need updating

## Technical Details

### Workspace Configuration
```ruby
# Root Gemfile
source "https://rubygems.org"

gem "ace-core", path: "ace-core"
gem "ace-context", path: "ace-context"
gem "ace-test-runner", path: "ace-test-runner"
gem "ace-test-support", path: "ace-test-support"

# Development dependencies
group :development, :test do
  gem "minitest"
  gem "rake"
end
```

### ATOM Structure Example (ace-core)
```
ace-core/
├── lib/
│   └── ace/
│       └── core/
│           ├── atoms/        # Pure functions
│           ├── molecules/    # Composed operations
│           ├── organisms/    # Business logic
│           └── models/       # Data structures
├── test/
├── exe/
└── ace-core.gemspec
```

### CI/CD Configuration
```yaml
# .github/workflows/ci.yml
strategy:
  matrix:
    ruby: ['3.0', '3.1', '3.2']
    gem: ['ace-core', 'ace-context', 'ace-test-runner', 'ace-test-support']
```

## Alternatives Considered

1. **Keep Submodules**: Continue with current architecture
   - Rejected due to ongoing complexity and friction

2. **Single Gem**: Combine everything into one large gem
   - Rejected as it loses modularity and focused functionality

3. **Separate Repositories**: Each gem in its own repository
   - Rejected due to coordination complexity without submodules

4. **Lerna-style Monorepo**: Use tooling like Lerna for JavaScript
   - Rejected as Ruby has established patterns that work well

## References

- [Research Document: ACE Monorepo Migration](dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems/docs/research-doc.md)
- [v.0.9.0 Release Reflections](dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems/reflections/v.0.9.0-comprehensive-development-reflections.md)
- [Rails Repository Structure](https://github.com/rails/rails) - Example of successful Ruby mono-repo
- [dry-rb Repository](https://github.com/dry-rb) - Pattern for related Ruby gems

## Decision Date

September 22, 2025

## Decision Makers

- Development Team
- Project Maintainers

---

This ADR documents the architectural shift from multi-repository submodules to a mono-repo with modular ace-* gems, providing better developer experience while maintaining clear separation of concerns.