# ace-llm-models sync-providers Usage

## Overview

Sync provider model lists with models.dev API to keep configurations up-to-date.

## Commands

### sync-providers - Update Provider Configs

```bash
# Preview changes (dry-run is default)
ace-llm-models sync-providers

# Apply changes to provider files
ace-llm-models sync-providers --apply

# Apply and commit changes
ace-llm-models sync-providers --apply --commit

# Sync specific provider only
ace-llm-models sync-providers --provider anthropic
ace-llm-models sync-providers -p openai

# Target specific config directory
ace-llm-models sync-providers --config-dir .ace/llm/providers
```

## Options

| Option | Short | Description |
|--------|-------|-------------|
| `--apply` | | Apply changes to config files (default: dry-run) |
| `--commit` | | Commit changes via ace-git-commit |
| `--provider` | `-p` | Sync specific provider only |
| `--config-dir` | | Target config directory |

## Output Format

```
Syncing provider configs with models.dev...

anthropic:
  + claude-sonnet-4-20250514      (new)
  + claude-opus-4-20250514        (new)
  - claude-3-sonnet-20240229      (deprecated)

  Suggested aliases:
    s4: claude-sonnet-4-20250514
    o4: claude-opus-4-20250514

google:
  + gemini-2.5-pro               (new)
  = gemini-2.0-flash             (unchanged)

openai:
  + gpt-5                        (new)
  + gpt-4.5-turbo               (new)

  Suggested aliases:
    5: gpt-5

Summary: 5 added, 1 removed, 12 unchanged across 3 providers

Run with --apply to update config files.
(Alias suggestions are informational only - add manually if desired)
```

## Typical Workflow

```bash
# 1. Sync models.dev cache first
ace-llm-models sync

# 2. Preview provider updates
ace-llm-models sync-providers

# 3. Apply changes (review diff first)
ace-llm-models sync-providers --apply

# 4. Or apply and commit in one step
ace-llm-models sync-providers --apply --commit
```

## Config Directory Resolution

The command looks for provider configs in this order:
1. `--config-dir` if specified
2. Project `.ace/llm/providers/` if exists
3. Gem's built-in `providers/` (read-only warning)

## Alias Suggestions

Aliases are suggested based on model naming patterns:
- `claude-sonnet-4-*` → `s4`
- `claude-opus-4-*` → `o4`
- `gpt-5` → `5`
- `gemini-2.5-pro` → `2.5p`

Suggestions are **informational only** - add manually to `aliases.model:` section if desired.

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Provider not in models.dev | Skip with warning |
| No changes detected | Report "already up to date" |
| Write permission denied | Error with suggestion to use project config |
| models.dev cache stale | Prompt to run `ace-llm-models sync` first |

## Examples

### Check what would change for all providers
```bash
ace-llm-models sync-providers
```

### Update only Anthropic models
```bash
ace-llm-models sync-providers --provider anthropic --apply
```

### Full sync with commit
```bash
ace-llm-models sync-providers --apply --commit
```

### Sync to project-level config
```bash
ace-llm-models sync-providers --config-dir .ace/llm/providers --apply
```
