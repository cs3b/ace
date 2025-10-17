# ace-git-diff Usage Documentation

## Overview

`ace-git-diff` provides consistent, configurable git diff operations across the entire ACE ecosystem. Configure diff behavior once for your project and have it apply consistently across all ace-* tools.

### Key Features
- **Global configuration**: One `.ace/diff/config.yml` for the entire project
- **User-controlled filtering**: No hardcoded patterns - you decide what to exclude
- **Flexible usage**: Use `diff:` key for consistency or `commands:` for custom needs
- **Smart caching**: Avoid redundant git operations with configurable TTL
- **Multiple formats**: Raw, filtered, analyzed, or JSON output

## Command Structure

### CLI Commands

```bash
# Basic usage (interactive mode)
ace-git-diff

# Configuration-based
ace-git-diff --config path/to/config.yml

# Range and time-based diffs
ace-git-diff HEAD~5..HEAD            # Commit range
ace-git-diff --since "2025-01-01"   # Date-based
ace-git-diff --since 7d              # Relative time (7 days)

# Special diff types
ace-git-diff --type staged           # Staged changes only
ace-git-diff --type working          # Working directory changes
ace-git-diff --type pr               # Pull request changes

# Path filtering
ace-git-diff --paths "lib/**/*.rb"   # Include only matching paths
ace-git-diff --exclude "test/**/*"   # Exclude patterns
ace-git-diff --filter-noise          # Apply default noise filtering

# Output formats
ace-git-diff --format json           # JSON structured output
ace-git-diff --format analyzed       # Include statistics and analysis
ace-git-diff --format raw            # Unfiltered git diff output
```

## Usage Scenarios

### Scenario 1: Initial Project Setup
**Goal**: Set up consistent diff filtering for your entire project team.

```bash
# 1. Create project-wide diff configuration
cat > .ace/diff/config.yml << 'EOF'
exclude_patterns:
  - "test/**/*"
  - "spec/**/*"
  - "**/*.lock"
  - "vendor/**/*"
  - "node_modules/**/*"
  - "coverage/**/*"
  - "tmp/**/*"
  - "**/*.generated.rb"

ignore_whitespace: true
exclude_renames: false
detect_moves: true

cache: true
cache_ttl: 300
EOF

# 2. Test configuration with ace-git-diff
ace-git-diff --since 7d

# 3. All ace-* tools now use these settings automatically
```

### Scenario 2: Code Review Workflow
**Goal**: Review PR changes with consistent filtering across tools.

```bash
# Using ace-review with the new diff: key
cat > .ace/review/presets/pr.yml << 'EOF'
pr:
  subject:
    diff:           # Uses ace-git-diff with global config
      type: pr
      # Automatically excludes test files, vendor, etc.
EOF

# Run review - excludes patterns are applied automatically
ace-review --preset pr

# Or use ace-git-diff directly for the same result
ace-git-diff --type pr --format analyzed
```

### Scenario 3: Documentation Updates
**Goal**: Check what code changes need documentation updates.

```yaml
# In document frontmatter (.md files)
---
ace-docs:
  subject:
    diff:
      paths: ["lib/ace/docs/**/*.rb"]
      since: 7d
      # Global exclude patterns applied automatically
---
```

```bash
# Run documentation analysis - uses ace-git-diff internally
ace-docs analyze README.md

# Or check diff directly
ace-git-diff --paths "lib/ace/docs/**/*.rb" --since 7d
```

### Scenario 4: Custom Git Commands (Escape Hatch)
**Goal**: Need specific git options not covered by diff: configuration.

```yaml
# In any ace-* gem config
subject:
  commands:    # Still supported for special cases
    - "git diff --stat origin/main...HEAD"
    - "git log --oneline -10"
    - "git diff --name-status"
```

### Scenario 5: Override Global Settings
**Goal**: Need raw, unfiltered diff for specific use case.

```bash
# Command-line override
ace-git-diff --format raw --no-filter

# Or in configuration
context:
  diff:
    ranges: ["origin/main...HEAD"]
    format: raw
    exclude_patterns: []  # Override global exclusions
```

### Scenario 6: Debugging Diff Issues
**Goal**: Understand what's being filtered and why.

```bash
# Show what would be excluded
ace-git-diff --dry-run --verbose

# Compare filtered vs raw
ace-git-diff --since 1d --format filtered > filtered.diff
ace-git-diff --since 1d --format raw > raw.diff
diff filtered.diff raw.diff

# Check cache status
ace-git-diff --cache-status
```

