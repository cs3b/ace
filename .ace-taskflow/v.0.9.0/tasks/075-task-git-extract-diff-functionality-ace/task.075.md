---
id: v.0.9.0+task.075
status: pending
priority: medium
estimate: 12-16h
dependencies: []
needs_review: true
---

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions

- [ ] **ace-git-commit dependency**: Should ace-git-diff extract/use ace-git-commit's DiffAnalyzer functionality?
  - **Research conducted**: Found ace-git-commit/lib/ace/git_commit/molecules/diff_analyzer.rb with git diff logic
  - **Current functionality**: DiffAnalyzer has methods like `get_staged_diff`, `get_all_diff`, `analyze_diff` (line counts), `detect_scope`
  - **Similar to**: ace-context's GitExtractor and ace-docs' ChangeDetector
  - **Suggested approach**: Extract common functionality to ace-git-diff, have ace-git-commit depend on it
  - **Why needs human input**: Decision on whether to refactor ace-git-commit or keep separate for now
  - **Impact**: If yes, ace-git-commit becomes a dependent gem (increases scope)

- [ ] **Backward compatibility strategy**: How do we handle migration for existing gems?
  - **Research conducted**: Reviewed current usage in ace-docs, ace-review, ace-context
  - **Current patterns**:
    - ace-docs: Uses `subject.diff.filters` in frontmatter
    - ace-review: Uses `subject.commands` with raw git diff commands
    - ace-context: Uses `diffs: ["range"]` array format
  - **Suggested approach**: Dual support - keep old keys working, add new `diff:` key
  - **Migration timeline options**:
    1. Immediate (v0.1.0): Support both, deprecation warnings on old keys
    2. Gradual (v0.1.0-0.2.0): Support both, no warnings until v0.2.0
    3. Long-term (v0.1.0-1.0.0): Support both until v1.0.0
  - **Why needs human input**: Choose deprecation timeline and whether to show warnings
  - **Impact**: Affects user experience and adoption friction

- [ ] **Hardcoded patterns migration**: What's the process for users with custom exclusions today?
  - **Research conducted**: Found hardcoded DEFAULT_EXCLUDE_PATTERNS in ace-docs/atoms/diff_filterer.rb
  - **Current hardcoded patterns**: test/, spec/, coverage/, tmp/, vendor/, node_modules/, .git/, *.lock files
  - **User pain point**: No way to customize these patterns currently
  - **Suggested approach**:
    1. Ship with same defaults in `.ace.example/diff/config.yml`
    2. Document how to override in project `.ace/diff/config.yml`
    3. Add `--no-default-excludes` CLI flag for power users
  - **Why needs human input**: Should defaults be more or less aggressive than current hardcoded ones?
  - **Impact**: Could surprise users if defaults change behavior

### [MEDIUM] Integration Questions

- [ ] **ace-git-commit DiffAnalyzer integration**: Keep separate or consolidate?
  - **Research conducted**: ace-git-commit has overlap but different focus (commit message generation)
  - **Overlap**: Both execute git diff commands, parse output
  - **Difference**: DiffAnalyzer focuses on commit context (scope detection), ace-git-diff focuses on filtering/caching
  - **Option 1**: Make ace-git-commit depend on ace-git-diff for basic diff operations
  - **Option 2**: Keep separate, accept some duplication for different use cases
  - **Option 3**: Extract only git command execution to ace-git-diff, keep analysis separate
  - **Why needs human input**: Architecture decision on gem boundaries
  - **Default assumption**: Option 2 (keep separate initially) to reduce risk

- [ ] **Configuration cascade precedence**: Should instance options completely override or merge with global config?
  - **Research conducted**: ace-core supports configuration cascade with nearest-wins
  - **Current pattern**: Gems use `Ace::Core.config.get('ace', 'gem_name')`
  - **Question**: If global config has `exclude_patterns: [A, B]` and instance has `exclude_patterns: [C]`, should result be:
    1. `[C]` (complete override)
    2. `[A, B, C]` (merge)
    3. Configurable per-key (some merge, some override)
  - **Similar patterns**: ace-lint merges some configs, overrides others
  - **Why needs human input**: UX decision on configuration behavior
  - **Default assumption**: Complete override (simpler mental model, explicit control)

