---
id: v.0.5.0+task.029
status: pending
priority: high
estimate: 24h
dependencies: [v.0.5.0+task.028]
---

# Implement composable prompt system for code review

## Behavioral Specification

### User Experience
- **Input**: Users configure review prompts via YAML with composable modules (base prompt, report format, focus areas, guidelines) or use CLI options to compose on-the-fly
- **Process**: System assembles complete prompts by combining selected modules from organized directories, applying context tool for intelligent composition
- **Output**: Unified, context-aware prompt sent to LLM for code review with reduced duplication and increased maintainability

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

Users can compose custom review prompts by selecting and combining modular components:
- Select a base prompt template that defines the core review structure
- Choose report format (standard, detailed, compact) for output structure
- Add multiple focus modules (architecture patterns, languages, frameworks, quality aspects)
- Include guideline modules (tone, formatting, icons) for consistent styling
- System automatically assembles these into a coherent prompt using intelligent merging
- Support both preset-based configuration and ad-hoc CLI composition
- Maintain full backwards compatibility with existing monolithic prompt files

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# CLI Interface
# Use composed preset
code-review --preset ruby-atom-full

# Custom composition via CLI
code-review \
  --prompt-base review-base/system.prompt.md \
  --prompt-focus "architecture/atom.md,languages/ruby.md" \
  --prompt-report detailed

# Add focus to existing preset
code-review --preset pr --add-focus "quality/security.md"

