# Synthesize Reviews Workflow Instruction

## Goal

Synthesize multiple code review reports into a unified, actionable improvement plan using the `code-review-synthesize` command. This workflow consolidates review outputs from different LLM providers, focus areas, or review runs into a single `cr-report.md` with resolved conflicts, prioritized recommendations, and clear implementation timeline.

## Prerequisites

- Multiple review reports in markdown format (cr-report-*.md files)
- Review reports following standard section formats
- Access to `code-review-synthesize` command (`code-review-synthesize`)
- LLM API access for synthesis (Google, Anthropic, OpenAI, etc.)

## Project Context Loading

- System prompt template: `dev-handbook/templates/review-synthesizer/system.prompt.md`
- Session patterns: `dev-taskflow/current/*/code_review/*/`
- Workflow standards: `dev-handbook/.meta/gds/workflow-instructions-definition.g.md`
- Tools documentation: `docs/tools.md`

## Command Structure

The synthesis workflow is now simplified to a single command:

```bash
code-review-synthesize <report1> <report2> [report3...] [options]
```

### Quick Start Examples

```bash
# Basic synthesis with default model (Google Gemini Pro)
code-review-synthesize cr-report-claude-opus.md cr-report-gpt4.md

# Synthesis with custom model
code-review-synthesize cr-report-*.md --model anthropic:claude-sonnet-4-20250514

# Synthesis with custom output location
code-review-synthesize cr-report-*.md --output final-synthesis.md

# Dry run to preview configuration
code-review-synthesize cr-report-*.md --dry-run

# Debug mode for troubleshooting
code-review-synthesize cr-report-*.md --debug
```

## Process Steps

### 1. Identify Review Reports

Locate the review reports you want to synthesize:

```bash
# In a session directory
ls -la cr-report-*.md

# Or find all review reports
find . -name "cr-report-*.md" -type f
```

### 2. Run Synthesis Command

Execute the synthesis with your preferred options:

```bash
# Simple synthesis (most common)
code-review-synthesize cr-report-*.md
```

**Progress indicators will show:**
- 🔍 Report collection and validation
- 📁 Session directory inference
- 📄 Output path determination
- 🧠 LLM synthesis execution
- ✅ Completion with metrics

### 3. Review Results

The command outputs:
- **cr-report.md**: Unified synthesis report
- **Metrics**: Processing time, cost, token usage
- **Session integration**: Updates README.md if in session directory

## Command Options Reference

| Option | Description | Default |
|--------|-------------|---------|
| `--model` | LLM model (provider:model) | `google:gemini-2.5-pro` |
| `--output` | Output file path | Inferred from session or `cr-report.md` |
| `--format` | Output format | `markdown` |
| `--system-prompt` | Custom system prompt file | Built-in template |
| `--force` | Force overwrite existing files | `false` |
| `--dry-run` | Preview configuration only | `false` |
| `--debug` | Enable debug output | `false` |

## Common Usage Patterns

### Session-based Synthesis (Recommended)

When working within a review session directory:

```bash
# Navigate to session directory
cd dev-taskflow/current/v.0.3.0-workflows/code_review/session-name/

# Synthesize all reports in session
code-review-synthesize cr-report-*.md

# Output automatically saved to cr-report.md in session
# Session README.md updated with synthesis results
```

### Multi-Provider Comparison

Synthesize reports from different LLM providers:

```bash
code-review-synthesize \
  cr-report-claude-opus.md \
  cr-report-gpt4.md \
  cr-report-gemini-pro.md \
  --output provider-comparison.md
```

### Focus Area Integration

Combine different review focus areas:

```bash
code-review-synthesize \
  cr-report-code-focus.md \
  cr-report-test-focus.md \
  cr-report-docs-focus.md \
  --output comprehensive-review.md
```

### Model Selection for Different Use Cases

```bash
# Cost-effective synthesis
code-review-synthesize cr-report-*.md --model google:gemini-2.5-pro

# High-quality analysis
code-review-synthesize cr-report-*.md --model anthropic:claude-sonnet-4-20250514

# Fast processing
code-review-synthesize cr-report-*.md --model google:gemini-2.5-flash
```

