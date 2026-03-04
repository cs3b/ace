# Prompt Caching Pattern

Standardized pattern for gems that generate prompts for LLM interactions.

## Overview

Gems that generate prompts (ace-review, ace-docs, ace-prompt-prep) use the `PromptCacheManager` from ace-support-core to store prompts in a predictable location for debugging and inspection.

## Directory Structure

```
.cache/
└── {gem-name}/
    └── sessions/
        └── {operation}-{timestamp}/
            ├── system.prompt.md    # System prompt
            ├── user.prompt.md      # User prompt
            └── metadata.yml        # Session metadata (optional)
```

## API Usage

```ruby
require 'ace/core/molecules/prompt_cache_manager'

# Create session directory
session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
  "ace-my-gem",
  "my-operation"
)
# Returns: .ace-local/my-gem/sessions/my-operation-20261116-143022/

# Save prompts
Ace::Core::Molecules::PromptCacheManager.save_system_prompt(
  system_prompt_content,
  session_dir
)

Ace::Core::Molecules::PromptCacheManager.save_user_prompt(
  user_prompt_content,
  session_dir
)

# Save metadata (optional)
metadata = {
  "timestamp" => Time.now.utc.iso8601,
  "gem" => "ace-my-gem",
  "operation" => "my-operation",
  "model" => "google:gemini-2.5-flash",
  "prompt_sizes" => { "system" => 1234, "user" => 5678 }
}
Ace::Core::Molecules::PromptCacheManager.save_metadata(metadata, session_dir)
```

## Benefits

- **Consistent locations**: All prompt caches in predictable `.cache/{gem}/sessions/` structure
- **Standard naming**: `system.prompt.md`, `user.prompt.md` across all gems
- **Git worktree support**: Uses ProjectRootFinder internally
- **Easy debugging**: Inspect exact prompts sent to LLMs
- **Metadata tracking**: Optional standardized metadata format

## Production Examples

| Gem | Usage |
|-----|-------|
| ace-docs | analyze-consistency operation |
| ace-prompt-prep | enhanced prompts with content-based deduplication |
| ace-review | session caching (optional migration to shared utility) |

## Related

- [ace-gems.g.md](../../../docs/ace-gems.g.md) - Gem development overview
- [ADR-022](../../../docs/decisions/ADR-022-configuration-default-and-override-pattern.md) - Configuration patterns