- [ ] **Cache invalidation strategy**: What should invalidate cached diffs?
  - **Research conducted**: Current implementations don't cache, regenerate each time
  - **Invalidation triggers to consider**:
    1. New commits (check `git rev-parse HEAD`)
    2. Staged changes (check `git diff --cached` output)
    3. TTL expiration (time-based, default 5 minutes)
    4. Config changes (harder to detect)
  - **Performance impact**: Diffs can be slow for large repos (>1s for 10k+ files)
  - **Suggested approach**: Invalidate on HEAD change + TTL, warn if config changed
  - **Why needs human input**: Balance between performance and correctness
  - **Default assumption**: Invalidate on HEAD change + 5 minute TTL (documented)

### [LOW] Enhancement Questions

- [ ] **Output format options**: What formats beyond raw/filtered/analyzed/json should we support?
  - **Research conducted**: Current implementations only output raw diff text
  - **Potential formats**:
    - `raw`: Unfiltered git diff
    - `filtered`: With exclude patterns applied
    - `analyzed`: With statistics (files, lines changed)
    - `json`: Structured data
    - `compact`: LLM-focused (seen in ace-docs CompactDiffPrompt)
    - `stat`: Just file names and line counts (like `git diff --stat`)
  - **Why needs human input**: Which formats are valuable enough to implement in v0.1.0?
  - **Default assumption**: raw, filtered, analyzed, json for v0.1.0; defer compact/stat

- [ ] **CLI interactive mode behavior**: What should ace-git-diff prompt for when run with no arguments?
  - **Research conducted**: Other ace-* gems like ace-review show preset selection
  - **Potential prompts**:
    1. Diff type (staged, working, pr, range)
    2. Output format
    3. Filter options
  - **Alternative**: Show usage help instead
  - **Why needs human input**: UX preference for CLI discoverability
  - **Default assumption**: Show usage help with examples (simpler, less surprising)

## Review Findings

### Research Summary

**Existing Git Diff Implementations Found:**
1. **ace-context/lib/ace/context/atoms/git_extractor.rb** (110 lines)
   - Pure functions for git operations
   - Safe command execution with Open3.capture3
   - Methods: git_diff, git_log, staged_diff, working_diff, changed_files
   - Good extraction candidate

2. **ace-docs/lib/ace/docs/atoms/diff_filterer.rb** (131 lines)
   - **Contains hardcoded DEFAULT_EXCLUDE_PATTERNS** (lines 10-23)
   - Pattern filtering and diff parsing
   - Statistics counting (additions, deletions, files)
   - Good extraction candidate

3. **ace-docs/lib/ace/docs/molecules/change_detector.rb** (367 lines)
   - Complex date-to-commit resolution
   - Multi-subject diff generation
   - Path filtering and rename detection
   - Partial extraction candidate (some logic is docs-specific)

4. **ace-git-commit/lib/ace/git_commit/molecules/diff_analyzer.rb** (111 lines)
   - **Not mentioned in task but has overlap**
   - Diff analysis for commit messages
   - Scope detection logic
   - Should be evaluated for consolidation

5. **ace-review/lib/ace/review/molecules/subject_extractor.rb** (103 lines)
   - Already delegates to ace-context for diffs
   - Good pattern for other gems to follow
   - Minimal changes needed

**Key Findings:**
- ✅ Task correctly identifies main extraction targets (GitExtractor, ChangeDetector, DiffFilterer)
- ⚠️ Task doesn't mention ace-git-commit's DiffAnalyzer (potential overlap)
- ✅ Hardcoded patterns problem accurately described in task
- ✅ Configuration approach (`.ace/diff/config.yml`) aligns with ace-core patterns
- ✅ File modification list is comprehensive

### Completeness Analysis

**Well-Specified:**
- ✅ Clear value proposition (consistency through global config)
- ✅ ATOM architecture structure defined
- ✅ Configuration examples provided
- ✅ Migration path documented
- ✅ File creation list is detailed
- ✅ Test strategy outlined

