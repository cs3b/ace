# Universal Code Review Workflow Instruction

## Goal

Perform comprehensive code review on any target (git diffs, file patterns, or specific files) with configurable focus areas, automatic project context loading, and structured file-based output. This universal workflow creates organized session directories with input files, combined prompts, multiple LLM reports, and synthesized results.

## Prerequisites

- Access to `dev-handbook/templates/review-*/*.md` prompt templates
- LLM query tools available (`dev-tools/exe/llm-query`)
- Git CLI available for diff operations
- Project documentation exists in `docs/` directory
- Write access to `dev-taskflow/current/` directory structure
- Multiple LLM provider access (Google Pro, Anthropic Opus)
- Understanding of session directory structure and file naming conventions

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

## Project Context Loading

- Load workflow standards: `dev-handbook/.meta/gds/workflow-instructions-definition.g.md`
- Load project structure: `docs/blueprint.md`
- Load project vision: `docs/what-do-we-build.md`
- Load review templates: `dev-handbook/templates/review-*/system.prompt.md`
- Load existing session patterns: `dev-taskflow/current/*/code_review/*/`

## High-Level Execution Plan

### Planning Steps

- [ ] Parse and validate command parameters
- [ ] Create structured session directory
- [ ] Determine target content type (git diff vs file content)
- [ ] Select appropriate review templates based on focus
- [ ] Resolve project context loading strategy

### Execution Steps

- [ ] Load project context (if enabled)
- [ ] Extract target content and save to input file
- [ ] Build combined prompt file with context + content + template
- [ ] Execute multiple LLM review queries (Google Pro, Anthropic Opus)
- [ ] Save individual model reports
- [ ] Generate session summary and file index

## Process Steps

### 1. Session Directory Creation

Create structured session directory for organized output:

```bash
# Generate session directory name
SESSION_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SESSION_NAME="${focus}-${target//\//-}-${SESSION_TIMESTAMP}"
SESSION_DIR="dev-taskflow/current/v.0.3.0-workflows/code_review/${SESSION_NAME}"

# Create session directory
mkdir -p "${SESSION_DIR}"

# Create session metadata
cat > "${SESSION_DIR}/session.meta" <<EOF
command: @review-code ${focus} ${target} ${context:-auto}
timestamp: $(date -Iseconds)
target: ${target}
focus: ${focus}
context: ${context:-auto}
EOF
```

**Validation:**

- Session directory created successfully
- Session metadata file contains all parameters
- Directory structure follows established pattern

### 2. Parameter Validation

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

### 3. Target Content Resolution and File Creation

Resolve target content and save to structured input files:

#### Git Ranges/Diffs → input.diff

```bash
# For commit ranges
git diff [range] --no-color > "${SESSION_DIR}/input.diff"

# For staged changes
git diff --staged --no-color > "${SESSION_DIR}/input.diff"

# For unstaged changes
git diff --no-color > "${SESSION_DIR}/input.diff"

# For working directory changes
git diff HEAD --no-color > "${SESSION_DIR}/input.diff"

# Add diff metadata
echo "# Diff Metadata" > "${SESSION_DIR}/input.meta"
echo "target: ${target}" >> "${SESSION_DIR}/input.meta"
echo "type: git_diff" >> "${SESSION_DIR}/input.meta"
echo "size: $(wc -l < "${SESSION_DIR}/input.diff") lines" >> "${SESSION_DIR}/input.meta"
```

#### File Patterns → input.xml

```bash
# Create XML container for multiple files
echo '<?xml version="1.0" encoding="UTF-8"?>' > "${SESSION_DIR}/input.xml"
echo '<documents>' >> "${SESSION_DIR}/input.xml"

# Use find or glob to resolve patterns and embed content
find . -path "./target-pattern" -type f | while read -r file; do
    echo "  <document path=\"$file\">" >> "${SESSION_DIR}/input.xml"
    echo "    <![CDATA[" >> "${SESSION_DIR}/input.xml"
    cat "$file" >> "${SESSION_DIR}/input.xml"
    echo "    ]]>" >> "${SESSION_DIR}/input.xml"
    echo "  </document>" >> "${SESSION_DIR}/input.xml"
done

echo '</documents>' >> "${SESSION_DIR}/input.xml"

# Add file pattern metadata
echo "target: ${target}" > "${SESSION_DIR}/input.meta"
echo "type: file_pattern" >> "${SESSION_DIR}/input.meta"
echo "files: $(find . -path "./target-pattern" -type f | wc -l)" >> "${SESSION_DIR}/input.meta"
```

