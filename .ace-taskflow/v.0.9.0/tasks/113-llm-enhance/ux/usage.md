# LLM Provider Fallback - Usage Guide

## Overview

The LLM provider fallback feature ensures your ace-* tools continue working even when your primary LLM provider experiences issues. When a provider returns errors (503 overloaded, rate limits, timeouts), the system automatically retries and/or switches to alternative providers without interrupting your workflow.

**Key Benefits:**
- Automatic recovery from temporary provider outages
- Transparent fallback to alternative providers
- Clear status messages about retry attempts
- Configurable retry behavior and fallback chains
- No changes required to existing commands

## Configuration

### Basic Configuration

Create or update `.ace/llm/config.yml` in your project:

```yaml
# Enable fallback globally
fallback:
  enabled: true
  retry_count: 3              # Number of retries before fallback
  retry_delay: 1.0            # Initial delay in seconds (exponential backoff)
  providers:                  # Fallback chain in priority order
    - claude-3.5-sonnet
    - gpt-4
    - gemini-1.5-pro
```

### Per-Provider Configuration

You can also configure fallback chains per provider:

```yaml
# In .ace/llm/providers/google.yml
fallback:
  providers:
    - anthropic:haiku       # Try Anthropic Haiku if Google fails
    - openai:gpt-4-turbo    # Then try GPT-4 Turbo
```

### Disable Fallback

To disable fallback for specific commands:

```yaml
fallback:
  enabled: false
```

Or via environment variable:
```bash
ACE_LLM_FALLBACK_ENABLED=false ace-llm-query "prompt"
```

## Usage Scenarios

### Scenario 1: Primary Provider Overloaded

**Goal:** Generate a commit message when Google Gemini returns 503 error

```bash
# Normal command - no changes needed
$ ace-git-commit

# What you see when primary provider fails:
Staging all changes...
✓ Changes staged successfully
Generating commit message...
⚠ gemini-2.0-exp unavailable (503), retrying... (attempt 2/3)
⚠ gemini-2.0-exp unavailable (503), retrying... (attempt 3/3)
ℹ gemini-2.0-exp unavailable, trying fallback provider claude-3.5-sonnet...
✓ Message generated using claude-3.5-sonnet
Committing...
✓ Commit created: feat(search): Add advanced pattern matching
```

The commit completes successfully using the fallback provider.

### Scenario 2: Rate Limit with Retry-After

**Goal:** Run code review when hitting rate limits

```bash
$ ace-review --preset pr

# Output with rate limit handling:
Analyzing changes...
⚠ openai:gpt-4 rate limited, waiting 5s (retry-after header)...
✓ Retry successful
Running code review...
[Review results displayed]
```

The system respects rate limit headers and waits before retrying.

### Scenario 3: Authentication Error Skip

**Goal:** Query with expired API key

```bash
$ ace-llm-query "Explain Ruby modules" -m anthropic:opus

# Output with auth error:
⚠ anthropic:opus authentication failed (401), skipping...
ℹ Trying fallback provider google:gemini-1.5-pro...
✓ Response from google:gemini-1.5-pro:

Ruby modules are a way to group methods, classes, and constants together...
```

Authentication errors skip immediately to the next provider without retry.

### Scenario 4: Explicit Fallback Chain

**Goal:** Specify custom fallback chain for a specific operation

```bash
# Use environment variable for one-off fallback chain
$ ACE_LLM_FALLBACK_PROVIDERS="openai:gpt-3.5-turbo,anthropic:haiku" \
  ace-llm-query "Quick summary of Docker"

# Or configure in project:
# .ace/llm/config.yml
fallback:
  providers:
    - openai:gpt-3.5-turbo
    - anthropic:haiku
```

### Scenario 5: All Providers Fail

**Goal:** Understand what happens when all providers are unavailable

