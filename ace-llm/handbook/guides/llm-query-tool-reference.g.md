# LLM Query Tool Reference Guide

## Purpose

This guide provides comprehensive documentation for the `llm-query` tool, covering all available parameters, usage patterns, provider-specific considerations, and best practices. This reference ensures that team members understand the full capabilities of the tool and can use it effectively in workflows.

## Tool Overview

The `llm-query` tool is a unified CLI interface for querying multiple LLM providers. It consolidates provider-specific logic into a single command with consistent parameter syntax across all supported providers.

### Basic Syntax

```bash
llm-query PROVIDER_MODEL PROMPT [OPTIONS]
```

### Quick Examples

```bash
# Basic query
llm-query google:gemini-2.5-flash "What is Ruby programming language?"

# With system prompt and output
llm-query anthropic:claude-sonnet-4-20250514 "Review this code" \
  --system system.md \
  --output review.md \
  --timeout 300

# Using alias with file input
llm-query gflash prompt.txt --format json --output response.json
```

## Parameter Reference

### Required Arguments

#### `PROVIDER_MODEL`

Specifies the LLM provider and model to use.

**Format Options:**

- `provider:model` - Full specification (e.g., `google:gemini-2.5-flash`)
- `provider` - Provider only, uses default model (e.g., `google`)
- `alias` - Predefined alias (e.g., `gflash`)

**Supported Providers:**

- `google` - Google Gemini models
- `anthropic` - Anthropic Claude models
- `openai` - OpenAI GPT models
- `mistral` - Mistral AI models
- `togetherai` - Together AI models
- `lmstudio` - Local LM Studio models

#### `PROMPT`

The prompt text or file path to process.

**Input Types:**

- **Direct text**: `"What is Ruby programming language?"`
- **File path**: `prompt.txt` (auto-detected based on file existence)
- **Stdin**: Use `-` to read from stdin

### Optional Parameters

#### `--system` / System Instructions

Specify system instructions/prompts separately from user prompts.

**Format:** `--system VALUE`
**Type:** String
**Input Types:**

- **Direct text**: `--system "You are a helpful assistant"`
- **File path**: `--system system.md` (auto-detected)

**Usage:**

```bash
# Direct system prompt
llm-query google:gemini-2.5-pro "Explain quantum computing" \
  --system "You are a physics professor. Be precise and educational."

# System prompt from file
llm-query anthropic:claude-sonnet-4-20250514 "Review this code" \
  --system tmpl://review-code/system
```

#### `--output` / `-o` / File Output

Direct output to a file with automatic format detection.

**Format:** `--output FILEPATH` or `-o FILEPATH`
**Type:** String
**Benefits:**

- Captures cost information and usage metrics
- Enables cost tracking and optimization
- Prevents output truncation issues
- Supports format inference from file extension

**Usage:**

```bash
# Auto-detect format from extension
llm-query gflash "Generate README" --output README.md

# Explicit format override
llm-query csonet "Data analysis" --output report.txt --format json
```

#### `--format` / Output Format

Override output format (normally inferred from file extension).

**Format:** `--format VALUE`
**Type:** String
**Values:** `text`, `json`, `markdown`
**Default:** Inferred from file extension or `text`

**Usage:**

```bash
# Force JSON output despite .txt extension
llm-query openai:gpt-4o "Generate data" --output data.txt --format json

# Explicit markdown formatting
llm-query google "Write tutorial" --format markdown
```

#### `--temperature` / Creativity Control

Control randomness/creativity in responses.

**Format:** `--temperature VALUE`
**Type:** Float
**Range:** 0.0 - 2.0
**Default:** Provider-specific (typically 0.7)

**Guidelines:**

- `0.0-0.3` - Deterministic, factual responses
- `0.4-0.7` - Balanced creativity and consistency
- `0.8-1.0` - Creative writing, brainstorming
- `1.1-2.0` - Highly creative, experimental

**Usage:**

```bash
# Deterministic code review
llm-query anthropic:claude-sonnet-4-20250514 "Review code" --temperature 0.2

# Creative writing
llm-query google:gemini-2.5-pro "Write a story" --temperature 1.2
```

#### `--max-tokens` / Output Length Control

Limit maximum output tokens.

**Format:** `--max-tokens VALUE`
**Type:** Integer
**Default:** Provider-specific

**Provider Limits:**

- Google Gemini: 8,192 tokens (default)
- Anthropic Claude: 4,096 tokens (default)
- OpenAI GPT: Model-dependent

**Usage:**

```bash
# Short summary
llm-query gflash "Summarize this document" --max-tokens 150

# Long-form content
llm-query copus "Write detailed analysis" --max-tokens 4096
```

#### `--timeout` / Request Timeout

Set request timeout in seconds.

**Format:** `--timeout VALUE`
**Type:** Integer
**Default:** Provider-specific
**Recommended:** 300-500 seconds for large content

**Usage:**

```bash
# Extended timeout for large documents
llm-query anthropic:claude-sonnet-4-20250514 "$(cat large-doc.md)" \
  --timeout 500 \
  --output analysis.md

# Quick timeout for simple queries
llm-query gflash "Quick question" --timeout 30
```

