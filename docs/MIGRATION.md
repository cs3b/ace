# Migration Guide: Unified LLM Query Command

This guide helps you migrate from the old provider-specific commands to the new unified `llm-query` command syntax introduced in v0.2.0.

## Overview

The unified `llm-query` command replaces all provider-specific executables with a single command using `provider:model` syntax. This provides:

- **Consistent Interface**: Same options and behavior across all providers
- **Easier Learning**: Learn one command instead of multiple
- **Future-Proof**: New providers integrate seamlessly
- **Better Documentation**: All providers documented together

## Command Migration Table

| Old Command | New Unified Command | Notes |
|-------------|-------|--------|
| `llm-google-query` | `llm-query google:gemini-2.5-flash` | Uses latest default model |
| `llm-gemini-query` | `llm-query google:gemini-2.5-flash` | Same as above |
| `llm-anthropic-query` | `llm-query anthropic:claude-4-0-sonnet-latest` | Uses latest Claude model |
| `llm-openai-query` | `llm-query openai:gpt-4o` | Uses GPT-4o as default |
| `llm-mistral-query` | `llm-query mistral:mistral-large` | Uses Mistral Large |
| `llm-together-ai-query` | `llm-query together_ai:meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo` | Uses Llama 3.1 70B |
| `llm-lmstudio-query` | `llm-query lmstudio` | Uses loaded model |

## Migration Examples

### Basic Queries

**Before:**
```bash
llm-google-query "What is Ruby programming?"
llm-anthropic-query "Explain quantum computing"
llm-openai-query "Write a Ruby script"
```

**After:**
```bash
llm-query google:gemini-2.5-flash "What is Ruby programming?"
llm-query anthropic:claude-4-0-sonnet-latest "Explain quantum computing"
llm-query openai:gpt-4o "Write a Ruby script"
```

### With Model Selection

**Before:**
```bash
llm-google-query "Complex task" --model gemini-1.5-pro
llm-anthropic-query "Fast task" --model claude-3-5-haiku-20241022
llm-openai-query "Mini task" --model gpt-4o-mini
```

**After:**
```bash
llm-query google:gemini-1.5-pro "Complex task"
llm-query anthropic:claude-3-5-haiku-20241022 "Fast task"
llm-query openai:gpt-4o-mini "Mini task"
```

### With Advanced Options

**Before:**
```bash
llm-google-query "Creative writing" --temperature 0.9 --max-tokens 500 --format json
llm-anthropic-query "Analysis" --system instructions.md --output report.md
llm-openai-query prompt.txt --debug --output response.json
```

**After:**
```bash
llm-query google:gemini-2.5-flash "Creative writing" --temperature 0.9 --max-tokens 500 --format json
llm-query anthropic:claude-4-0-sonnet-latest "Analysis" --system instructions.md --output report.md
llm-query openai:gpt-4o prompt.txt --debug --output response.json
```

## Step-by-Step Migration

### Step 1: Update Your Scripts

Replace old commands in your scripts:

```bash
# OLD: script.sh
#!/bin/bash
llm-google-query "Summarize this file" < input.txt > summary.txt
llm-anthropic-query "Review code" --system "You are a code reviewer" < code.rb > review.md

# NEW: script.sh
#!/bin/bash
llm-query google:gemini-2.5-flash "Summarize this file" < input.txt > summary.txt
llm-query anthropic:claude-4-0-sonnet-latest "Review code" --system "You are a code reviewer" < code.rb > review.md
```

### Step 2: Update Aliases

If you use shell aliases, update them:

```bash
# OLD aliases in ~/.bashrc or ~/.zshrc
alias gq='llm-google-query'
alias aq='llm-anthropic-query'
alias oq='llm-openai-query'

# NEW aliases
alias gq='llm-query google:gemini-2.5-flash'
alias aq='llm-query anthropic:claude-4-0-sonnet-latest'
alias oq='llm-query openai:gpt-4o'

# Or use the built-in aliases
alias gq='llm-query gflash'    # google:gemini-2.5-flash
alias aq='llm-query csonet'   # anthropic:claude-4-0-sonnet-latest
alias oq='llm-query o4mini'   # openai:gpt-4o-mini
```

### Step 3: Update Documentation

Update your project documentation:

```markdown
<!-- OLD documentation -->
To query Google Gemini:
```bash
llm-google-query "Your prompt here"
```

<!-- NEW documentation -->
To query Google Gemini:
```bash
llm-query google:gemini-2.5-flash "Your prompt here"
```
```

### Step 4: Update CI/CD Pipelines

Update your automation scripts:

```yaml
# OLD: .github/workflows/ai-review.yml
- name: Generate AI review
  run: llm-anthropic-query "Review this PR" --system review-prompt.md > ai-review.md

# NEW: .github/workflows/ai-review.yml
- name: Generate AI review
  run: llm-query anthropic:claude-4-0-sonnet-latest "Review this PR" --system review-prompt.md > ai-review.md
```

## Common Migration Scenarios

### 1. Multi-Provider Scripts

**Before (separate commands):**
```bash
#!/bin/bash
echo "Getting responses from multiple providers..."
llm-google-query "$1" > google-response.txt &
llm-anthropic-query "$1" > anthropic-response.txt &
llm-openai-query "$1" > openai-response.txt &
wait
```

**After (unified command):**
```bash
#!/bin/bash
echo "Getting responses from multiple providers..."
llm-query google:gemini-2.5-flash "$1" > google-response.txt &
llm-query anthropic:claude-4-0-sonnet-latest "$1" > anthropic-response.txt &
llm-query openai:gpt-4o "$1" > openai-response.txt &
wait
```

