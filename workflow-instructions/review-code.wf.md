# Universal Code Review Workflow Instruction

## Goal

Perform comprehensive code review on any target (git diffs, file patterns, or specific files) with configurable focus areas, automatic project context loading, and structured file-based output. This universal workflow creates organized session directories with input files, combined prompts, multiple LLM reports, and synthesized results.

## ⚠️ CRITICAL: AI Agent Instructions ⚠️

**FOR AI CODING AGENTS - READ THIS FIRST**

DO NOT manually read individual source files during code review execution. This workflow MUST be executed using the `code-review` command-line tool.

### What TO DO:
1. **First: Analyze the user's request** to determine proper command arguments:
   - FOCUS: `code`, `tests`, `docs`, or combinations like `"code tests"`
   - TARGET: Based on user request - `"src/**/*"`, `HEAD~5..HEAD`, `staged`, specific files, etc.
   - OPTIONS: `--context auto` (default), `--dry-run`, `--model`, etc.
2. **Second: Execute the constructed command**: `code-review FOCUS TARGET [OPTIONS]`
3. **Third: Let the tool handle all file reading and analysis**
4. **Fourth: Review the generated reports in the session directory**

### What NOT TO DO:
- ❌ Use Read tool on individual source files
- ❌ Use Glob tool to find files to read manually
- ❌ Load source code content into the session
- ❌ Manually implement the review steps described below

**The process steps below describe what the `code-review` tool does internally - they are NOT for manual execution by AI agents.**

## Prerequisites

- Access to `dev-handbook/templates/review-*/*.md` prompt templates
- LLM query tools available (`llm-query`)
- Git CLI available for diff operations
- Project documentation exists in `docs/` directory
- Write access to `dev-taskflow/current/` directory structure
- Multiple LLM provider access (Google Pro, Anthropic Opus)
- Understanding of session directory structure and file naming conventions

## Quick Start for AI Agents

**Step 1: Construct command based on user request**

Common patterns:
```bash
# Review entire src directory (with extended timeout for large codebases)
code-review code "src/**/*" --context auto --timeout 600

# Review recent changes
code-review code HEAD~5..HEAD --context auto

# Review staged changes
code-review code staged --context auto

# Combined code and test review (with extended timeout)
code-review "code tests" "src/**/*" --context auto --timeout 600

# Very large codebase review
code-review code "src/**/*" --context auto --timeout 900
```

**Step 2: Execute the constructed command** - this replaces all manual file reading and analysis.

## Command Structure

```
code-review FOCUS TARGET [OPTIONS]
```

### Parameters

- **FOCUS** (required): Review focus area(s) - space-separated for multiple
  - `code` - Code quality, architecture, security, performance
  - `tests` - Test coverage, quality, maintainability
  - `docs` - Documentation gaps, updates, cross-references
  - `"code tests"` - Combined review (use quotes for multiple)
  - `"code tests docs"` - Full review across all areas

- **TARGET** (required): What to review
  - `v.0.2.0..HEAD` - Git commit range
  - `HEAD~5..HEAD` - Recent commits
  - `'tests/**/*.rb'` - File patterns (use quotes for globs)
  - `lib/specific_file.rb` - Specific file
  - `staged` - Staged changes (`git diff --staged`)
  - `unstaged` - Unstaged changes (`git diff`)
  - `working` - All working directory changes (`git diff HEAD`)

### Options

- **--context=VALUE**: Project context control
  - `auto` (default) - Auto-load project context from `docs/`
  - `none` - Skip project context loading
  - `path/to/custom.md` - Load custom context file
- **--base-path=VALUE**: Base path for session storage (default: current release)
- **--dry-run**: Show what would be done without creating session
- **--session=VALUE**: Resume existing session by ID
- **--model=VALUE**: LLM model to use (e.g., `google:gemini-2.5-pro`)
- **--output=VALUE**: Output file for review report
- **--system-prompt=VALUE**: Custom system prompt file path (overrides focus-based selection)
- **--timeout=VALUE**: LLM query timeout in seconds
  - `600` (recommended) - For large codebases like entire `src/` directories
  - `300` (default) - For moderate content
  - `900` - For very large reviews or slow connections

## Project Context Loading

- Load workflow standards: `dev-handbook/.meta/gds/workflow-instructions-definition.g.md`
- Load project structure: `docs/blueprint.md`
- Load project vision: `docs/what-do-we-build.md`
- Load tools documentation: `docs/tools.md`
- Load review templates: `dev-handbook/templates/review-*/system.prompt.md`
- Load existing session patterns: `dev-taskflow/current/*/code_review/*/`