**Needs Clarification:**
- ⚠️ ace-git-commit overlap not addressed
- ⚠️ Backward compatibility timeline undefined
- ⚠️ Cache invalidation strategy needs detail
- ⚠️ Configuration merge vs override behavior unspecified

**Implementation Readiness:**
With the review questions answered, this task is **ready for implementation** with reasonable defaults. The core architecture is sound and extraction targets are clear.

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

## Technical Approach

### Architecture Pattern
The ace-git-diff gem will follow the standard ATOM architecture pattern used across all ace-* gems:
- **Atoms**: Pure functions for git command execution, diff filtering, pattern matching
- **Molecules**: Composed operations for diff generation, cache management, config loading
- **Organisms**: High-level orchestration for complete diff workflows
- **Models**: Data structures for diff results, configurations, cache entries

Integration with existing architecture:
- Uses ace-core for configuration cascade
- Provides unified interface for ace-docs, ace-review, ace-context
- Maintains backward compatibility through dual `diff:`/`commands:` support

### Technology Stack
- **Ruby 3.0+**: Consistent with other ace-* gems
- **Dependencies**:
  - `ace-core ~> 0.9`: Configuration management
  - `Open3`: Safe command execution (stdlib)
  - `YAML`: Configuration parsing (stdlib)
  - `FileUtils`: File operations (stdlib)
- **Development**:
  - `ace-test-support ~> 0.9`: Testing infrastructure
  - `rake`: Task automation
  - `minitest`: Test framework

## File Modifications

### Create Files

#### Core Gem Structure
- `ace-git-diff/` (root directory)
  - Purpose: New gem following ace-gems.g.md structure
  - Key components: ATOM architecture, CLI, configuration

- `ace-git-diff/.ace.example/diff/config.yml`
  - Purpose: Example configuration with sensible defaults
  - Key components: exclude_patterns, options, cache settings

- `ace-git-diff/lib/ace/git_diff.rb`
  - Purpose: Main module and configuration loader
  - Key components: config method, version require, namespace setup

- `ace-git-diff/lib/ace/git_diff/version.rb`
  - Purpose: Version constant
  - Key components: VERSION = "0.1.0"

#### ATOM Architecture Files

**Atoms** (Pure Functions):
- `lib/ace/git_diff/atoms/command_executor.rb`
  - Purpose: Safe git command execution
  - Extract from: ace-context GitExtractor
  - Key components: execute_git_command, error handling

- `lib/ace/git_diff/atoms/pattern_filter.rb`
  - Purpose: Pattern matching and filtering
  - Extract from: ace-docs DiffFilterer
  - Key components: filter_paths, match_pattern

- `lib/ace/git_diff/atoms/diff_parser.rb`
  - Purpose: Parse diff output into structures
  - New implementation
  - Key components: parse_diff, extract_files

- `lib/ace/git_diff/atoms/date_resolver.rb`
  - Purpose: Convert dates to git commits
  - Extract from: ace-docs ChangeDetector
  - Key components: resolve_since_to_commit

**Molecules** (Composed Operations):
- `lib/ace/git_diff/molecules/diff_generator.rb`
  - Purpose: Generate diffs with options
  - Combine: CommandExecutor + DateResolver
  - Key components: generate, special types (staged, working, pr)

- `lib/ace/git_diff/molecules/config_loader.rb`
  - Purpose: Load and merge configuration cascade
  - New implementation using ace-core
  - Key components: load_config, merge_configs

- `lib/ace/git_diff/molecules/cache_manager.rb`
  - Purpose: Cache diff results
  - New implementation
  - Key components: get, set, expired?

- `lib/ace/git_diff/molecules/diff_filter.rb`
  - Purpose: Apply exclude patterns to diffs
  - Uses: PatternFilter atom
  - Key components: filter_diff, apply_excludes

**Organisms** (Business Logic):
- `lib/ace/git_diff/organisms/diff_orchestrator.rb`
  - Purpose: Complete diff workflow orchestration
  - Combines all molecules
  - Key components: generate_diff, from_config

