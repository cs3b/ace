---
title: Standardize CLI Parameter Configuration and Output Summary
filename_suggestion: feat-config-cli-params-summary
enhanced_at: 2025-12-02 11:59:53.000000000 +00:00
location: active
llm_model: gflash
status: done
completed_at: 2025-12-09 00:57:40.000000000 +00:00
id: 8n1hz3
tags: []
created_at: '2025-12-02 11:58:58'
---

# Standardize CLI Parameter Configuration and Output Summary

## Problem
Currently, the definition and defaulting of CLI parameters across `ace-*` gems can be inconsistent. While `ace-support-core` provides a robust configuration cascade, there isn't a standardized pattern for individual `ace-*` gems to define their CLI-specific defaults within this cascade. Furthermore, when an `ace-*` CLI command is executed, there's no immediate, concise feedback on the *effective* configuration (including defaults, `.ace/` overrides, and CLI arguments) being used. This lack of transparency hinders debugging, makes autonomous agent execution less predictable, and increases the cognitive load for both human developers and AI agents trying to understand the operational context.

## Solution
We will standardize the way `ace-*` gems define and load CLI parameter defaults, and introduce a consistent mechanism to output a concise summary of the computed configuration at the start of any `ace-*` CLI command's execution.

1.  **Standardized CLI Parameter Defaults:** Each `ace-*` gem will define its default CLI parameters within its `.ace.example/gem/config.yml` (or a similar gem-specific configuration file) under a dedicated key (e.g., `cli_defaults` or `params`). This leverages the existing `ace-support-core` configuration cascade for a unified approach.
2.  **Unified Default Loading:** The `cli.rb` (Thor-based) entry point for each `ace-*` gem will be updated to consistently load these `cli_defaults` from the resolved configuration, ensuring that `ace-support-core`'s cascade logic (nearest-wins) correctly applies.
3.  **Concise Configuration Summary Output:** A new `Ace::Core` utility will be introduced to generate a compact, standardized summary of the *effective* configuration (especially CLI-relevant parameters) that is printed to `stderr` (to avoid interfering with `stdout` for deterministic output) at the very beginning of any `ace-*` CLI tool's execution. This summary will be designed to be machine-readable and human-friendly, fitting within 1-3 lines.

## Implementation Approach
*   **`ace-support-core` Enhancement:** Introduce new `Ace::Core::Molecules` for `CliConfigResolver` to merge CLI arguments with the configuration cascade, and `Ace::Core::Organisms::ConfigSummaryGenerator` to format the resolved configuration into a concise string. This ensures the ATOM pattern is followed.
*   **`ace-*` Gem Integration:** Each `ace-*` gem's `lib/ace/gem/cli.rb` will integrate these new `ace-support-core` components. A common `before_hook` or `initialize` method in a shared `Ace::Core::CliBase` (if applicable, or a mixin) will handle loading defaults and invoking the summary generator.
*   **Configuration:** Update `.ace.example/gem/config.yml` in each `ace-*` gem to include a `cli_defaults` section for its specific CLI parameters.
*   **Output Format:** The summary format will be a single-line, parseable string (e.g., JSON or key-value pairs) to ensure consistency and machine-readability, while remaining concise for human developers.

## Considerations
-   **Precedence:** Clearly define the order of precedence: explicit CLI arguments > `.ace/` project/user configuration > gem-defined `cli_defaults`.
-   **Output Format:** The summary format must be carefully designed to be both concise (1-3 lines) and easily parseable by AI agents, potentially using a structured format like a compact YAML or JSON snippet.
-   **Verbosity Control:** Implement a `--no-summary` or `--quiet` CLI option to suppress this output when only the command's primary result is desired, maintaining deterministic output for agents.
-   **Security:** Ensure no sensitive configuration data is exposed in the summary output.
-   **Backward Compatibility:** The changes should be introduced in a way that minimizes disruption to existing `ace-*` gems and their usage.

## Benefits
-   **Enhanced Determinism:** AI agents gain immediate, reliable insight into the exact parameters and configuration under which a command is executed, improving autonomous operation and debugging.
-   **Improved Transparency:** Both human developers and AI agents can quickly understand the effective configuration for any `ace-*` command.
-   **Reduced Cognitive Load:** Eliminates guesswork regarding active configuration values, streamlining development and troubleshooting.
-   **Standardization:** Promotes a consistent pattern for CLI parameter management across the entire `ace-*` ecosystem, simplifying development and maintenance.
-   **Easier Debugging:** The concise summary provides a quick snapshot for troubleshooting command execution issues.
-   **Better Agent Feedback:** Agents can parse the summary to understand the context of their command execution, enabling more intelligent decision-making.

---

## Original Idea

```
ace-* unified the way we can define any params tha cmd line take by having a default or params key in config file and for any cmd line tool - the main file - to be able to setup the defaults. We should probably also summarize the computed config at the very beginning of the cmd line output (the default one format) so we know whan are we running - it should always fit in 1-3 lines )
```