## High-Level Execution Plan

### For AI Agents: Two-Step Process
1. **Construct the appropriate command** based on user's request (see Quick Start section above)
2. **Execute the constructed command** and analyze the results

### Internal Tool Process (DO NOT EXECUTE MANUALLY)
The following steps are performed automatically by the `code-review` tool:

- [ ] Validate command parameters and options
- [ ] Determine review scope and requirements
- [ ] Check for existing sessions to resume
- [ ] Run `code-review` command with appropriate parameters
- [ ] Monitor execution progress and handle any errors
- [ ] Review generated reports and session artifacts
- [ ] Optionally synthesize multiple reports if needed

## Process Steps (Automated by code-review tool)

> **⚠️ AUTOMATED PROCESS WARNING**
> The steps below are performed automatically by the `code-review` tool.
> AI agents should NOT execute these manually.

### 1. Session Directory Creation

Create structured session directory using the `code-review-prepare` command:

```bash
# Create session directory with automatic naming and metadata
code-review-prepare session-dir --focus "${focus}" --target "${target}" --base-path "dev-taskflow/current/v.0.3.0-workflows"

# The command automatically:
# - Generates timestamp-based session name
# - Creates directory structure
# - Writes session metadata
# - Returns session directory path
```

**Command Output Example:**
```
Session directory created: dev-taskflow/current/v.0.3.0-workflows/code_review/code-HEAD~1..HEAD-20250107-143052
```

**Validation:**

- Session directory created successfully
- Session metadata file contains all parameters
- Directory structure follows established pattern
- Session ID available for resuming with `--session`

### 2. Parameter Validation

Validate the command parameters:

- **focus**: Must be one of `code`, `tests`, `docs`, or combination
- **target**: Must be valid git range, file pattern, or special keyword
- **context**: Must be `auto`, `none`, or valid file path

### 2. Project Context Loading

Use the `code-review-prepare project-context` command to handle context loading:

```bash
# Auto-load project context (default)
code-review-prepare project-context --context auto

# Skip context loading
code-review-prepare project-context --context none

# Load custom context file
code-review-prepare project-context --context path/to/custom.md
```

The command automatically:
- Loads appropriate files based on context mode
- Formats content for LLM consumption
- Saves to session directory as `project-context.md`
- Handles missing files gracefully

### 3. Target Content Resolution and File Creation

Use the `code-review-prepare project-target` command to extract and format target content:

```bash
# Extract target content based on type
code-review-prepare project-target --target "${target}"

# The command automatically:
# - Detects target type (git range, file pattern, or special keyword)
# - Extracts appropriate content
# - Formats as diff or XML based on content type
# - Generates metadata file
# - Saves to session directory
```

**Command Examples:**

```bash
# Git range → creates input.diff
code-review-prepare project-target --target "v.0.2.0..HEAD"

# File pattern → creates input.xml
code-review-prepare project-target --target "tests/**/*.rb"

# Special keywords → creates input.diff
code-review-prepare project-target --target "staged"
code-review-prepare project-target --target "unstaged"
code-review-prepare project-target --target "working"
```

**Validation:**

- Input file (input.diff or input.xml) created successfully
- Input metadata file contains target information
- Content properly formatted and readable
- File size and type automatically tracked

### 4. Review Template Selection

The `code-review` command automatically selects appropriate templates based on focus:

- **code**: Uses `dev-handbook/templates/review-code/system.prompt.md`
- **tests**: Uses `dev-handbook/templates/review-test/system.prompt.md`
- **docs**: Uses `dev-handbook/templates/review-docs/system.prompt.md`
- **combined**: Uses multiple templates and synthesizes results

Template selection is handled internally by the command based on the FOCUS parameter, but can be overridden using the `--system-prompt` option to specify a custom system prompt file.

### 5. Combined Prompt Construction

Use the `code-review-prepare prompt` command to build the complete review prompt:

```bash
# Build combined prompt with all components
code-review-prepare prompt \
  --focus "${focus}" \
  --target "${target}" \
  --context "${context:-auto}"

# The command automatically:
# - Combines project context (if loaded)
# - Includes target content (diff or files)
# - Adds focus-specific instructions
# - Generates YAML frontmatter
# - Saves as prompt.md in session directory
```

