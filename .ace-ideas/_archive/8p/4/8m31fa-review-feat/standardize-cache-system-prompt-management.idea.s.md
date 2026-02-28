---
title: Standardize and Cache System Prompt Management in ace-review
filename_suggestion: feat-review-prompt-management
enhanced_at: 2025-11-04 00:57:44.000000000 +00:00
location: active
llm_model: gflash
status: done
completed_at: 2025-11-15 10:55:43.000000000 +00:00
id: 8m31fa
tags: []
created_at: '2025-11-04 00:56:58'
---

# Standardize and Cache System Prompt Management in ace-review

## Problem
Currently, the mechanism by which `ace-review` crafts, manages, and passes system prompts to `ace-llm` for code analysis lacks explicit standardization and transparency. The absence of a clear, potentially cached representation (like a `system.md.tmp` file) makes it difficult to inspect the exact prompt sent to the LLM, leading to challenges in debugging, ensuring deterministic behavior, and understanding the full context provided to the AI reviewer. This ambiguity can hinder the reliability and predictability of `ace-review`'s output, especially for autonomous AI agents.

## Solution
Implement a standardized and transparent system for `ace-review` to generate, manage, and optionally cache the final system prompt before querying `ace-llm`. This solution will ensure that the system prompt is consistently constructed, debuggable, and contributes to the deterministic nature of ACE tools. A temporary, human-readable file (e.g., `system.md.tmp` within a designated cache directory) will be created to store the rendered system prompt for each review operation, providing full visibility.

## Implementation Approach
1.  **Prompt Generation Organism:** Introduce a new organism within `ace-review` (e.g., `Ace::Review::Organisms::SystemPromptGenerator`) responsible for orchestrating the assembly of the system prompt.
2.  **Context & Configuration Molecules:** This organism will utilize molecules to:
    *   Load review presets and configurations from `.ace/review/config.yml` (leveraging `Ace::Core.config`).
    *   Fetch relevant project context (e.g., file contents, diffs) via `ace-context`.
    *   Combine these inputs with predefined templates (potentially from `ace-review/handbook/templates/` or embedded strings).
3.  **Template Rendering Atom:** An atom (e.g., `Ace::Review::Atoms::TemplateRenderer`) will process the combined inputs and templates to produce the final system prompt string.
4.  **Caching Mechanism:** After generation, the `SystemPromptGenerator` organism will write the final system prompt to a temporary file, such as `.ace/review/cache/system_prompt_#{timestamp}.md` or `tmp/ace-review/system_prompt.md`, ensuring it's accessible for inspection. This caching can leverage `ace-context`'s caching capabilities if appropriate, or be managed internally by `ace-review`.
5.  **`ace-llm` Integration:** The `ace-review` CLI command will then pass the *content* of this generated system prompt directly to `ace-llm`'s query command as a dedicated system prompt argument.
6.  **Handbook Updates:** Document the new prompt generation and caching strategy within `ace-review/handbook/agents/review.ag.md` and relevant `workflow-instructions/*.wf.md` files to guide AI agents on how to understand and debug review operations.

## Considerations
-   **Integration with `ace-llm`:** Ensure seamless passing of the generated system prompt to `ace-llm`'s CLI interface, potentially as a file path or a direct string argument.
-   **Configuration Cascade:** Allow components of the system prompt (e.g., specific instructions, tone, focus areas) to be configurable via `ace-review`'s `.ace/review/config.yml` at various levels.
-   **Cache Management:** Define a clear strategy for cleaning up temporary prompt files to prevent accumulation, possibly integrated with `ace-context`'s cache invalidation or `ace-taskflow`'s cleanup routines.
-   **Determinism:** The prompt generation process must be entirely deterministic, ensuring that the same inputs always yield the same system prompt.
-   **Security:** Ensure that no sensitive information is inadvertently exposed or cached in the temporary prompt files.

## Benefits
-   **Enhanced Transparency:** Provides clear visibility into the exact system prompt used for each `ace-review` operation, aiding in debugging and understanding LLM behavior.
-   **Improved Determinism:** Standardizes prompt generation, leading to more consistent and predictable code review outcomes.
-   **Simplified Debugging:** The cached `system.md.tmp` file allows developers and agents to easily inspect the prompt, facilitating troubleshooting of unexpected LLM responses.
-   **Increased Maintainability:** A well-defined prompt management architecture makes `ace-review` easier to understand, extend, and maintain.
-   **Greater AI Agent Reliability:** Offers a more stable and predictable interface for AI agents interacting with `ace-review`, improving their ability to perform reliable code analysis.

---

## Original Idea

```
ace-review - why we don't have system.md.tmp (system prompt in cache folder) are we crafting and passing the system prompt to reviewer -> ace-llm-query
```