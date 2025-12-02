# Multi-Model Review Synthesis - Usage Guide

## Overview

The report synthesis feature automatically consolidates multiple LLM model reviews into a unified, actionable report. When you run ace-review with 2+ models, the synthesis identifies:

- **Consensus Findings**: Issues all models agree on (high confidence)
- **Strong Recommendations**: Issues found by 2+ models
- **Unique Insights**: Valuable findings from only one model (attributed)
- **Conflicting Views**: Where models disagree (with resolution suggestions)
- **Prioritized Actions**: Combined action items ranked by importance

## Command Types

### Bash CLI Commands

These commands run in your terminal and are the primary way to use synthesis.

### Claude Code Commands

Use `/ace-review` slash commands in Claude Code - they invoke the same bash commands internally.

## Basic Syntax

```bash
# Auto-synthesis (happens automatically with 2+ models)
ace-review --preset pr --model "gemini,gpt-4,claude" --auto-execute

# Standalone synthesis of existing reports
ace-review synthesize --session <session-directory>

# Synthesis with specific reports
ace-review synthesize --reports report1.md report2.md [options]
```

## Usage Scenarios

### Scenario 1: Automatic Multi-Model Review with Synthesis

**Goal**: Run a PR review with multiple AI models and automatically get a consolidated synthesis report.

**Steps**:

```bash
# Run review with 3 models - synthesis happens automatically
ace-review --preset pr --model "gemini-2.5-flash,gpt-4,claude-sonnet" --auto-execute

# Output shows individual reviews being generated:
#   ⏳ gemini-2.5-flash: querying...
#   ⏳ gpt-4: querying...
#   ⏳ claude-sonnet: querying...
#   ✓ gemini-2.5-flash: complete (12.3s)
#   ✓ gpt-4: complete (15.7s)
#   ✓ claude-sonnet: complete (14.2s)
#
# Then synthesis runs automatically:
#   Synthesizing 3 review reports...
#   ✓ Synthesis complete
#
# Saved: .cache/ace-review/sessions/review-20251201-143022/synthesis-report.md
```

**Expected Output**:

Session directory contains:
- `review-report-gemini-2.5-flash.md` - Individual model report
- `review-report-gpt-4.md` - Individual model report
- `review-report-claude-sonnet.md` - Individual model report
- `synthesis-report.md` - Consolidated synthesis report
- `metadata.yml` - Session metadata including synthesis info

### Scenario 2: Manual Synthesis of Existing Reports

**Goal**: You have multiple review reports from different runs and want to synthesize them together.

**Steps**:

```bash
# Navigate to a session directory
cd .cache/ace-review/sessions/review-20251201-143022/

# List available reports
ls review-report-*.md
# review-report-gemini-2.5-flash.md
# review-report-gpt-4.md
# review-report-claude-sonnet.md

# Synthesize all reports in the session
ace-review synthesize --session .

# Or specify explicit reports
ace-review synthesize --reports review-report-gemini-2.5-flash.md review-report-gpt-4.md
```

**Expected Output**:

```
Synthesizing 3 review reports...
  Reading: review-report-gemini-2.5-flash.md (2.4 KB)
  Reading: review-report-gpt-4.md (3.1 KB)
  Reading: review-report-claude-sonnet.md (2.8 KB)

Generating synthesis with google:gemini-2.5-flash...
✓ Synthesis complete

Saved: ./synthesis-report.md

Summary:
  Common findings: 5 (high confidence)
  Unique insights: 3
  Conflicts resolved: 1
  Action items: 8
```

### Scenario 3: Synthesis with Custom Model

**Goal**: Use a specific LLM model for synthesis (e.g., for higher quality analysis).

**Steps**:

```bash
# Use Claude Sonnet for synthesis instead of default
ace-review synthesize \
  --session .cache/ace-review/sessions/review-20251201/ \
  --synthesis-model anthropic:claude-sonnet-4

# Or during multi-model review
ace-review --preset pr \
  --model "gemini,gpt-4" \
  --synthesis-model anthropic:claude-sonnet-4 \
  --auto-execute
```

**Why**: Different synthesis models have different strengths:
- `google:gemini-2.5-flash` - Fast, cost-effective (default)
- `google:gemini-2.5-pro` - Balanced quality/cost
- `anthropic:claude-sonnet-4` - Highest quality, more expensive
- `openai:gpt-4` - Alternative high-quality option

### Scenario 4: Disable Auto-Synthesis