**Command Output:**
- Creates `prompt.md` with structured review prompt
- Includes all necessary context and content
- Ready for LLM processing

**Validation:**

- prompt.md file created with all sections
- System prompt template included correctly
- Project context loaded based on parameter
- Target content properly embedded
- Focus-specific instructions added

### 6. Multi-Model LLM Execution

The `code-review` command handles all LLM execution automatically:

```bash
# Execute complete code review
code-review "${focus}" "${target}" \
  --context "${context:-auto}" \
  --model "google:gemini-2.5-pro" \
  --output "${output_file}"

# Or use default multi-model execution
code-review "${focus}" "${target}"

# Resume a previous session
code-review "${focus}" "${target}" \
  --session "review-20240106-143052"

# Dry run to see what would be done
code-review "${focus}" "${target}" --dry-run
```

The command automatically:
- Executes with configured LLM providers
- Handles multi-model reviews when appropriate
- Creates structured report files
- Manages error handling and retries
- Generates execution summary

**Validation:**

- LLM execution completed successfully
- Report files contain structured review content
- Execution log captures any errors or issues
- Summary file provides execution overview

### 7. Session Finalization and Index Creation

The `code-review` command automatically creates session documentation:

**Generated Files:**
- `session.meta` - Session metadata and parameters
- `input.meta` - Target content metadata
- `input.diff` or `input.xml` - Extracted content
- `prompt.md` - Combined review prompt
- `cr-report-*.md` - Review reports (one per model)
- `execution.summary` - Execution results
- `README.md` - Session index with all file references

**Session Output Example:**
```
🎉 Code Review Session Completed: code-HEAD~1..HEAD-20240106-143052

📁 Session Directory: dev-taskflow/current/v.0.3.0-workflows/code_review/code-HEAD~1..HEAD-20240106-143052/
📋 Session Index: README.md

📊 Generated Reports:
   ✅ cr-report.md (final review)
   ✅ cr-report-gpro.md (if multi-model)
   ✅ cr-report-opus.md (if multi-model)

🔄 For multi-report synthesis: synthesize-reviews --session-dir <path>
```

**Validation:**

- Session documentation created automatically
- All review artifacts properly organized
- Session can be resumed with `--session` flag
- Ready for synthesis or further analysis

## Implementation Templates

### Focus Area Templates

Each template is used as a system prompt via the `--system` flag in the llm-query command,
keeping system instructions separate from the user prompt content.

#### Code Review Template Usage

```
System Prompt File: dev-handbook/templates/review-code/system.prompt.md
Usage: --system dev-handbook/templates/review-code/system.prompt.md
Focus: Ruby gem best practices, architecture compliance (see docs/architecture.md), security, performance
Output: Structured code review with 11 sections
```

#### Test Review Template Usage

```
System Prompt File: dev-handbook/templates/review-test/system.prompt.md
Usage: --system dev-handbook/templates/review-test/system.prompt.md
Focus: RSpec best practices, coverage, maintainability, performance
Output: Structured test review with 11 sections
```

#### Documentation Review Template Usage

```
System Prompt File: dev-handbook/templates/review-docs/system.prompt.md
Usage: --system dev-handbook/templates/review-docs/system.prompt.md
Focus: Documentation gaps, architecture updates, cross-references
Output: Structured documentation review with 11 sections
```

#### Combined Review Template Usage

```
System Prompt File: dev-handbook/templates/synthesize-reviews/system.prompt.md
Usage: --system dev-handbook/templates/synthesize-reviews/system.prompt.md
Focus: Meta-review comparing multiple review outputs
Output: Comparative analysis with scoring and recommendations
```

## For AI Coding Agents

### Recognition Patterns
If you are an AI agent asked to review code, you should:

1. **Recognize the request**: Code review tasks, source analysis, quality assessment
2. **Analyze user request**: Determine appropriate FOCUS, TARGET, and OPTIONS
3. **Construct command**: Build `code-review FOCUS TARGET [OPTIONS]`
4. **Execute the tool**: Run the constructed command
5. **Analyze results**: Review the generated session reports
6. **Never manually read**: Do not use Read, Glob, or similar tools on source files

### Success Criteria for AI Agents
- ✅ Analyzed user request to determine proper command arguments
- ✅ Constructed appropriate `code-review` command
- ✅ Executed the command successfully
- ✅ Session directory created with reports
- ✅ Analyzed generated reports
- ❌ Never loaded source code into session context

