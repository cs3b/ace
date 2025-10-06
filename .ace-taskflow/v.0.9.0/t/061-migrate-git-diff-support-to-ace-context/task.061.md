---
id: v.0.9.0+task.061
status: in-progress
priority: high
estimate: 3-5h
dependencies: []
created: 2025-10-06
progress: "Phase 1 & 2 complete (ace-context git/diff support + ace-review dependency). Phase 3-5 pending (refactoring ace-review to use ace-context)."
---

# Migrate Git/Diff Support to ace-context

## Context

Currently, ace-review duplicates content extraction logic that should be centralized in ace-context. Both gems implement file reading, command execution, and pattern matching independently. Additionally, ace-review has git/diff extraction capabilities that ace-context lacks, preventing unified content aggregation across the ACE ecosystem.

### Current State

**ace-review contains:**
- `SubjectExtractor` - extracts files/commands/diffs for review subject
- `ContextExtractor` - extracts files/commands for review context
- `GitExtractor` (atom) - git operations and diff extraction

**ace-context supports:**
- Files via `files:` key (glob patterns)
- Commands via `commands:` key
- Presets via frontmatter
- Missing: git/diff support

### Issues

1. **Duplication**: Both gems implement file/command extraction independently
2. **Inconsistency**: Similar but not identical config schemas
3. **Limited Composition**: Can't mix files + commands + diffs + presets in one unified config
4. **Scattered Logic**: Git operations only available in ace-review, not reusable

## Behavioral Specification

### What It Should Do

**ace-context becomes the universal content aggregator with:**

```yaml
context:
  files: [...]       # File paths and glob patterns ✅ (already supported)
  commands: [...]    # Shell commands ✅ (already supported)
  include: [...]     # Include patterns ✅ (already supported)
  exclude: [...]     # Exclude patterns ✅ (already supported)
  presets: [...]     # ace-context presets ✅ (already supported)
  diffs: [...]       # NEW: Git diff ranges/commands
```

**Example unified config:**
```yaml
# Can now compose all sources in one place
context:
  presets: [project]           # Load project preset
  files: ["lib/**/*.rb"]       # Add specific files
  diffs: ["origin/main...HEAD"] # Add git diff
  commands: ["git log -5"]     # Add command output
```

### How ace-review Should Use It

```ruby
# Subject extraction (what to review)
subject_context = Ace::Context.load_auto(subject_config, format: 'markdown')
subject = subject_context.content

# Context extraction (background info)
context_data = Ace::Context.load_auto(context_config, format: 'markdown')
context = context_data.content

# ace-review just orchestrates: compose prompts + call LLM
```

## User Experience

### Before (Current)

```bash
# User has to understand ace-review specific config
ace-review --subject 'files: ["lib/**/*.rb"]' --context 'presets: [project]'
# Error: presets not supported in context!
```

### After (Proposed)

```bash
# Consistent with ace-context everywhere
ace-review --subject 'files: ["lib/**/*.rb"]' --context 'presets: [project]'
# Works! ace-context handles preset loading

# Can compose sources
ace-review \
  --subject 'diffs: ["origin/main...HEAD"], files: ["new-feature/**/*.rb"]' \
  --context 'presets: [project, architecture]'
```

## Interface Contract

### ace-context Public API Extensions

```ruby
module Ace::Context
  # Add git diff support to ContextLoader
  class Organisms::ContextLoader
    def process_template_config(config)
      # Existing: files, commands, include, exclude
      # NEW: Process diffs key
      if config['diffs'] && config['diffs'].any?
        config['diffs'].each do |diff_range|
          result = git_extractor.extract_diff(diff_range)
          data[:diffs] << result if result[:success]
        end
      end
    end
  end

  # New atom for git operations
  module Atoms
    class GitExtractor
      def self.extract_diff(range)
        # Execute git diff with proper error handling
      end

      def self.staged_diff
        # Get staged changes
      end

      def self.working_diff
        # Get working tree changes
      end
    end
  end
end
```

### ace-review Simplification

```ruby
# Remove duplicated extraction logic
# Keep only:
- PresetManager (review-specific presets)
- PromptComposer (review prompt composition)
- LlmExecutor (LLM execution)
- ReviewManager (orchestration)

# Delete:
- SubjectExtractor → use Ace::Context.load_auto
- ContextExtractor → use Ace::Context.load_auto
- GitExtractor atom → moved to ace-context
```

## Implementation Plan

### Planning Steps

* [x] **Analyze ace-review git extraction**: Document all git operations in `ace-review/lib/ace/review/atoms/git_extractor.rb`
* [x] **Review ace-context extension points**: Identify where to add `diffs:` support in `ContextLoader#process_template_config`
* [x] **Design output format**: Determine how git diffs should be formatted in context output (markdown, xml, etc.)
* [x] **Identify edge cases**: Document error handling for invalid git ranges, missing repos, etc.

### Execution Steps

#### Phase 1: Extend ace-context with Git/Diff Support

- [x] Create `ace-context/lib/ace/context/atoms/git_extractor.rb`
  - Migrate from `ace-review/lib/ace/review/atoms/git_extractor.rb`
  - Keep array-based command execution for security
  - Add methods: `extract_diff`, `staged_diff`, `working_diff`, `tracking_branch`

