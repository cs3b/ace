# Task 060: Migrate Git/Diff Support to ace-context - Usage Guide

## Document Type: How-To Guide + Reference

## Overview

This task migrates git/diff extraction logic from ace-review to ace-context, centralizing all content aggregation capabilities in a single location. The goal is to eliminate code duplication and enable unified configuration schemas across the ACE ecosystem.

**Key Outcomes:**
- ace-context gains `diffs:` configuration key for git diff ranges
- ace-review simplifies by delegating all content extraction to ace-context
- Unified config schema: compose files + commands + presets + diffs in one place
- Better reusability: any tool can use ace-context for git content

## Context

**Current Problem:**
```
ace-review/
├── atoms/git_extractor.rb         # Git operations
├── molecules/subject_extractor.rb # Extracts files/commands/diffs
└── molecules/context_extractor.rb # Extracts files/commands

ace-context/
├── organisms/context_loader.rb    # Extracts files/commands
└── [NO git/diff support]
```

**After Migration:**
```
ace-context/
├── atoms/git_extractor.rb         # Migrated from ace-review
└── organisms/context_loader.rb    # Now supports diffs: [...]

ace-review/
├── [Uses Ace::Context.load_auto for everything]
└── [Focuses on review orchestration only]
```

## Implementation Phases

### Phase 1: Extend ace-context with Git/Diff Support

**Goal**: Add git diff extraction capabilities to ace-context

**Steps**:

1. **Migrate GitExtractor atom**:
```bash
# Copy from ace-review to ace-context
cp ace-review/lib/ace/review/atoms/git_extractor.rb \
   ace-context/lib/ace/context/atoms/git_extractor.rb

# Update namespace from Ace::Review to Ace::Context
# Ensure array-based command execution for security
```

2. **Update ContextLoader to support diffs**:
```ruby
# In ace-context/lib/ace/context/organisms/context_loader.rb
def process_template_config(config)
  # ... existing files, commands handling ...

  # NEW: Process diffs key
  if config['diffs'] && config['diffs'].any?
    config['diffs'].each do |diff_range|
      result = Ace::Context::Atoms::GitExtractor.extract_diff(diff_range)
      if result[:success]
        data[:diffs] ||= []
        data[:diffs] << {
          range: diff_range,
          output: result[:output]
        }
      else
        data[:errors] << "Failed to extract diff #{diff_range}: #{result[:error]}"
      end
    end
  end
end
```

3. **Add tests**:
```bash
cd ace-context
bundle exec ruby -Ilib:test test/context/atoms/git_extractor_test.rb
```

**Expected Output**:
```
GitExtractor
  ✓ extract_diff with valid range returns diff content
  ✓ extract_diff with invalid range returns error
  ✓ staged_diff returns staged changes
  ✓ working_diff returns unstaged changes

4 tests, 0 failures
```

### Phase 2: Add ace-context Dependency to ace-review

**Goal**: Make ace-review depend on ace-context gem

**Steps**:

1. **Update gemspec**:
```ruby
# In ace-review/ace-review.gemspec
spec.add_dependency 'ace-context', '~> 0.9'
```

2. **Update main require file**:
```ruby
# In ace-review/lib/ace/review.rb (top of file)
require 'ace/context'
```

3. **Install dependency**:
```bash
cd ace-review
bundle install
```

**Expected Output**:
```
Fetching ace-context 0.9.x
Installing ace-context 0.9.x
Bundle complete!
```

### Phase 3: Refactor ace-review to Use ace-context

**Goal**: Replace duplicate extraction code with ace-context calls

**Steps**:

1. **Update subject extraction**:
```ruby
# In ace-review/lib/ace/review/organisms/review_manager.rb

# BEFORE:
def extract_subject(subject_config)
  @subject_extractor.extract(subject_config)
end

# AFTER:
def extract_subject(subject_config)
  return "" unless subject_config

  context = Ace::Context.load_auto(subject_config, format: 'markdown')
  context.content || ""
end
```

2. **Update context extraction**:
```ruby
# BEFORE:
def extract_context(context_config)
  @context_extractor.extract(context_config)
end

# AFTER:
def extract_context(context_config)
  return "" unless context_config

  # Handle presets: [...] syntax
  if context_config.is_a?(String) && context_config.include?('presets:')
    parsed = YAML.safe_load(context_config)
    if parsed['presets']
      context = Ace::Context.load_multiple_presets(
        parsed['presets'],
        format: 'markdown'
      )
      return context.content || ""
    end
  end

  # Handle everything else
  context = Ace::Context.load_auto(context_config, format: 'markdown')
  context.content || ""
end
```

3. **Delete redundant files**:
```bash
cd ace-review
rm lib/ace/review/molecules/subject_extractor.rb
rm lib/ace/review/molecules/context_extractor.rb
rm lib/ace/review/atoms/git_extractor.rb
```

4. **Update requires**:
```ruby
# In ace-review/lib/ace/review.rb
# Remove these lines:
# require_relative "review/atoms/git_extractor"
# require_relative "review/molecules/subject_extractor"
# require_relative "review/molecules/context_extractor"
```