## Usage Examples

### Example 1: Code Review of Recent Changes

```bash
code-review code v.0.2.0..HEAD
```

- Reviews code changes from v.0.2.0 to HEAD
- Uses code review template
- Auto-loads project context
- Focuses on code quality, architecture, security

### Example 2: Test Review Without Context

```bash
code-review tests 'tests/**/*.rb' --context none
```

- Reviews all test files matching pattern
- Uses test review template
- Skips project context loading
- Focuses on test quality and coverage

### Example 3: Documentation Review with Custom Context

```bash
code-review docs v.0.2.0..HEAD --context custom-requirements.md
```

- Reviews documentation changes in commit range
- Uses documentation review template
- Loads custom context file
- Focuses on documentation completeness

### Example 4: Combined Review of Staged Changes

```bash
code-review "code tests docs" staged
```

- Reviews all staged changes
- Uses all three review templates + synthesizer
- Auto-loads project context
- Provides comprehensive review across all areas

### Example 5: Specific File Review

```bash
code-review code lib/coding_agent_tools/organisms/commit_message_generator.rb
```

- Reviews specific file
- Uses code review template
- Auto-loads project context
- Focuses on code quality for single file

### Example 6: Resume Previous Session

```bash
# Resume a previous review session
code-review code v.0.2.0..HEAD --session review-20240106-143052
```

- Resumes existing session with all context
- Continues from previous state
- Useful for iterative reviews

### Example 7: Dry Run Mode

```bash
# See what would be done without execution
code-review "code tests" HEAD~5..HEAD --dry-run
```

- Shows planned actions without creating session
- Validates parameters and configuration
- Useful for testing command setup

### Example 8: Custom Model Selection

```bash
# Use specific LLM model
code-review code staged --model anthropic:claude-3-opus-20240229
```

- Overrides default model selection
- Useful for specific review requirements
- Supports all configured LLM providers

### Example 9: Custom System Prompt

```bash
# Use custom system prompt instead of focus-based selection
code-review code HEAD~1..HEAD --system-prompt my-custom-review.md

# Custom prompt for specialized review type
code-review tests 'spec/**/*.rb' --system-prompt security-focused-review.md

# Combine with other options
code-review docs staged --system-prompt docs-style-guide.md --context none
```

- Overrides automatic system prompt selection based on focus
- Useful for specialized review types or custom review criteria
- Custom prompt file must exist and be readable
- Works with all focus types and other command options

## Success Criteria

- Command successfully parses all parameter combinations
- Session directory created with proper naming convention
- Target content correctly resolved and saved to input files (input.diff or input.xml)
- Combined prompt file (prompt.md) contains all required sections
- Appropriate review templates selected and embedded based on focus
- Project context loaded and included according to specification
- Multiple LLM queries execute successfully (Google Pro, Anthropic Opus)
- Individual report files (cr-report-*.md) generated with structured content
- Session index (README.md) provides complete file overview
- Execution summary documents successful runs and any errors
- Session directory ready for synthesis workflow integration
- All files follow established naming conventions and structure

## Error Handling

### Common Issues

**LLM API Failures:**

**Symptoms:**

- 401 Unauthorized responses from LLM providers
- "Invalid API key" or token expiration messages
- Authentication failures during review execution

**Recovery Steps:**

1. Verify API key environment variables are set:

   ```bash
   echo $GEMINI_API_KEY
   echo $ANTHROPIC_API_KEY
   ```

2. Test with `llm-models` command to verify connectivity
3. Retry with different model using `--model` option
4. Use `--dry-run` to test without API calls
5. Check session logs if using `--session`
6. Review error details in session execution.log

**Prevention:**

- Validate API keys before starting review session
- Check provider status pages for outages
- Have multiple LLM providers configured as fallbacks

**Rate Limiting and Quotas:**

**Symptoms:**

- API returns 429 (Too Many Requests)
- "Rate limit exceeded" or "Quota exhausted" messages
- Review execution slower than expected

**Recovery Steps:**

1. Check rate limit headers for reset timing
2. Implement exponential backoff:

   ```bash
   # Wait progressively longer between retries
   sleep 30 && retry_command
   sleep 60 && retry_command
   ```

3. Switch to alternative LLM provider if available
4. For non-urgent reviews, schedule for later execution
5. Continue with partial results if some providers succeed
6. Document rate limiting in execution summary