### 2. Model Comparison Scripts

**Before:**
```bash
#!/bin/bash
PROMPT="$1"
llm-google-query "$PROMPT" --model gemini-1.5-flash > fast-response.txt
llm-google-query "$PROMPT" --model gemini-1.5-pro > quality-response.txt
```

**After:**
```bash
#!/bin/bash
PROMPT="$1"
llm-query google:gemini-1.5-flash "$PROMPT" > fast-response.txt
llm-query google:gemini-1.5-pro "$PROMPT" > quality-response.txt
```

### 3. Conditional Provider Selection

**Before:**
```bash
#!/bin/bash
if [[ "$PROVIDER" == "google" ]]; then
    llm-google-query "$PROMPT"
elif [[ "$PROVIDER" == "anthropic" ]]; then
    llm-anthropic-query "$PROMPT"
elif [[ "$PROVIDER" == "openai" ]]; then
    llm-openai-query "$PROMPT"
fi
```

**After:**
```bash
#!/bin/bash
case "$PROVIDER" in
    google) MODEL="google:gemini-2.5-flash" ;;
    anthropic) MODEL="anthropic:claude-4-0-sonnet-latest" ;;
    openai) MODEL="openai:gpt-4o" ;;
    *) echo "Unknown provider: $PROVIDER"; exit 1 ;;
esac

llm-query "$MODEL" "$PROMPT"
```

### 4. Environment Variable Mapping

**Before:**
```bash
# Different commands needed different environment patterns
export GEMINI_API_KEY="..."      # for llm-google-query
export ANTHROPIC_API_KEY="..."   # for llm-anthropic-query
export OPENAI_API_KEY="..."      # for llm-openai-query
```

**After:**
```bash
# Same environment variables, unified command
export GOOGLE_API_KEY="..."      # for llm-query google:*
export ANTHROPIC_API_KEY="..."   # for llm-query anthropic:*
export OPENAI_API_KEY="..."      # for llm-query openai:*
```

## Backward Compatibility

### Legacy Command Status

The old provider-specific commands have been **removed** in v0.2.0:
- ✅ No breaking changes to options/flags
- ✅ All functionality preserved
- ❌ Old command names no longer exist
- ❌ No automatic fallback or wrapper scripts

### Migration Timeline

- **v0.1.x**: Old provider-specific commands only
- **v0.2.0**: Unified `llm-query` command only (breaking change)
- **Future**: New providers will only be available via unified command

## Validation and Testing

### Test Your Migration

1. **Verify the unified command works:**
   ```bash
   llm-query google:gemini-2.5-flash "test query"
   ```

2. **Test your updated scripts:**
   ```bash
   # Run your scripts with the new commands
   bash your-updated-script.sh
   ```

3. **Validate output consistency:**
   ```bash
   # Compare old vs new output (if you still have old commands)
   llm-query google:gemini-2.5-flash "What is Ruby?" > new-output.txt
   # Should produce equivalent results
   ```

### Common Migration Issues

**Issue: Command not found**
```bash
$ llm-google-query "test"
command not found: llm-google-query
```
**Solution:** Use the unified command:
```bash
$ llm-query google:gemini-2.5-flash "test"
```

**Issue: Wrong model specified**
```bash
$ llm-query google:gpt-4o "test"
Error: Unknown model 'gpt-4o' for provider 'google'
```
**Solution:** Use correct provider:model combination:
```bash
$ llm-query openai:gpt-4o "test"
```

**Issue: Environment variable not found**
```bash
$ llm-query google:gemini-2.5-flash "test"
Error: GOOGLE_API_KEY not found
```
**Solution:** Check your environment variable names:
```bash
# Make sure you're using the correct variable name
export GOOGLE_API_KEY="your-key"  # Not GEMINI_API_KEY
```

## Benefits After Migration

### Improved Developer Experience

1. **Single Command to Learn**: Master one command instead of multiple
2. **Consistent Options**: Same flags work across all providers
3. **Better Error Messages**: Unified error handling and reporting
4. **Easier Scripting**: Simplified conditional logic

### Enhanced Flexibility

1. **Easy Provider Switching**: Change `google:model` to `openai:model`
2. **Model Comparison**: Test same prompt across providers easily
3. **Future-Proof**: New providers integrate without new commands
4. **Aliases**: Use short aliases for frequently used combinations

### Better Documentation

1. **Unified Guide**: All providers documented in one place
2. **Consistent Examples**: Same patterns across all providers
3. **Centralized Troubleshooting**: Common issues and solutions
4. **Cross-Provider Comparisons**: Easy to compare capabilities

## Getting Help

### Check Available Providers and Models

```bash
# See all providers
llm-query --help

# List models for a provider
exe/llm-models google
exe/llm-models anthropic
exe/llm-models openai
```

### Debug Migration Issues

```bash
# Use debug mode to see what's happening
llm-query google:gemini-2.5-flash "test" --debug

# Check environment variables
env | grep API_KEY
```

### Resources

- **[Unified LLM Query Guide](./llm-integration/query.md)** - Complete documentation
- **[Model Management Guide](./llm-integration/model-management.md)** - How to find and use models
- **[Project README](../README.md)** - Quick start and examples
- **[GitHub Issues](https://github.com/your-repo/issues)** - Report migration problems

---

**Need help with migration?** Open an issue with your specific use case and we'll help you convert it to the new syntax.