**Goal**: Run multi-model review without automatic synthesis (you'll synthesize manually later).

**Steps**:

```bash
# Multi-model review without auto-synthesis
ace-review --preset pr --model "gemini,gpt-4,claude" --no-synthesize --auto-execute

# Later, synthesize manually with custom settings
ace-review synthesize \
  --session .cache/ace-review/sessions/review-20251201/ \
  --synthesis-model gpt-4 \
  --output comprehensive-synthesis.md
```

**Why**: Useful when you want to:
- Review individual reports first
- Choose a specific synthesis model
- Customize synthesis later
- Save on LLM costs initially

### Scenario 5: Synthesis for Task-Specific Review

**Goal**: Run multi-model review for a specific task and get synthesis saved to task directory.

**Steps**:

```bash
# Multi-model review with task integration
ace-review --preset pr \
  --model "gemini,gpt-4" \
  --task 126.02 \
  --auto-execute

# Reports saved to:
#   .ace-taskflow/v.0.9.0/tasks/126-llm-enhance/review/
# Individual reports AND synthesis included
```

**Expected Output**:

Task review directory contains:
- `review-report-gemini-2.5-flash-20251201.md`
- `review-report-gpt-4-20251201.md`
- `synthesis-report-20251201.md`

### Scenario 6: Synthesis Output to Custom Location

**Goal**: Save synthesis to a specific file instead of session directory.

**Steps**:

```bash
# Synthesize to custom output file
ace-review synthesize \
  --session .cache/ace-review/sessions/review-20251201/ \
  --output docs/final-review-synthesis.md

# Or synthesize specific reports to custom location
ace-review synthesize \
  --reports review-1.md review-2.md review-3.md \
  --output /tmp/consolidated-review.md
```

## Command Reference

### `ace-review synthesize`

Synthesize multiple review reports into a consolidated report.

**Syntax**:
```bash
ace-review synthesize [OPTIONS]
```

**Options**:

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `--session DIR` | String | Session directory containing review reports | Current directory |
| `--reports FILE...` | Array | Explicit report files to synthesize | All review-report-*.md in session |
| `--synthesis-model MODEL` | String | LLM model for synthesis | Same as review model or gemini-2.5-flash |
| `--output FILE` | String | Output file path | synthesis-report.md in session |

**Internal Implementation**:
- Uses `ReportSynthesizer` molecule
- Reads reports with `File.read`
- Calls `Ace::LLM::QueryInterface.query` for synthesis
- Saves to `synthesis-report.md` by default

### `ace-review` with Multi-Model

Run review with multiple models (synthesis auto-triggers).

**Syntax**:
```bash
ace-review --preset PRESET --model "MODEL1,MODEL2,..." [OPTIONS]
```

**Synthesis Options**:

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `--model "a,b,c"` | String | Comma-separated models (triggers synthesis if 2+) | Single model |
| `--synthesis-model MODEL` | String | Model for synthesis | First model in list |
| `--no-synthesize` | Boolean | Skip auto-synthesis | false |

**Internal Implementation**:
- Multi-model execution via `MultiModelExecutor` (from task 126.01)
- Auto-synthesis via `ReviewManager.auto_synthesize`
- Triggered when: 2+ models succeed AND config.synthesis.enabled != false AND --no-synthesize not used

## Synthesis Report Format

The synthesized report follows this structure:

```markdown
# Multi-Model Review Synthesis

## Overview
- Models: gemini-2.5-flash, gpt-4, claude-sonnet
- Subject: PR #50 (origin/main...feature-branch)
- Generated: 2025-12-01 17:55:00

## Consensus Findings (All Models Agree)
1. **Missing error handling in user input validation** (file.rb:45)
   - All models flagged this as a critical issue
   - Potential for null pointer exceptions
   - Suggested fix: Add nil check before processing

2. [More consensus findings...]

## Strong Recommendations (2+ Models)
1. **Improve test coverage for edge cases** (gemini, gpt-4)
   - Current coverage: 75%, target: 90%
   - Missing tests for boundary conditions

2. [More strong recommendations...]

## Unique Insights

### From gemini-2.5-flash:
- Performance optimization opportunity in loop iteration (file.rb:120)
- Could reduce O(n²) to O(n) with hash lookup

### From gpt-4:
- Architectural consideration: Consider extracting this logic to a service object
- Improves testability and separation of concerns

### From claude-sonnet:
- Documentation gap: Complex algorithm needs inline comments
- Future maintainers will struggle to understand intent

## Conflicting Views & Resolution

### Topic: Error handling strategy
- **gemini**: Raise exceptions immediately for fail-fast behavior
- **gpt-4**: Return error objects for better control flow
- **claude**: Use Result/Either pattern for functional approach
- **Suggested resolution**: Use exceptions for unexpected errors, Result pattern for expected validation failures

## Prioritized Action Items

### High Priority (Consensus)
1. Add error handling for user input (file.rb:45)
2. Fix null pointer exception risk (file.rb:67)

### Medium Priority (Strong Recommendations)
3. Increase test coverage to 90%
4. Add documentation for complex algorithm

### Low Priority (Unique Insights)
5. Consider performance optimization (file.rb:120)
6. Extract service object for better architecture

## Individual Report References
- [gemini-2.5-flash](./review-report-gemini-2.5-flash.md)
- [gpt-4](./review-report-gpt-4.md)
- [claude-sonnet](./review-report-claude-sonnet.md)
```

## Configuration

### Config File: `.ace/review/config.yml`

```yaml
synthesis:
  enabled: true  # Auto-synthesize when 2+ models complete
  default_model: "google:gemini-2.5-flash"  # Model to use if not specified
```

### Environment Variables

None currently used for synthesis.

## Tips and Best Practices

### 1. Choose Models Strategically

Mix fast and thorough models:
```bash
ace-review --preset pr --model "gemini-2.5-flash,gpt-4" --auto-execute
# Fast model catches obvious issues, thorough model adds depth
```

### 2. Review Individual Reports First

```bash
# Get individual reports without synthesis
ace-review --preset pr --model "gemini,gpt-4,claude" --no-synthesize --auto-execute

# Review each report manually
cat .cache/ace-review/sessions/review-*/review-report-*.md

# Then synthesize with optimal model
ace-review synthesize --session .cache/ace-review/sessions/review-*/ --synthesis-model gpt-4
```

### 3. Use Synthesis for Different Perspectives

```bash
# Security-focused models
ace-review --preset security --model "gemini,claude" --auto-execute

# Performance-focused models
ace-review --preset performance --model "gemini,gpt-4" --auto-execute
```

### 4. Cost Optimization

Default synthesis model (gemini-2.5-flash) is cost-effective:
- Individual reviews: $0.10-0.30 per model (depending on code size)
- Synthesis: $0.05-0.15 (smaller prompt, just combining reports)
- Total for 3 models + synthesis: ~$0.50

### 5. Synthesis Quality Depends on Report Quality

- Ensure individual reviews use good presets
- Larger diff = better model diversity in findings
- Small changes may not benefit from multi-model synthesis

## Troubleshooting

### Issue: Synthesis not triggered automatically

**Check**:
1. Are you using 2+ models? (`--model "a,b"`)
2. Is synthesis enabled in config? (`.ace/review/config.yml`)
3. Did you use `--no-synthesize` flag?

**Solution**:
```bash
# Verify config
cat .ace/review/config.yml | grep -A2 synthesis

# Run with explicit synthesis
ace-review --preset pr --model "gemini,gpt-4" --auto-execute
```

### Issue: Synthesis fails with "No reports found"

**Check**:
1. Are you in the correct session directory?
2. Do reports follow naming convention? (`review-report-*.md`)

**Solution**:
```bash
# List reports in session
ls .cache/ace-review/sessions/review-*/review-report-*.md

# Use explicit session path
ace-review synthesize --session .cache/ace-review/sessions/review-20251201/
```

### Issue: Synthesis output is low quality

**Try**:
1. Use a better synthesis model (`--synthesis-model gpt-4`)
2. Ensure individual reports have good content (check preset)
3. Verify reports cover same subject

**Solution**:
```bash
# Re-synthesize with better model
ace-review synthesize \
  --session .cache/ace-review/sessions/review-20251201/ \
  --synthesis-model anthropic:claude-sonnet-4
```

### Issue: Synthesis exceeds context limit

**Check**:
Report sizes may be too large for synthesis model context.

**Solution**:
```bash
# Check report sizes
du -h .cache/ace-review/sessions/review-*/review-report-*.md

# Use model with larger context
ace-review synthesize \
  --session .cache/ace-review/sessions/review-20251201/ \
  --synthesis-model anthropic:claude-sonnet-4  # 200K context
```

## Migration Notes

### From Manual Synthesis to Auto-Synthesis

**Before** (manual workflow):
```bash
# Run reviews separately
ace-review --preset pr --model gemini --auto-execute
ace-review --preset pr --model gpt-4 --auto-execute

# Manually synthesize
code-review-synthesize report1.md report2.md
```

**After** (auto-synthesis):
```bash
# Single command
ace-review --preset pr --model "gemini,gpt-4" --auto-execute
# Synthesis happens automatically
```

### Key Differences

1. **Auto-trigger**: Synthesis runs automatically when 2+ models complete
2. **Consistent naming**: Reports use `review-report-{model}.md` format
3. **Session integration**: All reports in same session directory
4. **Config control**: Can disable via config or --no-synthesize flag

## Examples from Production Use

### Example 1: PR Review with 3 Models

```bash
cd ~/project
git checkout -b feature/user-auth

# Make changes...
git add .
git commit -m "Add user authentication"

# Multi-model review
ace-review --preset pr --model "gemini-2.5-flash,gpt-4,claude-sonnet" --auto-execute

# Check synthesis
cat .cache/ace-review/sessions/review-*/synthesis-report.md
```

Result: Found 3 consensus issues, 5 strong recommendations, resolved 2 conflicting views

### Example 2: Security Review Synthesis

```bash
# Security-focused review with multiple models
ace-review --preset security \
  --model "gemini-2.5-pro,claude-sonnet" \
  --subject 'diff: {ranges: ["origin/main...HEAD"]}' \
  --auto-execute

# Synthesis identifies security issues all models agree on (high priority)
```

Result: 2 critical security issues (consensus), 4 recommendations (strong), 3 unique insights

### Example 3: Task-Specific Review

```bash
# Review specific task implementation
ace-review --preset ruby-atom \
  --model "gemini,gpt-4" \
  --task 126.02 \
  --auto-execute

# Reports saved to task directory with synthesis
```

Result: Task review includes individual reports + synthesis in `.ace-taskflow/.../review/`