- `lib/ace/git_diff/organisms/integration_helper.rb`
  - Purpose: Helpers for gem integration
  - New implementation
  - Key components: for_ace_docs, for_ace_review, for_ace_context

**Models** (Data Structures):
- `lib/ace/git_diff/models/diff_result.rb`
  - Purpose: Structured diff results
  - Key components: content, stats, metadata

- `lib/ace/git_diff/models/diff_config.rb`
  - Purpose: Configuration data structure
  - Key components: exclude_patterns, options, cascade

#### CLI Implementation
- `lib/ace/git_diff/cli.rb`
  - Purpose: Thor CLI interface
  - Key components: diff command, options parsing

- `lib/ace/git_diff/commands/diff_command.rb`
  - Purpose: Main diff command implementation
  - Key components: execute, option handling

- `exe/ace-git-diff`
  - Purpose: Executable entry point
  - Key components: CLI.start(ARGV)

#### Testing Structure
- `test/test_helper.rb`
  - Purpose: Test setup and helpers
  - Key components: AceTestCase, fixtures

- `test/atoms/*_test.rb`
  - Purpose: Atom unit tests
  - Key components: Pure function testing

- `test/molecules/*_test.rb`
  - Purpose: Molecule integration tests
  - Key components: Component interaction

- `test/organisms/*_test.rb`
  - Purpose: Organism integration tests
  - Key components: Full workflow testing

- `test/commands/*_test.rb`
  - Purpose: CLI command tests
  - Key components: Command execution, output

#### Documentation
- `ace-git-diff/README.md`
  - Purpose: Gem overview and quick start
  - Key components: Installation, usage, migration

- `ace-git-diff/CHANGELOG.md`
  - Purpose: Version history
  - Key components: Keep a Changelog format

- `ace-git-diff/handbook/agents/diff.ag.md`
  - Purpose: Single-purpose diff agent
  - Key components: Agent definition for Claude

### Modify Files

#### Update Existing Gems
- `ace-docs/lib/ace/docs/molecules/change_detector.rb`
  - Changes: Add delegation to ace-git-diff when available
  - Impact: Gradual migration path
  - Integration: Check for ace-git-diff, fallback to current

- `ace-review/lib/ace/review/molecules/subject_extractor.rb`
  - Changes: Support `diff:` key delegation
  - Impact: New configuration option
  - Integration: Detect diff: config, delegate to ace-git-diff

- `ace-context/lib/ace/context/organisms/context_loader.rb`
  - Changes: Integrate diff: key processing
  - Impact: Enhanced diff handling
  - Integration: Process diff: like diffs: but via ace-git-diff

### Delete Files
None - this is a new gem creation with optional integration

## Risk Assessment

### Technical Risks

**Risk:** Breaking existing diff functionality in ace-docs/ace-context
- **Probability:** Medium
- **Impact:** High
- **Mitigation:** Implement as optional delegation with fallback
- **Rollback:** Feature flag to disable ace-git-diff integration

**Risk:** Configuration cascade complexity
- **Probability:** Low
- **Impact:** Medium
- **Mitigation:** Extensive testing of merge scenarios
- **Rollback:** Simplified config with clear precedence

### Integration Risks

**Risk:** Performance degradation from abstraction layer
- **Probability:** Low
- **Impact:** Medium
- **Mitigation:** Implement caching, benchmark before/after
- **Monitoring:** Response time metrics

### Performance Risks

**Risk:** Cache invalidation issues
- **Probability:** Medium
- **Impact:** Low
- **Mitigation:** Conservative TTL, clear cache commands
- **Monitoring:** Cache hit rates
- **Thresholds:** <100ms for cached, <500ms for fresh

## Implementation Plan

### Planning Steps

* [ ] Analyze git diff usage patterns across all ace-* gems
  > TEST: Usage Analysis Complete
  > Type: Pre-condition Check
  > Assert: All diff patterns documented
  > Command: grep -r "git diff" ace-*/lib | wc -l

* [ ] Research Ruby diff parsing libraries for potential use
* [ ] Design cache key strategy for diff results
* [ ] Plan configuration migration path for existing gems

### Execution Steps

