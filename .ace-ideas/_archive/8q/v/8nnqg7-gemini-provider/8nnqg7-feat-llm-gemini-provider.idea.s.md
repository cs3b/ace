---
title: Add Gemini Provider to ace-llm-providers-cli with System Prompt Emulation
filename_suggestion: feat-llm-gemini-provider
enhanced_at: 2025-12-24 17:38:38 +0000
llm_model: gflash
source: "taskflow:v.0.9.0"
id: 8nnqg7
status: done
tags: []
created_at: "2025-12-24 17:37:59"
---

# Add Gemini Provider to ace-llm-providers-cli with System Prompt Emulation

## Problem
The ACE ecosystem relies on a standardized dual-prompt input (System Prompt and User Prompt) for deterministic agent behavior, managed by tools like `ace-prompt` and consumed by `ace-review` or `ace-git-commit`. Integrating Google Gemini models via `ace-llm-providers-cli` is challenging because the underlying Gemini API or CLI tool may not expose a dedicated 'system prompt' parameter, requiring system instructions to be merged into the primary user input.

## Solution
Implement a specialized prompt transformation Molecule within `ace-llm-providers-cli` for the Gemini provider. This Molecule will intercept the standard System Prompt and User Prompt inputs, concatenate them into a single, structured input string, and pass this merged content to the Gemini CLI via the `--prompt` argument. This approach emulates system prompt functionality, preserving the integrity of ACE workflows.

## Implementation Approach
1. **New Provider Module:** Create the necessary structure for the Gemini provider within `ace-llm-providers-cli`, adhering to the `ace-llm-providers-*` pattern.
2. **Prompt Merger Molecule:** Develop a Molecule (e.g., `GeminiPromptFormatter`) responsible for combining the system and user prompts. This component must use clear delimiters (e.g., Markdown headers or specific instruction tags) to ensure the model correctly interprets the system instructions first.
3. **Organism Integration:** Update the command execution Organism to utilize the `GeminiPromptFormatter` before invoking the external Gemini CLI tool.
4. **Configuration:** Ensure configuration options (like model name, API key location, and potentially the merging template) are managed via the ACE configuration cascade, specifically under `.ace/llm/providers/gemini.yml`.
5. **Caching:** Utilize `Ace::Core::Molecules::PromptCacheManager` to save the final, merged prompt content for debugging and review, maintaining consistency with other ACE tools.

## Considerations
- **Prompt Effectiveness:** The merging strategy must be tested to ensure the Gemini model respects the system instructions embedded in the user prompt.
- **CLI Consistency:** The resulting CLI interface and output format must align with the deterministic, parseable output expected by `ace-llm` consumers.
- **Context Window:** Implement checks to prevent the combined prompt from exceeding the Gemini model's maximum context length.

## Benefits
- Expands the multi-provider capabilities of `ace-llm`, offering agents access to Google Gemini models.
- Maintains the conceptual separation of System and User prompts for ACE agents, simplifying workflow design.
- Provides a reusable pattern for integrating future LLMs that lack native system prompt support.

---

## Original Idea

```
ace-llm-providers-cli - add support for gemini (it doesn't have system prompt so i probalby should use system prompt as inline prompt and --promp to pass the prompt as in others providers
```