#### Specific Files → input.xml

```bash
# Create XML container for single file
echo '<?xml version="1.0" encoding="UTF-8"?>' > "${SESSION_DIR}/input.xml"
echo '<documents>' >> "${SESSION_DIR}/input.xml"
echo "  <document path=\"${target}\">" >> "${SESSION_DIR}/input.xml"
echo "    <![CDATA[" >> "${SESSION_DIR}/input.xml"
cat "${target}" >> "${SESSION_DIR}/input.xml"
echo "    ]]>" >> "${SESSION_DIR}/input.xml"
echo "  </document>" >> "${SESSION_DIR}/input.xml"
echo '</documents>' >> "${SESSION_DIR}/input.xml"

# Add single file metadata
echo "target: ${target}" > "${SESSION_DIR}/input.meta"
echo "type: single_file" >> "${SESSION_DIR}/input.meta"
echo "size: $(wc -l < "${target}") lines" >> "${SESSION_DIR}/input.meta"
```

**Validation:**

- Input file (input.diff or input.xml) created successfully
- Input metadata file contains target information
- Content properly formatted and readable

### 4. Review Template Selection

Select appropriate universal templates based on focus:

- **code**: Use `dev-handbook/templates/review-code/system.prompt.md` (universal template with combination instructions)
- **tests**: Use `dev-handbook/templates/review-test/system.prompt.md` (universal template with combination instructions)
- **docs**: Use `dev-handbook/templates/review-docs/system.prompt.md` (universal template with combination instructions)
- **combined**: Use primary template with combination instructions activated, then synthesize with `dev-handbook/templates/review-synthesizer/system.prompt.md`

### 5. Combined Prompt Construction

Build the complete prompt and save to prompt.md:

