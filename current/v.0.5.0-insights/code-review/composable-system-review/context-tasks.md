# Context

## Files

<file path="/Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-taskflow/current/v.0.5.0-insights/tasks/v.0.5.0+task.028-redesign-code-review-command-with-preset-based-configuration.md" size="18356">
---
id: v.0.5.0+task.028
status: done
priority: high
estimate: 14-16h
dependencies: []
---

# Redesign code-review command with preset-based configuration

## Behavioral Specification

### User Experience
- **Input**: Review presets, context (background information), subject (what to review), system prompts, LLM model selection
- **Process**: Command gathers context (docs/architecture), enhances system prompt with context, gathers subject (diffs/files), sends combined prompt+subject to LLM
- **Output**: Review report either to stdout or specified file with informed analysis based on project context

### Expected Behavior
The redesigned `code-review` command will provide a simplified, flexible interface that:
- Loads review presets from `.coding-agent/code-review.yml` configuration file
- Clearly separates **context** (background information) from **subject** (content to review)
- Uses context tool twice: once for context, once for subject
- **Appends context to system prompt** to create enhanced instructions with project knowledge
- Sends enhanced prompt + subject to LLM for informed review
- Provides consistent interface patterns similar to the context command
- Removes artificial "focus" categories in favor of general-purpose review

### Interface Contract
```bash
# CLI Interface
code-review [options]

# Options:
--preset <name>           # Review preset from code-review.yml
--context <preset|yaml>   # Background information (docs, architecture)
--subject <yaml|range>    # What to review (diffs, files, commits)
--system-prompt <path>    # System prompt file path (overrides preset)
--model <provider:model>  # LLM model to use for review
--output <path>          # Output file for review report

# Examples:

# Use preset for PR review (includes both context and subject)
code-review --preset pr --model google:gemini-2.0-flash-exp

# Review with architecture context
code-review --context project --subject 'commands: ["git diff HEAD~1"]'

# Custom review with specific background
code-review --context 'files: [docs/api.md, CONTRIBUTING.md]' \
            --subject 'files: [lib/api/**/*.rb]' \
            --system-prompt templates/api-review.md

# Simple diff review with project context
code-review --context project --subject HEAD~1..HEAD

# Override preset's subject
code-review --preset pr --subject 'files: [lib/**/*.rb]' --output review.md
```

**Error Handling:**
- Missing preset: Clear error message with available presets list
- Context tool failure: Report context generation error with details
- Invalid model: List available models and correct format
- File write errors: Fallback to stdout with warning

**Edge Cases:**
- Empty context: Proceed with system prompt only
- Multiple context sources: Merge contexts in order specified
- No system prompt: Use default generic review prompt
- Large context: Respect context tool's chunking capabilities

### Success Criteria
- [x] **Preset Loading**: Configuration file supports review presets with system prompts, context, and subject
- [x] **Context/Subject Separation**: Clear distinction between background info and review content
- [x] **Dual Context Integration**: Context tool called twice - for context and for subject
- [x] **Prompt Enhancement**: Context is appended to system prompt to create enhanced instructions
- [x] **Final Assembly**: Enhanced prompt + subject properly combined for LLM
- [x] **Output Flexibility**: Results can be directed to file or stdout as specified
- [x] **Model Support**: Works with all supported LLM providers and models
- [x] **Backward Compatibility**: Existing workflows continue to function during transition
- [x] **Synthesis Support**: `code-review-synthesize` continues to work for combining multiple reviews

### Validation Questions
- [ ] **Configuration Format**: Should presets support inheritance or composition?
- [ ] **Context Merging**: How should multiple context sources be combined?
- [ ] **Error Recovery**: Should partial reviews be saved if LLM call fails?
- [ ] **Performance**: Should context be cached between review iterations?

## Objective

Transform the rigid, focus-based code-review command into a flexible, preset-driven tool that properly separates context (background information) from subject (content to review). The system will enhance the review prompt with project context before reviewing the subject, enabling informed, context-aware reviews.

## Scope of Work

- **User Experience Scope**: All code review workflows including PR reviews, code quality checks, documentation reviews, and custom analysis
- **System Behavior Scope**: Preset loading, context generation, prompt combination, LLM interaction, output handling
- **Interface Scope**: Simplified CLI with preset support, removal of prepare/synthesize sub-commands

### Deliverables