## Command Reference

### ace-git-diff

Generate git diffs with consistent project-wide configuration.

**Syntax:**
```bash
ace-git-diff [RANGE] [OPTIONS]
```

**Arguments:**
- `RANGE`: Git commit range (e.g., `HEAD~5..HEAD`, `main...feature`)

**Options:**
- `--config PATH`: Load specific configuration file
- `--since TIME`: Changes since time (e.g., "2025-01-01", "7d", "2h")
- `--type TYPE`: Special diff types (staged, working, pr)
- `--paths PATTERN`: Include only matching paths (glob patterns)
- `--exclude PATTERN`: Exclude paths (can be used multiple times)
- `--filter-noise`: Apply default noise filtering
- `--format FORMAT`: Output format (raw, filtered, analyzed, json)
- `--no-cache`: Skip cache, force fresh diff
- `--cache-ttl SECONDS`: Override cache TTL
- `--verbose`: Show filtering decisions
- `--dry-run`: Show what would be done without executing

**Internal Implementation:**
- Uses `git diff` with safe command execution (Open3.capture3)
- Applies configuration cascade: Global → Gem → Instance
- Caches results to `.cache/ace-git-diff/` with TTL
- Filters patterns using Ruby glob matching

### Configuration via diff: key

Use in any ace-* gem configuration or preset.

**Syntax:**
```yaml
subject:
  diff:
    type: STRING        # Special types: pr, staged, working
    ranges:             # Explicit commit ranges
      - STRING
    since: STRING       # Time-based: "7d", "2025-01-01"
    paths:              # Include patterns
      - GLOB
    exclude_patterns:   # Override global excludes
      - GLOB
    format: STRING      # Output format
```

## Tips and Best Practices

### 1. Start with Conservative Excludes
Begin with a minimal exclude list and add patterns as needed:
```yaml
exclude_patterns:
  - "**/*.lock"      # Lock files rarely need review
  - "vendor/**/*"    # Third-party code
  - "node_modules/**/*"  # Dependencies
```

### 2. Use Project-Specific Patterns
Add patterns specific to your project:
```yaml
exclude_patterns:
  - "**/*.generated.rb"  # Generated code
  - "db/schema.rb"        # Auto-generated schema
  - "public/assets/**/*"  # Compiled assets
```

### 3. Leverage Caching for Performance
For expensive diff operations:
```yaml
cache: true
cache_ttl: 600  # Cache for 10 minutes
```

### 4. Override When Needed
Global config is the default, but you can always override:
```bash
# Quick override from command line
ace-git-diff --exclude "" --format raw  # No exclusions

# Or in specific gem config
diff:
  exclude_patterns: []  # Clear all excludes for this context
```

### 5. Debug Filtering Issues
When diffs seem wrong:
```bash
# See what's being filtered
ace-git-diff --verbose --dry-run

# Compare with raw git
git diff HEAD~1 | wc -l
ace-git-diff HEAD~1 --format raw | wc -l
```

## Migration Notes

### From ace-context
```yaml
# Before
diffs:
  - origin/main...HEAD

# After
diff:
  ranges: ["origin/main...HEAD"]
```

### From ace-docs
```yaml
# Before
subject:
  diff:
    filters: ["lib/**/*.rb"]

# After
subject:
  diff:
    paths: ["lib/**/*.rb"]
    # Global excludes applied automatically
```

### From ace-review
```yaml
# Before
subject:
  commands:
    - "git diff origin/main...HEAD"

# After (Option 1: Use diff:)
subject:
  diff:
    type: pr

# After (Option 2: Keep commands:)
subject:
  commands:  # Still works!
    - "git diff origin/main...HEAD"
```

## Troubleshooting

### Diffs Include Unwanted Files
1. Check global config: `cat .ace/diff/config.yml`
2. Verify patterns: `ace-git-diff --verbose`
3. Add excludes: Update `exclude_patterns` in config

### Diffs Missing Expected Files
1. Check path filters: Ensure `paths:` patterns match
2. Verify no over-exclusion: Review `exclude_patterns`
3. Use `--format raw` to see unfiltered diff

### Cache Issues
1. Clear cache: `rm -rf .cache/ace-git-diff/`
2. Disable cache: `ace-git-diff --no-cache`
3. Reduce TTL: `cache_ttl: 60` for 1-minute cache

### Performance Problems
1. Enable caching: `cache: true` in config
2. Use path filters: Limit diff scope with `paths:`
3. Increase cache TTL for stable branches