```bash
# Build combined prompt file with YAML frontmatter
cat > "${SESSION_DIR}/prompt.md" <<EOF
---
generated: $(date -Iseconds)
target: ${target}
focus: ${focus}
context: ${context:-auto}
type: review-prompt
---

<review-prompt>
EOF

echo -e "\n  <project-context>" >> "${SESSION_DIR}/prompt.md"

# Add project context if enabled
if [[ "${context:-auto}" != "none" ]]; then
    if [[ "${context:-auto}" == "auto" ]]; then
        echo "    <document type=\"blueprint\">" >> "${SESSION_DIR}/prompt.md"
        echo "      <![CDATA[" >> "${SESSION_DIR}/prompt.md"
        cat "docs/blueprint.md" >> "${SESSION_DIR}/prompt.md"
        echo "      ]]>" >> "${SESSION_DIR}/prompt.md"
        echo "    </document>" >> "${SESSION_DIR}/prompt.md"
        echo "    <document type=\"vision\">" >> "${SESSION_DIR}/prompt.md"
        echo "      <![CDATA[" >> "${SESSION_DIR}/prompt.md"
        cat "docs/what-do-we-build.md" >> "${SESSION_DIR}/prompt.md"
        echo "      ]]>" >> "${SESSION_DIR}/prompt.md"
        echo "    </document>" >> "${SESSION_DIR}/prompt.md"
    else
        echo "    <document type=\"custom\">" >> "${SESSION_DIR}/prompt.md"
        echo "      <![CDATA[" >> "${SESSION_DIR}/prompt.md"
        cat "${context}" >> "${SESSION_DIR}/prompt.md"
        echo "      ]]>" >> "${SESSION_DIR}/prompt.md"
        echo "    </document>" >> "${SESSION_DIR}/prompt.md"
    fi
fi

echo "  </project-context>" >> "${SESSION_DIR}/prompt.md"

echo -e "\n  <review-target" >> "${SESSION_DIR}/prompt.md"

# Add target content
if [[ -f "${SESSION_DIR}/input.diff" ]]; then
    echo " type=\"diff\">" >> "${SESSION_DIR}/prompt.md"
    echo "    <![CDATA[" >> "${SESSION_DIR}/prompt.md"
    cat "${SESSION_DIR}/input.diff" >> "${SESSION_DIR}/prompt.md"
    echo "    ]]>" >> "${SESSION_DIR}/prompt.md"
elif [[ -f "${SESSION_DIR}/input.xml" ]]; then
    echo " type=\"file\">" >> "${SESSION_DIR}/prompt.md"
    echo "    <![CDATA[" >> "${SESSION_DIR}/prompt.md"
    cat "${SESSION_DIR}/input.xml" >> "${SESSION_DIR}/prompt.md"
    echo "    ]]>" >> "${SESSION_DIR}/prompt.md"
fi

echo "  </review-target>" >> "${SESSION_DIR}/prompt.md"

echo -e "\n  <focus-areas type=\"${focus}\">" >> "${SESSION_DIR}/prompt.md"

case "${focus}" in
    "code")
        echo "    <area>Code quality, architecture, security, performance</area>" >> "${SESSION_DIR}/prompt.md"
        echo "    <area>ATOM architecture compliance</area>" >> "${SESSION_DIR}/prompt.md"
        echo "    <area>Ruby best practices and conventions</area>" >> "${SESSION_DIR}/prompt.md"
        ;;
    "tests")
        echo "    <area>Test coverage, quality, maintainability</area>" >> "${SESSION_DIR}/prompt.md"
        echo "    <area>RSpec best practices</area>" >> "${SESSION_DIR}/prompt.md"
        echo "    <area>Test architecture and organization</area>" >> "${SESSION_DIR}/prompt.md"
        ;;
    "docs")
        echo "    <area>Documentation gaps, updates, cross-references</area>" >> "${SESSION_DIR}/prompt.md"
        echo "    <area>Architecture documentation alignment</area>" >> "${SESSION_DIR}/prompt.md"
        echo "    <area>User experience and clarity</area>" >> "${SESSION_DIR}/prompt.md"
        ;;
esac

echo "  </focus-areas>" >> "${SESSION_DIR}/prompt.md"
echo "</review-prompt>" >> "${SESSION_DIR}/prompt.md"
```

**Validation:**

- prompt.md file created with all sections
- System prompt template included correctly
- Project context loaded based on parameter
- Target content properly embedded
- Focus-specific instructions added

### 6. Multi-Model LLM Execution

Execute reviews with multiple LLM providers:

```bash
# Execute Google Pro review
echo "Executing Google Pro review..."
dev-tools/exe/llm-query google:gemini-2.5-pro "$(cat "${SESSION_DIR}/prompt.md")" --system "${SYSTEM_PROMPT_PATH}" --output "${SESSION_DIR}/cr-report-gpro.md"

# Check Google Pro execution status
if [[ $? -eq 0 ]] && [[ -s "${SESSION_DIR}/cr-report-gpro.md" ]]; then
    echo "✅ Google Pro review completed successfully"
else
    echo "❌ Google Pro review failed or produced empty output"
    echo "Error details:" >> "${SESSION_DIR}/execution.log"
    tail -n 20 "${SESSION_DIR}/cr-report-gpro.md" >> "${SESSION_DIR}/execution.log"
fi

# Execute Anthropic Opus review
echo "Executing Anthropic Opus review..."
dev-tools/exe/llm-query anthropic:claude-3-opus-20240229 "$(cat "${SESSION_DIR}/prompt.md")" --system "${SYSTEM_PROMPT_PATH}" --output "${SESSION_DIR}/cr-report-opus.md"

# Check Anthropic Opus execution status
if [[ $? -eq 0 ]] && [[ -s "${SESSION_DIR}/cr-report-opus.md" ]]; then
    echo "✅ Anthropic Opus review completed successfully"
else
    echo "❌ Anthropic Opus review failed or produced empty output"
    echo "Error details:" >> "${SESSION_DIR}/execution.log"
    tail -n 20 "${SESSION_DIR}/cr-report-opus.md" >> "${SESSION_DIR}/execution.log"
fi

# Create execution summary
cat > "${SESSION_DIR}/execution.summary" <<EOF
Session: ${SESSION_NAME}
Timestamp: $(date -Iseconds)
Target: ${target}
Focus: ${focus}

Execution Results:
- Google Pro: $([ -s "${SESSION_DIR}/cr-report-gpro.md" ] && echo "✅ Success" || echo "❌ Failed")
- Anthropic Opus: $([ -s "${SESSION_DIR}/cr-report-opus.md" ] && echo "✅ Success" || echo "❌ Failed")

Files Generated:
$(ls -la "${SESSION_DIR}"/ | grep -E '\.(md|meta|log)$')
EOF
```

