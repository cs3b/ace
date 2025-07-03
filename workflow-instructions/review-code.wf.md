# Universal Code Review Workflow Instruction

## Goal

Perform comprehensive code review on any target (git diffs, file patterns, or specific files) with configurable focus areas and automatic project context loading. This universal workflow replaces multiple specialized review tools with a single, flexible command.

## Prerequisites

- Access to `dev-handbook/templates/review-*/*.md` prompt templates
- LLM query tools available (`dev-tools/exe/llm-query`)
- Git CLI available for diff operations
- Project documentation exists in `docs/` directory

## Command Structure

```
@review-code [focus] [target] [context]
```

### Parameters

- **focus** (required): Review focus area(s)
  - `code` - Code quality, architecture, security, performance
  - `tests` - Test coverage, quality, maintainability
  - `docs` - Documentation gaps, updates, cross-references
  - `code tests docs` - Combined review (synthesized output)

- **target** (required): What to review
  - `v.0.2.0..HEAD` - Git commit range
  - `HEAD~5..HEAD` - Recent commits
  - `tests/**/*.rb` - File patterns
  - `lib/specific_file.rb` - Specific file
  - `staged` - Staged changes (`git diff --staged`)
  - `unstaged` - Unstaged changes (`git diff`)
  - `working` - All working directory changes (`git diff HEAD`)

- **context** (optional): Project context control
  - `auto` (default) - Auto-load project context from `docs/`
  - `none` - Skip project context loading
  - `path/to/custom.md` - Load custom context file

## High-Level Execution Plan

### Planning Steps

- [ ] Parse and validate command parameters
- [ ] Determine target content type (git diff vs file content)
- [ ] Select appropriate review templates based on focus
- [ ] Resolve project context loading strategy

### Execution Steps

- [ ] Load project context (if enabled)
- [ ] Extract target content (git diff or file content)
- [ ] Select and prepare review prompts
- [ ] Execute LLM review query
- [ ] Format and present results

## Process Steps

### 1. Parameter Validation

Validate the command parameters:

- **focus**: Must be one of `code`, `tests`, `docs`, or combination
- **target**: Must be valid git range, file pattern, or special keyword
- **context**: Must be `auto`, `none`, or valid file path

### 2. Project Context Loading

Based on context parameter:

- **auto** (default): Load project context from:

  ```bash
  # Load core project documents
  docs/what-do-we-build.md
  docs/architecture.md
  docs/blueprint.md
  ```

- **none**: Skip project context loading entirely

- **custom path**: Load specified context file instead of defaults

### 3. Target Content Resolution

Resolve target content based on type:

#### Git Ranges/Diffs

```bash
# For commit ranges
git diff [range] --no-color

# For staged changes
git diff --staged --no-color

# For unstaged changes
git diff --no-color

# For working directory changes
git diff HEAD --no-color
```

#### File Patterns

```bash
# Use find or glob to resolve patterns
find . -path "./target-pattern" -type f
```

#### Specific Files

```bash
# Read file content directly
cat path/to/file.rb
```

### 4. Review Template Selection

Select appropriate universal templates based on focus:

- **code**: Use `dev-handbook/templates/review-code/system.prompt.md` (universal template with combination instructions)
- **tests**: Use `dev-handbook/templates/review-test/system.prompt.md` (universal template with combination instructions)
- **docs**: Use `dev-handbook/templates/review-docs/system.prompt.md` (universal template with combination instructions)
- **combined**: Use primary template with combination instructions activated, then synthesize with `dev-handbook/templates/review-synthesizer/system.prompt.md`

### 5. LLM Query Construction

Build the complete prompt:

```
[SYSTEM PROMPT from template]

# Project Context
[PROJECT CONTEXT if enabled]

# Review Target
[TARGET CONTENT - diff or file content]

# Focus Areas
[FOCUS-SPECIFIC INSTRUCTIONS]
```

### 6. LLM Execution

Execute the review query:

```bash
# Use existing LLM tools
dev-tools/exe/llm-query [model] "[constructed-prompt]"
```

### 7. Result Processing

For combined reviews:

- Execute separate queries for each focus area
- Use synthesizer template to compare and rank results
- Present unified output

For single focus reviews:

- Present direct LLM output
- Apply consistent formatting

## Implementation Templates

### Focus Area Templates

#### Code Review Template Usage

```
System Prompt: dev-handbook/templates/review-code/system.prompt.md
Focus: Ruby gem best practices, ATOM architecture, security, performance
Output: Structured code review with 11 sections
```

