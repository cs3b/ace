---
id: v.0.9.0+task.117
status: pending
priority: medium
estimate: 16-24h
dependencies: []
---

# Implement ace-prompt for fast LLM-powered prompt enhancement

## Behavioral Specification

### User Experience
- **Input**: Developers store prompts in files at hierarchical paths (.ace/prompts/, .cache/prompts/queue/), optionally specifying context presets in frontmatter
- **Process**: ace-prompt reads the prompt file, merges context presets (config defaults + prompt-specific), enriches with ace-context, optionally enhances via Haiku LLM for clarity, and outputs to stdout
- **Output**: Enhanced, contextually-enriched prompt ready to pipe to ace-llm-query or other tools

### Expected Behavior

Developers need a fast, intelligent prompt enhancement layer that ensures all prompts sent to LLM models are clear, contextual, and unambiguous. The tool should:

1. **File-based Prompt Management**: Store prompts in files with YAML frontmatter for metadata and context specification
2. **Hierarchical Discovery**: Find prompts using protocol-based discovery (prompt://) and hierarchical search paths
3. **Context Enrichment**: Automatically enrich prompts with project context by merging default presets from config with prompt-specific presets
4. **Fast Enhancement**: Use Haiku model to refine prompts for clarity, ensuring unambiguous instructions
5. **Seamless Integration**: Work as a preprocessing layer before ace-llm-query, via piping or /ace:prompt workflow

The focus is on developer experience: making it easy to create, reuse, and enhance prompts without manual context copying or prompt refinement.

### Interface Contract

```bash
# CLI Interface

# Read prompt with automatic enhancement (default behavior)
ace-prompt read PROMPT_NAME
ace-prompt read prompt://enhance-system
# Output: Enhanced prompt with merged context to stdout
# Exit code: 0 on success, 1 on error

# Read raw prompt without any processing
ace-prompt read PROMPT_NAME --raw
# Output: Raw prompt content only
# Exit code: 0 on success, 1 on error

# Read with context but no enhancement
ace-prompt read PROMPT_NAME --no-enhance
# Output: Prompt with context enrichment only
# Exit code: 0 on success, 1 on error

# Enhance prompt explicitly
ace-prompt enhance PROMPT_NAME
# Output: Enhanced prompt to stdout
# Exit code: 0 on success, 1 on error

# List available prompts
ace-prompt list
# Output: Table of prompts with name, location, context presets
# Exit code: 0 on success, 1 on error

# Show prompt info and effective context
ace-prompt info PROMPT_NAME
# Output: Metadata, context presets, file path
# Exit code: 0 on success, 1 on error

# Show current configuration
ace-prompt config
# Output: Current config with search paths, enhancement settings
# Exit code: 0 on success, 1 on error

# Integration via slash command
/ace:prompt
# Behavior: Uses ace-prompt read with auto-enhance, ready for LLM execution
```

**Prompt File Format:**
```markdown
---
title: Code Review Enhancement
description: Enhance code review prompts
context: [task, diff]  # Simple preset list merged with config defaults
enhancement:
  model: haiku
  temperature: 0.3
---

Prompt content here...
```

**Configuration Format (.ace/prompt/config.yml):**
```yaml
prompt:
  search_paths:
    - .ace/prompts
    - .cache/prompts/queue
  enhancement:
    enabled: true
    model: haiku
    temperature: 0.3
    cache_enhanced: true
    cache_path: .cache/prompts/enhanced
    system_prompt: prompt://enhance-system
  context:
    default_presets: [base, project]
    max_context_size: 8000
```

**Error Handling:**
- **Prompt not found**: "Prompt 'NAME' not found. Available prompts: [list]" (exit 1)
- **Invalid frontmatter**: "Invalid YAML frontmatter in prompt file" (exit 1)
- **Context preset not found**: "Context preset 'NAME' not found" (exit 1)
- **Enhancement failure**: "Failed to enhance prompt: [LLM error]" (exit 1)
- **Protocol resolution failure**: "Cannot resolve prompt:// protocol" (exit 1)

**Edge Cases:**
- Empty prompt file: Return empty string with warning
- Missing context preset: Skip missing preset, log warning, continue with available
- Cache miss: Enhance on-the-fly, save to cache
- Multiple prompts with same name: Use first found in search path order

### Success Criteria

- [ ] **Prompt File Management**: Developers can store prompts in .ace/prompts/ and .cache/prompts/queue/ with YAML frontmatter
- [ ] **Protocol Discovery**: Prompts are discoverable via prompt:// protocol through ace-nav integration
- [ ] **Context Preset Merging**: Config default_presets merge with prompt-specific context presets correctly
- [ ] **ace-context Integration**: Merged presets are passed to ace-context and output prepended to prompt
- [ ] **Fast Enhancement**: Haiku model enhances prompts for clarity in <2 seconds
- [ ] **CLI Commands**: All commands (read, enhance, list, info, config) work correctly with proper exit codes
- [ ] **Piping Support**: Enhanced prompts pipe cleanly to ace-llm-query
- [ ] **Caching**: Enhanced prompts cache to .cache/prompts/enhanced/ for performance
- [ ] **/ace:prompt Integration**: Slash command works in Claude Code using ace-prompt read
- [ ] **Error Handling**: Clear error messages for all failure scenarios

### Validation Questions

- [ ] **Context Merging Strategy**: Should prompt-specific presets replace or extend config defaults? (Current spec: extend/merge)
- [ ] **Enhancement Caching**: Should cache be keyed by prompt content hash or file path? (Current spec: TBD)
- [ ] **Protocol Registration**: Should prompt:// be registered in ace-prompt gem or centrally? (Current spec: in gem)
- [ ] **Default Behavior**: Should --auto-enhance be default for `read` command or opt-in? (Current spec: default)
- [ ] **Context Size Limits**: How to handle when merged context exceeds max_context_size? (Current spec: TBD)
- [ ] **Enhancement System Prompt**: Should enhancement instructions be configurable per-prompt or global? (Current spec: global with override)

## Objective

Enable developers to manage prompts as versionable files with automatic context enrichment and LLM-powered enhancement, ensuring all prompts sent to language models are clear, contextual, and unambiguous. This improves prompt quality, reduces manual context copying, and creates a reusable prompt library.

## Scope of Work

- **User Experience Scope**:
  - File-based prompt storage and management
  - Protocol-based prompt discovery
  - Context enrichment through preset merging
  - Fast prompt enhancement via LLM
  - Command-line interface for prompt operations
  - Integration with Claude Code via /ace:prompt

- **System Behavior Scope**:
  - Hierarchical prompt file discovery
  - YAML frontmatter parsing
  - ace-nav protocol registration (prompt://)
  - ace-context preset merging and enrichment
  - ace-llm integration for Haiku-based enhancement
  - Result caching for performance
  - Configuration via ace-support-core cascade

- **Interface Scope**:
  - CLI commands: read, enhance, list, info, config
  - Protocol handler for prompt://
  - /ace:prompt slash command integration
  - YAML frontmatter schema for prompts
  - Configuration schema for .ace/prompt/config.yml

### Deliverables

#### Behavioral Specifications
- User experience flow for prompt creation, discovery, and execution
- System behavior for context merging and enhancement
- Interface contracts for all CLI commands and protocols

#### Validation Artifacts
- Success criteria validation through CLI testing
- User acceptance scenarios for prompt workflows
- Behavioral test scenarios covering normal and edge cases

## Out of Scope

- ❌ **Implementation Details**: ATOM architecture, specific file structures, gem organization (handled in planning phase)
- ❌ **Technology Decisions**: Thor vs custom CLI, specific cache format, LLM provider details (handled in planning phase)
- ❌ **Performance Optimization**: Specific caching strategies, concurrent enhancement (handled in implementation)
- ❌ **Future Enhancements**: Prompt versioning, diff tracking, interactive selection, multi-prompt sessions (deferred)

## References

- Source idea file: .ace-taskflow/v.0.9.0/ideas/done/20251106-135655-llm-feat/implement-ace-prompt-command-for-file-based-management.s.md
- Related gems: ace-context (preset system), ace-llm (enhancement), ace-nav (protocol registration)
- Similar patterns: ace-context preset composition, ace-review preset-based reviews

## Technical Research

### Architecture Pattern Analysis
Following ACE gem patterns (docs/ace-gems.g.md):
- **ATOM architecture**: atoms/ (pure functions) → molecules/ (operations) → organisms/ (orchestration) → models/ (data)
- **Config cascade**: Use ace-support-core VirtualConfigResolver for .ace/prompt/config.yml
- **Handbook integration**: agents/ and workflow-instructions/ for AI integration
- **Protocol registration**: Similar to wfi:// in ace-nav, implement prompt:// protocol
- **Flat test structure**: test/{atoms,molecules,organisms,models}/ following ADR-017

### Technology Stack
**Dependencies:**
- **ace-support-core** (~> 0.10): Config cascade, VirtualConfigResolver, FileReader/Writer
- **ace-llm** (~> 0.5): QueryInterface for Haiku enhancement
- **ace-context** (~> 0.8): Preset loading and context aggregation
- **ace-nav** (~> 0.4): Protocol registration support
- **thor** (~> 1.2): CLI framework (standard for ace-* gems)

**Development Dependencies:**
- **ace-support-test-helpers** (~> 0.9): Testing infrastructure
- **minitest** (~> 5.0): Test framework

### Implementation Approach

**Preset Merging Strategy:**
Following ace-context patterns, implement preset array merging:
1. Load config default_presets: [base, project]
2. Parse prompt frontmatter context: [task, diff]
3. Merge arrays: [base, project, task, diff]
4. Execute: `ace-context base project task diff`
5. Prepend output to prompt content

**Enhancement Strategy:**
Use ace-llm QueryInterface with Haiku:
1. Load enhancement system prompt (configurable via prompt://enhance-system)
2. Build enhancement query: system prompt + original prompt
3. Execute via `Ace::LLM::QueryInterface.query(prompt, model: 'haiku', temperature: 0.3)`
4. Cache result keyed by content hash (MD5)
5. Return enhanced prompt

**Protocol Registration:**
Register with ace-nav in .ace.example/nav/protocols/wfi-sources/ace-prompt.yml:
```yaml
sources:
  - type: directory
    path: .ace/prompts
    protocol: prompt
  - type: directory
    path: .cache/prompts/queue
    protocol: prompt
```

### File Modification Planning

#### Create Files

**Gem Structure:**
- `ace-prompt/lib/ace/prompt/version.rb` - Version constant (0.1.0)
- `ace-prompt/lib/ace/prompt/cli.rb` - Thor CLI entry point
- `ace-prompt/lib/ace/prompt.rb` - Main module and config accessor

**Atoms (Pure Functions):**
- `ace-prompt/lib/ace/prompt/atoms/protocol_resolver.rb` - Resolve prompt:// to file path
- `ace-prompt/lib/ace/prompt/atoms/frontmatter_parser.rb` - Parse YAML frontmatter
- `ace-prompt/lib/ace/prompt/atoms/content_hasher.rb` - MD5 hash for caching
- `ace-prompt/lib/ace/prompt/atoms/preset_merger.rb` - Merge preset arrays

**Molecules (Operations):**
- `ace-prompt/lib/ace/prompt/molecules/prompt_finder.rb` - Hierarchical search
- `ace-prompt/lib/ace/prompt/molecules/prompt_loader.rb` - Load with metadata
- `ace-prompt/lib/ace/prompt/molecules/context_builder.rb` - Build ace-context call
- `ace-prompt/lib/ace/prompt/molecules/cache_manager.rb` - Cache read/write

**Organisms (Business Logic):**
- `ace-prompt/lib/ace/prompt/organisms/context_aggregator.rb` - Orchestrate ace-context
- `ace-prompt/lib/ace/prompt/organisms/prompt_enhancer.rb` - LLM enhancement
- `ace-prompt/lib/ace/prompt/organisms/prompt_manager.rb` - Full workflow orchestration

**Models:**
- `ace-prompt/lib/ace/prompt/models/prompt.rb` - Prompt data model
- `ace-prompt/lib/ace/prompt/models/prompt_metadata.rb` - Metadata model

**CLI Commands:**
- `ace-prompt/lib/ace/prompt/commands/read_command.rb` - Read command
- `ace-prompt/lib/ace/prompt/commands/enhance_command.rb` - Enhance command
- `ace-prompt/lib/ace/prompt/commands/list_command.rb` - List command
- `ace-prompt/lib/ace/prompt/commands/info_command.rb` - Info command
- `ace-prompt/lib/ace/prompt/commands/config_command.rb` - Config command

**Configuration & Examples:**
- `ace-prompt/.ace.example/prompt/config.yml` - Example configuration
- `ace-prompt/.ace.example/nav/protocols/wfi-sources/ace-prompt.yml` - Protocol registration
- `ace-prompt/.ace.example/prompts/enhance-system.md` - Enhancement system prompt example

**Handbook:**
- `ace-prompt/handbook/agents/enhance-prompt.ag.md` - Enhancement agent
- `ace-prompt/handbook/workflow-instructions/prompt-enhancement.wf.md` - Enhancement workflow

**Documentation:**
- `ace-prompt/README.md` - Overview and quick start
- `ace-prompt/CHANGELOG.md` - Keep a Changelog format
- `ace-prompt/docs/usage.md` - Comprehensive usage guide

**Tests (Flat Structure):**
- `ace-prompt/test/test_helper.rb` - Test configuration
- `ace-prompt/test/atoms/protocol_resolver_test.rb`
- `ace-prompt/test/atoms/frontmatter_parser_test.rb`
- `ace-prompt/test/atoms/content_hasher_test.rb`
- `ace-prompt/test/atoms/preset_merger_test.rb`
- `ace-prompt/test/molecules/prompt_finder_test.rb`
- `ace-prompt/test/molecules/prompt_loader_test.rb`
- `ace-prompt/test/molecules/context_builder_test.rb`
- `ace-prompt/test/molecules/cache_manager_test.rb`
- `ace-prompt/test/organisms/context_aggregator_test.rb`
- `ace-prompt/test/organisms/prompt_enhancer_test.rb`
- `ace-prompt/test/organisms/prompt_manager_test.rb`
- `ace-prompt/test/models/prompt_test.rb`
- `ace-prompt/test/integration/cli_integration_test.rb`

**Mono-repo Integration:**
- `bin/ace-prompt` - Development binstub
- `ace-prompt/exe/ace-prompt` - Gem executable
- `ace-prompt/ace-prompt.gemspec` - Gem specification
- `ace-prompt/Rakefile` - Test tasks

**Claude Code Integration:**
- `.claude/commands/ace-prompt.md` - /ace:prompt command definition

#### Modify Files

**Root Gemfile:**
- Add `gem 'ace-prompt', path: './ace-prompt'` to development dependencies

**Root Rakefile (if exists):**
- Include ace-prompt tests in unified test tasks

## Test Case Planning

### Test Scenarios

**Happy Path Scenarios:**
1. Read simple prompt without enhancement - verify raw content output
2. Read prompt with auto-enhancement - verify enhanced output differs from raw
3. List available prompts - verify discovery across search paths
4. Context preset merging - verify config + prompt presets combine correctly
5. Cache hit on enhanced prompt - verify fast retrieval (<100ms)
6. Protocol resolution prompt://name - verify file path resolution

**Edge Case Scenarios:**
1. Empty prompt file - return empty string with warning
2. Prompt with no frontmatter - treat as plain text, use config defaults
3. Missing context preset in frontmatter - skip missing, log warning, continue
4. Multiple prompts with same name - use first found in search order
5. Very large prompt (>10KB) - handle without memory issues
6. Concurrent cache access - handle file locks correctly

**Error Condition Scenarios:**
1. Prompt not found - clear error message with available prompts list
2. Invalid YAML frontmatter - parse error with line number
3. ace-context preset not found - error message identifying missing preset
4. LLM enhancement failure - fallback to raw prompt or retry once
5. Cache write permission denied - warn and continue without caching
6. Protocol resolution fails - clear error about protocol setup

**Integration Point Scenarios:**
1. ace-context integration - verify preset array passed correctly
2. ace-llm QueryInterface - verify model, temperature, prompt passed
3. ace-nav protocol registration - verify prompt:// resolves
4. Config cascade - verify .ace/prompt/config.yml loads from project root
5. Piping to ace-llm-query - verify output format compatible

### Test Type Categorization

**Unit Tests (High Priority):**
- Protocol resolver: prompt://name → file path mapping
- Frontmatter parser: YAML parsing with error handling
- Preset merger: Array concatenation logic
- Content hasher: MD5 generation for caching
- All atoms tested in isolation with mocked dependencies

**Integration Tests (Medium Priority):**
- CLI commands end-to-end (read, enhance, list, info, config)
- Context aggregator with real ace-context calls
- Prompt enhancer with real ace-llm calls (using VCR cassettes)
- Cache manager with filesystem operations
- Protocol registration with ace-nav

**Performance Tests (High Priority):**
- Enhancement latency: <2 seconds for typical prompt
- Cache retrieval: <100ms for cached prompts
- Large prompt handling: >10KB prompts without issues
- Concurrent access: Multiple processes reading/enhancing

**Security Tests (Medium Priority):**
- Path traversal prevention: prompt://../../../etc/passwd blocked
- Command injection in prompts: No shell execution vulnerabilities
- Config validation: Invalid config rejected safely

## Implementation Plan

### Planning Steps

* [ ] **Research ace-context preset loading mechanism**
  - Read ace-context/lib/ace/context/molecules/preset_manager.rb
  - Understand how presets are loaded and composed
  - Document preset array passing to ace-context CLI

* [ ] **Research ace-llm QueryInterface usage**
  - Read ace-llm/lib/ace/llm/organisms/query_interface.rb
  - Understand model selection and parameter passing
  - Document how to call Haiku with system prompts

* [ ] **Research ace-nav protocol registration**
  - Read ace-nav documentation for protocol registration
  - Understand .ace.example/ structure for protocols
  - Document how to register prompt:// protocol

* [ ] **Design enhancement system prompt**
  - Draft instructions for Haiku to clarify prompts
  - Include examples of good vs unclear prompts
  - Test system prompt effectiveness manually

* [ ] **Design cache key strategy**
  - Decide: content hash vs file path + mtime
  - Consider invalidation strategy
  - Document cache directory structure

### Execution Steps

#### Phase 1: Gem Foundation (2-3h)

- [ ] Create gem directory structure following ace-* patterns
  > TEST: Directory Structure Validation
  > Type: Structure Validation
  > Assert: All required directories exist with correct naming
  > Command: test -d ace-prompt/lib/ace/prompt/{atoms,molecules,organisms,models,commands}

- [ ] Create gemspec with dependencies
  > TEST: Dependency Verification
  > Type: Gem Configuration
  > Assert: Gemspec loads and all dependencies resolve
  > Command: cd ace-prompt && bundle install

- [ ] Create .ace.example/prompt/config.yml with all settings
- [ ] Create version.rb with 0.1.0
- [ ] Create main module lib/ace/prompt.rb with config accessor
- [ ] Create Thor CLI skeleton lib/ace/prompt/cli.rb
- [ ] Create executable exe/ace-prompt
- [ ] Create development binstub bin/ace-prompt
- [ ] Create test_helper.rb with ace-support-test-helpers
- [ ] Create Rakefile with test tasks
- [ ] Verify: `bundle exec rake test` runs (0 tests initially)

#### Phase 2: Protocol & Reading (3-4h)

- [ ] Implement ProtocolResolver atom (prompt:// → file path)
  > TEST: Protocol Resolution
  > Type: Unit Test
  > Assert: prompt://name resolves to .ace/prompts/name.md
  > Command: bundle exec rake test TEST=test/atoms/protocol_resolver_test.rb

- [ ] Implement FrontmatterParser atom (YAML parsing)
  > TEST: Frontmatter Parsing
  > Type: Unit Test
  > Assert: Parses valid YAML, handles errors gracefully
  > Command: bundle exec rake test TEST=test/atoms/frontmatter_parser_test.rb

- [ ] Implement PromptFinder molecule (hierarchical search)
  > TEST: Hierarchical Discovery
  > Type: Unit Test
  > Assert: Finds prompts in .ace/prompts/ before .cache/prompts/queue/
  > Command: bundle exec rake test TEST=test/molecules/prompt_finder_test.rb

- [ ] Implement PromptLoader molecule (load with metadata)
  > TEST: Prompt Loading
  > Type: Unit Test
  > Assert: Returns Prompt model with content and metadata
  > Command: bundle exec rake test TEST=test/molecules/prompt_loader_test.rb

- [ ] Implement Prompt and PromptMetadata models
- [ ] Implement ReadCommand (read, --raw, --no-enhance flags)
  > TEST: Read Command Integration
  > Type: Integration Test
  > Assert: ace-prompt read test-prompt outputs content
  > Command: bin/ace-prompt read test-prompt --raw

- [ ] Register prompt:// protocol in .ace.example/nav/protocols/wfi-sources/ace-prompt.yml
- [ ] Verify: ace-prompt read works for file paths and protocol

#### Phase 3: Context Preset Merging (3-4h)

- [ ] Implement PresetMerger atom (array concatenation)
  > TEST: Preset Merging Logic
  > Type: Unit Test
  > Assert: [a,b] + [c,d] = [a,b,c,d], handles empty arrays
  > Command: bundle exec rake test TEST=test/atoms/preset_merger_test.rb

- [ ] Implement ContextBuilder molecule (build ace-context call)
  > TEST: Context Command Building
  > Type: Unit Test
  > Assert: Builds correct ace-context CLI command with presets
  > Command: bundle exec rake test TEST=test/molecules/context_builder_test.rb

- [ ] Implement ContextAggregator organism (orchestrate ace-context)
  > TEST: Context Aggregation
  > Type: Integration Test
  > Assert: Calls ace-context with merged presets, returns content
  > Command: bundle exec rake test TEST=test/organisms/context_aggregator_test.rb

- [ ] Add --no-context flag to ReadCommand
- [ ] Verify: ace-prompt read with context presets prepends ace-context output

#### Phase 4: Enhancement Engine (4-6h)

- [ ] Implement ContentHasher atom (MD5 hashing)
  > TEST: Content Hashing
  > Type: Unit Test
  > Assert: Generates consistent MD5 hash for content
  > Command: bundle exec rake test TEST=test/atoms/content_hasher_test.rb

- [ ] Implement CacheManager molecule (read/write cache)
  > TEST: Cache Operations
  > Type: Unit Test
  > Assert: Writes and reads cached content correctly
  > Command: bundle exec rake test TEST=test/molecules/cache_manager_test.rb

- [ ] Create enhancement system prompt in .ace.example/prompts/enhance-system.md
- [ ] Implement PromptEnhancer organism (LLM integration)
  > TEST: Prompt Enhancement
  > Type: Integration Test (with VCR)
  > Assert: Enhances prompt via Haiku, caches result
  > Command: bundle exec rake test TEST=test/organisms/prompt_enhancer_test.rb

- [ ] Implement EnhanceCommand (explicit enhancement)
- [ ] Add --auto-enhance support to ReadCommand
- [ ] Implement PromptManager organism (full workflow orchestration)
- [ ] Verify: ace-prompt enhance produces different output than raw
- [ ] Performance test: Enhancement completes in <2 seconds

#### Phase 5: Additional Commands (2-3h)

- [ ] Implement ListCommand (discover and display prompts)
  > TEST: List Command
  > Type: Integration Test
  > Assert: Lists all prompts from search paths
  > Command: bin/ace-prompt list | grep -q "test-prompt"

- [ ] Implement InfoCommand (show metadata and context)
- [ ] Implement ConfigCommand (display current config)
- [ ] Add comprehensive error handling to all commands
- [ ] Verify: All CLI commands work with proper exit codes

#### Phase 6: Integration & Polish (3-4h)

- [ ] Create handbook/agents/enhance-prompt.ag.md
- [ ] Create handbook/workflow-instructions/prompt-enhancement.wf.md
- [ ] Create .claude/commands/ace-prompt.md for /ace:prompt integration
- [ ] Write comprehensive README.md with examples
- [ ] Write docs/usage.md with detailed usage guide
- [ ] Create example prompts in .ace.example/prompts/
- [ ] Run full test suite and ensure >90% coverage
  > TEST: Full Test Suite
  > Type: Comprehensive Test Run
  > Assert: All tests pass, coverage >90%
  > Command: bundle exec rake test && coverage report

- [ ] Run ace-lint on all markdown and YAML files
  > TEST: Documentation Quality
  > Type: Linting
  > Assert: No linting errors in docs
  > Command: ace-lint "ace-prompt/**/*.{md,yml}"

- [ ] Create CHANGELOG.md with initial 0.1.0 release notes
- [ ] Update task status: draft → pending

## Risk Analysis

### Technical Risks

**Risk: ace-context preset not found**
- Mitigation: Validate presets exist before calling ace-context
- Fallback: Skip missing presets with warning, continue with available

**Risk: LLM enhancement timeout/failure**
- Mitigation: Set reasonable timeout (30s), implement retry logic
- Fallback: Return original prompt with warning if enhancement fails

**Risk: Cache corruption**
- Mitigation: Validate cached content before returning
- Fallback: Re-enhance if cache invalid, log warning

**Risk: Protocol registration conflicts**
- Mitigation: Check if prompt:// already registered
- Fallback: Document conflict resolution in README

### Rollback Strategy

**Phase 1-2 failures:** Delete gem directory, no impact on other gems
**Phase 3 failures:** ace-context integration isolated, doesn't affect ace-context gem
**Phase 4 failures:** Enhancement optional, can disable in config
**Phase 5-6 failures:** Commands independent, can disable specific commands

### Performance Impact

**Positive impacts:**
- Cached enhancements reduce repeated LLM calls
- Preset merging eliminates manual context copying
- Fast Haiku model provides <2s enhancements

**Monitoring:**
- Log enhancement latency for performance tracking
- Monitor cache hit rate
- Track ace-context execution time

**Thresholds:**
- Enhancement: <2 seconds for typical prompts
- Cache retrieval: <100ms
- Protocol resolution: <10ms