```bash
$ ace-git-commit

# Output when all providers fail:
Generating commit message...
⚠ gemini-2.0-exp unavailable (503), retrying... (attempt 2/3)
⚠ gemini-2.0-exp unavailable (503), retrying... (attempt 3/3)
ℹ gemini-2.0-exp unavailable, trying fallback provider claude-3.5-sonnet...
⚠ claude-3.5-sonnet unavailable (503), trying next provider...
ℹ Trying fallback provider gpt-4...
⚠ gpt-4 unavailable (503), trying next provider...

Error: All configured providers unavailable.
Try:
  - Check provider status pages
  - Configure additional providers
  - Retry in a few minutes
  - Run with --debug for detailed errors
```

### Scenario 6: Monitoring Fallback Events

**Goal:** Track when fallback is being used

```bash
# Enable debug logging to see fallback details
$ ACE_LLM_DEBUG=true ace-llm-query "test" 2>llm-debug.log

# Check logs for fallback events
$ grep "fallback" llm-debug.log
[2025-11-16 14:30:22] INFO: Primary provider gemini failed, attempting fallback
[2025-11-16 14:30:23] INFO: Fallback to claude-3.5-sonnet successful
[2025-11-16 14:30:23] INFO: Response delivered from fallback provider
```

## Command Reference

### ace-llm-query with Fallback

```bash
ace-llm-query "prompt" [options]
  -m, --model PROVIDER:MODEL    # Primary provider (fallback automatic)
  --show-config                 # Display current fallback configuration
  --debug                       # Show detailed fallback attempts
```

**Internal Implementation:** Uses QueryInterface with FallbackOrchestrator

### ace-git-commit with Fallback

```bash
ace-git-commit [options]
  # Fallback handled automatically based on config
  # No command changes needed
```

**Internal Implementation:** Inherits fallback from ace-llm QueryInterface

### ace-review with Fallback

```bash
ace-review --preset PR [options]
  # Fallback handled automatically
  # Preset-specific providers respected
```

**Internal Implementation:** Preset providers use fallback chains

## Tips and Best Practices

### Optimal Configuration

1. **Order providers by reliability**: Place most stable providers first
2. **Mix provider types**: Combine different vendors for better resilience
3. **Set reasonable retry counts**: 2-3 retries is usually sufficient
4. **Use exponential backoff**: Prevents overwhelming recovering services

### Performance Considerations

- First fallback attempt adds ~1-2 seconds
- Each additional fallback adds provider connection time
- Total timeout limited to 30 seconds across all attempts
- Consider provider response times when ordering fallback chain

### Troubleshooting

**Issue:** Fallback not working
- Check: Is fallback enabled in config?
- Check: Are fallback providers configured with valid API keys?
- Run with `--debug` to see detailed error messages

**Issue:** Too many retries slowing down commands
- Reduce `retry_count` in configuration
- Decrease `retry_delay` for faster failures
- Consider removing slow providers from chain

**Issue:** Unexpected provider being used
- Check fallback chain order in configuration
- Verify primary provider credentials are valid
- Look for rate limit issues on primary provider

### Cost Management

When using fallback, be aware of potential cost differences:

```yaml
# Cost-conscious configuration
fallback:
  providers:
    - anthropic:haiku      # Lowest cost
    - openai:gpt-3.5-turbo # Medium cost
    - anthropic:opus       # High cost (last resort)
```

## Migration Notes

### From Manual Provider Switching

**Before (manual switching on failure):**
```bash
# Try primary
$ ace-llm-query "prompt" -m gemini
Error: Provider unavailable

# Manually retry with different provider
$ ace-llm-query "prompt" -m claude
Success!
```

**After (automatic fallback):**
```bash
# Single command with automatic fallback
$ ace-llm-query "prompt" -m gemini
# Automatically falls back to claude on failure
Success!
```

### Key Differences
- No need to manually retry with different providers
- Automatic exponential backoff on retries
- Clear status messages about what's happening
- Configuration-driven fallback chains
- Same commands work with added resilience