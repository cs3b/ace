---
id: v.0.9.0+task.075
status: draft
priority: medium
estimate: 12-16h
dependencies: []
---

# Extract git diff functionality to ace-git-diff gem

## Description

Extract git diff functionality from ace-docs and ace-context into a new standalone ace-git-diff gem that provides unified git diff operations for the entire ACE ecosystem. This gem will consolidate the best features from existing implementations and provide **consistent diff behavior** across all tools through a global, user-configurable YAML configuration.

### Core Value: Consistency

The primary value of ace-git-diff is **consistency**:
- **One configuration, all gems**: Configure diff behavior once for the entire project
- **No hardcoded patterns**: All exclude patterns are user-configurable, not constants in code
- **Project-level standards**: Teams can define what they never want to see in diffs
- **Predictable behavior**: Same configuration = same results across all ace-* tools

## Behavioral Specification

### User Experience

Users will experience a unified git diff utility that:
- **Configures once, applies everywhere**: Set project-wide diff preferences in `.ace/diff/config.yml`
- **Consistent filtering**: All gems use the same exclude patterns and options
- **User-controlled defaults**: No hardcoded constants - everything is configurable
- **Flexible usage**: Use simple `diff:` key for consistency or `commands:` for custom needs
- **Smart defaults with overrides**: Global → Gem-specific → Instance configuration cascade

### Interface Contracts

#### CLI Interface
```bash
# Basic usage
ace-git-diff                          # Interactive mode
ace-git-diff --config path/to/config.yml  # Load from config

# Range and time-based
ace-git-diff HEAD~5..HEAD             # Commit range
ace-git-diff --since "2025-01-01"    # Date-based
ace-git-diff --since 7d               # Relative time

# Special types
ace-git-diff --type staged            # Staged changes
ace-git-diff --type working           # Working directory
ace-git-diff --type pr                # PR changes (tracking...HEAD)

# Filtering
ace-git-diff --paths "lib/**/*.rb" --exclude "test/**/*"
ace-git-diff --filter-noise          # Auto-exclude common noise

# Output formats
ace-git-diff --format json           # JSON output
ace-git-diff --format analyzed       # With statistics
```

#### Ruby API
```ruby
# Direct usage with options
diff = Ace::GitDiff.generate(
  ranges: ["origin/main...HEAD"],
  paths: ["lib/**/*.rb"],
  exclude: ["test/**/*"],
  format: :filtered
)

# From configuration hash
config = YAML.load_file("config.yml")
diff = Ace::GitDiff.from_config(config["diff"])

# Integration helpers for ace-* gems
Ace::GitDiff.for_ace_docs(document)   # Reads document's diff config
Ace::GitDiff.for_ace_review(preset)   # Reads preset's diff config
Ace::GitDiff.for_ace_context(config)  # Reads context's diff config
```

### Global Configuration Pattern

#### Project-Level Configuration
```yaml
# .ace/diff/config.yml - Global project-wide diff configuration
# Users configure this ONCE for their entire project

# Default exclude patterns (user-configurable, not hardcoded!)
exclude_patterns:
  # Common patterns (can be modified per project)
  - "test/**/*"
  - "spec/**/*"
  - "**/*.lock"
  - "vendor/**/*"
  - "node_modules/**/*"
  - "coverage/**/*"
  - "**/fixtures/**/*"
  # Project-specific additions
  - "tmp/**/*"
  - "**/*.generated.rb"
  - "docs/archive/**/*"

# Default diff options
ignore_whitespace: true    # Skip whitespace-only changes
exclude_renames: false      # Include file renames
detect_moves: true         # Detect moved files

# Performance defaults
cache: true                # Enable caching
cache_ttl: 300            # Cache for 5 minutes

# Output defaults
format: filtered          # Default: filtered (removes excluded patterns)
max_lines: 10000         # Prevent huge diffs
```

#### Using the `diff:` Configuration Key

```yaml
# Simple usage in any ace-* gem configuration
subject:
  diff:                   # Just 'diff:', not 'git_diff:'
    type: pr             # Special type: pr, staged, working
    paths:               # Optional: additional path filters
      - "lib/**/*.rb"

# The global config is automatically applied!

# Alternative: Still support raw commands when needed
subject:
  commands:              # Escape hatch for custom needs
    - "git diff --name-only HEAD~1"
    - "git log --oneline -5"
```

### Migration Examples for Existing Gems