## Output Structure

The synthesized report follows the standard 11-section format:

1. **Methodology** - Analysis approach and assumptions
2. **Consensus Analysis** - Issues found by multiple reviewers
3. **Unique Insights** - Provider-specific findings
4. **Conflict Resolution** - Resolved disagreements
5. **Unified Improvement Plan** - Prioritized action items (🔴🟡🟢🔵)
6. **Quality Scoring** - Provider comparison (if applicable)
7. **Implementation Timeline** - Phased approach
8. **Cost vs Quality** - Efficiency analysis (if cost data available)
9. **Overall Ranking** - Provider recommendations
10. **Key Takeaways** - Main insights
11. **Quality Assurance Checklist** - Completion validation

## Advanced Features

### Automatic Session Detection

The tool automatically:
- Detects session directories from report paths
- Infers appropriate output locations
- Updates session documentation
- Preserves existing files with sequencing

### Intelligent File Sequencing

Existing synthesis files are preserved:
- `cr-report.md` → `cr-report.1.md` → `cr-report.2.md`
- Use `--force` to overwrite without sequencing

### Error Handling and Recovery

The tool handles common issues:
- Invalid report formats (warnings with continuation)
- Missing session directories (graceful fallback)
- LLM API failures (clear error messages)
- File permission issues (helpful guidance)

## Cost Optimization

### Model Selection by Use Case

| Use Case | Recommended Model | Cost | Quality |
|----------|------------------|------|---------|
| Quick synthesis | `google:gemini-2.5-flash` | Lowest | Good |
| Standard synthesis | `google:gemini-2.5-pro` | Low | High |
| Critical analysis | `anthropic:claude-sonnet-4-20250514` | Higher | Highest |
| Experimental | `openai:gpt-4o` | Moderate | High |

### Dry Run for Planning

Always preview before expensive operations:

```bash
# Check configuration and estimated scope
code-review-synthesize cr-report-*.md --dry-run
```

## Integration with Review Workflow

### Complete Review Session Workflow

1. **Generate Reviews**: Use `code-review` command with different models/focus
2. **Synthesize Results**: Use `code-review-synthesize` on generated reports
3. **Create Tasks**: Convert synthesis action items to development tasks
4. **Track Progress**: Use synthesis checklist for implementation tracking

### Session Directory Structure After Synthesis

```
session-directory/
├── input.diff                    # Original changes
├── input.xml                     # Structured input
├── project_context.md            # Project context
├── combined_prompt.md             # Review prompt
├── cr-report-claude-opus.md       # Individual reviews
├── cr-report-gpt4.md
├── cr-report-gemini-pro.md
├── cr-report.md                   # 🆕 Unified synthesis
├── synthesis.meta                 # Synthesis metadata
└── README.md                      # Updated with synthesis info
```

## Troubleshooting

### Common Issues

**No reports found:**
```bash
# Check file patterns
ls -la cr-report-*.md
# Use explicit file names if glob fails
code-review-synthesize cr-report-file1.md cr-report-file2.md
```

**LLM API errors:**
```bash
# Use debug mode for detailed error info
code-review-synthesize cr-report-*.md --debug
# Try different model if one fails
code-review-synthesize cr-report-*.md --model google:gemini-2.5-pro
```

**Permission issues:**
```bash
# Check file permissions
ls -la cr-report-*.md
# Use explicit output path
code-review-synthesize cr-report-*.md --output /tmp/synthesis.md
```

## Success Criteria

- ✅ Multiple review reports successfully processed
- ✅ Session directory automatically detected (if applicable)
- ✅ Unified cr-report.md created with comprehensive synthesis
- ✅ All consensus items identified and conflicts resolved
- ✅ Prioritized action items with clear implementation phases
- ✅ Session documentation updated with synthesis results
- ✅ Processing metrics displayed (time, cost, tokens)


## Next Steps After Synthesis

1. **Review synthesis results** in cr-report.md
2. **Create implementation tasks** from action items
3. **Plan development timeline** based on priority phases
4. **Track progress** against synthesis recommendations
5. **Archive session** when implementation complete