5. **Run tests**:
```bash
cd ace-review
bundle exec rake test
```

**Expected Output**:
```
ReviewManager
  ✓ extract_subject uses ace-context
  ✓ extract_context supports presets
  ✓ extract_context handles files and commands

All tests passing
```

### Phase 4: Update Documentation

**Goal**: Document the new unified schema and capabilities

**Files to Update**:

1. **ace-context/README.md**:
```markdown
## Configuration Keys

```yaml
context:
  files: [...]       # File paths and glob patterns
  commands: [...]    # Shell commands to execute
  include: [...]     # Include patterns
  exclude: [...]     # Exclude patterns
  presets: [...]     # Load ace-context presets
  diffs: [...]       # NEW: Git diff ranges
```

### Example: Unified Content Loading

```yaml
context:
  presets: [project]              # Load project documentation
  files: ["lib/new-feature/**/*"] # Add new code files
  diffs: ["origin/main...HEAD"]   # Include git changes
  commands: ["git log -5"]        # Add recent commits
```
```

2. **ace-review/README.md**:
```markdown
## Changes in 0.9.6

- **ace-context Integration**: All content extraction now delegated to ace-context
- **Unified Schema**: Consistent config across ace-context and ace-review
- **Preset Support**: `--context 'presets: [project]'` now works as documented
- **Simplified Codebase**: Removed duplicate extraction logic

### Subject and Context Configuration

Both `--subject` and `--context` now use ace-context's unified schema:

```bash
# Files (use 'files:' not 'patterns:')
ace-review --subject 'files: ["lib/**/*.rb"]'

# Git diffs
ace-review --subject 'diffs: ["origin/main...HEAD"]'

# Presets (now supported!)
ace-review --context 'presets: [project, architecture]'

# Composition
ace-review \
  --subject 'files: ["new/**/*.rb"], diffs: ["main...HEAD"]' \
  --context 'presets: [project]'
```
```

3. **ace-review/CHANGELOG.md**:
```markdown
## [0.9.6] - 2025-10-06

### Changed

- **ace-context integration**: Migrated all content extraction to ace-context
  - Removed duplicate `SubjectExtractor` and `ContextExtractor`
  - ace-review now uses `Ace::Context.load_auto()` for all content loading
  - Added ace-context dependency to gemspec

### Added

- **Preset support in context**: `--context 'presets: [...]'` now works (was documented but not implemented)
- **Unified config schema**: Same configuration works for both subject and context
- **Composable sources**: Mix files, commands, diffs, and presets in one config

### Removed

- `lib/ace/review/molecules/subject_extractor.rb` - replaced by ace-context
- `lib/ace/review/molecules/context_extractor.rb` - replaced by ace-context
- `lib/ace/review/atoms/git_extractor.rb` - migrated to ace-context

### Fixed

- Clarified documentation: use `files:` not `patterns:` for file globs
```

### Phase 5: Version Bumps and Testing

**Goal**: Finalize versions and ensure all tests pass

**Steps**:

1. **Bump ace-context version**:
```ruby
# In ace-context/lib/ace/context/version.rb
VERSION = "0.10.0"  # Minor bump for new diffs: feature
```

2. **Update ace-review version**:
```ruby
# In ace-review/lib/ace/review/version.rb
VERSION = "0.9.6"  # Already updated in Phase 2
```

3. **Run full test suites**:
```bash
# ace-context tests
cd ace-context
bundle exec rake test
# Expected: All tests pass with new git diff tests

# ace-review tests
cd ace-review
bundle exec rake test
# Expected: All tests pass with ace-context integration
```

4. **Manual integration test**:
```bash
cd ace-review

# Test file extraction
ace-review --preset ruby-atom \
  --subject 'files: ["ace-context/lib/**/*.rb"]' \
  --dry-run

# Test diff extraction
ace-review --preset pr \
  --subject 'diffs: ["origin/main...HEAD"]' \
  --dry-run

# Test preset context (previously broken)
ace-review --preset code \
  --context 'presets: [project]' \
  --subject 'diffs: ["HEAD~1..HEAD"]' \
  --dry-run

# Test composition
ace-review \
  --subject 'files: ["lib/**/*.rb"], diffs: ["main...feature"]' \
  --context 'presets: [project, architecture]' \
  --dry-run
```

**Expected Output**:
```
✓ Review session prepared: .ace-taskflow/v.0.9.0/reviews/review-20251006-HHMMSS
  Prompt: .../prompt.md.tmp
  Subject: .../subject.md.tmp
  Context: .../context.md.tmp
```

5. **Commit changes**:
```bash
# Commit ace-context changes
cd ace-context
git add .
git commit -m "feat: Add git/diff support for unified content aggregation

- Add GitExtractor atom for git operations
- Support diffs: key in ContextLoader
- Enable composition of files + commands + diffs + presets
- Update to v0.10.0"

# Commit ace-review changes
cd ../ace-review
git add .
git commit -m "refactor: Integrate ace-context for content extraction

- Add ace-context dependency
- Replace SubjectExtractor/ContextExtractor with ace-context calls
- Enable preset support in context configuration
- Update to v0.9.6
- Remove duplicate extraction code"
```