#### ace-docs Migration
```yaml
# Before (in document frontmatter)
ace-docs:
  subject:
    diff:
      filters: ["lib/**/*.rb"]

# After Option 1: Use consistent diff configuration
ace-docs:
  subject:
    diff:              # Delegates to ace-git-diff with global config
      paths: ["lib/**/*.rb"]
      since: 7d
      # Inherits all global exclude patterns automatically!

# After Option 2: Keep using commands if needed
ace-docs:
  subject:
    commands:          # Still supported for special cases
      - "git diff --name-only lib/"
```

#### ace-review Migration
```yaml
# Before (in preset)
pr:
  subject:
    commands:
      - "git diff origin/main...HEAD"
      - "git log origin/main..HEAD --oneline"

# After Option 1: Use consistent diff configuration
pr:
  subject:
    diff:              # Simple and consistent
      type: pr
      # Global exclude patterns applied automatically!

# After Option 2: Keep commands for complex needs
pr:
  subject:
    commands:          # When you need specific git options
      - "git diff --stat origin/main...HEAD"
```

#### ace-context Migration
```yaml
# Before (in preset)
context:
  diffs:
    - origin/main...HEAD

# After: Integrated with ace-git-diff
context:
  diff:                # Simplified key
    ranges: ["origin/main...HEAD"]
    format: raw
    # Can override global settings if needed
    exclude_patterns: []  # No filtering for raw context
```

## Acceptance Criteria

- [ ] Create ace-git-diff gem with ATOM architecture
- [ ] Implement global configuration via `.ace/diff/config.yml`
- [ ] Make ALL exclude patterns user-configurable (no hardcoded constants)
- [ ] Support both `diff:` key for consistency and `commands:` for flexibility
- [ ] Extract and unify GitExtractor from ace-context
- [ ] Extract and unify ChangeDetector + DiffFilterer from ace-docs
- [ ] Configuration cascade: Global → Gem-specific → Instance
- [ ] Provide delegation helpers for ace-docs, ace-review, ace-context
- [ ] Include comprehensive test coverage
- [ ] Add example `.ace.example/diff/config.yml` with sensible defaults
- [ ] Document migration path showing both `diff:` and `commands:` options
- [ ] Cache diffs with configurable TTL
- [ ] Support multiple output formats (raw, filtered, analyzed, json)

## Implementation Notes

### Why This Matters: The Consistency Value

**Current Problem:**
- Each gem has its own exclude patterns (often hardcoded)
- Different filtering behavior across tools
- No central place to configure project-wide diff preferences
- Teams can't easily standardize what appears in diffs

**Solution Value:**
- **Configure once**: Set up `.ace/diff/config.yml` once per project
- **Apply everywhere**: All ace-* gems automatically use the same configuration
- **User control**: Teams decide what to exclude, not gem authors
- **Flexibility preserved**: Still support `commands:` for special cases

### Components to Extract

1. **From ace-context/lib/ace/context/atoms/git_extractor.rb**:
   - Safe command execution with Open3.capture3
   - Status handling and error reporting
   - Special diff methods (staged_diff, working_diff)

2. **From ace-docs/lib/ace/docs/molecules/change_detector.rb**:
   - Date-to-commit resolution logic
   - Path filtering implementation
   - Batch diff generation

3. **From ace-docs/lib/ace/docs/atoms/diff_filterer.rb**:
   - Noise filtering patterns (CONVERT TO USER CONFIG)
   - Diff size estimation
   - Line counting utilities

### Key Architecture Decisions

- **No hardcoded patterns**: All defaults go in `.ace.example/diff/config.yml`
- **Configuration cascade**: Global → Gem → Instance (using ace-core)
- **Both `diff:` and `commands:`**: Consistency when wanted, flexibility when needed
- **User-first design**: Projects control their diff behavior
- **ATOM pattern**: Clean separation of concerns

### Migration Strategy

1. Create ace-git-diff with global config support
2. Provide `.ace.example/diff/config.yml` with sensible defaults
3. Update gems to delegate to ace-git-diff when using `diff:` key
4. Keep `commands:` working for backward compatibility
5. Document both approaches clearly in README

## References

- Original idea: .ace-taskflow/v.0.9.0/docs/ideas/075-20251016-193739-we-should-probably-extract-this-part-to-sepearte-p.md
- Related gems: ace-context, ace-docs, ace-review
- Architecture patterns: docs/ace-gems.g.md, docs/architecture.md
