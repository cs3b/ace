---
:input_tokens: 114638
:output_tokens: 1054
:total_tokens: 115692
:took: 3.811
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-24T00:11:18Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 114638
:cost:
  :input: 0.011464
  :output: 0.000422
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.011885
  :currency: USD
---

# Remake llm-models Command

## Intention

To refactor the `llm-models` command to dynamically list available LLM models from configured providers, with options to refresh cached model lists and use a common interface for model discovery.

## Problem It Solves

**Observed Issues:**
- The current `llm-models` command is not explicitly defined or described in the provided context, suggesting it might be missing or underdeveloped.
- Model discovery is not dynamically handled across all providers, leading to potential outdated information.
- There is no mechanism to refresh the cached list of models, which could lead to users querying non-existent models.
- Caching of model lists is not explicitly managed and stored in a user-accessible, XDG-compliant location.

**Impact:**
- Users may not be aware of the full range of LLM models available through the toolkit.
- Inconsistent or missing model information can lead to errors when querying LLMs.
- Lack of a refresh mechanism prevents users from accessing newly released models.
- Manual management of model lists would be required if not properly cached and managed.

## Key Patterns from Reflections

- **Dynamic Provider System Architecture (ADR-012)**: The project has a dynamic provider system where clients define their metadata. This pattern should be leveraged for model discovery.
- **XDG-Compliant Caching System (ADR-014)**: Model lists should be cached in `$XDG_CACHE_HOME/coding-agent-tools/models/` for performance and compliance.
- **ATOM Architecture**: Model discovery logic should fit within the ATOM structure, likely as a molecule or organism interacting with provider clients.
- **LLM Integration Architecture (ADR-014)**: Standardized handling of LLM providers, including model information, is a core part of the project.
- **CLI Tool Patterns**: Commands should be well-defined with clear options and help messages, following conventions established by `dry-cli`.

## Solution Direction

1. **Refactor `llm-models` Command**: Implement a new `llm-models` command that lists models, supporting dynamic discovery and caching.
2. **Dynamic Model Discovery**: Leverage the dynamic provider system (ADR-012) to discover models from each registered LLM provider. Provider clients should expose a method to fetch their available models.
3. **Caching Mechanism**: Implement caching for model lists in the XDG-compliant directory (`$XDG_CACHE_HOME/coding-agent-tools/models/`). Cache responses should be refreshed via a `--refresh-models` flag.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the exact command structure for `llm-models`? Should it be `llm-models` or `llm models`?
2. How will model information (name, context size, provider) be displayed to the user? What format will be used?
3. What is the strategy for handling providers that do not support dynamic model listing via API?
4. What is the cache expiration policy for model lists if `--refresh-models` is not used?

**Open Questions:**
- How will the `llm-models` command interact with the `ProviderModelParser` or similar components for model data retrieval?
- Should there be a default provider if none is specified, or should the command list models from all providers?
- What specific error handling should be implemented if a provider fails to return its model list?

## Assumptions to Validate

**We assume that:**
- LLM provider clients can be extended to expose a method for listing their available models. - *Needs validation*
- The `CacheManager` molecule can be used or extended to handle caching of model lists in the specified XDG directory. - *Needs validation*
- The `dry-cli` framework can accommodate the new command structure and options. - *Needs validation*

## Expected Benefits

- **Comprehensive Model Visibility**: Users will have a clear view of all LLM models accessible through the toolkit.
- **Improved User Experience**: Dynamic listing and caching simplify model discovery and usage.
- **Reduced Maintenance**: Eliminates hardcoded model lists and manual updates.
- **Extensibility**: New LLM providers can be added without modifying the `llm-models` command itself.
- **Adherence to Standards**: Leverages existing architectural patterns for dynamic providers and caching.

## Big Unknowns

**Technical Unknowns:**
- The precise API calls or methods required from each provider client to fetch model lists.
- The exact implementation details for the `--refresh-models` flag's cache invalidation strategy.

**User/Market Unknowns:**
- How frequently users will need to refresh their model lists.
- User preference for the display format of model information.

**Implementation Unknowns:**
- The impact of dynamic model loading on command startup time.
- The effort required to extend existing provider clients to support model listing.
```

> SOURCE

```text
remake the llm-models cmd - we should have llm-query google - to list all the models and additional flage --list-models --refresh-models (each provider should have their own way to load list of available models, dynamicly, but also cache responses, in .coding-agent home folder as they do not change so often
```
