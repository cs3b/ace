---
id: v.0.9.0+task.042
status: done
priority: high
estimate: 30 minutes
dependencies: []
---

# Fix ace-git-commit API key loading from .ace/.env cascade

## Behavioral Context

**Issue**: ace-git-commit was failing with "No API key found for google" even though GOOGLE_API_KEY was properly configured in `~/.ace/.env`.

**Key Behavioral Requirements**:
- API keys should be loaded from `.ace/.env` files when not in ENV
- Global ENV should not be polluted with all variables from .env files
- Keys should be loaded on-demand when requested

## Objective

Fixed ace-llm's EnvReader to load API keys from `.ace/.env` cascade on-demand without polluting the global ENV.

## Scope of Work

- Modified `EnvReader.get_api_key` to check cascade when key not in ENV
- Added `load_env_cascade_without_setting` method for clean loading
- Updated `load_env_cascade` to not set ENV by default

### Deliverables

#### Create
- `ace-llm/lib/ace/llm/atoms/env_reader.rb::load_env_cascade_without_setting` method

#### Modify
- `ace-llm/lib/ace/llm/atoms/env_reader.rb` - Updated get_api_key and load_env_cascade methods

## Implementation Summary

### What Was Done

- **Problem Identification**: ace-git-commit couldn't find API keys because EnvReader only checked ENV, not .ace/.env files
- **Investigation**: Found that `load_env_cascade` was defined but never called automatically
- **Solution**: Modified `get_api_key` to load from cascade on-demand without setting ENV
- **Validation**: Tested ace-git-commit successfully with dry run

### Technical Details

The fix modified `EnvReader.get_api_key` to:
1. First check ENV for the key
2. If not found, load vars from `.ace/.env` cascade (without setting to ENV)
3. Check loaded vars for the key
4. Return the key if found

This maintains clean ENV isolation while allowing tools to access keys from `.ace/.env` files.

### Testing/Validation

```bash
# Tested ace-git-commit with the fix
bundle exec ace-git-commit --dry-run -i "Fixed API key loading"
```

**Results**: Successfully generated commit message using Gemini API with key from ~/.ace/.env

## References

- Commits: 95ad9402 - "fix(ace-llm): load API keys from .ace/.env on demand without polluting ENV"
- Related tasks: Led to task.043 for proper refactoring
- Follow-up needed: Refactor to centralize in ace-core (completed in task.043)