# Legacy monolithic prompt (backwards compatible)
code-review --system-prompt "review-code/system.ruby.atom.prompt.md"
```

**Error Handling:**
- Missing module file: Clear error message with available modules list
- Invalid composition syntax: Show correct format examples
- Conflicting configurations: Precedence rules (CLI > preset > default)

**Edge Cases:**
- Empty composition: Falls back to default base prompt
- Duplicate modules: Automatically deduplicated
- Mixed legacy and composition: Legacy takes precedence for safety

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Modular Composition**: Users can compose prompts from modular components via YAML configuration
- [ ] **CLI Flexibility**: Command-line options allow on-the-fly prompt composition
- [ ] **Backwards Compatible**: Existing system_prompt approach continues working unchanged
- [ ] **Duplication Reduced**: All 19 existing prompts expressible as compositions with 60%+ less duplication
- [ ] **Performance Maintained**: Module loading and assembly within 10% of current performance

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [x] **Module Organization**: Should modules be organized by type (base/format/focus) or by domain (ruby/vue/security)?
  - Answer: By type for better discoverability and composition
- [x] **Composition Order**: Does module order matter for assembly?
  - Answer: Yes, base -> format -> focus -> guidelines
- [x] **Cache Strategy**: Should assembled prompts be cached for performance?
  - Answer: Yes, with 15-minute TTL
- [ ] **Migration Path**: Should we auto-migrate existing prompts or maintain both?
  - Pending: Maintain both initially, gradual migration

## Objective

Eliminate the 60-80% duplication across 19+ code review prompt files by creating a composable module system that allows mixing and matching prompt components while maintaining full backwards compatibility with existing monolithic prompts.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Configuration-based and CLI-based prompt composition with clear error messages
- **System Behavior Scope**: Module loading, intelligent assembly, caching, backwards compatibility
- **Interface Scope**: Enhanced code-review CLI options, YAML preset configuration, module directory structure

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- Composable prompt configuration format
- Module assembly behavior documentation
- CLI interface specification for composition

#### Validation Artifacts
- Backwards compatibility test suite
- Performance benchmarks vs current system
- Module composition validation tests

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Breaking Changes**: Any changes that break existing system_prompt usage
- ❌ **Prompt Content Changes**: Modifying the actual review criteria or guidelines
- ❌ **Auto-Migration**: Automatic conversion of existing prompts (manual migration only)
- ❌ **Dynamic Module Loading**: Runtime module discovery or hot-reloading

## References

- Current implementation: dev-tools/lib/coding_agent_tools/cli/commands/code/review.rb
- Existing prompts: dev-handbook/templates/review*/*.prompt.md (19 files)
- Related task: v.0.5.0+task.028 (code-review preset system)

---

# IMPLEMENTATION PLAN

## 0. Directory Audit ✅

_Command run:_

```bash
find dev-handbook/templates -name "*.prompt.md" -type f | head -20
```

_Result excerpt:_

```
dev-handbook/templates/idea-manager/system.prompt.md
dev-handbook/templates/release-reflections/synthsize.system.prompt.md
dev-handbook/templates/review/agents.prompt.md
dev-handbook/templates/review/code.prompt.md
dev-handbook/templates/review/docs.prompt.md
dev-handbook/templates/review/performance.prompt.md
dev-handbook/templates/review/pr.prompt.md
dev-handbook/templates/review/security.prompt.md
dev-handbook/templates/review/test.prompt.md
dev-handbook/templates/review-code/system.prompt.rails.md
dev-handbook/templates/review-code/system.ruby.atom.prompt.md
dev-handbook/templates/review-code/system.vue.firebase.prompt.md
dev-handbook/templates/review-docs/system.cc.agent.prompt.md
dev-handbook/templates/review-docs/system.ruby.atom.prompt.md
dev-handbook/templates/review-docs/system.vue.firebase.prompt.md
dev-handbook/templates/review-synthesizer/system.prompt.md
dev-handbook/templates/review-test/system.prompt.rails.md
dev-handbook/templates/review-test/system.ruby.atom.prompt.md
dev-handbook/templates/review-test/system.vue.firebase.prompt.md
```

## Technical Approach

### Architecture Pattern
- Modular composition pattern with lazy loading
- Directory-based module organization for discoverability
- Context tool integration for multi-file assembly
- Cache layer for assembled prompt performance

### Technology Stack
- Ruby (existing codebase language)
- YAML for configuration (existing pattern)
- Markdown for prompt modules (existing format)
- Context tool for module gathering (existing integration)

### Implementation Strategy
- Phase 1: Create module directory structure and extract common content
- Phase 2: Build composition engine with module loading
- Phase 3: Integrate with ReviewPresetManager and configuration
- Phase 4: Add CLI options for composition control
- Phase 5: Migrate existing prompts and test compatibility

## File Modifications

### Create
- dev-handbook/templates/review-modules/base/system.md
  - Purpose: Core review instruction template
  - Key components: Role definition, placeholder sections
  - Dependencies: None (base module)

- dev-handbook/templates/review-modules/base/sections.md
  - Purpose: Standard section structure
  - Key components: Common review sections
  - Dependencies: base/system.md

- dev-handbook/templates/review-modules/format/*.md (3 files)
  - Purpose: Output formatting rules
  - Key components: standard.md, detailed.md, compact.md
  - Dependencies: Formatting guidelines

- dev-handbook/templates/review-modules/focus/*/*.md (15+ files)
  - Purpose: Specific review focus areas
  - Key components: architecture/, languages/, quality/, scope/ subdirs
  - Dependencies: Base modules

- dev-handbook/templates/review-modules/guidelines/*.md (3 files)
  - Purpose: Style and tone guidelines
  - Key components: tone.md, icons.md, approval.md
  - Dependencies: None

### Modify
- dev-tools/lib/coding_agent_tools/molecules/code/prompt_enhancer.rb
  - Changes: Add compose_prompt() method for module assembly
  - Impact: Enables modular prompt composition
  - Integration points: ReviewPresetManager, ContextIntegrator

- dev-tools/lib/coding_agent_tools/molecules/code/review_preset_manager.rb
  - Changes: Add prompt_composition support alongside system_prompt
  - Impact: Backwards compatible preset resolution
  - Integration points: Review command, configuration loading

- dev-tools/lib/coding_agent_tools/cli/commands/code/review.rb
  - Changes: Add composition CLI options (--prompt-base, --prompt-focus, etc.)
  - Impact: User-facing composition interface
  - Integration points: Option parsing, preset override logic

- dev-handbook/.meta/tpl/dotfiles/code-review.yml
  - Changes: Add example prompt_composition configurations
  - Impact: User configuration examples
  - Integration points: Preset definitions

### Delete
- None (maintaining backwards compatibility)

## Implementation Plan

### Planning Steps

* [ ] Analyze existing 19 prompt files for common patterns
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Common sections, formatting rules, and focus areas identified
  > Command: grep -h "^##" dev-handbook/templates/review*/*.prompt.md | sort | uniq -c | sort -rn

* [ ] Design module hierarchy and naming conventions
* [ ] Research context tool usage patterns for multi-file loading
* [ ] Plan caching strategy for assembled prompts

### Execution Steps

- [ ] Phase 1: Create module directory structure
  > TEST: Directory Structure Created
  > Type: Action Validation
  > Assert: review-modules/ directory with base/, format/, focus/, guidelines/ subdirs exists
  > Command: ls -la dev-handbook/templates/review-modules/

- [ ] Phase 1: Extract common content from existing prompts into base modules
  > TEST: Base Modules Extracted
  > Type: Action Validation
  > Assert: system.md and sections.md created with core content
  > Command: wc -l dev-handbook/templates/review-modules/base/*.md

- [ ] Phase 1: Create format modules (standard, detailed, compact)

- [ ] Phase 1: Extract focus-specific content into categorized modules

- [ ] Phase 2: Implement compose_prompt() method in PromptEnhancer
  > TEST: Composition Method Works
  > Type: Unit Test
  > Assert: compose_prompt assembles modules correctly
  > Command: rspec spec/molecules/code/prompt_enhancer_spec.rb -e "compose_prompt"

- [ ] Phase 2: Add module loading with error handling

- [ ] Phase 2: Implement intelligent prompt assembly with deduplication

- [ ] Phase 3: Extend ReviewPresetManager with prompt_composition support
  > TEST: Preset Resolution Works
  > Type: Integration Test
  > Assert: Both system_prompt and prompt_composition presets resolve
  > Command: rspec spec/molecules/code/review_preset_manager_spec.rb

- [ ] Phase 3: Create example composition presets in code-review.yml

- [ ] Phase 3: Test backwards compatibility with existing system_prompt

- [ ] Phase 4: Add CLI options for prompt composition
  > TEST: CLI Options Parse
  > Type: Integration Test
  > Assert: --prompt-base, --prompt-focus options work
  > Command: code-review --help | grep "prompt-"

- [ ] Phase 4: Implement CLI override logic for composition

- [ ] Phase 4: Add --add-focus option for extending presets

- [ ] Phase 5: Create migration mapping for existing 19 prompts
  > TEST: All Prompts Migrated
  > Type: Validation Test
  > Assert: Each existing prompt has equivalent composition
  > Command: ls dev-handbook/templates/review*/*.prompt.md | wc -l

- [ ] Phase 5: Test performance of module loading vs monolithic
  > TEST: Performance Acceptable
  > Type: Performance Test
  > Assert: Module assembly within 10% of monolithic loading
  > Command: ruby -r benchmark -e "# benchmark module vs monolithic"

- [ ] Phase 5: Document composition system and migration guide

- [ ] Phase 5: Run full backwards compatibility test suite
  > TEST: Backwards Compatible
  > Type: End-to-End Test
  > Assert: All existing code-review commands work unchanged
  > Command: rspec spec/cli/commands/code/review_spec.rb

## Acceptance Criteria

- [ ] Module-based prompts reduce duplication by 60%+ across 19 files
- [ ] CLI supports both legacy system_prompt and new prompt_composition
- [ ] Performance of module assembly within 10% of current system
- [ ] All existing presets work without modification
- [ ] Clear documentation for module composition system

## Risk Assessment

### Technical Risks
- **Risk:** Module loading performance impact
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Implement caching layer with TTL
  - **Rollback:** Revert to monolithic prompts

- **Risk:** Complex module dependencies
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Simple linear assembly order
  - **Rollback:** Simplify to base + additions model

### Integration Risks
- **Risk:** Breaking existing workflows
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Full backwards compatibility, extensive testing
  - **Monitoring:** Error tracking on system_prompt vs prompt_composition

### Performance Risks
- **Risk:** Multiple file reads slow down review
  - **Mitigation:** Cache assembled prompts for 15 minutes
  - **Monitoring:** Track assembly time metrics
  - **Thresholds:** < 100ms assembly time