**Prevention:**

- Check API quotas before expensive operations
- Use lighter/faster models for exploratory reviews
- Space out large review operations

**Timeout Failures:**

**Symptoms:**

- LLM operations hang or timeout
- Large content processing failures
- Model context length exceeded errors

**Recovery Steps:**

1. Cancel hung operation if possible: `Ctrl+C`
2. Reduce content size by summarizing or chunking:

   ```bash
   # Split large diffs into smaller chunks
   git diff --stat v.0.2.0..HEAD
   ```

3. Increase timeout for legitimate large operations
4. Switch to higher-capacity model if available
5. Process content in smaller batches

**Prevention:**

- Estimate content size before processing: `git diff --stat`
- Set appropriate timeouts based on content size
- Use streaming responses for large operations when available

**Session Directory Creation Failures:**

**Symptoms:**

- Cannot create session directory
- Permission denied on filesystem operations
- Session timestamp conflicts

**Recovery Steps:**

1. Check current directory permissions: `pwd && ls -la`
2. Verify `dev-taskflow/current/` directory exists and is writable
3. Try alternative session directory location
4. Fix timestamp conflicts by adding random suffix
5. Ask user to check filesystem permissions

**Prevention:**

- Check write permissions before creating session directory
- Use absolute paths for session creation
- Verify dev-taskflow structure exists

**Git Operation Failures:**

**Symptoms:**

- `git diff` commands fail or return empty results
- Invalid git ranges or commit references
- Repository not in expected state

**Recovery Steps:**

1. Verify git repository status: `git status`
2. Check if commit ranges exist: `git log --oneline v.0.2.0..HEAD`
3. Use `code-review --help` to verify valid target formats
4. Test with simpler target first (e.g., `HEAD~1..HEAD`)
5. Use quotes for file patterns: `'**/*.rb'`

**Prevention:**

- Validate git ranges before processing: `git rev-parse`
- Check repository state: `git status`
- Verify file patterns match existing files

**Template Missing or Corrupted:**

**Symptoms:**

- Review template files not found in expected locations
- Template content appears corrupted or incomplete
- System prompt generation fails

**Recovery Steps:**

1. Check template file existence:

   ```bash
   ls -la dev-handbook/templates/review-*/system.prompt.md
   ```

2. Verify template content is readable and complete
3. Use fallback basic review format if templates unavailable
4. Regenerate prompt manually with project context
5. Ask user to check dev-handbook submodule status

**Prevention:**

- Verify template availability before review execution
- Check dev-handbook submodule is properly initialized
- Have fallback review formats available

**Invalid Parameters:**

**Symptoms:**

- Command parsing fails with unrecognized parameters
- Focus area not supported
- Target files or ranges don't exist
- Custom system prompt file not found or not readable

**Recovery Steps:**

1. Run `code-review --help` to see valid options
2. Use quotes for multiple focus areas: `"code tests"`
3. Verify file paths and git ranges exist
4. Check custom system prompt file exists: `ls -la my-custom-prompt.md`
5. Use `--dry-run` to validate parameters
6. Check example usage in help output

**Prevention:**

- Validate all parameters before execution
- Provide clear usage examples in error messages
- Use tab completion for file patterns where possible

**Large Content Handling:**

**Symptoms:**

- Review content exceeds LLM context limits
- Processing extremely large diffs or file sets
- Memory or performance issues

**Recovery Steps:**

1. Automatically truncate very large diffs with warning
2. Process large file sets in batches
3. Summarize content before sending to LLM
4. Use diff statistics instead of full content for overview
5. Ask user to narrow review scope

**Prevention:**

- Check content size before processing: `wc -l input.diff`
- Warn users about large review scope
- Optimize prompt length to stay within model limits

**Multi-Model Execution Failures:**

**Symptoms:**

- Only some LLM providers succeed
- Inconsistent results across models
- Partial session completion

**Recovery Steps:**

1. Continue with successful provider results
2. Document failed providers in execution.log
3. Retry failed providers with simplified prompts
4. Generate session summary with available results
5. Note limitations in final report

**Prevention:**

- Test all providers before starting multi-model execution
- Have clear fallback strategies for provider failures
- Set realistic expectations for multi-provider availability

### Error Recovery Framework

When errors occur during review execution:

1. **Immediate Assessment:**
   - Can the review continue with partial results?
   - Is this a temporary or permanent failure?
   - Are there alternative approaches available?