- [x] Update `ace-context/lib/ace/context/organisms/context_loader.rb`
  - Add `diffs:` key support in `process_template_config` (line ~358)
  - Handle diff extraction with error reporting
  - Format diff output consistently with other content types

- [x] Update `ace-context/lib/ace/context.rb`
  - Require new git_extractor atom
  - Export as part of public API

- [x] Add tests for git operations in ace-context
  - Test diff extraction
  - Test error handling (invalid ranges, no git repo)
  - Test output formatting

#### Phase 2: Add ace-context Dependency to ace-review

- [x] Update `ace-review/ace-review.gemspec`
  - Add `spec.add_dependency 'ace-context', '~> 0.9'`
  - Bump version to 0.9.6

- [x] Update `ace-review/lib/ace/review.rb`
  - Add `require 'ace/context'` at top level

#### Phase 3: Refactor ace-review to Use ace-context

- [x] Replace `SubjectExtractor` with ace-context calls
  - Modified SubjectExtractor to delegate to Ace::Context.load_auto
  - Preserved special keywords (staged, working, pr)
  - Supports files, commands, and diffs via ace-context

- [x] Replace `ContextExtractor` with ace-context calls
  - Modified ContextExtractor to delegate to Ace::Context.load_auto
  - Preserved "project" context behavior (default docs)
  - Supports ace-review presets and ace-context presets
  - Enables `presets:` support for context

- [x] Delete redundant extraction code
  - Removed `ace-review/lib/ace/review/atoms/git_extractor.rb`
  - Removed `ace-review/lib/ace/review/atoms/file_reader.rb`
  - Kept SubjectExtractor and ContextExtractor as compatibility wrappers

- [x] Update require statements
  - Cleaned up `ace-review/lib/ace/review.rb` to remove deleted atom files

#### Phase 4: Update Documentation and Tests

- [ ] Update ace-context README
  - Document new `diffs:` key
  - Add examples of git diff usage
  - Show composition with files/commands/presets

- [ ] Update ace-context CHANGELOG
  - Add entry for git/diff support
  - Note new `diffs:` configuration key

- [ ] Update ace-review README
  - Update to v0.9.6
  - Document that context/subject now use ace-context
  - Update examples to show working `presets:` syntax
  - Clarify use of `files:` not `patterns:`

- [ ] Update ace-review CHANGELOG
  - Document ace-context integration
  - Note removal of duplicate extraction code
  - Highlight new capabilities (preset composition)

- [ ] Update ace-review workflow documentation
  - Fix `review.wf.md` examples to use `files:` not `patterns:`
  - Show working `presets:` context examples

- [ ] Update/fix ace-review tests
  - Update tests that relied on old extractors
  - Add tests for ace-context integration
  - Verify preset loading works

#### Phase 5: Version Bumps and Release

- [ ] Bump ace-context version
  - Update `lib/ace/context/version.rb` to appropriate version
  - Consider if this is minor (0.9.x → 0.10.0) or patch

- [ ] Bump ace-review version
  - Already updated to 0.9.6 in Phase 2
  - Ensure CHANGELOG reflects all changes

- [ ] Run full test suite for both gems
  - `cd ace-context && bundle exec rake test`
  - `cd ace-review && bundle exec rake test`

- [ ] Commit changes
  - Atomic commits per phase
  - Clear commit messages referencing task 061

## Acceptance Criteria

### Functional Requirements

- [ ] ace-context supports `diffs:` key in configuration
- [ ] ace-context can extract git diffs with proper formatting
- [ ] ace-review uses ace-context for all content extraction (subject & context)
- [ ] `--context 'presets: [project]'` works in ace-review (as documented)
- [ ] `--subject 'files: [...]'` works (clarified: not `patterns:`)
- [ ] Can compose multiple sources: `presets: [...], files: [...], diffs: [...], commands: [...]`

### Technical Requirements

- [ ] No duplication of extraction logic between gems
- [ ] ace-review depends on ace-context properly
- [ ] All existing ace-review tests pass
- [ ] Git operations use secure array-based command execution
- [ ] Error handling for invalid git ranges/missing repos

### Documentation Requirements

- [ ] ace-context README documents `diffs:` key with examples
- [ ] ace-review README updated to show ace-context integration
- [ ] Workflow documentation clarified (use `files:` not `patterns:`)
- [ ] CHANGELOG updated for both gems

## Success Criteria

1. **Architecture**: ace-context is the single source of truth for content aggregation
2. **Simplicity**: ace-review code is simpler, focused on review orchestration
3. **Consistency**: Same config schema across ace-context and ace-review
4. **Functionality**: All existing ace-review features work + new preset composition
5. **Documentation**: Clear examples showing unified content loading

## Notes

- This is a refactoring task - no new end-user features, just better architecture
- Breaking change if external code depends on ace-review extractors (unlikely)
- Consider: ace-context version might need minor bump (0.9 → 0.10) for new `diffs:` feature
- The `patterns:` vs `files:` confusion is resolved: always use `files:` for file globs