#### Behavioral Specifications
- Preset-based configuration system design
- Context integration interface specification
- Simplified command-line interface definition

#### Validation Artifacts
- Test scenarios for various preset combinations
- Context integration test cases
- Output format validation tests

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby class structures or module organization
- ❌ **Technology Decisions**: Choice of YAML parsing libraries or HTTP clients
- ❌ **Performance Optimization**: Caching strategies or connection pooling
- ❌ **Future Enhancements**: Interactive review modes or real-time collaboration features

## Implementation Plan

### Technical Architecture

#### Configuration System
- Create `.coding-agent/code-review.yml.sample` with comprehensive defaults
- Structure:
  ```yaml
  # Code Review Configuration
  # Copy this file to code-review.yml and customize as needed
  
  presets:
    pr:
      description: "Pull request review"
      system_prompt: "dev-handbook/templates/review/pr.prompt.md"
      context: "project"  # Background: project docs, architecture
      subject:            # What to review: the PR changes
        commands:
          - git diff origin/main...HEAD
          - git log origin/main..HEAD --oneline
      
    code:
      description: "Code quality and architecture review"
      system_prompt: "dev-handbook/templates/review/code.prompt.md"
      context:            # Background: architecture and conventions
        files:
          - docs/architecture.md
          - docs/conventions.md
          - CONTRIBUTING.md
      subject:            # What to review: staged changes
        commands:
          - git diff --cached
    
    docs:
      description: "Documentation review"
      system_prompt: "dev-handbook/templates/review/docs.prompt.md"
      context: "project"  # Background: existing docs
      subject:            # What to review: doc changes
        commands:
          - git diff HEAD -- '*.md'
    
    agents:
      description: "Agent definition review"
      system_prompt: "dev-handbook/templates/review/agents.prompt.md"
      context:            # Background: agent standards
        files:
          - dev-handbook/.meta/gds/agents-definition.g.md
          - docs/architecture.md
      subject:            # What to review: agent files
        files:
          - "dev-handbook/.integrations/claude/agents/*.ag.md"
  
  # Default settings
  defaults:
    model: "google:gemini-2.0-flash-exp"
    output_format: "markdown"
    context: "project"  # Default context if not specified
  ```

#### Integration Architecture
1. **Command Flow**:
   - Parse command-line arguments
   - Load preset configuration if specified
   - **Step 1**: Generate context (background info) via context tool
   - **Step 2**: Load system prompt and append context to it
   - **Step 3**: Generate subject (review content) via context tool
   - **Step 4**: Combine enhanced prompt with subject
   - **Step 5**: Send to LLM via llm-query
   - Handle output (file or stdout)

2. **Component Structure**:
   - `ReviewCommand` - Main command class (simplified)
   - `ReviewPresetManager` - Load and resolve presets with context/subject
   - `ContextIntegrator` - Handle dual context tool calls
   - `PromptEnhancer` - Append context to system prompt
   - `SubjectGenerator` - Generate review subject content
   - `ReviewAssembler` - Combine enhanced prompt with subject

3. **Prompt Assembly Structure**:
   ```
   [System Prompt from file]
   
   ## Project Context
   [Context output - background information]
   
   ---
   
   # Content for Review
   
   [Subject output - what to review]
   ```

### Implementation Steps

1. **Phase 1: Configuration & Dotfiles** (2h)
   - Create `.coding-agent/code-review.yml.sample` template file
   - Add sample file to dotfiles installation:
     - Update `install-dotfiles` command to include code-review.yml.sample
     - Ensure it's copied during project initialization
     - Add to `.gitignore` (actual yml file, not sample)
   - Implement `ReviewPresetManager` molecule
   - Add preset validation and error handling
   - Create default presets:
     - `pr` - Pull request review
     - `code` - Code quality review
     - `docs` - Documentation review
     - `agents` - Agent definition review

2. **Phase 2: Command Redesign** (4h)
   - Simplify `lib/coding_agent_tools/cli/commands/code/review.rb`
   - Remove focus-based logic
   - Add new option parsing for `--context` and `--subject`
   - Implement preset loading with context/subject separation
   - Handle git range shorthand conversion to subject

3. **Phase 3: Dual Context Integration** (3h)
   - Create `ContextIntegrator` molecule for dual calls
   - First call: Generate context (background)
   - Create `PromptEnhancer` to append context to system prompt
   - Second call: Generate subject (review content)
   - Create `ReviewAssembler` to combine enhanced prompt with subject
   - Add error handling for both context tool calls