- [ ] Create ace-git-diff gem directory structure
  ```bash
  mkdir -p ace-git-diff/{lib/ace/git_diff/{atoms,molecules,organisms,models,commands},test/{atoms,molecules,organisms,commands,fixtures},exe,handbook/{agents,workflow-instructions},.ace.example/diff}
  ```

- [ ] Initialize gem with basic files (Gemfile, gemspec, Rakefile)
  > TEST: Gem Structure Valid
  > Type: Action Validation
  > Assert: All required files exist
  > Command: ls -la ace-git-diff/{*.gemspec,Gemfile,Rakefile} 2>/dev/null | wc -l | grep -q 3

- [ ] Extract and adapt CommandExecutor atom from ace-context
  ```bash
  # Extract git execution logic from ace-context/lib/ace/context/atoms/git_extractor.rb
  # Create ace-git-diff/lib/ace/git_diff/atoms/command_executor.rb
  ```

- [ ] Extract and adapt PatternFilter atom from ace-docs
  ```bash
  # Extract filtering logic from ace-docs/lib/ace/docs/atoms/diff_filterer.rb
  # Create ace-git-diff/lib/ace/git_diff/atoms/pattern_filter.rb
  ```

- [ ] Implement ConfigLoader molecule with ace-core integration
  > TEST: Config Loading Works
  > Type: Action Validation
  > Assert: Configuration cascade functions correctly
  > Command: ruby -I lib -r ace/git_diff -e "p Ace::GitDiff.config"

- [ ] Create DiffGenerator molecule combining atoms
  ```ruby
  # Combine CommandExecutor + DateResolver
  # Support special types: staged, working, pr
  ```

- [ ] Implement CacheManager molecule for result caching
  > TEST: Cache Operations
  > Type: Action Validation
  > Assert: Cache set/get/expire works
  > Command: ruby -I lib test/molecules/cache_manager_test.rb

- [ ] Create DiffOrchestrator organism for complete workflow
  ```ruby
  # Orchestrate: config → generate → filter → cache → format
  ```

- [ ] Implement CLI with Thor
  > TEST: CLI Execution
  > Type: Action Validation
  > Assert: CLI commands work
  > Command: bundle exec exe/ace-git-diff --help

- [ ] Create example configuration file
  ```yaml
  # .ace.example/diff/config.yml with sensible defaults
  ```

- [ ] Write comprehensive test suite
  > TEST: Test Coverage
  > Type: Action Validation
  > Assert: All components tested
  > Command: bundle exec rake test

- [ ] Add integration helpers for ace-docs
  ```ruby
  # lib/ace/git_diff/organisms/integration_helper.rb
  # def self.for_ace_docs(document)
  ```

- [ ] Add integration helpers for ace-review
  ```ruby
  # def self.for_ace_review(preset)
  ```

- [ ] Add integration helpers for ace-context
  ```ruby
  # def self.for_ace_context(config)
  ```

- [ ] Update ace-docs to optionally use ace-git-diff
  > TEST: ace-docs Integration
  > Type: Integration Test
  > Assert: ace-docs can use ace-git-diff
  > Command: cd ace-docs && bundle exec rake test

- [ ] Update ace-review to support diff: key
  > TEST: ace-review Integration
  > Type: Integration Test
  > Assert: ace-review processes diff: config
  > Command: cd ace-review && bundle exec rake test

- [ ] Create handbook agent for diff operations
  ```markdown
  # handbook/agents/diff.ag.md
  ```

- [ ] Write README with installation and migration guide

- [ ] Create CHANGELOG.md with initial version

- [ ] Run full test suite across all affected gems
  > TEST: Full Integration
  > Type: System Test
  > Assert: All gems work with ace-git-diff
  > Command: for gem in ace-git-diff ace-docs ace-review ace-context; do cd $gem && bundle exec rake test || exit 1; cd ..; done

## References

- Original idea: .ace-taskflow/v.0.9.0/docs/ideas/075-20251016-193739-we-should-probably-extract-this-part-to-sepearte-p.md
- Related gems: ace-context, ace-docs, ace-review
- Architecture patterns: docs/ace-gems.g.md, docs/architecture.md
- Usage documentation: ux/usage.md
