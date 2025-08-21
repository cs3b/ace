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

## References

- Original bug report about context --output flag
- Current code-review command implementation
- Context tool command structure
- Existing preset patterns in context.yml
- Discussion on context vs subject separation