#### `--debug` / `-d` / Debug Output

Enable verbose debug information.

**Format:** `--debug` or `-d`
**Type:** Boolean
**Default:** `false`

**Debug Information:**

- API request/response details
- Error stack traces
- Parameter validation details
- Provider-specific debugging

**Usage:**

```bash
# Debug API issues
llm-query google:gemini-2.5-flash "Test query" --debug

# Debug with output file
llm-query csonet "Analysis" --output result.md --debug
```

#### `--force` / `-f` / Force Overwrite

Force overwrite existing output files without confirmation.

**Format:** `--force` or `-f`
**Type:** Boolean
**Default:** `false`

**Use Cases:**

- CI/CD automation (non-interactive environments)
- Batch processing workflows
- Overwriting previous analysis results

**Usage:**

```bash
# Automation-friendly
llm-query anthropic:claude-sonnet-4-20250514 "Update analysis" \
  --output existing-report.md \
  --force

# Interactive workflow (prompts for confirmation)
llm-query gflash "New content" --output existing.md
```

## Provider-Specific Features

### Google Gemini

**Provider ID:** `google`
**API Key:** `GOOGLE_API_KEY` environment variable
**Aliases:**

- `gflash` → `google:gemini-2.5-flash`
- `gpro` → `google:gemini-2.5-pro`

**Available Models:**

- `gemini-2.5-flash` - Fast, efficient model
- `gemini-2.5-pro` - High-capability model

**Capabilities:**

- Large context windows
- Multimodal support (text)
- Fast response times

**Usage:**

```bash
# Using full specification
llm-query google:gemini-2.5-flash "Quick question"

# Using provider default
llm-query google "Question with default model"

# Using alias
llm-query gflash "Fast response needed"
```

### Anthropic Claude

**Provider ID:** `anthropic`
**API Key:** `ANTHROPIC_API_KEY` environment variable
**Aliases:**

- `csonet` → `anthropic:claude-sonnet-4-20250514`
- `copus` → `anthropic:claude-4-0-opus-latest`

**Available Models:**

- `claude-sonnet-4-20250514` - Balanced performance
- `claude-4-0-opus-latest` - Highest capability

**Capabilities:**

- Superior reasoning and analysis
- Excellent code understanding
- Strong safety alignment

**Usage:**

```bash
# High-quality analysis
llm-query anthropic:claude-sonnet-4-20250514 "Analyze this code"

# Using alias for convenience
llm-query csonet "Complex reasoning task"
```

### OpenAI GPT

**Provider ID:** `openai`
**API Key:** `OPENAI_API_KEY` environment variable
**Aliases:**

- `o4mini` → `openai:gpt-4o-mini`

**Available Models:**

- `gpt-4o` - Latest high-capability model
- `gpt-4o-mini` - Efficient model
- `gpt-3.5-turbo` - Fast, cost-effective

**Capabilities:**

- Strong general knowledge
- Good creative writing
- Reliable performance

### Other Providers

**Mistral AI:** `mistral`
**Together AI:** `togetherai`
**LM Studio:** `lmstudio` (local models)

Each provider follows the same parameter patterns with provider-specific defaults.

## Usage Patterns

### Pattern 1: Basic Query

**Use Case:** Simple question-answer interactions

```bash
llm-query gflash "What is the capital of France?"
```

### Pattern 2: System Prompt with File Input

**Use Case:** Structured analysis with context

```bash
llm-query anthropic:claude-sonnet-4-20250514 "$(cat document.md)" \
  --system "You are a technical reviewer. Focus on accuracy and clarity." \
  --output review.md
```

### Pattern 3: Code Review Workflow

**Use Case:** Systematic code analysis

```bash
llm-query csonet "$(git diff HEAD~1..HEAD)" \
  --system tmpl://review-code/system \
  --timeout 500 \
  --output code-review.md
```

### Pattern 4: Batch Processing

**Use Case:** Processing multiple files

```bash
for file in docs/*.md; do
  llm-query gpro "$(cat "$file")" \
    --system "Summarize this document in 2-3 sentences." \
    --output "summaries/$(basename "$file" .md)-summary.md" \
    --force
done
```

### Pattern 5: Creative Writing

**Use Case:** Content generation

```bash
llm-query google:gemini-2.5-pro "Write a technical blog post about Docker" \
  --temperature 0.8 \
  --max-tokens 2000 \
  --output blog-post.md
```

### Pattern 6: Data Analysis

**Use Case:** Structured data processing

```bash
llm-query openai:gpt-4o "$(cat data.json)" \
  --system "Analyze this data and provide insights in JSON format." \
  --format json \
  --output analysis.json
```

## Best Practices

### System Prompt Separation

**Always use `--system` flag for system instructions:**

```bash
# ✅ CORRECT: Separate system and user prompts
llm-query csonet "Review this function" \
  --system "You are a senior developer. Focus on best practices."

# ❌ AVOID: Embedding system instructions in user prompt
llm-query csonet "You are a senior developer. Review this function..."
```

**Benefits:**

- Cleaner prompt structure
- Better model understanding
- Consistent results
- Easier prompt management

