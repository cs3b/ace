---
title: Implement structured subfolders for ace-taskflow subtasks
filename_suggestion: feat-taskflow-subtask-structure
enhanced_at: 2025-12-05 23:10:55.000000000 +00:00
location: active
llm_model: gflash
id: 8n4yr0
status: pending
tags: []
created_at: '2025-12-05 23:10:00'
---

# Implement structured subfolders for ace-taskflow subtasks

## Problem
Currently, `ace-taskflow` subtasks are often represented by a single entry, with detailed usage or related assets (like specific prompts or templates) potentially scattered or embedded directly within the main task definition. This approach becomes problematic for complex subtasks that require extensive documentation, multiple associated files (e.g., specific prompts, code snippets, configuration files), or dedicated sub-agents. This lack of a standardized, self-contained structure hinders discoverability, maintainability, and the ability for AI agents to autonomously understand and execute detailed subtask requirements, deviating from the `ADR-001 Workflow Self-Containment` principle.

## Solution
Introduce a structured subfolder approach for `ace-taskflow` subtasks. Instead of a flat representation, each subtask within a task would reside in its own dedicated directory. This directory would serve as a self-contained unit for all assets related to that specific subtask, including:
- `usage.md`: Detailed instructions and examples for the subtask.
- `prompts/`: LLM prompts specific to the subtask's execution, potentially leveraging `ace-prompt` for management.
- `templates/`: Code or configuration templates required by the subtask.
- `agents/`: Small, single-purpose agents (`.ag.md`) designed to perform specific actions within the subtask's scope.
- `metadata.yml`: Subtask-specific configuration or parameters, adhering to the `ace-support-core` config cascade.

This structure would mirror the `handbook/` organization found in other `ace-*` gems, promoting consistency across the project.

## Implementation Approach
1.  **`ace-taskflow` Core Modifications**: Update `ace-taskflow`'s `Organisms` (e.g., `TaskResolver`, `SubtaskOrchestrator`) and `Molecules` (e.g., `PathExpander`, `ResourceLoader`) to recognize and navigate this new subtask directory structure.
2.  **`ace-nav` Integration**: Ensure `ace-nav` can discover and link to subtask-specific resources using a `wfi://` protocol extension (e.g., `wfi://task-id/subtask-name/usage.md`). This will enhance resource discovery for both humans and AI agents.
3.  **`ace-prompt` & `ace-llm` Integration**: If subtasks utilize LLM interactions, integrate with `ace-prompt` for prompt management and `ace-llm` for model execution. The `PromptCacheManager` from `ace-support-core` should be used for caching subtask-specific prompts.
4.  **Configuration**: Leverage `ace-support-core`'s config cascade for `metadata.yml` within subtask folders, allowing for granular, subtask-specific overrides.
5.  **CLI Interface**: Design a clear CLI interface for `ace-taskflow` to interact with this new structure, e.g., `ace-taskflow subtask show <task-id> <subtask-name>` or `ace-taskflow subtask run <task-id> <subtask-name>`.

## Considerations
-   **Backward Compatibility**: Define a clear migration path or graceful fallback for existing `ace-taskflow` tasks that do not yet use the subfolder structure.
-   **Complexity Management**: Ensure the new structure doesn't introduce unnecessary overhead for very simple subtasks. Perhaps make the subfolder structure optional or provide a streamlined default.
-   **AI Agent Guidance**: Update `ace-handbook` guides and `ace-integration-claude` assets to instruct AI agents on how to effectively utilize this new subtask organization for better context and execution.
-   **Performance**: Evaluate potential performance impacts of deeper directory traversal for subtask discovery.

## Benefits
-   **Improved Organization**: Centralizes all related assets for a subtask, making complex tasks easier to manage and understand.
-   **Enhanced Discoverability**: Both human developers and AI agents can easily locate specific documentation, prompts, and templates for any given subtask via `ace-nav`.
-   **Self-Containment**: Adheres to `ADR-001 Workflow Self-Containment`, making subtasks more robust and portable.
-   **Autonomous Execution**: Provides AI agents with a richer, more structured context for executing subtasks, leading to more reliable and accurate outcomes.
-   **Consistency**: Aligns `ace-taskflow`'s internal structure with the `handbook/` pattern used by other `ace-*` gems, promoting a unified project architecture.

---

## Original Idea

```
ace-taskflow - subtask -> should have their own subfolders, or not ? ( if we need a detailed version of usage / etc / so far we are creating usage with subtask name)
```