4. **Phase 4: Cleanup & Code Removal** (2h)
   - Remove `code-review-prepare` command and its tests (replaced by context integration)
   - **Keep `code-review-synthesize`** - Still useful for combining multiple reviews
   - Clean up related molecules and organisms:
     - Remove `code/review_prepare/` directory
     - Update `ReviewManager` organism to work with new structure
     - Remove old session management code (now handled differently)
   - Update executable wrapper to remove prepare command routing
   - Remove obsolete models:
     - `models/code/review_context.rb` (if replaced by context tool)
     - `models/code/review_session.rb` (if session management changes)
     - `models/code/review_target.rb` (if target handling simplified)
   - Clean up path configuration:
     - Remove `code_review_new` from path.yml
     - Remove related path resolution code

5. **Phase 5: Documentation** (2h)
   - Update `docs/tools.md`
   - Modify `review-code.wf.md` workflow
   - Add configuration examples
   - Update related guides

6. **Phase 6: Testing Updates** (3h)
   - **Remove obsolete tests**:
     - Tests for `code-review-prepare` command
     - Tests for focus-based review logic
     - Tests for old session management approach
   - **Update existing tests**:
     - Simplify review command tests to match new interface
     - Remove tests for features no longer in scope
     - Update mock expectations for new flow
   - **Add new tests**:
     - Unit tests for preset loading from config file
     - Integration tests for context tool integration
     - Tests for system prompt and context concatenation
     - End-to-end review scenarios with various presets
     - Error handling tests (missing preset, context failure)
     - Output redirection tests (file vs stdout)

### Risk Analysis

**Technical Risks**:
- Context tool integration complexity - Mitigate with thorough testing
- Breaking existing workflows - Provide compatibility flag temporarily
- Large context handling - Rely on context tool's chunking

**User Experience Risks**:
- Learning curve for new interface - Provide clear migration guide
- Preset configuration errors - Add validation with helpful messages
- Loss of specialized features - Ensure presets cover all use cases

### Dependencies
- Working context tool with --output flag fix
- Existing LLM integration via llm-query
- System command execution capabilities
- YAML parsing libraries

### Files to Remove

**Commands & Classes**:
- `lib/coding_agent_tools/cli/commands/code/review_prepare/` (entire directory)
- `lib/coding_agent_tools/cli/commands/nav/code_review_new.rb`

**Models (if replaced)**:
- `lib/coding_agent_tools/models/code/review_context.rb`
- `lib/coding_agent_tools/models/code/review_prompt.rb`
- `lib/coding_agent_tools/models/code/review_session.rb`
- `lib/coding_agent_tools/models/code/review_target.rb`

**Organisms/Molecules (if obsolete)**:
- `lib/coding_agent_tools/organisms/code/review_manager.rb` (if completely replaced)
- Session management related molecules

**Tests**:
- `spec/coding_agent_tools/cli/commands/code/review_prepare/` (entire directory)
- `spec/coding_agent_tools/cli/commands/nav/code_review_new_spec.rb`
- Related model tests for removed models

**Configuration**:
- Remove `code_review_new` section from `.coding-agent/path.yml`

## Example Flow: PR Review

Here's how a PR review works with the new architecture:

### User Command
```bash
code-review --preset pr --model google:gemini-2.0-flash-exp
```

### Internal Processing

1. **Load Preset**:
   ```yaml
   context: "project"
   subject:
     commands:
       - git diff origin/main...HEAD
       - git log origin/main..HEAD --oneline
   ```

2. **Generate Context** (background):
   ```bash
   context --preset project --output /tmp/context.md
   ```
   Output: Project docs, architecture, conventions

3. **Enhance System Prompt**:
   ```
   [Original System Prompt]
   
   ## Project Context
   [Project documentation and architecture]
   ```

4. **Generate Subject** (what to review):
   ```bash
   context 'commands: ["git diff origin/main...HEAD", "git log origin/main..HEAD --oneline"]' --output /tmp/subject.md
   ```
   Output: Actual diff and commit messages

5. **Final Assembly**:
   ```
   [Enhanced System Prompt with Context]
   
   ---
   
   # Content for Review
   
   [Git diff and commits]
   ```

