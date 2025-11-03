# Idea

---
title: Implement Direct Anthropic API Integration in ace-llm with Custom Prompts
filename_suggestion: feat-llm-anthropic-direct-prompts
enhanced_at: 2025-11-03 00:05:58
location: active
llm_model: gflash
---

## Problem
Currently, `ace-llm` may rely on a generic LLM interface or default system prompts, potentially imposed by higher-level integrations like Claude Code. This limits the ability to fully leverage specific LLM provider features, such as Anthropic's distinct `system_prompt` and `user_prompt` structure, for optimized and precise interactions. For tasks requiring high speed and specific output, like generating git commit messages, this lack of direct control can hinder performance and quality. `ace-git-commit`, in particular, could benefit significantly from a streamlined, direct interaction with fast models like Claude Haiku without any intervening default prompts.

## Solution
Enhance the `ace-llm` gem to provide a direct and explicit interface for interacting with Anthropic models (e.g., Claude Haiku). This interface will allow users and agents to specify both a `system_prompt` and a `user_prompt` directly to the Anthropic API, bypassing any default or generic system prompts. This will enable fine-grained control over the LLM's behavior and response generation. The `ace-git-commit` gem will then be updated to utilize this new `ace-llm` capability, demonstrating its effectiveness by generating very fast and accurate git commit messages using Claude Haiku.

## Implementation Approach
1.  **`ace-llm` Gem Enhancement (Organism/Molecule Level)**:
    *   Modify `lib/ace/llm/` to introduce new CLI options or command parameters (e.g., `ace-llm query --provider anthropic --system-prompt "..." --prompt "..."`) that accept distinct `system_prompt` and `user_prompt` arguments.
    *   Within the `ace-llm`'s provider abstraction layer (potentially `ace-llm-providers-cli` or a new `ace-llm-providers-anthropic` if warranted by complexity, following the `ace-llm-providers-*` pattern), ensure that the underlying API calls to Anthropic are constructed precisely with the provided prompts.
    *   Implement robust error handling for Anthropic-specific responses, rate limits, and API errors.
2.  **`ace-git-commit` Integration (Organism Level)**:
    *   Update `ace-git-commit`'s core logic (likely within `lib/ace/git/commit/organisms/` or `commands/`) to call the enhanced `ace-llm` interface.
    *   Define optimized `system_prompt` and `user_prompt` templates within `ace-git-commit/handbook/agents/` or `workflow-instructions/` specifically tailored for generating concise and relevant git commit messages.
    *   Configure `ace-git-commit` to default to the Anthropic provider (e.g., Haiku) when this feature is enabled, potentially via `Ace::Core.config.get('ace', 'git-commit', 'llm_provider')`.
3.  **Testing**: Develop comprehensive unit and integration tests for `ace-llm` to verify the correct passing of custom prompts to Anthropic. Add integration tests within `ace-git-commit` to confirm that it successfully generates fast and accurate commit messages using the new `ace-llm` interface and Claude Haiku.

## Considerations
-   **Configuration Cascade**: Ensure that provider-specific settings (e.g., Anthropic API key, default model) are managed via `Ace::Core.config.get('ace', 'llm', 'anthropic')` for consistency and project-level overrides.
-   **CLI Interface Design**: The `ace-llm` CLI should be intuitive for specifying both system and user prompts, potentially using file paths for longer prompts.
-   **Provider Abstraction**: Maintain `ace-llm`'s multi-provider abstraction while allowing for provider-specific prompt structures without breaking compatibility with other LLMs.
-   **Performance**: Prioritize low-latency responses, especially when integrating with models like Claude Haiku.

## Benefits
-   **Enhanced LLM Control**: Provides developers and AI agents with precise control over LLM interactions, leading to more accurate and context-aware outputs.
-   **Improved `ace-git-commit` Performance**: Enables significantly faster and potentially higher-quality git commit message generation, streamlining the development workflow.
-   **Increased Flexibility**: Makes `ace-llm` more versatile, allowing it to fully leverage the unique capabilities and prompt structures of various LLM providers.
-   **AI-Native Development**: Further empowers autonomous AI agents by offering deterministic and direct access to LLM features, reducing reliance on intermediary prompt engineering layers.
-   **Reduced Overhead**: Eliminates potential interference from generic or default system prompts, leading to more direct and efficient LLM usage.

---

## Original Idea

```
research the best way to allow ace-llm package to run query to to anthropic using system prompt and prompt without using claude code (so no default system prompt anymore). Best way to test it is on ace-git -> so we shouodl get very fast git commit messages using haiku
```

---
Captured: 2025-11-03 00:05:42
