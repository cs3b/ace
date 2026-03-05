---
title: Enhance ace-llm for Direct Anthropic Prompt Control
filename_suggestion: feat-llm-anthropic-direct-prompts
enhanced_at: 2025-11-03 00:15:55.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2025-11-13 10:27:59.000000000 +00:00
id: 8m20di
tags: []
created_at: '2025-11-03 00:15:00'
---

# Enhance ace-llm for Direct Anthropic Prompt Control

## Problem
Currently, `ace-llm`'s integration with Anthropic models, particularly when leveraging Claude Code as an intermediary, introduces a default system prompt. This implicit prompt interferes with the ability of `ace-*` gems, such as `ace-git-commit`, to precisely control the LLM's behavior using custom system and user prompts. This limitation prevents optimal fine-tuning of model responses for specific, deterministic tasks, leading to less efficient or less accurate outputs than desired, especially when aiming for concise and fast responses from models like Haiku.

## Solution
Enhance `ace-llm` to provide a direct integration with Anthropic's API, allowing users to explicitly define both the system prompt and the user prompt without any additional, default system prompts being injected by intermediary tools like Claude Code. This new capability will be exposed via the `ace-llm query` CLI command, enabling a syntax like `ace-llm query cs:haiku --system system.md --prompt prompt.md`. The solution must ensure that this direct integration continues to utilize the existing subscription-based token management for Anthropic models, rather than requiring separate custom API keys for each query.

## Implementation Approach
1.  **New Provider Gem**: Create a new gem, `ace-llm-providers-anthropic`, following the `ace-llm-providers-*` pattern. This gem will encapsulate the direct API calls to Anthropic, handling authentication and request/response parsing.
2.  **`ace-llm` Integration**: Modify `ace-llm` to recognize and dispatch requests to this new `ace-llm-providers-anthropic` gem when a specific Anthropic model is requested. The `ace-llm` CLI will be updated to accept `--system <file>` and `--prompt <file>` arguments, which will be passed directly to the new provider.
3.  **ATOM Architecture**: 
    *   **Atoms**: Functions for reading prompt files (`system.md`, `prompt.md`), low-level HTTP requests to Anthropic API.
    *   **Molecules**: Constructing the Anthropic API request payload (including `system` and `messages` arrays), parsing API responses.
    *   **Organisms**: The `ace-llm` command logic (within `lib/ace/llm/commands/`) that orchestrates provider selection, prompt loading, and response handling.
4.  **Configuration**: Leverage `ace-support-core`'s configuration cascade (`Ace::Core.config.get`) to manage Anthropic API endpoints and any necessary authentication details, ensuring subscription-based token usage.
5.  **Testing**: Develop comprehensive tests within `ace-llm-providers-anthropic` and `ace-llm` to verify that system and user prompts are correctly transmitted to the Anthropic API without modification, and that the output is as expected. A key integration test will involve using `ace-git-commit` with a Haiku model via the new direct prompt mechanism to validate the speed and quality of generated commit messages.

## Considerations
-   **Provider Naming**: Confirm `ace-llm-providers-anthropic` is the most appropriate name, aligning with existing provider patterns.
-   **CLI Interface**: Ensure the `--system` and `--prompt` flags are intuitive and consistent with `ace-llm`'s existing command structure.
-   **Token Management**: Meticulously verify that the direct API calls correctly utilize the existing subscription-based token system, avoiding any accidental fallback to individual API keys.
-   **Error Handling**: Implement robust error handling for API failures, invalid prompt files, or model-specific issues.
-   **Backward Compatibility**: Ensure that existing Claude Code-based Anthropic integrations within `ace-llm` continue to function without disruption.

## Benefits
-   **Enhanced Prompt Control**: Provides developers and AI agents with granular control over LLM prompts, leading to more precise and predictable outputs.
-   **Improved Efficiency**: Enables optimal prompt engineering for specific tasks, resulting in faster and more accurate responses from models like Haiku, particularly beneficial for `ace-git-commit`.
-   **Increased Flexibility**: Expands `ace-llm`'s utility for a wider range of tasks requiring strict adherence to custom system instructions.
-   **Reduced Prompt Interference**: Eliminates the need to work around or compensate for unwanted default system prompts from intermediary tools.
-   **Direct API Access**: Establishes a cleaner, more direct integration pattern for LLM providers within the ACE ecosystem.

---

## Original Idea

```
research the best way to allow ace-llm package to run query to to anthropic using system prompt and prompt without using claude code (so no default system prompt anymore - we have a cc provider that run llm using claude code, but claude code is by default addint their own prompt). Best way to test it is on ace-git -> so we shouodl get very fast git commit messages using haiku: eg.: llm-query cs:haiku prompt.md --system system.md ( and it should not add addtional system prompt, but still use the the subscriptions based tokens, not custom anthropic key (this one we already have)
```