### Output and Cost Tracking

**Use `--output` flag for important results:**

```bash
# ✅ CORRECT: Direct file output with cost tracking
llm-query gpro "Generate report" \
  --output report.md \
  --timeout 300

# ❌ SUBOPTIMAL: Manual redirection loses cost information
llm-query gpro "Generate report" > report.md
```

**Benefits:**

- Cost information captured
- Usage metrics available
- No output truncation
- Better error handling

### Timeout Management

**Set appropriate timeouts for content size:**

```bash
# Large documents need extended timeouts
llm-query anthropic:claude-sonnet-4-20250514 "$(cat large-handbook.md)" \
  --timeout 500 \
  --output analysis.md

# Quick queries can use shorter timeouts
llm-query gflash "Simple question" --timeout 30
```

### Provider Selection

**Choose providers based on task requirements:**

- **Analysis/Reasoning:** `anthropic:claude-sonnet-4-20250514`
- **Fast responses:** `google:gemini-2.5-flash`
- **Creative writing:** `google:gemini-2.5-pro`
- **General purpose:** `openai:gpt-4o`

### Error Handling

**Use `--debug` flag for troubleshooting:**

```bash
# Debug API issues
llm-query provider:model "query" --debug --output result.md
```

**Use `--force` in automation:**

```bash
# Prevent interactive prompts in CI/CD
llm-query csonet "Analysis" --output report.md --force
```

## Troubleshooting

### Common Issues

#### Authentication Errors

**Symptoms:**

- `401 Unauthorized` responses
- "Invalid API key" messages
- Authentication failures

**Solutions:**

1. Verify environment variables are set:

   ```bash
   echo $GOOGLE_API_KEY
   echo $ANTHROPIC_API_KEY
   echo $OPENAI_API_KEY
   ```

2. Check API key format and permissions
3. Test with simple query first
4. Review provider documentation for key requirements

#### Rate Limiting

**Symptoms:**

- `429 Too Many Requests` responses
- "Rate limit exceeded" messages
- Slow response times

**Solutions:**

1. Implement delays between requests
2. Use different providers for load distribution
3. Check API quotas and limits
4. Use lighter models for high-frequency requests

#### Timeout Issues

**Symptoms:**

- Operations hang or timeout
- Large content processing failures
- Context length exceeded errors

**Solutions:**

1. Increase timeout for large content:

   ```bash
   llm-query provider:model "large-content" --timeout 600
   ```

2. Split large content into smaller chunks
3. Use summarization for oversized inputs
4. Switch to higher-capacity models

#### File Output Issues

**Symptoms:**

- Cannot write to output file
- Permission denied errors
- File overwrite prompts

**Solutions:**

1. Check directory permissions
2. Use `--force` flag in automation
3. Verify output directory exists
4. Use absolute file paths

#### Provider Availability

**Symptoms:**

- Unknown provider errors
- Model not available messages
- Connection failures

**Solutions:**

1. Check provider status pages
2. Verify model names and availability
3. Use alternative providers as fallbacks
4. Check network connectivity

### Debugging Commands

**Get available providers and models:**

```bash
llm-query --help
```

**Test authentication:**

```bash
llm-query google "test" --debug
```

**Validate provider:model combinations:**

```bash
llm-query google:gemini-2.5-flash "validation test"
```

## Workflow Integration

### Review Code Workflow

The `llm-query` tool is used extensively in the review-code workflow:

**File:** `wfi://review/run`

**Usage Pattern:**

```bash
# Multi-Model LLM Execution (lines 331, 344)
llm-query google:gemini-2.5-pro \
    "$(cat "${SESSION_DIR}/prompt.md")" \
    --system "${SYSTEM_PROMPT_PATH}" \
    --timeout 500 \
    --output "${SESSION_DIR}/cr-report-gpro.md"

llm-query anthropic:claude-3-opus-20240229 \
    "$(cat "${SESSION_DIR}/prompt.md")" \
    --system "${SYSTEM_PROMPT_PATH}" \
    --timeout 500 \
    --output "${SESSION_DIR}/cr-report-opus.md"
```

### Handbook Review Command

**Canonical source:** `ace-handbook/handbook/skills/`

Provider integrations may project these canonical skill definitions into folders such as
`.claude/skills/`, but the source of truth lives under package `handbook/skills/` directories.

**Usage Pattern:**

```bash
# Pre-configured system prompt and parameters
system-prompt: dev-local/handbook/tpl/review/system.prompt.md
timeout: 500 seconds
output: Direct file output with cost tracking
```

### Template Files

**System Prompt Templates:**

- `tmpl://review-code/system`
- `tmpl://review-test/system`
- `tmpl://review-docs/system`

**Usage in Workflows:**

```bash
SYSTEM_PROMPT_PATH="tmpl://review-docs/system"
llm-query csonet "content" --system "${SYSTEM_PROMPT_PATH}"
```

## Related Documentation

- **Tool Source:** `llm-query`

- **Usage Examples:** `dev-tools/README.md`

## Version Information

This documentation covers the llm-query tool as of the current dev-tools implementation. For the latest features and updates, refer to the tool's help output:
```bash
llm-query --help
```