**Validation:**

- Both LLM providers executed successfully
- Report files contain structured review content
- Execution log captures any errors or issues
- Summary file provides execution overview

### 7. Session Finalization and Index Creation

Create session index and prepare for synthesis:

```bash
# Create session index file
cat > "${SESSION_DIR}/README.md" <<EOF
# Code Review Session: ${SESSION_NAME}

**Generated**: $(date -Iseconds)  
**Command**: \`@review-code ${focus} ${target} ${context:-auto}\`  
**Target**: ${target}  
**Focus**: ${focus}  
**Context**: ${context:-auto}

## Session Files

### Input Files
- [\`session.meta\`](./session.meta) - Session metadata and parameters
- [\`input.meta\`](./input.meta) - Target content metadata
$([ -f "${SESSION_DIR}/input.diff" ] && echo "- [\\`input.diff\\`](./input.diff) - Git diff content")
$([ -f "${SESSION_DIR}/input.xml" ] && echo "- [\\`input.xml\\`](./input.xml) - File content in XML format")

### Prompt and Execution
- [\`prompt.md\`](./prompt.md) - User prompt (PROJECT CONTEXT + FOCUS REVIEW)
- [\`system.prompt.combined.md\`](./system.prompt.combined.md) - Combined system prompt (for multi-focus reviews)
- [\`execution.summary\`](./execution.summary) - LLM execution results
- [\`execution.log\`](./execution.log) - Detailed execution logs (if errors occurred)

### Review Reports
$([ -f "${SESSION_DIR}/cr-report-gpro.md" ] && echo "- [\\`cr-report-gpro.md\\`](./cr-report-gpro.md) - Google Pro review report")
$([ -f "${SESSION_DIR}/cr-report-opus.md" ] && echo "- [\\`cr-report-opus.md\\`](./cr-report-opus.md) - Anthropic Opus review report")

## Next Steps

To synthesize multiple reports into a unified analysis:

\`\`\`bash
@review-synthesizer dir:${SESSION_DIR}/
\`\`\`

This will create \`cr-report.md\` with the final synthesized review.

## Session Statistics

- **Input Size**: $([ -f "${SESSION_DIR}/input.diff" ] && wc -l < "${SESSION_DIR}/input.diff" || echo "N/A") lines
- **Prompt Size**: $(wc -w < "${SESSION_DIR}/prompt.md") words
- **Reports Generated**: $(ls "${SESSION_DIR}"/cr-report-*.md 2>/dev/null | wc -l)
- **Total Session Files**: $(ls "${SESSION_DIR}"/ | wc -l)
EOF

# Display session completion summary
echo ""
echo "🎉 Code Review Session Completed: ${SESSION_NAME}"
echo ""
echo "📁 Session Directory: ${SESSION_DIR}/"
echo "📋 Session Index: ${SESSION_DIR}/README.md"
echo ""
echo "📊 Generated Reports:"
[ -f "${SESSION_DIR}/cr-report-gpro.md" ] && echo "   ✅ Google Pro: cr-report-gpro.md"
[ -f "${SESSION_DIR}/cr-report-opus.md" ] && echo "   ✅ Anthropic Opus: cr-report-opus.md"
echo ""
echo "🔄 Next Step: Run @review-synthesizer dir:${SESSION_DIR}/ to create unified report"
echo ""
```

**Validation:**

- Session index (README.md) created with all file references
- Execution summary shows successful LLM runs
- Session directory contains all expected files
- Clear next steps provided for synthesis

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
