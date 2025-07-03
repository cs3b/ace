# Handbook Review Command

Comprehensive wrapper for reviewing dev-handbook changes using the unified review-code workflow with handbook-specific configuration.

## Command Usage

```
@handbook-review [target] [git-range]
```

### Parameters

- **target** (required): What to review in dev-handbook
  - `workflows` - Review workflow-instructions files
  - `guides` - Review guide files  
  - `templates` - Review template files
  - `all` - Review all handbook content

- **git-range** (optional): Git range for diff-based review
  - `v.0.2.0..HEAD` - From tag to HEAD
  - `HEAD~5..HEAD` - Recent commits
  - `41a9da9f..HEAD` - From specific commit
  - If omitted, reviews working directory changes

## Pre-Configured Parameters

This command automatically sets:
- **Focus**: `docs` (uses documentation review approach)
- **Context**: `docs/**/*.md` (project documentation context)
- **System Prompt**: `dev-local/handbook/tpl/review/system.prompt.md` (handbook-specific)
- **Session Directory**: `code_review/YYYYMMDD-HHMMSS-handbook-[target]/`
- **Repository Context**: dev-handbook submodule only

## Implementation

Execute handbook review by calling review-code workflow with pre-configured parameters:

```bash
# Set up session variables
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TARGET="${1:-all}"
GIT_RANGE="${2:-}"

# Validate target parameter
case "$TARGET" in
    "workflows"|"guides"|"templates"|"all")
        ;;
    *)
        echo "❌ Invalid target: $TARGET"
        echo "Valid targets: workflows, guides, templates, all"
        exit 1
        ;;
esac

# Create session directory with handbook-specific naming
SESSION_NAME="${TIMESTAMP}-handbook-${TARGET}"
SESSION_DIR="dev-taskflow/current/v.0.3.0-workflows/code_review/${SESSION_NAME}"
mkdir -p "${SESSION_DIR}"

# Create session metadata
cat > "${SESSION_DIR}/session.meta" <<EOF
command: @handbook-review ${TARGET} ${GIT_RANGE}
timestamp: $(date -Iseconds)
target: ${TARGET}
git_range: ${GIT_RANGE:-working}
focus: docs (handbook-specific)
context: docs/**/*.md
system_prompt: dev-local/handbook/tpl/review/system.prompt.md
repository: dev-handbook (submodule)
EOF

# Change to dev-handbook submodule directory
cd dev-handbook

# Generate target content based on parameters
if [[ -n "$GIT_RANGE" ]]; then
    echo "📝 Generating diff for git range: $GIT_RANGE"
    
    # Create git diff from dev-handbook submodule
    git diff ${GIT_RANGE} --no-color > "../${SESSION_DIR}/input.diff"
    
    # Add diff metadata
    cat > "../${SESSION_DIR}/input.meta" <<EOF
target: ${TARGET}
git_range: ${GIT_RANGE}
type: git_diff
repository: dev-handbook
size: $(wc -l < "../${SESSION_DIR}/input.diff") lines
EOF

else
    echo "📁 Generating file content for target: $TARGET"
    
    # Create XML container for handbook files
    echo '<?xml version="1.0" encoding="UTF-8"?>' > "../${SESSION_DIR}/input.xml"
    echo '<documents>' >> "../${SESSION_DIR}/input.xml"
    
    # Add files based on target
    case "$TARGET" in
        "workflows")
            find workflow-instructions -name "*.wf.md" -type f | while read -r file; do
                echo "  <document path=\"$file\">" >> "../${SESSION_DIR}/input.xml"
                echo "    <![CDATA[" >> "../${SESSION_DIR}/input.xml"
                cat "$file" >> "../${SESSION_DIR}/input.xml"
                echo "    ]]>" >> "../${SESSION_DIR}/input.xml"
                echo "  </document>" >> "../${SESSION_DIR}/input.xml"
            done
            ;;
        "guides")
            find guides -name "*.g.md" -type f | while read -r file; do
                echo "  <document path=\"$file\">" >> "../${SESSION_DIR}/input.xml"
                echo "    <![CDATA[" >> "../${SESSION_DIR}/input.xml"
                cat "$file" >> "../${SESSION_DIR}/input.xml"
                echo "    ]]>" >> "../${SESSION_DIR}/input.xml"
                echo "  </document>" >> "../${SESSION_DIR}/input.xml"
            done
            ;;
        "templates")
            find templates -name "*.md" -type f | while read -r file; do
                echo "  <document path=\"$file\">" >> "../${SESSION_DIR}/input.xml"
                echo "    <![CDATA[" >> "../${SESSION_DIR}/input.xml"
                cat "$file" >> "../${SESSION_DIR}/input.xml"
                echo "    ]]>" >> "../${SESSION_DIR}/input.xml"
                echo "  </document>" >> "../${SESSION_DIR}/input.xml"
            done
            ;;
        "all")
            find . -name "*.md" -type f -not -path "./.git/*" | while read -r file; do
                echo "  <document path=\"$file\">" >> "../${SESSION_DIR}/input.xml"
                echo "    <![CDATA[" >> "../${SESSION_DIR}/input.xml"
                cat "$file" >> "../${SESSION_DIR}/input.xml"
                echo "    ]]>" >> "../${SESSION_DIR}/input.xml"
                echo "  </document>" >> "../${SESSION_DIR}/input.xml"
            done
            ;;
    esac
    
    echo '</documents>' >> "../${SESSION_DIR}/input.xml"
    
    # Add file pattern metadata
    file_count=$(find . -name "*.md" -type f | wc -l)
    cat > "../${SESSION_DIR}/input.meta" <<EOF
target: ${TARGET}
type: file_pattern
repository: dev-handbook
files: ${file_count}
EOF
fi

# Return to main repository
cd ..

# Build handbook-specific prompt (USER PROMPT ONLY - system prompt passed separately)
cat > "${SESSION_DIR}/prompt.md" <<EOF
# Handbook Review Prompt - ${TARGET} Focus

Generated: $(date -Iseconds)
Target: ${TARGET}
Git Range: ${GIT_RANGE:-working directory}
Focus: docs (handbook-specific analysis)
Context: docs/**/*.md
EOF

echo -e "\n\n## Project Context\n" >> "${SESSION_DIR}/prompt.md"

# Add project context from docs/
echo "### Project Structure (docs/blueprint.md)" >> "${SESSION_DIR}/prompt.md"
cat "docs/blueprint.md" >> "${SESSION_DIR}/prompt.md"
echo -e "\n\n### Project Vision (docs/what-do-we-build.md)" >> "${SESSION_DIR}/prompt.md"
cat "docs/what-do-we-build.md" >> "${SESSION_DIR}/prompt.md"

echo -e "\n\n## Review Target\n" >> "${SESSION_DIR}/prompt.md"

# Add target content
if [[ -f "${SESSION_DIR}/input.diff" ]]; then
    echo "### Git Diff Changes (dev-handbook)" >> "${SESSION_DIR}/prompt.md"
    cat "${SESSION_DIR}/input.diff" >> "${SESSION_DIR}/prompt.md"
elif [[ -f "${SESSION_DIR}/input.xml" ]]; then
    echo "### Handbook Content (${TARGET})" >> "${SESSION_DIR}/prompt.md"
    cat "${SESSION_DIR}/input.xml" >> "${SESSION_DIR}/prompt.md"
fi

echo -e "\n\n## Focus Areas\n" >> "${SESSION_DIR}/prompt.md"
echo "Comprehensive handbook review focusing on:" >> "${SESSION_DIR}/prompt.md"
echo "- Workflow instructions effectiveness and AI agent compatibility" >> "${SESSION_DIR}/prompt.md"
echo "- Guide completeness and cross-reference integrity" >> "${SESSION_DIR}/prompt.md"
echo "- Template consistency and embedding standards" >> "${SESSION_DIR}/prompt.md"
echo "- Documentation gaps and architecture alignment" >> "${SESSION_DIR}/prompt.md"

# Execute multi-model reviews
echo ""
echo "🧠 Executing handbook review with multiple models..."

# Execute Google Pro review
echo "📊 Executing Google Pro review..."
dev-tools/exe/llm-query google:gemini-2.5-pro "$(cat "${SESSION_DIR}/prompt.md")" --system "dev-local/handbook/tpl/review/system.prompt.md" --output "${SESSION_DIR}/cr-report-gpro.md"

if [[ $? -eq 0 ]] && [[ -s "${SESSION_DIR}/cr-report-gpro.md" ]]; then
    echo "✅ Google Pro review completed successfully"
else
    echo "❌ Google Pro review failed"
    echo "Error details:" >> "${SESSION_DIR}/execution.log"
    tail -n 20 "${SESSION_DIR}/cr-report-gpro.md" >> "${SESSION_DIR}/execution.log"
fi

# Execute Anthropic Claude review
echo "📊 Executing Anthropic Claude review..."
dev-tools/exe/llm-query anthropic:claude-3-sonnet-20240229 "$(cat "${SESSION_DIR}/prompt.md")" --system "dev-local/handbook/tpl/review/system.prompt.md" --output "${SESSION_DIR}/cr-report-claude.md"

if [[ $? -eq 0 ]] && [[ -s "${SESSION_DIR}/cr-report-claude.md" ]]; then
    echo "✅ Anthropic Claude review completed successfully"
else
    echo "❌ Anthropic Claude review failed"
    echo "Error details:" >> "${SESSION_DIR}/execution.log"
    tail -n 20 "${SESSION_DIR}/cr-report-claude.md" >> "${SESSION_DIR}/execution.log"
fi

# Create execution summary
cat > "${SESSION_DIR}/execution.summary" <<EOF
Handbook Review Session: ${SESSION_NAME}
Timestamp: $(date -Iseconds)
Target: ${TARGET}
Git Range: ${GIT_RANGE:-working directory}

Execution Results:
- Google Pro: $([ -s "${SESSION_DIR}/cr-report-gpro.md" ] && echo "✅ Success" || echo "❌ Failed")
- Anthropic Claude: $([ -s "${SESSION_DIR}/cr-report-claude.md" ] && echo "✅ Success" || echo "❌ Failed")

Files Generated:
$(ls -la "${SESSION_DIR}/" | grep -E '\.(md|meta|log)$')
EOF

# Create session index
cat > "${SESSION_DIR}/README.md" <<EOF
# Handbook Review Session: ${SESSION_NAME}

**Generated**: $(date -Iseconds)  
**Command**: \`@handbook-review ${TARGET} ${GIT_RANGE}\`  
**Target**: ${TARGET}  
**Git Range**: ${GIT_RANGE:-working directory}  
**Repository**: dev-handbook (submodule)

## Session Files

### Input Files
- [\`session.meta\`](./session.meta) - Session metadata and parameters
- [\`input.meta\`](./input.meta) - Target content metadata
$([ -f "${SESSION_DIR}/input.diff" ] && echo "- [\`input.diff\`](./input.diff) - Git diff content from dev-handbook")
$([ -f "${SESSION_DIR}/input.xml" ] && echo "- [\`input.xml\`](./input.xml) - Handbook file content in XML format")

### Prompt and Execution
- [\`prompt.md\`](./prompt.md) - User prompt (PROJECT CONTEXT + FOCUS REVIEW)
- [\`execution.summary\`](./execution.summary) - LLM execution results
$([ -f "${SESSION_DIR}/execution.log" ] && echo "- [\`execution.log\`](./execution.log) - Detailed execution logs")

### Review Reports
$([ -f "${SESSION_DIR}/cr-report-gpro.md" ] && echo "- [\`cr-report-gpro.md\`](./cr-report-gpro.md) - Google Pro handbook review")
$([ -f "${SESSION_DIR}/cr-report-claude.md" ] && echo "- [\`cr-report-claude.md\`](./cr-report-claude.md) - Anthropic Claude handbook review")

## Next Steps

To synthesize multiple reports into a unified analysis:

\`\`\`bash
@review-synthesizer dir:${SESSION_DIR}/
\`\`\`

This will create \`cr-report.md\` with the final synthesized handbook review.

## Session Statistics

- **Target**: ${TARGET}
- **Input Type**: $([ -f "${SESSION_DIR}/input.diff" ] && echo "Git diff" || echo "File content")
- **Input Size**: $([ -f "${SESSION_DIR}/input.diff" ] && wc -l < "${SESSION_DIR}/input.diff" || echo "N/A") lines
- **Prompt Size**: $(wc -w < "${SESSION_DIR}/prompt.md") words
- **Reports Generated**: $(ls "${SESSION_DIR}"/cr-report-*.md 2>/dev/null | wc -l)
- **Total Session Files**: $(ls "${SESSION_DIR}"/ | wc -l)
EOF

# Display completion summary
echo ""
echo "🎉 Handbook Review Session Completed: ${SESSION_NAME}"
echo ""
echo "📁 Session Directory: ${SESSION_DIR}/"
echo "📋 Session Index: ${SESSION_DIR}/README.md"
echo ""
echo "📈 Generated Reports:"
[ -f "${SESSION_DIR}/cr-report-gpro.md" ] && echo "   ✅ Google Pro: cr-report-gpro.md"
[ -f "${SESSION_DIR}/cr-report-claude.md" ] && echo "   ✅ Anthropic Claude: cr-report-claude.md"
echo ""
echo "🔄 Next Step: Run @review-synthesizer dir:${SESSION_DIR}/ to create unified report"
echo ""
```

## Usage Examples

### Review workflow instructions changes from recent tag
```
@handbook-review workflows v.0.2.0..HEAD
```

### Review all guides in working directory  
```
@handbook-review guides
```

### Review templates with git range
```
@handbook-review templates HEAD~3..HEAD
```

### Review all handbook content
```
@handbook-review all
```

## Session Output Structure

```
code_review/YYYYMMDD-HHMMSS-handbook-[target]/
├── session.meta              # Session configuration and metadata
├── input.diff               # Git diff (if git-range provided)
├── input.xml                # File content (if target pattern used)
├── input.meta               # Input content metadata
├── prompt.md                # Complete handbook review prompt
├── cr-report-gpro.md        # Google Pro review report
├── cr-report-claude.md      # Anthropic Claude review report
├── execution.summary        # LLM execution results
├── execution.log           # Error logs (if any failures)
└── README.md               # Session index and next steps
```

This command provides handbook-specific review capabilities while leveraging the unified review-code workflow infrastructure.