2. **Recovery Actions:**
   - Document error details in `execution.log`
   - Try alternative providers or simplified approaches
   - Continue with available results if possible
   - Update session summary with limitations

3. **User Communication:**
   - The `code-review` command provides clear error messages
   - Session logs contain detailed error information
   - Use `--session` to resume after fixing issues
   - Check execution.summary for partial results

## Context Window Management

### Overview

Large code reviews can exceed LLM context windows, requiring strategic content chunking and prioritization. This section provides comprehensive guidance for handling substantial diffs, file sets, and review content that may exceed token limits while maintaining review quality and context.

### LLM Context Limits

Different LLM providers have varying context window sizes:

- **Claude 3.5 Sonnet**: 200,000 tokens (~150,000 words)
- **GPT-4 Turbo**: 128,000 tokens (~96,000 words)
- **Gemini 2.5 Pro**: 2,000,000 tokens (~1,500,000 words)
- **Claude 3 Opus**: 200,000 tokens (~150,000 words)

### Content Size Estimation

Before processing, estimate content size to determine if chunking is needed:

```bash
# Check diff size
git diff --stat v.0.2.0..HEAD
git diff v.0.2.0..HEAD | wc -l

# Check file pattern size
find . -name "*.rb" -exec wc -l {} + | tail -1

# Check total content size in words
git diff v.0.2.0..HEAD | wc -w
```

### Chunking Indicators

Implement chunking when content exceeds these thresholds:

- **Diff content**: >10,000 lines or >50,000 words
- **File patterns**: >20 files or >100,000 lines total
- **Combined context**: Project context + review content >75% of model limit
- **Error indicators**: "Context length exceeded" or timeout errors

### File Prioritization Strategies

When chunking is required, prioritize files based on:

#### High Priority (Review First)
- **Core architecture files**: `lib/coding_agent_tools/*.rb`
- **Public APIs**: Classes with `public` methods, CLI commands
- **Security-critical**: Authentication, authorization, credential handling
- **Recent changes**: Files with most commits in target range
- **Complex logic**: Files with high cyclomatic complexity

#### Medium Priority
- **Business logic**: Organisms and molecules with core functionality
- **Configuration**: Settings, constants, initialization files
- **Integration points**: Files interfacing with external services
- **Test files**: Specs covering critical functionality

#### Low Priority (Review Last)
- **Documentation**: README, guides, inline comments
- **Utilities**: Helper functions, formatters, validators
- **Generated files**: Auto-generated code, build artifacts
- **Development tools**: Scripts, development-only code

### Chunking Approaches

#### 1. Logical Chunking (Preferred)

Split content by logical boundaries:

```bash
# Split by file type
git diff v.0.2.0..HEAD -- "*.rb" > ruby-changes.diff
git diff v.0.2.0..HEAD -- "*.md" > doc-changes.diff

# Split by directory
git diff v.0.2.0..HEAD -- "lib/" > lib-changes.diff
git diff v.0.2.0..HEAD -- "spec/" > spec-changes.diff

# Split by feature area
git diff v.0.2.0..HEAD -- "*client*" > client-changes.diff
git diff v.0.2.0..HEAD -- "*auth*" > auth-changes.diff
```

#### 2. Size-Based Chunking

Split large diffs by line count:

```bash
# Split diff into chunks of 5000 lines each
git diff v.0.2.0..HEAD > full.diff
split -l 5000 full.diff chunk-
```

#### 3. File-Based Chunking

Process files individually when patterns are too large:

```bash
# Get list of changed files
git diff --name-only v.0.2.0..HEAD | while read file; do
    echo "Processing: $file"
    git diff v.0.2.0..HEAD -- "$file" > "chunk-${file//\//-}.diff"
done
```

#### 4. Priority-Based Chunking

Create chunks based on file priority:

```bash
# High priority files first
git diff v.0.2.0..HEAD -- "lib/coding_agent_tools/*.rb" > high-priority.diff

# Medium priority files
git diff v.0.2.0..HEAD -- "lib/coding_agent_tools/*/*.rb" > medium-priority.diff

# Low priority files
git diff v.0.2.0..HEAD -- "spec/" "docs/" > low-priority.diff
```

### Context Overflow Error Handling

#### Detection Patterns

Common error messages indicating context overflow:

- "Context length exceeded"
- "Token limit exceeded"
- "Request too large"
- "Maximum context size"
- Timeout errors with large prompts

