# Multi-Model Execution - Usage Guide

## Overview

Run a single review preparation against multiple LLM models concurrently. This feature enables:

- Comparing insights from different models (e.g., GPT-4 vs Gemini vs Claude)
- Gathering diverse perspectives on code quality
- Validating findings across multiple AI providers
- Saving time with parallel execution

## Command Types

All examples below use the `ace-review` CLI tool (bash command):

```bash
ace-review --preset pr --model "gemini,gpt-4" --auto-execute
```

## Command Structure

### Basic Invocation

```bash
# Single model (existing behavior)
ace-review --preset pr --model gemini --auto-execute

# Multiple models via comma-separated list
ace-review --preset pr --model "gemini,gpt-4,claude" --auto-execute

# Multiple models via repeated --model flags
ace-review --preset pr --model gemini --model gpt-4 --model claude --auto-execute
```

### Model Name Format

Models use the `provider:model` format or aliases:

```bash
# Full provider:model format
--model "google:gemini-2.5-flash,openai:gpt-4,anthropic:claude-sonnet-4"

# Using aliases (from ace-llm configuration)
--model "gemini,gpt-4,claude"

# Mix of formats
--model "gpro,google:gemini-2.5-flash,gpt-4"
```

### Preset Configuration

Define multiple models in preset YAML:

```yaml
# .ace/review/presets/multi-model.yml
description: "Multi-model PR review"

# Use models array for multi-model execution
models:
  - google:gemini-2.5-flash
  - openai:gpt-4
  - anthropic:claude-sonnet-4

instructions:
  # ... rest of preset configuration
```

Then invoke:

```bash
ace-review --preset multi-model --auto-execute
```

## Usage Scenarios

### Scenario 1: Quick Multi-Model Review

**Goal**: Get quick feedback from multiple models on uncommitted changes

**Commands**:
```bash
# Review current changes with 3 models
ace-review --preset pr --model "gemini,gpt-4,claude" --auto-execute

# Expected output:
# Preparing review...
# ✓ Preset loaded: pr
# ✓ Subject extracted: origin/main...HEAD (15 files)
# ✓ Prompts composed
#
# Executing reviews (3 models):
#   ⏳ gemini-2.5-flash: querying...
#   ⏳ gpt-4: querying...
#   ⏳ claude-sonnet: querying...
#   ✓ gemini-2.5-flash: complete (2.3s)
#   ✓ gpt-4: complete (4.1s)
#   ✓ claude-sonnet: complete (3.8s)
#
# Reviews saved:
#   .cache/ace-review/sessions/review-20251201-175500/
#   ├── review-gemini-2.5-flash.md
#   ├── review-gpt-4.md
#   └── review-claude-sonnet.md
```

**Expected Output Files**:
- `.cache/ace-review/sessions/review-{timestamp}/review-gemini-2.5-flash.md`
- `.cache/ace-review/sessions/review-{timestamp}/review-gpt-4.md`
- `.cache/ace-review/sessions/review-{timestamp}/review-claude-sonnet.md`
- `.cache/ace-review/sessions/review-{timestamp}/metadata.yml` (includes all model timings)

### Scenario 2: Preset-Based Multi-Model Review

**Goal**: Use a preset configured for multiple models

**Setup** (`.ace/review/presets/comprehensive.yml`):
```yaml
description: "Comprehensive multi-model review"

models:
  - google:gemini-2.5-flash  # Fast, good for quick feedback
  - openai:gpt-4             # Deep analysis
  - anthropic:claude-sonnet  # Code understanding

instructions:
  # ... preset configuration
```

**Commands**:
```bash
ace-review --preset comprehensive --auto-execute
```

**Expected Output**:
Same as Scenario 1, but models come from preset configuration.

### Scenario 3: Override Preset Models

**Goal**: Use a preset but override its model selection

**Commands**:
```bash
# Preset defines models: [gemini, gpt-4]
# But we want to test with different models
ace-review --preset comprehensive --model "claude,gemini-exp" --auto-execute
```

