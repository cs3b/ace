---
id: v.0.5.0+task.028
status: pending
priority: high
estimate: 12-14h
dependencies: []
---

# Redesign code-review command with preset-based configuration

## Behavioral Specification

### User Experience
- **Input**: Review presets, context configurations (presets or inline YAML), system prompts, target files/commits, LLM model selection
- **Process**: Command gathers context using context tool, combines with system prompt, sends to specified LLM for review
- **Output**: Review report either to stdout or specified file with detailed analysis

### Expected Behavior
The redesigned `code-review` command will provide a simplified, flexible interface that:
- Loads review presets from `.coding-agent/code-review.yml` configuration file
- Integrates seamlessly with the context tool for content gathering (files, git diffs, command outputs)
- Supports flexible combinations of presets with inline overrides
- Concatenates system prompt with generated context before sending to LLM
- Provides consistent interface patterns similar to the context command
- Removes artificial "focus" categories in favor of general-purpose review

### Interface Contract
```bash
# CLI Interface
code-review [target] [options]

# Options:
--preset <name>           # Review preset from code-review.yml
--context <preset|yaml>   # Context preset name or inline YAML config
--system-prompt <path>    # System prompt file path (overrides preset)
--model <provider:model>  # LLM model to use for review
--output <path>          # Output file for review report

# Examples:

# Use preset for PR review
code-review --preset pr --model google:gemini-2.0-flash-exp

# Custom context with preset system prompt
code-review --preset code --context 'commands: ["git diff HEAD~1"]'

# Fully custom review
code-review --context 'files: [lib/**/*.rb]' --system-prompt templates/review.md

# Mix preset with additional context
code-review --preset agents --context 'files: [*.ag.md]' --output review.md

# Simple git diff review (target as git range)
code-review HEAD~1..HEAD --system-prompt templates/code.prompt.md
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
- [ ] **Preset Loading**: Configuration file supports review presets with system prompts and context configs
- [ ] **Context Integration**: Context tool is called internally and output is captured correctly
- [ ] **Prompt Combination**: System prompt and context are properly concatenated
- [ ] **Output Flexibility**: Results can be directed to file or stdout as specified
- [ ] **Model Support**: Works with all supported LLM providers and models
- [ ] **Backward Compatibility**: Existing workflows continue to function during transition
- [ ] **Synthesis Support**: `code-review-synthesize` continues to work for combining multiple reviews

### Validation Questions
- [ ] **Configuration Format**: Should presets support inheritance or composition?
- [ ] **Context Merging**: How should multiple context sources be combined?
- [ ] **Error Recovery**: Should partial reviews be saved if LLM call fails?
- [ ] **Performance**: Should context be cached between review iterations?

## Objective

Transform the rigid, focus-based code-review command into a flexible, preset-driven tool that leverages the context system for content gathering. This creates a general-purpose review tool that can adapt to any review scenario without artificial limitations.

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
      context_config: |
        commands:
          - git diff origin/main...HEAD
          - git log origin/main..HEAD --oneline
      
    code:
      description: "Code quality and architecture review"
      system_prompt: "dev-handbook/templates/review/code.prompt.md"
      context_config: |
        commands:
          - git diff --cached
        files:
          - docs/architecture.md
    
    docs:
      description: "Documentation review"
      system_prompt: "dev-handbook/templates/review/docs.prompt.md"
      context_preset: "project"  # Use existing context preset
    
    agents:
      description: "Agent definition review"
      system_prompt: "dev-handbook/templates/review/agents.prompt.md"
      context_preset: "agents"  # Reference existing context preset
  
  # Default settings
  defaults:
    model: "google:gemini-2.0-flash-exp"
    output_format: "markdown"
  ```

#### Integration Architecture
1. **Command Flow**:
   - Parse command-line arguments
   - Load preset configuration if specified
   - Prepare context configuration (preset or inline)
   - Call context tool via system command
   - Load system prompt file
   - Combine prompt + context
   - Send to LLM via llm-query
   - Handle output (file or stdout)

2. **Component Structure**:
   - `ReviewCommand` - Main command class (simplified)
   - `ReviewPresetManager` - Load and resolve presets
   - `ContextIntegrator` - Handle context tool integration
   - `PromptCombiner` - Merge system prompt with context

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

2. **Phase 2: Command Redesign** (3h)
   - Simplify `lib/coding_agent_tools/cli/commands/code/review.rb`
   - Remove focus-based logic
   - Add new option parsing
   - Implement preset loading

3. **Phase 3: Context Integration** (2h)
   - Create `ContextIntegrator` molecule
   - Implement system command execution
   - Handle context output capture
   - Add error handling for context failures

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

## References

- Original bug report about context --output flag
- Current code-review command implementation
- Context tool command structure
- Existing preset patterns in context.yml