#### Test Review Template Usage

```
System Prompt: dev-handbook/templates/review-test/system.prompt.md
Focus: RSpec best practices, coverage, maintainability, performance
Output: Structured test review with 11 sections
```

#### Documentation Review Template Usage

```
System Prompt: dev-handbook/templates/review-docs/system.prompt.md
Focus: Documentation gaps, architecture updates, cross-references
Output: Structured documentation review with 11 sections
```

#### Combined Review Template Usage

```
System Prompt: dev-handbook/templates/review-synthesizer/system.prompt.md
Focus: Meta-review comparing multiple review outputs
Output: Comparative analysis with scoring and recommendations
```

## Usage Examples

### Example 1: Code Review of Recent Changes

```
@review-code code v.0.2.0..HEAD
```

- Reviews code changes from v.0.2.0 to HEAD
- Uses code review template
- Auto-loads project context
- Focuses on code quality, architecture, security

### Example 2: Test Review Without Context

```
@review-code tests tests/**/*.rb context:none
```

- Reviews all test files matching pattern
- Uses test review template
- Skips project context loading
- Focuses on test quality and coverage

### Example 3: Documentation Review with Custom Context

```
@review-code docs v.0.2.0..HEAD context:custom-requirements.md
```

- Reviews documentation changes in commit range
- Uses documentation review template
- Loads custom context file
- Focuses on documentation completeness

### Example 4: Combined Review of Staged Changes

```
@review-code code tests docs staged
```

- Reviews all staged changes
- Uses all three review templates + synthesizer
- Auto-loads project context
- Provides comprehensive review across all areas

### Example 5: Specific File Review

```
@review-code code lib/coding_agent_tools/organisms/commit_message_generator.rb
```

- Reviews specific file
- Uses code review template
- Auto-loads project context
- Focuses on code quality for single file

### Example 6: Non-Interactive Prompt Generation

```bash
# Generate prompt file for batch processing
dev-tools/exe/generate-review-prompt --focus code --target v.0.2.0..HEAD --output code-review-prompt.md

# Process with LLM
dev-tools/exe/llm-query gemini "$(cat code-review-prompt.md)"
```

- Generates fully hydrated prompt with embedded content
- Suitable for batch processing or large diffs
- Avoids agent context limitations
- Ready for direct LLM processing

## Success Criteria

- Command successfully parses all parameter combinations
- Target content is correctly resolved (git diffs, file patterns, specific files)
- Appropriate review templates are selected based on focus
- Project context is loaded according to specification
- LLM queries execute successfully with well-formed prompts
- Results are presented in consistent, actionable format
- Combined reviews provide synthesized analysis when requested

## Error Handling

- **Invalid focus**: Display available focus options
- **Invalid target**: Validate git ranges, file patterns, file existence
- **Invalid context**: Verify context file exists or use defaults
- **Git command failures**: Provide clear error messages
- **LLM query failures**: Retry with simplified prompt or different model
- **Template missing**: Fallback to basic review format

## Integration Points

### Existing Tools

- Leverages `dev-tools/exe/llm-query` for LLM communication
- Uses universal review templates in `dev-handbook/templates/review-*/`
- Integrates with project context loading patterns
- Compatible with existing Git workflow

### Claude Code Commands

- Designed to be called via thin Claude Code command wrapper
- Parameters passed through unchanged
- Results returned for display in Claude Code interface

### Non-Interactive Prompt Generation

- Use `dev-tools/exe/generate-review-prompt` for batch processing
- Generates fully hydrated prompts with embedded content
- Supports all focus areas and target types
- Output ready for direct LLM processing without agent context limits

## Performance Considerations

- **Large diffs**: Automatically truncate or summarize very large diffs
- **Many files**: Process in batches for file patterns
- **Combined reviews**: Execute focus areas in parallel where possible
- **Context loading**: Cache project context to avoid repeated loading
- **LLM calls**: Optimize prompt length to stay within model limits

## Security Considerations

- **Sensitive content**: Warn when reviewing files that might contain secrets
- **External commands**: Validate all git commands and file paths
- **Context files**: Verify context files are within project boundaries
- **LLM queries**: Sanitize prompts to prevent injection attacks

---

This workflow provides a unified interface for all code review scenarios while maintaining the flexibility and power of specialized review tools. It serves as the implementation foundation for the `/review-code` Claude Code command.