#### Recovery Strategies

**Immediate Actions:**
1. Save current session state
2. Reduce content size by 50%
3. Retry with simplified prompt
4. Document overflow in execution.log

**Content Reduction Techniques:**

```bash
# Reduce diff context lines
git diff -U1 v.0.2.0..HEAD  # Minimal context
git diff --stat v.0.2.0..HEAD  # Summary only

# Focus on specific file types
git diff v.0.2.0..HEAD -- "*.rb" | head -5000

# Remove whitespace-only changes
git diff -w v.0.2.0..HEAD
```

#### Automated Recovery

```bash
# Function to handle context overflow
handle_context_overflow() {
    local original_content="$1"
    local chunk_size=5000

    echo "⚠️  Context overflow detected. Implementing chunking strategy..."

    # Split content into manageable chunks
    echo "$original_content" | split -l $chunk_size - chunk-

    # Process each chunk separately
    for chunk in chunk-*; do
        echo "Processing chunk: $chunk"
        process_review_chunk "$chunk"
    done

    # Combine results
    combine_chunked_results
}
```

### Maintaining Context Across Chunks

#### Context Preservation Techniques

1. **Shared Context File**: Create reusable context for all chunks
2. **Progressive Context**: Build context incrementally across chunks
3. **Cross-Reference Links**: Link findings between chunks
4. **Summary Continuity**: Maintain running summary across chunks

#### Implementation Example

```bash
# Create shared context file
cat > shared-context.md <<EOF
# Shared Review Context

## Project Overview
$(cat docs/what-do-we-build.md)

## Architecture Summary
$(cat docs/architecture.md | head -50)

## Review Scope
Target: $target
Focus: $focus
Total Files: $(git diff --name-only $target | wc -l)

## Chunking Strategy
- Strategy: Logical chunking by directory
- Chunk Size: ~5000 lines per chunk
- Priority: High-priority files first
EOF

# Use shared context in each chunk review
for chunk in chunk-*; do
    cat shared-context.md "$chunk" | llm-query --focus "$focus"
done
```

### Performance Optimization

#### Parallel Processing

```bash
# Process multiple chunks in parallel
process_chunks_parallel() {
    local chunks=("$@")

    for chunk in "${chunks[@]}"; do
        {
            echo "Processing $chunk in background..."
            process_review_chunk "$chunk" > "result-$chunk.md"
        } &
    done

    # Wait for all background jobs
    wait

    echo "All chunks processed. Combining results..."
    combine_results
}
```

#### Caching Strategies

```bash
# Cache project context to avoid repeated loading
cache_project_context() {
    local cache_file="$SESSION_DIR/project-context.cache"

    if [[ ! -f "$cache_file" ]]; then
        echo "Building project context cache..."
        build_project_context > "$cache_file"
    fi

    echo "Using cached project context: $cache_file"
}
```

### Chunking Workflow Implementation

#### Step 1: Content Analysis

```bash
analyze_content_size() {
    local target="$1"
    local line_count word_count

    case "$target" in
        *..*)
            # Git range
            line_count=$(git diff "$target" | wc -l)
            word_count=$(git diff "$target" | wc -w)
            ;;
        *.*)
            # File pattern
            line_count=$(find . -name "$target" -exec wc -l {} + | tail -1 | awk '{print $1}')
            word_count=$(find . -name "$target" -exec wc -w {} + | tail -1 | awk '{print $1}')
            ;;
    esac

    echo "Content size: $line_count lines, $word_count words"

    # Determine if chunking is needed
    if [[ $line_count -gt 10000 ]] || [[ $word_count -gt 50000 ]]; then
        echo "CHUNKING_REQUIRED"
        return 1
    else
        echo "CHUNKING_NOT_REQUIRED"
        return 0
    fi
}
```

#### Step 2: Chunking Strategy Selection

```bash
select_chunking_strategy() {
    local target="$1"
    local content_size="$2"

    case "$target" in
        *..*)
            # Git ranges: use logical chunking by directory
            echo "LOGICAL_DIRECTORY"
            ;;
        *.*)
            # File patterns: use file-based chunking
            echo "FILE_BASED"
            ;;
        *)
            # Default: size-based chunking
            echo "SIZE_BASED"
            ;;
    esac
}
```

#### Step 3: Chunk Processing

