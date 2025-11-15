---
id: v.0.9.0+task.112
status: pending
priority: medium
estimate: 4-6h
dependencies: []
---

# Standardize cache system prompt management across ace-* gems

## Behavioral Specification

### User Experience
- **Input**: Developers and AI agents executing ace-review, ace-docs, or other prompt-generating gems
- **Process**: Consistent, transparent generation and caching of prompts with standardized file locations and naming
- **Output**: Predictable, debuggable prompt cache files in standardized locations with consistent naming conventions

### Expected Behavior
When a developer or AI agent uses ace-review or ace-docs (or future prompt-generating gems), they experience:

1. **Consistent cache locations**: All prompt caches appear in `.cache/{gem-name}/sessions/{operation}-{timestamp}/` with identical structure
2. **Predictable file names**: System prompts always named `system.prompt.md`, user prompts always `user.prompt.md`
3. **Transparent debugging**: Easy inspection of exact prompts sent to LLMs via standardized cache files
4. **Unified metadata format**: Consistent `metadata.yml` structure across all gems for tracking session information
5. **Reusable utilities**: Shared prompt caching behavior reduces code duplication and ensures consistency

### Interface Contract
```bash
# Consistent cache structure across all gems
.cache/
├── ace-review/sessions/
│   └── review-20251115-143022/
│       ├── system.prompt.md      # System prompt (standardized name)
│       ├── user.prompt.md        # User prompt (standardized name)
│       ├── metadata.yml          # Session metadata (standardized schema)
│       └── output.md             # Gem-specific output
├── ace-docs/sessions/
│   └── analyze-20251115-143045/
│       ├── system.prompt.md      # Same naming convention
│       ├── user.prompt.md        # Same naming convention
│       ├── metadata.yml          # Same metadata schema
│       └── report.md             # Gem-specific output

# Metadata schema (standardized across all gems)
timestamp: 2025-11-15T14:30:22Z
gem: ace-review
operation: code-review
model: google:gemini-2.5-flash
prompt_sizes:
  system: 1234
  user: 5678
session_dir: /path/to/session
```

**Error Handling:**
- [Cache directory creation failure]: Fail with clear error message about permissions
- [File write failure]: Report specific file and reason for failure
- [Invalid metadata]: Validate and report schema violations

**Edge Cases:**
- [Concurrent operations]: Each operation gets unique timestamp-based directory
- [Long prompts]: Handle prompts exceeding filesystem limits gracefully
- [Special characters in operation names]: Sanitize for valid directory names

### Success Criteria
- [ ] **Consistent Naming**: All gems use identical file naming: `system.prompt.md` and `user.prompt.md`
- [ ] **Unified Structure**: All gems use `.cache/{gem}/sessions/{operation}-{timestamp}/` pattern
- [ ] **Shared Utilities**: Common prompt caching code extracted to ace-support-core
- [ ] **Metadata Standardization**: All gems use same metadata.yml schema
- [ ] **Zero Breaking Changes**: Existing functionality preserved with smooth migration
- [ ] **Documentation**: Pattern documented in ace-gems.g.md for future gems

### Validation Questions
- [ ] **Migration Strategy**: Should we provide backward compatibility for old cache locations?
- [ ] **Cache Retention**: Should there be a unified cache cleanup strategy across gems?
- [ ] **Metadata Extensions**: Can gems add custom fields to metadata.yml or must it be fixed?
- [ ] **Access Patterns**: Should we provide CLI tools for inspecting cached prompts across gems?

## Objective

Standardize how ace-* gems generate, cache, and manage prompts sent to LLMs to improve debugging transparency, reduce code duplication, and ensure consistent behavior across the ecosystem. This addresses the discovery that ace-review and ace-docs already implement prompt caching but with inconsistent patterns.

## Scope of Work

- **User Experience Scope**: Developers debugging LLM interactions, AI agents reading cached prompts, maintainers adding prompt caching to new gems
- **System Behavior Scope**: Prompt generation, cache file creation, metadata tracking, session management
- **Interface Scope**: File system structure, naming conventions, metadata schemas

### Deliverables

#### Behavioral Specifications
- Standardized cache directory structure specification
- Unified file naming conventions
- Common metadata schema definition

#### Validation Artifacts
- Migration guide for existing gems (ace-review, ace-docs)
- Testing scenarios for cache operations
- Documentation updates for ace-gems.g.md

## Out of Scope
- ❌ **Implementation Details**: Specific Ruby modules, class hierarchies, method signatures
- ❌ **Technology Decisions**: Whether to use FileUtils, Pathname, or other libraries
- ❌ **Performance Optimization**: Cache compression, cleanup algorithms, or storage optimization
- ❌ **Future Enhancements**: Distributed caching, cloud storage, or advanced cache features

## References

- Original idea: `.ace-taskflow/v.0.9.0/ideas/done/20251104-005745-review-feat/standardize-cache-system-prompt-management.s.md`
- Current ace-review implementation: v0.13.0 with existing prompt caching
- Current ace-docs implementation: with different naming conventions
- Investigation results showing existing but inconsistent implementations

## Implementation Plan

### Planning Steps

* [ ] **Analyze Current Implementations**: Deep dive into ace-review and ace-docs prompt caching
  - Review `ace-review/lib/ace/review/organisms/review_manager.rb` (lines 171-189)
  - Review `ace-docs/lib/ace/docs/organisms/cross_document_analyzer.rb` (lines 198-206)
  - Document current differences in detail

* [ ] **Design Shared Utilities**: Plan ace-support-core additions
  - Design `Ace::Core::Molecules::PromptCacheManager` interface
  - Define standardized methods for session creation, prompt saving, metadata management
  - Plan migration path for existing implementations

