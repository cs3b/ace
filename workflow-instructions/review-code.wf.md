# Code Review Workflow Instruction

## Goal

Perform comprehensive code review using `code-review` and `llm-query` tools with proper parameter preparation, multi-model execution, and conditional synthesis of results.

## ⚠️ CRITICAL: AI Agent Instructions ⚠️

**FOR AI CODING AGENTS - READ THIS FIRST**

This workflow uses TWO main tools: `code-review` and `llm-query`. Follow the process steps exactly as described.

### What TO DO:
1. **Analyze the user's request** to prepare parameters
2. **Execute code-review** with proper parameters
3. **Execute llm-query** for each configured model with `--timeout 600`
4. **Run code-review-synthesize** if multiple reports exist
5. **Validate final reports** are present

### What NOT TO DO:
- ❌ Use Read tool on individual source files
- ❌ Create tasks (user's responsibility after reviewing reports)
- ❌ Skip parameter preparation steps

## Prerequisites

- Access to `code-review` and `llm-query` tools
- Multiple LLM provider access configured
- Access to `code-review-synthesize` tool
- Write access to session directories
- Git CLI available for diff operations

## Quick Start Examples

```bash
# Review recent changes
code-review code HEAD~5..HEAD --context auto

# Review staged changes  
code-review code staged --context auto

# Review specific files
code-review code "src/**/*.rb" --context auto

# Combined review
code-review "code tests" HEAD~3..HEAD --context auto
```

## Project Context Loading

- Load project structure: `docs/blueprint.md`
- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load tools documentation: `docs/tools.md`

## High-Level Execution Plan

- [ ] Prepare parameters for code-review
- [ ] Run code-review command
- [ ] Ensure all files are available
- [ ] Prepare parameters for llm-query with --timeout 600
- [ ] Run llm-query for each configured model
- [ ] Conditionally run code-review-synthesize if multiple reports
- [ ] Ensure final code review report is present

## Process Steps

### 1. **Prepare Parameters for code-review**

Extract and prepare parameters from user request:

- **FOCUS**: Determine review focus (`code`, `tests`, `docs`, or combinations like `"code tests"`)
- **TARGET**: Identify what to review (`HEAD~5..HEAD`, `staged`, `"src/**/*.rb"`, specific files)
- **OPTIONS**: Set additional options (`--context auto`, `--dry-run`, `--model`, etc.)
- **INHERITANCE**: Use any parameters already defined by user in earlier workflow steps

**Parameter Examples:**
```bash
# From user request: "Review recent changes to the authentication system"
FOCUS="code"
TARGET="HEAD~3..HEAD"
OPTIONS="--context auto"

# From user request: "Review all test files for the API"
FOCUS="tests" 
TARGET="spec/api/**/*.rb"
OPTIONS="--context auto"
```

**Validation:**
- Parameters extracted correctly from user request
- Focus area valid (`code`, `tests`, `docs`, or valid combination)
- Target format valid (git range, file pattern, or keyword)

### 2. **Run code-review**

Execute the code-review command with prepared parameters:

```bash
code-review "${FOCUS}" "${TARGET}" ${OPTIONS}
```

**Command Examples:**
```bash
code-review code HEAD~5..HEAD --context auto
code-review "code tests" staged --context auto
code-review docs "docs/**/*.md" --context auto
```

**Validation:**
- Command executes successfully
- Session directory created
- No critical errors reported

### 3. **Ensure All Files Are Available**

Verify that code-review generated all necessary files:

- Check session directory exists and is accessible
- Verify input files are present (input.diff or input.xml)
- Confirm project context loaded if requested
- Validate session metadata files exist

**Expected Files:**
- Session directory: `dev-taskflow/current/*/code_review/*/`
- Input content: `input.diff` or `input.xml`
- Session metadata: `session.meta`
- Project context: `project-context.md` (if using --context auto)

**Validation:**
- All expected files present and readable
- File sizes indicate content was properly captured
- No missing or empty critical files

### 4. **Prepare Parameters for llm-query**

Build llm-query parameters based on code-review session files:

- **SYSTEM PROMPT**: Use appropriate template from session or specify custom
- **INPUT CONTENT**: Use session files as input content
- **MODELS**: Determine which models to run (defaults to gpro if not specified by user)
- **TIMEOUT**: Set timeout to 600 seconds as specified
- **OUTPUT**: Prepare output file paths for each model

**Parameter Preparation:**
```bash
# Use session files and system prompt
SYSTEM_PROMPT="${SESSION_DIR}/system.prompt.md"
INPUT_CONTENT="${SESSION_DIR}/prompt.md"
TIMEOUT=600
MODELS=("gpro")  # Default to single gpro model unless user specifies multiple
```

**Validation:**
- System prompt file exists and is readable
- Input content properly formatted
- Model list contains valid model identifiers
- Timeout set to 600 as required

### 5. **Run llm-query for Each Model**

Execute llm-query for each configured model with prepared parameters:

```bash
# For each model in the configuration
for model in "${MODELS[@]}"; do
    llm-query "${model}" \
        --system "${SYSTEM_PROMPT}" \
        --timeout 600 \
        --output "${SESSION_DIR}/cr-report-${model//[:\/]/-}.md" \
        < "${INPUT_CONTENT}"
done
```

**Multi-Model Execution:**
- Run queries sequentially or in parallel based on configuration
- Handle individual model failures gracefully
- Continue with successful models if some fail
- Generate separate report file for each model

**Validation:**
- At least one model execution succeeds
- Report files generated for successful models
- Error handling documented for failed models
- Individual reports contain structured review content

### 6. **Conditional: Run code-review-synthesize**

If multiple reports exist, run synthesis to combine them:

**Condition Check:**
```bash
# Count number of generated reports
REPORT_COUNT=$(find "${SESSION_DIR}" -name "cr-report-*.md" | wc -l)

if [ "${REPORT_COUNT}" -gt 1 ]; then
    # Multiple reports exist - run synthesis
    code-review-synthesize \
        --format report \
        --include-recommendations \
        --session-dir "${SESSION_DIR}"
else
    # Single report - no synthesis needed
    echo "Single report generated - synthesis not required"
fi
```

**Synthesis Execution:**
- Combine multiple model reports into unified analysis
- Include recommendations from synthesis
- Generate comparative analysis
- Create final synthesized report

**Validation:**
- Synthesis runs successfully if multiple reports exist
- Final synthesized report generated
- Individual reports preserved alongside synthesis
- Clear indication of which reports were synthesized

### 7. **Ensure Code Review Report is Present**

Validate that final review report(s) are available:

**Final Report Validation:**
- If synthesis was run: verify synthesized report exists
- If single model: verify individual report exists  
- Check report completeness and format
- Confirm reports are accessible to user

**Final Output:**
```bash
# Final report location
if [ -f "${SESSION_DIR}/cr-report-synthesized.md" ]; then
    FINAL_REPORT="${SESSION_DIR}/cr-report-synthesized.md"
else
    FINAL_REPORT=$(find "${SESSION_DIR}" -name "cr-report-*.md" | head -1)
fi

echo "Code review completed. Report available at: ${FINAL_REPORT}"
```

**Validation:**
- Final report file exists and is readable
- Report contains structured review content
- User can access and review the results
- Session directory organized for future reference

**Important:** This workflow generates reports only. Task creation is the user's responsibility after reviewing the reports.

## Command Parameters

### code-review Command

```
code-review FOCUS TARGET [OPTIONS]
```

**Parameters:**
- **FOCUS** (required): `code`, `tests`, `docs`, or combinations like `"code tests"`
- **TARGET** (required): Git range, file pattern, or keyword (`HEAD~5..HEAD`, `staged`, `"src/**/*"`)

**Common Options:**
- `--context auto` - Auto-load project context (default)
- `--context none` - Skip project context
- `--timeout 600` - Set timeout for operations
- `--model MODEL` - Specify specific LLM model
- `--dry-run` - Show what would be done without execution

### llm-query Command

```
llm-query MODEL --system PROMPT_FILE --timeout 600 --output REPORT_FILE < INPUT_FILE
```

**Required Parameters:**
- **MODEL**: LLM model identifier (defaults to `gpro`, user can specify multiple models)
- `--system`: System prompt file path
- `--timeout 600`: Timeout in seconds (as specified)
- `--output`: Output report file path

### code-review-synthesize Command

```
code-review-synthesize --format report --include-recommendations --session-dir SESSION_DIR
```

**Parameters:**
- `--format report` - Output format for synthesis
- `--include-recommendations` - Include synthesis recommendations
- `--session-dir` - Session directory containing multiple reports

## Usage Examples

### Example 1: Simple Code Review
```bash
# User request: "Review the recent authentication changes"
FOCUS="code"
TARGET="HEAD~3..HEAD"
code-review code HEAD~3..HEAD --context auto
```

### Example 2: Multi-Model Review with Synthesis
```bash
# User request: "Review all API tests with multiple models"
FOCUS="tests"
TARGET="spec/api/**/*.rb"
code-review tests "spec/api/**/*.rb" --context auto
# Multiple models configured - synthesis will run automatically
```

### Example 3: Staged Changes Review
```bash
# User request: "Review my staged changes before commit"
FOCUS="code"
TARGET="staged"
code-review code staged --context auto
```

## Success Criteria

- ✅ Parameters correctly extracted from user request
- ✅ code-review command executes successfully
- ✅ All session files generated and accessible
- ✅ llm-query executed for each configured model with --timeout 600
- ✅ code-review-synthesize runs when multiple reports exist
- ✅ Final review report(s) available and readable
- ✅ User receives clear indication of report location
- ✅ No tasks created (user responsibility after reviewing reports)

## Error Handling

### Common Issues
- **Missing files**: Verify all expected session files exist
- **LLM failures**: Continue with successful models, document failures
- **Parameter errors**: Validate focus, target, and option parameters
- **Synthesis failures**: Preserve individual reports even if synthesis fails

### Recovery Actions
- Log errors clearly for user review
- Continue workflow with partial results when possible
- Provide clear error messages with suggested fixes
- Maintain session integrity for troubleshooting

---

This simplified workflow focuses on the core two-tool approach using `code-review` and `llm-query` with conditional synthesis, achieving the goal of streamlined code review without task creation.