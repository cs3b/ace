# Provider Allow-List Filtering - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Configure active providers in project config

**Goal**: Restrict a project to only use approved LLM providers

```yaml
# .ace/llm/config.yml
llm:
  providers:
    active:
      - google
      - anthropic
      - openai
```

```bash
ace-llm --list-providers

# Expected output:
# Available LLM Providers (filtered — 3 of 26 active):
#
# ✓ anthropic (API key configured)
#   Models: claude-3-5-sonnet, claude-3-haiku
#
# ✓ google (API key configured)
#   Models: gemini-2.5-flash, gemini-2.0-flash-lite
#
# ✓ openai (API key configured)
#   Models: gpt-4, gpt-4o-mini
#
# Inactive providers (23):
#   claude, codex, deepseek, gemini, mistral, ...
```

### Scenario 2: Override via environment variable

**Goal**: Temporarily restrict to a single provider for testing

```bash
ACE_LLM_PROVIDERS_ACTIVE=google ace-llm --list-providers

# Expected output:
# Available LLM Providers (filtered — 1 of 26 active):
#
# ✓ google (API key configured)
#   Models: gemini-2.5-flash, gemini-2.0-flash-lite
#
# Inactive providers (25):
#   anthropic, claude, codex, deepseek, ...
```

### Scenario 3: Query an inactive provider (error)

**Goal**: User gets clear guidance when trying to use a filtered-out provider

```bash
ACE_LLM_PROVIDERS_ACTIVE=google ace-llm deepseek:deepseek-chat "Hello"

# Expected output:
# Error: Provider 'deepseek' is inactive. It exists but is not in llm.providers.active.
# To enable it, add 'deepseek' to llm.providers.active in your config.
# Active providers: google
```

### Scenario 4: No filter configured (backward compatible)

**Goal**: Without any `active` config, behavior is identical to today

```bash
# No llm.providers.active in any config file
ace-llm --list-providers

# Expected output: identical to current behavior
# Available LLM Providers:
#
# ✓ anthropic (API key configured)
#   Models: ...
# ...all 26 providers listed...
```

### Scenario 5: Empty active list (backward compatible)

**Goal**: Explicit empty list treated as "no filter"

```yaml
# .ace/llm/config.yml
llm:
  providers:
    active: []
```

```bash
ace-llm --list-providers

# Expected output: identical to current behavior (all providers shown)
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
- Provider name normalization must match `ClientRegistry#normalize_provider_name` (downcase, strip `-_`)
- The "inactive" vs "unknown" error distinction is a key UX requirement