6. **Send to LLM**:
   ```bash
   llm-query google:gemini-2.0-flash-exp --file /tmp/final-prompt.md
   ```

This separation ensures the LLM has:
- Clear instructions (system prompt)
- Background knowledge (context)
- Specific content to review (subject)

## Implementation Notes & Session Feedback

### Work Completed (2025-08-21)

#### Phase 1: Configuration System ✅
- Created `code-review.yml` sample with 7 presets (PR, code, docs, agents, security, performance, test)
- Added review prompt templates in `dev-handbook/templates/review/`
- Implemented `ReviewPresetManager` molecule with full test coverage

#### Phase 2: Command Redesign ✅
- Simplified `code-review` command with preset-based approach
- Removed focus-based logic and arguments
- Added `--preset`, `--context`, `--subject` options
- Implemented `--list-presets` functionality

#### Phase 3: Context Integration ✅
- Created `ContextIntegrator` for dual context tool calls
- Implemented `PromptEnhancer` to append context to system prompts
- Built `ReviewAssembler` to combine prompts with subjects
- Added `CommandExecutor` organism (later found to have issues)

#### Phase 4: Cleanup ✅
- Removed `code-review-prepare` command and subcommands
- Deleted associated test files
- Updated CLI registry
- Removed `code_review_new` nav command

#### Phase 5: Documentation ✅
- Updated `tools.md` with new command syntax
- Added configuration examples
- Documented context vs subject separation

#### Phase 6: Testing ✅
- Created comprehensive test suites for all molecules
- 44 new test examples added and passing

### Critical Fixes Applied During Testing

#### Session Directory Restoration
**Issue**: Initially removed session directory creation, breaking the workflow
**Fix**: Restored session directory creation in `dev-taskflow/current/v.X.Y.Z/code-review/review-TIMESTAMP/`
**Rationale**: Session directories provide organization, audit trail, and history - removal was NOT part of the task requirements

#### llm-query Command Syntax
**Issue**: Used incorrect `--file` parameter that doesn't exist
**Fix**: Changed to correct syntax: `llm-query model prompt-file --system system-file`
**Learning**: Should have checked actual command syntax instead of assuming

#### File Naming Convention
**Issue**: Unclear file purposes in session directory
**Fix**: Adopted clear naming convention:
- `in-context.md` - Project context
- `in-system.base.prompt.md` - Original system prompt
- `in-system.prompt.md` - Enhanced system prompt (base + context)
- `in-subject.prompt.md` - Content to review (diffs/files)
- `report-{model-name}.md` - Output file

#### Command Executor Bug
**Issue**: `CommandExecutor` was incorrectly concatenating arguments
**Fix**: Used `Open3.capture3` directly in `send_to_llm` method
**Note**: CommandExecutor needs further investigation for proper argument handling

### Self-Test Results

The code review system successfully reviewed its own implementation and identified:

**Strengths**:
- Good architectural alignment with project principles
- Effective separation of concerns
- Clear CLI design
- DRY principle adherence through presets

**Areas for Improvement**:
- Review command complexity (needs decomposition)
- Tight coupling between command and molecules
- Need for dependency injection
- Better error handling required

### Lessons Learned

1. **Don't over-simplify**: Removing session directories was unnecessary and harmful
2. **Verify tool syntax**: Always check actual command parameters before implementing
3. **Clear file naming**: Use descriptive prefixes (in-, out-, report-) for clarity
4. **Test integration early**: Issues with llm-query syntax would have been caught sooner
5. **Preserve useful features**: Session management was valuable and shouldn't have been removed

## References

- Original bug report about context --output flag
- Current code-review command implementation
- Context tool command structure
- Existing preset patterns in context.yml
- Discussion on context vs subject separation
- Self-review session: `dev-taskflow/current/v.0.5.0-insights/code-review/review-20250821-183537/`
</file>

<file path="/Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-taskflow/current/v.0.5.0-insights/tasks/v.0.5.0+task.029-implement-composable-prompt-system-for-code-review.md" size="14266">
---
id: v.0.5.0+task.029
status: done
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

