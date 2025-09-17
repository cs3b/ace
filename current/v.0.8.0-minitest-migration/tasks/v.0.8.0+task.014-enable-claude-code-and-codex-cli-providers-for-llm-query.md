---
id: v.0.8.0+task.014
status: done
priority: high
estimate: 2h
dependencies: []
---

# Enable Claude Code and Codex CLI providers for llm-query and code-review

## Behavioral Context

**Issue**: The Claude Code (cc) and Codex CLI providers were implemented but not being discovered by the provider registration system, preventing their use with llm-query and code-review commands.

**Key Behavioral Requirements**:
- Claude Code CLI provider (cc:opus, cc:sonnet, cc:haiku) should be available for llm-query
- Codex CLI provider (codex:gpt-5, codex:mini) should be available for llm-query
- Code review presets should support using these CLI-based providers
- Clear separation between API-based and CLI-based LLM providers

## Objective

Fixed provider discovery mechanism to enable CLI-based LLM providers (Claude Code and Codex) alongside API-based providers, allowing developers to use their preferred LLM tools for code review and queries.

## Scope of Work

- Fixed provider discovery to search in nested directories (`organisms/llm/*/*_client.rb`)
- Reorganized directory structure for clarity (local → cli for CLI-based providers)
- Added missing method implementation for provider class name resolution
- Fixed broken require paths in base client classes
- Added aliases for convenient access to CLI providers
- Created specialized code review presets for Opus and Codex

### Deliverables

#### Create
- None (all files existed, only fixes and moves)

#### Modify
- `lib/ace_tools/molecules/provider_model_parser.rb` - Fixed provider discovery
- `lib/ace_tools/organisms/llm/base/base_client.rb` - Fixed require paths
- `lib/ace_tools/molecules/http/http_client.rb` - Fixed syntax error
- `.coding-agent/llm-aliases.yml` - Added CLI provider aliases
- `.coding-agent/code-review.yml` - Added Opus and Codex presets

#### Move
- `lib/ace_tools/organisms/llm/local/lmstudio_client.rb` → `llm/api/` (uses API, not CLI)
- `lib/ace_tools/organisms/llm/local/` → `llm/cli/` (renamed for clarity)

## Implementation Summary

### What Was Done

- **Problem Identification**: Provider discovery was only searching for `*_client.rb` directly in organisms/ directory, missing nested subdirectories
- **Investigation**: Found that ClaudeCodeClient and CodexClient existed but weren't being loaded due to incorrect glob pattern
- **Solution**:
  1. Updated glob pattern to `organisms/llm/*/*_client.rb`
  2. Added missing `filename_to_class_name` method with proper acronym handling
  3. Fixed require logic to properly load nested client files
  4. Fixed broken require_relative paths in base_client.rb
  5. Fixed syntax error in http_client.rb (missing end statement)
- **Validation**: Successfully tested both providers with llm-query and code-review commands

### Technical Details

Key changes to provider discovery:
```ruby
# Before: Only searched top-level
client_files = Dir.glob(File.join(organisms_path, "*_client.rb"))

# After: Searches nested LLM subdirectories
client_files = Dir.glob(File.join(organisms_path, "llm", "*", "*_client.rb"))

# Added proper file loading
require file.sub(/^#{Regexp.escape(organisms_path)}\//, "ace_tools/organisms/")
```

Added filename to class name conversion:
```ruby
def filename_to_class_name(filename)
  parts = filename.split('_')
  parts.map do |part|
    case part.downcase
    when 'api' then 'API'
    when 'openai' then 'OpenAI'
    when 'togetherai' then 'TogetherAI'
    when 'lmstudio' then 'LMStudio'
    else part.capitalize
    end
  end.join
end
```

### Testing/Validation

```bash
# Test Claude Code provider
llm-query cc:opus "say hi"
# Result: ✅ Successfully returned response from Claude Opus

# Test Codex provider
llm-query codex:gpt-5 "say hello"
# Result: ✅ Successfully returned response from Codex GPT-5

# Test code review presets
code-review --preset opus-deep --dry-run
# Result: ✅ Correctly configured with cc:opus model

code-review --preset codex-comprehensive --dry-run
# Result: ✅ Correctly configured with codex:gpt-5 model

# Test aliases
llm-query copus "hello"  # ✅ Works
llm-query codex "hello"  # ✅ Works
```

**Results**: All CLI providers now properly discovered and functional. Code review can leverage both Claude Code and Codex for comprehensive analysis.

## References

- Related issue: Provider discovery failing for nested client files
- Documentation: Updated llm-aliases.yml and code-review.yml configurations
- Follow-up needed: Consider creating wrapper scripts for quick access (e.g., `code-review-opus`, `code-review-codex`)