**Expected Behavior**:
- CLI `--model` flag overrides preset `models:` array
- Reviews run with claude and gemini-exp instead of preset models
- All other preset configuration (instructions, subject, context) remains unchanged

### Scenario 4: Fault Isolation - One Model Fails

**Goal**: Demonstrate resilience when one model provider fails

**Commands**:
```bash
# Simulate: gpt-4 API is down but others work
ace-review --preset pr --model "gemini,gpt-4,claude" --auto-execute

# Expected output:
# Executing reviews (3 models):
#   ⏳ gemini-2.5-flash: querying...
#   ⏳ gpt-4: querying...
#   ⏳ claude-sonnet: querying...
#   ✓ gemini-2.5-flash: complete (2.3s)
#   ✗ gpt-4: failed (API error: rate limit exceeded)
#   ✓ claude-sonnet: complete (3.8s)
#
# Reviews saved (2 of 3 succeeded):
#   .cache/ace-review/sessions/review-20251201-175500/
#   ├── review-gemini-2.5-flash.md
#   └── review-claude-sonnet.md
#
# Errors:
#   - gpt-4: API error: rate limit exceeded
```

**Expected Behavior**:
- Failed model doesn't prevent other models from completing
- Error is logged but exit code is 0 if at least one succeeds
- Metadata includes failure information

### Scenario 5: Dry Run with Multiple Models

**Goal**: Prepare prompts without executing any LLM queries

**Commands**:
```bash
ace-review --preset pr --model "gemini,gpt-4,claude" --dry-run
```

**Expected Output**:
```
Preparing review...
✓ Preset loaded: pr
✓ Subject extracted: origin/main...HEAD (15 files)
✓ Prompts composed

Review session prepared: .cache/ace-review/sessions/review-20251201-175500/
  System prompt: .cache/ace-review/sessions/review-20251201-175500/system.prompt.md
  User prompt: .cache/ace-review/sessions/review-20251201-175500/user.prompt.md

Would execute with models: gemini-2.5-flash, gpt-4, claude-sonnet

To execute with all models:
  ace-review --preset pr --model "gemini,gpt-4,claude" --auto-execute
```

**Expected Behavior**:
- Prompts generated once (same for all models)
- No LLM queries executed
- Shows which models would be used

### Scenario 6: Task Integration with Multiple Models

**Goal**: Save multi-model reviews to task directory

**Commands**:
```bash
ace-review --preset pr --model "gemini,gpt-4" --task 126 --auto-execute
```

**Expected Output Files**:
- `.ace-taskflow/v.0.9.0/tasks/126-*/reviews/review-gemini-2.5-flash-{timestamp}.md`
- `.ace-taskflow/v.0.9.0/tasks/126-*/reviews/review-gpt-4-{timestamp}.md`
- Both reviews also in `.cache/ace-review/sessions/review-{timestamp}/`

## Command Reference

### --model FLAG

**Syntax**: `--model MODEL[,MODEL...]` or multiple `--model MODEL` flags

**Purpose**: Specify one or more models for review execution

**Formats**:
- Comma-separated: `--model "model1,model2,model3"`
- Repeated flags: `--model model1 --model model2 --model model3`
- Provider:model: `--model "google:gemini-2.5-flash"`
- Aliases: `--model "gemini"` (from ace-llm config)

**Behavior**:
- Single model: Executes serially (existing behavior preserved)
- Multiple models: Executes concurrently with progress display
- Deduplication: `--model "gemini,gemini"` → runs once
- Validation: Invalid model names fail before execution
- Override: CLI flag overrides preset `models:` array

**Examples**:
```bash
# Single model (existing)
--model "gemini"

# Multiple via comma
--model "gemini,gpt-4,claude"

# Multiple via flags
--model gemini --model gpt-4

# Full provider:model format
--model "google:gemini-2.5-flash,openai:gpt-4"
```

### PRESET models: ARRAY

**Location**: `.ace/review/presets/{preset-name}.yml`

