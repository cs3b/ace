---
title: Implement Model Alias Resolution in ace-llm
filename_suggestion: feat-llm-model-aliases
enhanced_at: 2025-12-23 14:44:55.000000000 +00:00
location: active
llm_model: gflash
source: taskflow:v.0.9.0
id: 8nmm3l
status: pending
tags: []
created_at: '2025-12-23 14:43:58'
---

# Implement Model Alias Resolution in ace-llm

## Problem
The `ace-llm` gem currently relies on strict canonical model identifiers (`provider:model-id`) for all operations, including `ace-llm-models info`. If a user or an autonomous agent attempts to use a common alias or a slightly different provider name (as shown in the example `openrouter:minimax`), the command fails with a 'Model not found' error. This lack of flexibility reduces the usability and robustness of the deterministic CLI interface, especially when dealing with providers that have complex or frequently changing model names.

## Solution
Implement a robust model alias resolution system within `ace-llm`. This system will allow users to define custom, project-specific aliases for complex model identifiers using the ACE configuration cascade. When a model is requested, `ace-llm` will first check the alias map before attempting a direct lookup against the configured LLM providers.

## Implementation Approach
1.  **Configuration**: Define a standard configuration structure for aliases, likely within `.ace/llm/aliases.yml`, utilizing `ace-support-core` for configuration loading and cascade resolution. This allows project-specific and user-global aliases.
2.  **ATOM Architecture**: 
    *   **Molecule**: Create `Ace::Llm::Molecules::AliasConfigLoader` to load and merge alias configurations from the cascade.
    *   **Organism**: Create `Ace::Llm::Organisms::ModelResolver` which encapsulates the logic to check the alias map and return the canonical `provider:model-id` before delegating to the underlying provider API lookup.
3.  **Integration**: Update the `ace-llm-models` CLI command (specifically the `info` and `list` actions) to utilize the `ModelResolver` organism, ensuring that all model lookups are alias-aware.

## Considerations
- **CLI Interface**: Ensure the `ace-llm-models list` command can optionally display known aliases alongside canonical names for transparency.
- **Precedence**: The resolution logic must clearly define precedence (e.g., aliases should resolve before attempting a direct provider lookup if the alias matches a known canonical name).
- **Deterministic Output**: The resolution process must be deterministic, ensuring that autonomous agents can rely on aliases consistently.

## Benefits
- **Improved Usability**: Allows human developers to use shorter, more memorable names for complex models.
- **Agent Robustness**: Enables AI agents to use flexible model names, making workflows defined in `handbook/workflow-instructions/*.wf.md` more portable.
- **Configuration Management**: Centralizes model naming conventions within the ACE configuration system, simplifying maintenance when provider names change.

---

## Original Idea

```
we should be able to search by aliases also

❯ ace-llm-models info openrouter:minimax
Error: Model 'openrouter:minimax' not found
```