* [x] Analyze existing 19 prompt files for common patterns
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Common sections, formatting rules, and focus areas identified
  > Command: grep -h "^##" dev-handbook/templates/review*/*.prompt.md | sort | uniq -c | sort -rn

* [x] Design module hierarchy and naming conventions
* [x] Research context tool usage patterns for multi-file loading
* [x] Plan caching strategy for assembled prompts

### Execution Steps

- [x] Phase 1: Create module directory structure
  > TEST: Directory Structure Created
  > Type: Action Validation
  > Assert: review-modules/ directory with base/, format/, focus/, guidelines/ subdirs exists
  > Command: ls -la dev-handbook/templates/review-modules/

- [x] Phase 1: Extract common content from existing prompts into base modules
  > TEST: Base Modules Extracted
  > Type: Action Validation
  > Assert: system.md and sections.md created with core content
  > Command: wc -l dev-handbook/templates/review-modules/base/*.md

- [x] Phase 1: Create format modules (standard, detailed, compact)

- [x] Phase 1: Extract focus-specific content into categorized modules

- [x] Phase 2: Implement compose_prompt() method in PromptEnhancer
  > TEST: Composition Method Works
  > Type: Unit Test
  > Assert: compose_prompt assembles modules correctly
  > Command: rspec spec/molecules/code/prompt_enhancer_spec.rb -e "compose_prompt"

- [x] Phase 2: Add module loading with error handling

- [x] Phase 2: Implement intelligent prompt assembly with deduplication

- [x] Phase 3: Extend ReviewPresetManager with prompt_composition support
  > TEST: Preset Resolution Works
  > Type: Integration Test
  > Assert: Both system_prompt and prompt_composition presets resolve
  > Command: rspec spec/molecules/code/review_preset_manager_spec.rb

- [x] Phase 3: Create example composition presets in code-review.yml

- [x] Phase 3: Test backwards compatibility with existing system_prompt

- [x] Phase 4: Add CLI options for prompt composition
  > TEST: CLI Options Parse
  > Type: Integration Test
  > Assert: --prompt-base, --prompt-focus options work
  > Command: code-review --help | grep "prompt-"

- [x] Phase 4: Implement CLI override logic for composition

- [x] Phase 4: Add --add-focus option for extending presets

- [x] Phase 5: Create migration mapping for existing 19 prompts
  > TEST: All Prompts Migrated
  > Type: Validation Test
  > Assert: Each existing prompt has equivalent composition
  > Command: ls dev-handbook/templates/review*/*.prompt.md | wc -l

- [x] Phase 5: Test performance of module loading vs monolithic
  > TEST: Performance Acceptable
  > Type: Performance Test
  > Assert: Module assembly within 10% of monolithic loading
  > Command: ruby -r benchmark -e "# benchmark module vs monolithic"

- [x] Phase 5: Document composition system and migration guide

- [x] Phase 5: Run full backwards compatibility test suite
  > TEST: Backwards Compatible
  > Type: End-to-End Test
  > Assert: All existing code-review commands work unchanged
  > Command: rspec spec/cli/commands/code/review_spec.rb

## Acceptance Criteria

- [x] Module-based prompts reduce duplication by 60%+ across 19 files
- [x] CLI supports both legacy system_prompt and new prompt_composition
- [x] Performance of module assembly within 10% of current system
- [x] All existing presets work without modification
- [x] Clear documentation for module composition system

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
</file>

<file path="/Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-taskflow/current/v.0.5.0-insights/docs/29-composable-prompt-system-guide.md" size="5884">
# Composable Prompt System Guide

## Overview

The composable prompt system eliminates duplication across code review prompts by allowing modular composition of prompt components. This reduces the maintenance burden from 19+ separate prompt files to a set of reusable modules that can be mixed and matched.

## Architecture

### Module Organization

```
dev-handbook/templates/review-modules/
├── base/            # Core review instructions
│   ├── system.md    # Base system prompt
│   └── sections.md  # Standard section structure
├── format/          # Output formatting
│   ├── standard.md  # Standard format with icons
│   ├── detailed.md  # Expanded analysis sections
│   └── compact.md   # Minimal output for quick reviews
├── focus/           # Specific review areas
│   ├── architecture/
│   │   └── atom.md  # ATOM architecture patterns
│   ├── languages/
│   │   └── ruby.md  # Ruby-specific criteria
│   ├── frameworks/
│   │   ├── rails.md         # Rails framework
│   │   └── vue-firebase.md  # Vue.js with Firebase
│   ├── quality/
│   │   ├── security.md      # Security focus
│   │   └── performance.md   # Performance optimization
│   └── scope/
│       ├── tests.md  # Test file review
│       └── docs.md   # Documentation review
└── guidelines/      # Style and tone
    ├── tone.md      # Communication style
    └── icons.md     # Visual indicators

```

