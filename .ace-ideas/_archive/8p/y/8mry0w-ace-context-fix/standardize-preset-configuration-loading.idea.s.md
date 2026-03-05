---
title: Standardize ace-context Preset Configuration Loading
filename_suggestion: fix-context-config-loading
enhanced_at: 2025-11-28 22:41:52.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2025-12-01 18:16:09.000000000 +00:00
id: 8mry0w
tags: []
created_at: '2025-11-28 22:40:59'
---

# Standardize ace-context Preset Configuration Loading

## Problem
Currently, the `ace-context` gem exhibits inconsistent behavior when loading context configurations, specifically regarding the `presets` field. When `presets` are defined directly under `context:` in a YAML file or Markdown frontmatter (e.g., `context: presets: [project-base]`), they are not correctly recognized or applied. However, when nested under a specific section like `context: sections: project-context: presets: [project-base]`, the configuration is processed as expected. This discrepancy was identified when using `ace-prompt --context` and leads to unpredictable context loading for AI agents and human developers, hindering reliable workflow execution.

## Solution
Standardize the configuration loading and parsing mechanism within `ace-context` to ensure that `presets` and other context-related configurations are interpreted identically, regardless of whether they originate from a standalone YAML file or Markdown frontmatter. This involves creating a unified parsing and validation layer that can consistently extract and apply context settings from various input formats, adhering to a single, well-defined schema for context configuration.

## Implementation Approach
1.  **Identify Parsing Discrepancy**: Pinpoint the exact `molecules` (e.g., `context_loader`, `config_finder`) or `organisms` (e.g., `context_resolver`) within `ace-context` where the handling of top-level `context: presets:` diverges from nested `context: sections: ... presets:`. This might involve inspecting the `Ace::Core.config` usage within `ace-context`.
2.  **Standardize Configuration Model**: Define a canonical `model` (e.g., `ContextConfig`) within `ace-context` that represents the expected structure of context configuration, including `presets`, ensuring it can handle both flat and nested definitions consistently.
3.  **Refactor Parsing Molecules**: Enhance or create `molecules` responsible for parsing configuration from both YAML files and Markdown frontmatter. These molecules should consistently map the input to the `ContextConfig` model. Leverage `ace-support-core`'s configuration utilities where appropriate to maintain consistency with the project's `Config Cascade` principle.
4.  **Unified Resolution Organism**: Ensure the `organism` responsible for resolving and applying context (e.g., `ContextResolver`) operates solely on the standardized `ContextConfig` model, guaranteeing consistent behavior irrespective of the original source.
5.  **Testing**: Implement comprehensive unit and integration tests for `ace-context` to cover various configuration scenarios, including both top-level and nested `presets` from YAML and Markdown frontmatter, utilizing `ace-test-support` for robust validation.

## Considerations
-   **Backward Compatibility**: Ensure that any changes to the parsing logic do not inadvertently break existing, correctly functioning context configurations that might be relying on the nested structure.
-   **Error Handling**: Implement clear and actionable error messages for malformed context configurations to guide users and agents in correcting their settings.
-   **CLI Interface**: Verify that the `ace-prompt --context` command continues to function intuitively and leverages the corrected, consistent context loading.
-   **Documentation**: Update `ace-context` documentation to clearly define the expected structure for context configurations and `presets`, providing examples for both top-level and nested usage.

## Benefits
-   **Consistency**: Ensures `ace-context` behaves predictably across all configuration sources and formats, reducing ambiguity for agents and developers.
-   **Reliability**: Eliminates configuration-related errors stemming from inconsistent parsing, improving the robustness of AI-assisted workflows.
-   **Usability**: Simplifies context configuration for both human developers and AI agents, making `presets` easier to manage and apply without unexpected behavior.
-   **Maintainability**: A standardized parsing approach makes the `ace-context` gem easier to understand, debug, and extend in the future.
-   **Enhanced Agent Autonomy**: Provides a more reliable foundation for agents to load and utilize project context, improving their ability to perform tasks accurately and autonomously.

---

## Original Idea

```
ace-context should handle context config the same way independend on how do we loading it. e.g.: we have issue to load context: presets: [project-base], but context: sections: project-context: presets: [project-base] works, some config load from yml are working like this but markdown file with config is not working. Found when using ace-prompt --context
```