* [ ] **Define Migration Strategy**: Plan backward compatibility approach
  - Determine if symlinks needed for old cache locations
  - Plan deprecation warnings for old patterns
  - Design smooth transition path

* [ ] **Test Strategy Planning**: Design test approach
  - Plan unit tests for new shared utilities
  - Plan integration tests for migrated gems
  - Design validation for backward compatibility

### Execution Steps

#### Phase 1: Create Shared Utilities in ace-support-core

- [ ] **Create PromptCacheManager molecule**
  > TEST: Module Creation
  > Type: Unit Test
  > Assert: Ace::Core::Molecules::PromptCacheManager exists
  > Command: # ruby -e "require 'ace/core'; puts Ace::Core::Molecules::PromptCacheManager"

  Create file: `ace-support-core/lib/ace/core/molecules/prompt_cache_manager.rb`
  - Implement `create_session_directory(gem_name, operation)`
  - Implement `save_prompt(content, session_dir, type: 'system')`
  - Implement `save_metadata(metadata, session_dir)`
  - Implement `standardize_metadata(raw_metadata)`

- [ ] **Add test coverage for PromptCacheManager**
  Create file: `ace-support-core/test/molecules/prompt_cache_manager_test.rb`
  - Test session directory creation with timestamps
  - Test prompt file saving with standardized names
  - Test metadata schema validation
  - Test error handling for file operations

- [ ] **Update ace-support-core version**
  Edit: `ace-support-core/lib/ace/core/version.rb`
  - Bump version for new functionality

#### Phase 2: Migrate ace-review to Standardized Pattern

- [ ] **Update ace-review to use shared utilities**
  > TEST: ace-review Cache Standardization
  > Type: Integration Test
  > Assert: ace-review creates system.prompt.md (not system.prompt.md)
  > Command: # ace-review --preset test && ls -la .cache/ace-review/sessions/*/system.prompt.md

  Edit: `ace-review/lib/ace/review/organisms/review_manager.rb`
  - Replace custom cache creation with PromptCacheManager
  - Ensure file naming matches standard (already correct)
  - Update metadata generation to use standard schema

- [ ] **Add ace-support-core dependency**
  Edit: `ace-review/ace-review.gemspec`
  - Update ace-support-core version requirement

- [ ] **Update ace-review tests**
  Edit: `ace-review/test/organisms/review_manager_test.rb`
  - Update tests to verify standardized behavior

#### Phase 3: Migrate ace-docs to Standardized Pattern

- [ ] **Rename ace-docs cache files to standard names**
  > TEST: ace-docs Cache Standardization
  > Type: Integration Test
  > Assert: ace-docs creates system.prompt.md (not prompt-system.md)
  > Command: # ace-docs analyze-consistency && ls -la .cache/ace-docs/sessions/*/system.prompt.md

  Edit: `ace-docs/lib/ace/docs/organisms/cross_document_analyzer.rb`
  - Change `prompt-system.md` → `system.prompt.md`
  - Change `prompt-user.md` → `user.prompt.md`
  - Replace custom cache code with PromptCacheManager

- [ ] **Update session directory pattern**
  Edit: `ace-docs/lib/ace/docs/organisms/cross_document_analyzer.rb`
  - Change directory pattern to `{operation}-{timestamp}`
  - Use PromptCacheManager.create_session_directory

- [ ] **Add ace-support-core dependency**
  Edit: `ace-docs/ace-docs.gemspec`
  - Update ace-support-core version requirement

- [ ] **Update ace-docs tests**
  Edit: `ace-docs/test/organisms/cross_document_analyzer_test.rb`
  - Update tests for new file names
  - Verify standardized structure

#### Phase 4: Documentation and Guidelines

- [ ] **Update ace-gems development guide**
  Edit: `docs/ace-gems.g.md`
  - Add "Prompt Caching Pattern" section
  - Document PromptCacheManager usage
  - Provide examples for new gems

- [ ] **Create prompt caching guide**
  Create: `dev-handbook/guides/prompt-caching-pattern.g.md`
  - Document standardized structure
  - Provide implementation examples
  - Include migration guide

- [ ] **Update gem READMEs**
  - Edit: `ace-review/README.md` - Document cache structure
  - Edit: `ace-docs/README.md` - Document cache structure
  - Edit: `ace-support-core/README.md` - Document PromptCacheManager

#### Phase 5: Validation and Testing

- [ ] **Manual validation of ace-review**
  - Run ace-review with various presets
  - Verify cache files use standard names
  - Check metadata.yml format

- [ ] **Manual validation of ace-docs**
  - Run ace-docs analyze-consistency
  - Verify migrated file names
  - Check backward compatibility if implemented

- [ ] **Run full test suite**
  > TEST: All Tests Pass
  > Type: Test Suite
  > Assert: All ace-* gem tests pass
  > Command: # bundle exec rake test

  - Run ace-support-core tests
  - Run ace-review tests
  - Run ace-docs tests

### Risk Mitigation

- **Breaking changes**: Careful migration with tests at each step
- **Cache compatibility**: Consider symlinks or dual-write during transition
- **Performance impact**: Minimal - mostly renaming and organization
- **Rollback plan**: Git revert if issues discovered

### Validation Checklist

- [ ] ace-review uses `system.prompt.md` naming
- [ ] ace-docs uses `system.prompt.md` naming (migrated from `prompt-system.md`)
- [ ] Both gems use `.cache/{gem}/sessions/{op}-{timestamp}/` structure
- [ ] PromptCacheManager in ace-support-core works correctly
- [ ] All tests pass for affected gems
- [ ] Documentation updated in ace-gems.g.md
- [ ] No breaking changes for existing functionality