---
:input_tokens: 45637
:output_tokens: 1227
:total_tokens: 46864
:took: 5.474
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-07-30T21:31:13Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45637
:cost:
  :input: 0.004564
  :output: 0.000491
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005055
  :currency: USD
---

# Enhance LLM Model Aliases and Programmatic Access

## Intention

To simplify the programmatic use of LLM model aliases and default overwrites across different commands, enabling more flexible and composable AI workflows.

## Problem It Solves

**Observed Issues:**
- **Complexity in Programmatic Usage**: The current system for managing LLM model aliases and default overwrites is becoming complicated for programmatic access, making it difficult for one command or component to invoke another (like an "idea manager" invoking `llm-query`) without unintended side effects or complex argument parsing.
- **Inconsistent Default Overwriting**: Different commands might have varying mechanisms or complexities for overwriting default model configurations, leading to a fragmented user and developer experience.
- **Limited Composability**: The current structure hinders the ability to build complex AI workflows where components seamlessly delegate LLM tasks to each other with configurable models.

**Impact:**
- **Reduced Developer Productivity**: Developers spend more time deciphering complex model selection logic or finding workarounds when integrating LLM functionalities programmatically.
- **Hindered Workflow Automation**: Building sophisticated AI workflows that chain multiple commands or custom logic becomes cumbersome and error-prone.
- **Potential for Inconsistent Behavior**: Different commands might interpret or apply model overrides differently, leading to unexpected results.

## Key Patterns from Reflections

- **ATOM Architecture**: LLM interactions are managed by `Organisms` (e.g., `OpenAIClient`, `GoogleClient`) which use `Molecules` (e.g., `HTTPRequestBuilder`) and `Atoms` (e.g., `HTTPClient`). Model selection and aliasing should integrate cleanly into this structure.
- **Dynamic Provider System Architecture (ADR-012)**: The system dynamically discovers providers and their configurations, which should extend to managing aliases and defaults in a similarly dynamic and decoupled manner.
- **Zeitwerk for Autoloading (ADR-007)**: Class loading is handled automatically, implying that model alias configurations should also be discoverable and loadable without explicit manual registration for every new alias or provider.
- **Unified LLM Query Interface (`llm-query` CLI)**: This tool already provides a user-facing way to manage models and aliases, suggesting that the programmatic interface should mirror or complement this.
- **XDG-Compliant Caching (ADR-014)**: Model information, including potential alias mappings or user-defined defaults, could be managed via the caching system.
- **Consistent CLI Error Reporting (ADR-009)**: Any new programmatic interfaces or changes should adhere to consistent error reporting, especially when dealing with model selection or configuration issues.

## Solution Direction

1. **Unified Model Configuration Service**:
    - **Description**: Introduce a central `ModelConfigurationService` (likely a Molecule or Organism) responsible for managing LLM model aliases, provider defaults, and user-defined overrides. This service would provide a programmatic API for querying and setting model configurations.
2. **Enhanced `llm-query` Command**:
    - **Description**: Refactor the `llm-query` command to leverage the new `ModelConfigurationService` for all model alias and default handling. This ensures consistency between CLI usage and programmatic access. The command should also expose flags or options to interact with the configuration service (e.g., setting aliases).
3. **Programmatic Access via `ModelConfigurationService`**:
    - **Description**: Provide clear methods within the `ModelConfigurationService` for other components (like an "idea manager") to retrieve the effective model configuration (including resolved aliases and defaults) for a given provider and model name, or to specify a model directly.

## Critical Questions

**Before proceeding, we need to answer:**
1. How will the `ModelConfigurationService` store and retrieve model aliases and overrides? (e.g., in memory, XDG cache, configuration files)
2. What will be the precise API signature for querying and setting model configurations programmatically?
3. How will conflicts between global defaults, provider-specific aliases, and user-defined overrides be resolved?

**Open Questions:**
- What level of abstraction is needed for "overwriting defaults" programmatically versus setting specific aliases?
- How will this system integrate with the existing `ProviderModelParser` and `LlmModelInfo` structures?
- Should alias definitions be part of the `.ace/handbook` or managed purely through code/configuration?

## Assumptions to Validate

**We assume that:**
- A centralized service for model configuration is a scalable and maintainable approach. - *Needs validation*
- Users/developers will benefit from a consistent way to manage model aliases across CLI and programmatic usage. - *Needs validation*
- The existing ATOM architecture can accommodate a new `ModelConfigurationService` without significant refactoring. - *Needs validation*

## Expected Benefits

- **Improved Developer Experience**: Simplified and consistent programmatic access to LLM model configurations.
- **Enhanced Workflow Composability**: Easier creation of complex AI workflows by allowing components to reliably delegate LLM tasks with configurable models.
- **Reduced Maintenance**: Centralized management of aliases and defaults reduces duplication and simplifies updates.
- **Consistent User Experience**: CLI and programmatic interfaces for model configuration will be aligned.

## Big Unknowns

**Technical Unknowns:**
- The exact persistence mechanism for aliases and overrides (e.g., integration with XDG cache vs. dedicated config files).
- The performance implications of dynamic alias resolution and configuration loading.

**User/Market Unknowns:**
- How users will prefer to manage their custom model aliases and overrides (e.g., via CLI commands, config files, or direct code).

**Implementation Unknowns:**
- The specific methods and data structures required for the `ModelConfigurationService` API.
- The refactoring effort needed for existing commands to adopt the new service.