## Usage Scenarios

### Scenario 1: Review New Feature Code with Context

**Goal**: Review new feature files with project documentation as context

**Before** (doesn't work):
```bash
ace-review --subject 'files: ["new-feature/**/*.rb"]' \
           --context 'presets: [project]'
# Error: presets not supported in context
```

**After** (works with ace-context):
```bash
ace-review --subject 'files: ["new-feature/**/*.rb"]' \
           --context 'presets: [project]' \
           --auto-execute

# ✓ Loads project preset for context
# ✓ Loads new feature files for subject
# ✓ Composes review prompt
# ✓ Executes LLM review
```

### Scenario 2: Review Git Changes Across Multiple Repos

**Goal**: Review changes across main repo and submodules

**Configuration**:
```yaml
# .ace/review/presets/multi-repo.yml
subject:
  diffs:
    - "origin/main...HEAD"                    # Main repo
    - "ace-context/origin/main...HEAD"        # Submodule
    - "ace-review/origin/main...HEAD"         # Submodule

context:
  presets: [project, architecture]
```

**Usage**:
```bash
ace-review --preset multi-repo --auto-execute
```

### Scenario 3: Compose Multiple Content Sources

**Goal**: Review specific files + recent changes + with full context

**Command**:
```bash
ace-review \
  --subject 'files: ["lib/new/**/*.rb"], diffs: ["HEAD~3..HEAD"]' \
  --context 'presets: [project], files: ["docs/architecture.md"]' \
  --auto-execute
```

**What happens**:
1. Subject includes: new files + git diff of last 3 commits
2. Context includes: project preset + architecture docs
3. All aggregated by ace-context using unified schema
4. ace-review composes prompt and calls LLM

## Troubleshooting

### Problem: Tests Failing After Migration

**Symptom**: `NameError: uninitialized constant SubjectExtractor`

**Solution**:
```bash
# Update test files to use ace-context
# Replace extractor tests with integration tests

# Example:
# BEFORE:
# extractor = SubjectExtractor.new
# subject = extractor.extract(config)

# AFTER:
# context = Ace::Context.load_auto(config)
# subject = context.content
```

### Problem: Git Diff Not Working

**Symptom**: `Error: Failed to extract diff`

**Solution**:
```bash
# Ensure you're in a git repository
git status

# Verify the range is valid
git log --oneline origin/main...HEAD

# Check ace-context git extractor works
cd ace-context
bundle exec ruby -Ilib -e "
  require 'ace/context'
  result = Ace::Context::Atoms::GitExtractor.extract_diff('HEAD~1..HEAD')
  puts result[:success] ? 'OK' : result[:error]
"
```

### Problem: Preset Not Found

**Symptom**: `Preset 'project' not found`

**Solution**:
```bash
# List available presets
ace-context --list-presets

# Check preset exists
ls -la .ace/context/presets/project.md

# Verify preset format
cat .ace/context/presets/project.md
# Should have frontmatter with:
# ---
# description: ...
# context:
#   files: [...]
# ---
```

## Best Practices

### 1. Use Unified Schema Consistently

Always use the same config keys across ace-context and ace-review:
- `files:` for file paths and globs (NOT `patterns:`)
- `commands:` for shell commands
- `diffs:` for git diff ranges
- `presets:` for ace-context presets

### 2. Compose Sources Strategically

Combine sources for comprehensive reviews:
```yaml
subject:
  files: ["new/**/*"]        # What changed
  diffs: ["main...feature"]  # How it changed

context:
  presets: [project]         # What matters
  files: ["docs/api.md"]     # Specific reference
```

### 3. Test Both Gems Independently

Before integration testing:
```bash
# Test ace-context alone
cd ace-context
bundle exec rake test

# Test ace-review alone
cd ace-review
bundle exec rake test

# Then test integration
ace-review --preset test-preset --dry-run
```

## Success Checklist

- [ ] ace-context supports `diffs:` key
- [ ] GitExtractor migrated and tested
- [ ] ace-review uses ace-context for all extraction
- [ ] Duplicate code removed from ace-review
- [ ] `presets:` works in ace-review context
- [ ] All tests pass in both gems
- [ ] Documentation updated
- [ ] Version numbers bumped appropriately
- [ ] Integration tested manually
- [ ] Changes committed with clear messages

## Migration Notes

**From ace-review 0.9.5 to 0.9.6:**

- Replace `SubjectExtractor` usage → `Ace::Context.load_auto`
- Replace `ContextExtractor` usage → `Ace::Context.load_auto` or `load_multiple_presets`
- Update test mocks/stubs to use ace-context methods
- Remove requires for deleted extractor files

**Key Differences:**
- ace-review no longer has git_extractor atom (moved to ace-context)
- Preset support now actually works in context configuration
- Unified schema means same config works everywhere
- Better error messages from ace-context's centralized handling