```bash
process_with_chunking() {
    local target="$1"
    local focus="$2"
    local strategy="$3"

    echo "🔄 Processing with chunking strategy: $strategy"

    case "$strategy" in
        "LOGICAL_DIRECTORY")
            process_logical_chunks "$target" "$focus"
            ;;
        "FILE_BASED")
            process_file_chunks "$target" "$focus"
            ;;
        "SIZE_BASED")
            process_size_chunks "$target" "$focus"
            ;;
    esac

    # Combine and synthesize results
    synthesize_chunked_results
}
```

### Quality Assurance for Chunked Reviews

#### Completeness Checks

```bash
verify_chunk_completeness() {
    local original_files chunk_files

    # Get list of files in original diff
    original_files=$(git diff --name-only "$target" | sort)

    # Get list of files in all chunks
    chunk_files=$(cat chunk-*/files.list | sort | uniq)

    # Compare coverage
    if diff <(echo "$original_files") <(echo "$chunk_files") > /dev/null; then
        echo "✅ All files covered in chunks"
    else
        echo "❌ Some files missing from chunks"
        diff <(echo "$original_files") <(echo "$chunk_files")
    fi
}
```

#### Cross-Chunk Consistency

```bash
check_cross_chunk_consistency() {
    local reports=("$@")

    echo "Checking consistency across chunk reports..."

    # Extract key findings from each report
    for report in "${reports[@]}"; do
        grep -E "^## (Critical|High|Medium)" "$report" > "${report}.findings"
    done

    # Look for contradictory findings
    echo "Analyzing findings for consistency..."
    compare_findings *.findings
}
```

### Example Chunking Scenarios

#### Scenario 1: Large Feature Branch Review

```bash
# Target: Feature branch with 50+ files changed
@review-code code feature-branch..main

# Automatic chunking triggered
# Strategy: Logical chunking by component
# Chunks:
#   - Core logic changes (lib/coding_agent_tools/*.rb)
#   - CLI changes (lib/coding_agent_tools/cli/*.rb)
#   - Client changes (lib/coding_agent_tools/organisms/*client*.rb)
#   - Test changes (spec/)
```

#### Scenario 2: Documentation Review

```bash
# Target: All markdown files
@review-code docs **/*.md

# Chunking by document type:
#   - API documentation (docs/user/*.md)
#   - Development guides (docs/development/*.md)
#   - Architecture docs (docs/architecture.md, docs/blueprint.md)
```

#### Scenario 3: Refactoring Review

```bash
# Target: Large refactoring diff
@review-code code v.0.2.0..v.0.3.0

# Priority-based chunking:
#   - High priority: Public API changes
#   - Medium priority: Internal refactoring
#   - Low priority: Test updates and documentation
```

### Integration with Existing Error Handling

The context window management integrates seamlessly with existing error handling:

1. **Detection**: Context overflow errors caught by existing error handlers
2. **Recovery**: Automatic fallback to chunking strategies
3. **Logging**: Context management logged in execution.log
4. **User Communication**: Clear messaging about chunking decisions

### Performance Metrics

Track chunking performance for optimization:

```bash
# Log chunking metrics
log_chunking_metrics() {
    local session_dir="$1"

    cat >> "$session_dir/chunking.metrics" <<EOF
Chunking Session: $(date -Iseconds)
Original Size: $(cat "$session_dir/original.size")
Chunk Count: $(ls "$session_dir"/chunk-* | wc -l)
Processing Time: $(cat "$session_dir/processing.time")
Success Rate: $(calculate_success_rate "$session_dir")
EOF
}
```

## Integration Points

### Existing Tools

- Leverages `llm-query` for LLM communication
- Uses universal review templates in `dev-handbook/templates/review-*/`
- Integrates with project context loading patterns
- Compatible with existing Git workflow

### Claude Code Commands

- Designed to be called via thin Claude Code command wrapper
- Parameters passed through unchanged
- Results returned for display in Claude Code interface

### Non-Interactive Prompt Generation

- Use `code-review` command for batch processing
- Generates complete review sessions with embedded content
- Supports all focus areas and target types
- Session output ready for direct LLM processing or further analysis

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

This workflow provides a streamlined interface for all code review scenarios using the Ruby gem commands (`code-review` and `code-review-prepare`). The new commands simplify the review process while maintaining all the power and flexibility of the original workflow, with added benefits of:

- Automatic session management and resumption
- Built-in error handling and recovery
- Simplified command interface
- Consistent output structure
- Easy integration with other tools
