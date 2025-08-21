---
id: v.0.5.0+task.028
status: pending
priority: high
estimate: 8-12h
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
- Create `.coding-agent/code-review.yml` for preset definitions
- Structure:
  ```yaml
  presets:
    pr:
      description: "Pull request review"
      system_prompt: "templates/review/pr.prompt.md"
      context_config: |
        commands:
          - git diff origin/main...HEAD
          - git log origin/main..HEAD --oneline
    
    agents:
      description: "Agent definition review"
      system_prompt: "templates/review/agents.prompt.md"
      context_preset: "agents"  # Reference existing context preset
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

1. **Phase 1: Configuration** (2h)
   - Create `.coding-agent/code-review.yml` template
   - Implement `ReviewPresetManager` molecule
   - Add preset validation and error handling

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

4. **Phase 4: Cleanup** (1h)
   - Remove `code-review-prepare` command
   - Remove `code-review-synthesize` command
   - Clean up related molecules and organisms
   - Update executable wrapper

5. **Phase 5: Documentation** (2h)
   - Update `docs/tools.md`
   - Modify `review-code.wf.md` workflow
   - Add configuration examples
   - Update related guides

6. **Phase 6: Testing** (2h)
   - Unit tests for preset loading
   - Integration tests for context tool
   - End-to-end review scenarios
   - Backward compatibility tests

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

## References

- Original bug report about context --output flag
- Current code-review command implementation
- Context tool command structure
- Existing preset patterns in context.yml