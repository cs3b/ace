---
id: v.0.9.0+task.075
status: draft
priority: medium
estimate: 12-16h
dependencies: []
---

# Extract git diff functionality to ace-git-diff gem

## Description

Extract git diff functionality from ace-docs and ace-context into a new standalone ace-git-diff gem that provides unified git diff operations for the entire ACE ecosystem. This gem will consolidate the best features from existing implementations and provide a consistent, human-friendly YAML configuration pattern that all ace-* gems can easily delegate to.

## Behavioral Specification

### User Experience

Users will experience a unified git diff utility that:
- Generates git diffs with flexible inputs (dates, commits, ranges, special keywords)
- Filters diffs to remove noise (tests, lock files, vendor code)
- Caches diffs for performance across multiple operations
- Supports multiple output formats (raw, filtered, analyzed, json)
- Integrates seamlessly with all ace-* gems through delegation

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
diff = Ace::GitDiff.from_config(config["git_diff"])

# Integration helpers for ace-* gems
Ace::GitDiff.for_ace_docs(document)   # Reads document's git_diff config
Ace::GitDiff.for_ace_review(preset)   # Reads preset's git_diff config
Ace::GitDiff.for_ace_context(config)  # Reads context's git_diff config
```

### Unified YAML Configuration Pattern

The gem will support a unified configuration pattern that works across all ace-* gems:

```yaml
# Unified git_diff configuration block
git_diff:
  # Range-based (from ace-context pattern)
  ranges:
    - origin/main...HEAD
    - HEAD~5..HEAD

  # Time-based alternatives
  since: "2025-01-01"      # Absolute date
  # or: since: 7d          # Relative time

  # Path filtering (from ace-docs pattern)
  paths:
    - "lib/**/*.rb"
    - "docs/*.md"

  # Exclude patterns (noise filtering)
  exclude:
    - "test/**/*"
    - "**/*.lock"
    - "vendor/**/*"
    - "node_modules/**/*"
    - "coverage/**/*"

  # Special keywords (from ace-review pattern)
  type: staged  # Options: staged, working, pr, unstaged

  # Processing options
  ignore_whitespace: true
  include_renames: false
  detect_moves: true

  # Performance options
  cache: true
  cache_ttl: 300  # seconds

  # Output options
  format: filtered  # Options: raw, filtered, analyzed, json
  max_lines: 10000  # Limit output size
```

### Migration Examples for Existing Gems

#### ace-docs Migration
```yaml
# Before (in document frontmatter)
ace-docs:
  subject:
    diff:
      filters: ["lib/**/*.rb"]

# After (delegates to ace-git-diff)
ace-docs:
  subject:
    git_diff:
      paths: ["lib/**/*.rb"]
      exclude: ["test/**/*"]
      since: 7d
```

#### ace-review Migration
```yaml
# Before (in preset)
pr:
  subject:
    commands:
      - "git diff origin/main...HEAD"

# After (delegates to ace-git-diff)
pr:
  subject:
    git_diff:
      type: pr
      exclude: ["**/*.lock"]
```

#### ace-context Migration
```yaml
# Before (in preset)
context:
  diffs:
    - origin/main...HEAD

# After (integrated with ace-git-diff)
context:
  git_diff:
    ranges: ["origin/main...HEAD"]
    format: raw
```

## Acceptance Criteria

- [ ] Create ace-git-diff gem with ATOM architecture
- [ ] Extract and unify GitExtractor from ace-context
- [ ] Extract and unify ChangeDetector + DiffFilterer from ace-docs
- [ ] Implement unified YAML configuration parser
- [ ] Support all existing configuration patterns for backward compatibility
- [ ] Provide delegation helpers for ace-docs, ace-review, ace-context
- [ ] Include comprehensive test coverage
- [ ] Add handbook with agents and workflows
- [ ] Document migration path in README
- [ ] Cache diffs with configurable TTL
- [ ] Support multiple output formats (raw, filtered, analyzed, json)

## Implementation Notes

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
   - Noise filtering patterns
   - Diff size estimation
   - Line counting utilities

### Architecture Decisions

- Follow ATOM pattern with clear separation of concerns
- Use ace-core for configuration management
- Implement caching at the Organism layer
- Keep Atoms pure and side-effect free
- Provide backward-compatible interfaces

### Migration Strategy

1. Create ace-git-diff as standalone gem
2. Update ace-context to optionally use ace-git-diff
3. Update ace-docs to delegate diff operations to ace-git-diff
4. Update ace-review to use ace-git-diff instead of direct ace-context
5. Maintain backward compatibility during transition period

## References

- Original idea: .ace-taskflow/v.0.9.0/docs/ideas/075-20251016-193739-we-should-probably-extract-this-part-to-sepearte-p.md
- Related gems: ace-context, ace-docs, ace-review
- Architecture patterns: docs/ace-gems.g.md, docs/architecture.md
