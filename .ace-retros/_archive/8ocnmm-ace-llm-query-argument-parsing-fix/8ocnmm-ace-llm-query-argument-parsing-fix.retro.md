---
id: 8ocnmm
title: ace-llm Query Command Argument Parsing Fix
type: standard
tags: []
created_at: '2026-01-13 15:45:07'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8ocnmm-ace-llm-query-argument-parsing-fix.md"
---

# Reflection: ace-llm Query Command Argument Parsing Fix

**Date**: 2026-01-13
**Context**: Fix for ambiguous argument handling in ace-llm query command when --model flag doesn't contain colon
**Author**: cs3b
**Type**: Standard

## What Went Well

- Root cause analysis identified that "grok" was a configured alias, not a plain model name
- Solution added proper validation using ClientRegistry to check if positional arg is a valid provider
- All 269 tests passed after the fix
- Clean separation between code fix and test improvement

## What Could Be Improved

- Test design: The test used "grok" (an alias) when it should have used a non-alias value
- Initial fix attempts were too broad (checking for ":" instead of validating against actual providers)
- Multiple iterations needed to understand the alias resolution behavior
- Test performance: Commands tests taking 24s, likely making real API calls instead of using mocks

## Key Learnings

- **Global Aliases Exist**: The ace-llm package has global aliases configured in `.ace-defaults/llm/providers/xai.yml`:
  - `grok` → `xai:grok-4`
  - `grokfast` → `xai:grok-4-1-fast`
  - `grokcode` → `xai:grok-code-fast-1`
- **Alias Resolution Happens Early**: The `resolve_alias_if_needed()` method converts aliases before validation, which affects code flow
- **Provider Registry as Source of Truth**: When validating providers, use `ClientRegistry#available_providers` instead of guessing from string patterns
- **Test Value Selection Matters**: Tests for "ambiguous" cases must use values that are truly ambiguous (not aliases)

## Technical Details

### The Bug

When `--model` flag is used with a value that doesn't contain ":" (like `--model unknown-model test`), and the first positional argument is not a valid provider, the command would proceed with invalid input instead of showing help.

### The Fix

Added validation in `extract_provider_model_and_prompt()`:

```ruby
# When --model doesn't contain ":" and positional arg exists
if args.first && !args.first.include?(":")
  # Check if first arg is a valid provider
  registry = Ace::LLM::Molecules::ClientRegistry.new
  unless registry.available_providers.include?(args.first)
    # Not a valid provider - ambiguous case
    return [nil, nil]
  end
end
```

### Files Changed

1. `ace-llm/lib/ace/llm/commands/query.rb` - Added provider validation
2. `ace-llm/test/commands/query_command_test.rb` - Fixed test to use "unknown-model" instead of "grok"

## Action Items

### Stop Doing

- Using configured aliases as test values for "invalid" input cases
- Guessing validity based on string patterns (like checking for ":") instead of consulting the registry

### Continue Doing

- Running full test suite after fixes (269 tests all passed)
- Using `ClientRegistry#available_providers` for provider validation

### Start Doing

- **Priority**: Investigate test performance issue (commands tests taking 24s)
  - Set up VCR/webmock for recording API responses
  - Configure default test model (claude:haiku for cheapest option)
  - Update tests to use mocks instead of real API calls
- Review global aliases before designing test cases
- Document available aliases in test helpers for reference

## Additional Context

- **Task**: 205 (Fix xAI API Response Parsing Error)
- **PR**: #154 (fix(llm): handle non-JSON xAI API error responses)
- **Version Bump**: ace-llm 0.20.1 → 0.20.2
- **CHANGELOG**: Main project updated to 0.9.295