**Syntax**:
```yaml
# Single model (existing, backward compatible)
model: google:gemini-2.5-flash

# Multiple models (new)
models:
  - google:gemini-2.5-flash
  - openai:gpt-4
  - anthropic:claude-sonnet
```

**Behavior**:
- If `models:` array present, use all models in concurrent execution
- If `model:` scalar present (existing), use single model (backward compatible)
- If both present, `models:` takes precedence
- CLI `--model` flag overrides preset configuration

**Internal Implementation**:
- PresetManager.resolve_preset() returns array of models
- ReviewManager handles array and spawns concurrent executions
- LlmExecutor.execute_batch() coordinates parallel queries

## Tips and Best Practices

### Model Selection Strategy

**Quick Feedback** (fast, inexpensive):
```bash
--model "gemini,google:gemini-2.5-flash-lite"
```

**Comprehensive Analysis** (slower, thorough):
```bash
--model "gpt-4,anthropic:claude-sonnet-4,google:gemini-pro"
```

**Balanced Approach**:
```bash
--model "gemini,gpt-4"  # One fast, one thorough
```

### Performance Optimization

- **Concurrency limit**: Default 3 concurrent models (configurable via environment)
- **Timeout handling**: Each model has independent timeout (default 600s)
- **Early termination**: Failed model doesn't block others

### Error Handling

**Partial Success**:
- If 2 of 3 models succeed, exit code is 0
- Failed model errors logged to stderr
- Metadata includes success/failure for each model

**Complete Failure**:
- If all models fail, exit code is 1
- Detailed error messages for each failure
- Session files preserved for debugging

### Deduplication

Models are deduplicated automatically:
```bash
# These are equivalent (gemini runs once):
--model "gemini,gemini"
--model gemini --model gemini
```

### Troubleshooting

**Progress not showing**:
- Ensure `--auto-execute` is set
- Check stderr for output (progress goes to stderr)

**One model slow, blocking others**:
- Models run concurrently, slowest determines total time
- Consider using `--dry-run` to validate setup first

**API rate limits**:
- Fault isolation prevents one failure from blocking others
- Consider spreading requests across time or using fewer concurrent models

## Migration Notes

### From Single Model

**Before** (v0.12.x):
```bash
ace-review --preset pr --model gemini --auto-execute
```

**After** (v0.13.0+):
```bash
# Single model (unchanged, fully backward compatible)
ace-review --preset pr --model gemini --auto-execute

# Multi-model (new capability)
ace-review --preset pr --model "gemini,gpt-4" --auto-execute
```

### Preset Configuration Evolution

**Before** (v0.12.x):
```yaml
model: google:gemini-2.5-flash
```

**After** (v0.13.0+):
```yaml
# Option 1: Keep single model (backward compatible)
model: google:gemini-2.5-flash

# Option 2: Use multi-model array
models:
  - google:gemini-2.5-flash
  - openai:gpt-4
```

Both formats supported. No breaking changes.

## Configuration Reference

### Environment Variables

**ACE_REVIEW_MAX_CONCURRENT_MODELS** (optional):
- Controls maximum concurrent model executions
- Default: 3
- Example: `export ACE_REVIEW_MAX_CONCURRENT_MODELS=5`

**ACE_LLM_FALLBACK_ENABLED**:
- Inherited from ace-llm
- Controls provider fallback behavior
- Default: true

### Session Metadata

Multi-model execution enhances metadata with per-model information:

```yaml
# .cache/ace-review/sessions/review-{timestamp}/metadata.yml
timestamp: "2025-12-01T17:55:00Z"
preset: "pr"
models:
  - name: "google:gemini-2.5-flash"
    status: "success"
    duration: 2.3
    output_file: "review-gemini-2.5-flash.md"
  - name: "openai:gpt-4"
    status: "success"
    duration: 4.1
    output_file: "review-gpt-4.md"
  - name: "anthropic:claude-sonnet"
    status: "failed"
    error: "API rate limit exceeded"
total_duration: 4.1  # Max of all concurrent executions
success_count: 2
failure_count: 1
```