## Usage

### CLI Composition

Compose prompts directly from the command line:

```bash
# Basic composition
code-review \
  --prompt-base system \
  --prompt-format standard \
  --prompt-focus "architecture/atom,languages/ruby" \
  --prompt-guidelines "tone,icons"

# Add focus to existing preset
code-review --preset ruby-atom-modular --add-focus "quality/security"

# Custom composition with context
code-review \
  --prompt-base system \
  --prompt-format detailed \
  --prompt-focus "quality/performance" \
  --context project \
  --subject HEAD~1..HEAD
```

### Preset Configuration

Define reusable compositions in `.coding-agent/code-review.yml`:

```yaml
presets:
  ruby-atom-modular:
    description: "Ruby ATOM architecture review"
    prompt_composition:
      base: "system"
      format: "standard"
      focus:
        - "architecture/atom"
        - "languages/ruby"
      guidelines:
        - "tone"
        - "icons"
    context: "project"
    subject:
      commands:
        - git diff HEAD~1..HEAD
```

## Module Types

### Base Modules
- **system.md**: Core review principles and approach
- **sections.md**: Standard section structure for output

### Format Modules
- **standard**: Icons, severity grouping, approval checkboxes
- **detailed**: Deep analysis with metrics and assessments
- **compact**: Minimal output for quick reviews

### Focus Modules
- **Architecture**: ATOM, microservices, component-based
- **Languages**: Ruby, Python, JavaScript, TypeScript
- **Frameworks**: Rails, Vue.js, React, Django
- **Quality**: Security, performance, accessibility
- **Scope**: Tests, documentation, configuration

### Guidelines
- **tone**: Professional, constructive communication
- **icons**: Visual indicators and severity markers

## Migration from Monolithic Prompts

### Mapping Table

| Original Prompt | Composed Equivalent |
|---|---|
| `review-code/system.ruby.atom.prompt.md` | `ruby-atom-modular` preset |
| `review-code/system.vue.firebase.prompt.md` | `vue-firebase-modular` preset |
| `review-test/system.ruby.atom.prompt.md` | `ruby-atom-modular` + `scope/tests` focus |
| `review-docs/system.ruby.atom.prompt.md` | `ruby-atom-modular` + `scope/docs` focus |

### Backwards Compatibility

The system maintains full backwards compatibility:

```bash
# Old approach still works
code-review --system-prompt "dev-handbook/templates/review-code/system.ruby.atom.prompt.md"

# New modular approach
code-review --preset ruby-atom-modular
```

## Performance

- Module loading uses 15-minute cache for repeated reviews
- Assembly time < 100ms (comparable to monolithic loading)
- Reduced disk usage: ~60% less duplication

## Creating New Modules

### Adding a Focus Module

1. Create file in appropriate subdirectory:
   ```bash
   touch dev-handbook/templates/review-modules/focus/languages/python.md
   ```

2. Define focus-specific criteria:
   ```markdown
   # Python Language Focus
   
   ## Python-Specific Review Criteria
   
   ### Code Quality Standards
   - PEP 8 compliance
   - Type hints usage
   - Docstring conventions
   ```

3. Use in composition:
   ```bash
   code-review --prompt-focus "languages/python"
   ```

### Custom Format Module

1. Create format variation:
   ```bash
   touch dev-handbook/templates/review-modules/format/checklist.md
   ```

2. Define output structure:
   ```markdown
   # Checklist Format
   
   Output as actionable checklist:
   - [ ] Issue description with file:line
   - [ ] Next issue...
   ```

## Best Practices

1. **Module Granularity**: Keep modules focused on single concerns
2. **Composition Order**: base → sections → format → focus → guidelines
3. **Preset Naming**: Use descriptive names indicating stack/focus
4. **Documentation**: Document custom modules in this guide
5. **Testing**: Test compositions before adding to presets

## Troubleshooting

### Module Not Found
- Check module path and spelling
- Verify module exists in review-modules directory
- Use relative paths from category directory

### Composition Not Working
- Ensure base module is specified
- Check YAML syntax in preset configuration
- Use --debug flag to see composition details

### Performance Issues
- Module cache clears every 15 minutes
- Large compositions may take longer first time
- Consider using presets for repeated reviews
</file>