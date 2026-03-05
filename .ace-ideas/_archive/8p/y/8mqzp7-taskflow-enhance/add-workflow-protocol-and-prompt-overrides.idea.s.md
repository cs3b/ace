---
title: Enhance ace-taskflow with Workflow Protocol and Prompt Overrides
filename_suggestion: feat-taskflow-protocol-overrides
enhanced_at: 2025-11-27 23:48:15.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2025-12-09 01:00:09.000000000 +00:00
id: 8mqzp7
tags: []
created_at: '2025-11-27 23:47:59'
---

# Enhance ace-taskflow with Workflow Protocol and Prompt Overrides

## Problem
AI agents operating within `ace-taskflow` currently lack a standardized, declarative mechanism to dynamically invoke specific `ace-context` or `ace-nav` workflows, or to override default LLM prompts for tools like `ace-git-commit` on a per-task basis. This limits the flexibility and adaptability of agent workflows, often requiring manual intervention or less robust scripting for task-specific customizations.

## Solution
Introduce a robust protocol definition and override system within `ace-taskflow`. This system will allow tasks to specify `wfi://` protocols for `ace-context` and `ace-nav` workflows, enabling dynamic invocation of project context loading and task-specific navigation. Furthermore, it will provide a `prompt://` protocol for `ace-context` to override system prompts for LLM-powered tools, such as `ace-git-commit`, ensuring task-specific prompt customization.

## Implementation Approach
*   **`ace-taskflow`**: Extend `ace-taskflow`'s `models` to include new data structures for defining workflow and prompt overrides within task presets or definitions. `molecules` would be responsible for parsing and validating these protocol definitions. An `organism` within `ace-taskflow` would orchestrate the resolution and execution, delegating to the appropriate gems.
*   **`ace-context`**: Enhance `ace-context` to recognize and resolve a new `prompt://` URI scheme. This `molecule` would locate and load prompt content from the configuration cascade (e.g., `.ace/prompts/` or gem-specific `handbook/prompts/`), allowing it to override default prompts. The existing `ace-context` `organism` for loading context would be extended to handle `wfi://load-project-context` invocations.
*   **`ace-nav`**: The `ace-nav` `organism` would be the target for `wfi://work-on-task` invocations, providing the necessary resource discovery and navigation capabilities as specified by the task.
*   **`ace-llm`**: The `ace-llm` gem would be updated to consume prompts resolved via `ace-context`'s `prompt://` mechanism, ensuring that overridden prompts are used for LLM interactions.
*   This approach aligns with the ATOM pattern by clearly separating data structures (models), parsing/resolution logic (molecules), and orchestration (organisms). It also leverages the `wfi://` protocol and `ace-context`'s configuration cascade, adhering to core ACE principles.

## Considerations
-   **Integration with existing `ace-*` gems**: Ensure seamless integration with `ace-git-commit` for prompt overrides and `ace-nav` for workflow execution.
-   **Configuration cascade implications**: Define a clear precedence for prompt overrides (e.g., task-specific overrides taking precedence over project-level, which take precedence over gem defaults).
-   **CLI interface design**: How will `ace-taskflow` expose these protocol definitions and overrides to human users and agents?
-   **Security**: Implement robust validation for `prompt://` content to prevent prompt injection or unintended behavior.
-   **Documentation**: Provide clear examples and guides on how to define and use these new protocol types within `ace-taskflow` presets and task definitions.

## Benefits
-   **Enhanced Agent Autonomy**: Agents can dynamically adapt their behavior and context loading based on specific task requirements.
-   **Increased Workflow Flexibility**: Allows for highly customizable and reusable workflows within `ace-taskflow`.
-   **Improved Prompt Management**: Centralizes and standardizes the process of overriding LLM prompts, making it easier to fine-tune agent behavior.
-   **Reduced Duplication**: Promotes the reuse of `wfi://` and `prompt://` definitions across tasks.
-   **Deterministic Execution**: Provides a clear, declarative way for agents to specify and execute complex operations.

---

## Original Idea

```
define in ace taskflow protocol for running ace-context wfi://load-project-context -> %load-project-context  and ace-nav wfi://work-on-task -> &work-on-task. We can also think about options to overwrite protocol %prompt@git-commit.system -> ace-context prompt://git-commit.system
```