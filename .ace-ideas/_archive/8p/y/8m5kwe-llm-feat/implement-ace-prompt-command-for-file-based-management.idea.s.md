---
title: Implement `ace-prompt` command for file-based prompt management and archiving
filename_suggestion: feat-llm-prompt-file-management
enhanced_at: 2025-11-06 13:56:54.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2025-11-16 15:57:10.000000000 +00:00
id: 8m5kwe
tags: []
created_at: '2025-11-06 13:55:59'
---

# Implement `ace-prompt` command for file-based prompt management and archiving

## Problem
AI agents and human developers currently lack a robust, versionable system for managing prompts within the ACE project. Relying solely on in-editor prompt entry (e.g., Claude Code's editor) is inefficient for complex, multi-turn interactions and makes prompt iteration, versioning, and reuse challenging. There's no standardized way to store prompts tied to specific tasks or releases, track their evolution, or archive previous interactions for auditability and learning.

## Solution
Introduce a new `ace-prompt` gem and CLI command that provides a structured approach to prompt management. This command will enable users to:
1.  **Read Prompts from Files**: Locate and retrieve prompt content from files based on a hierarchical search path (project-level, release-level, or task-level).
2.  **Archive Prompts**: After a prompt is used, automatically archive the original file by moving it to a timestamped archive location.
3.  **Summarize Previous Interaction**: Optionally, embed a summary of the previous prompt's context or interaction within the *new* prompt file, maintaining continuity.
4.  **Prepare New Prompts**: Create a new, empty prompt file in the appropriate location, ready for the next iteration or interaction.

This system will significantly improve the developer experience for both humans and AI agents by making prompt management deterministic, versionable, and integrated with the ACE taskflow.

## Implementation Approach
This functionality will be implemented as a new `ace-prompt` gem, adhering to the ACE mono-repo and ATOM architecture patterns.

*   **Gem Structure**: `ace-prompt` will follow the standard `ace-*` gem structure, including `lib/ace/prompt/`, `handbook/`, `test/`, and `exe/ace-prompt`.
*   **ATOM Architecture**:
    *   **Atoms**: `PathResolver` (for hierarchical lookup), `FileArchiver` (for moving/renaming files), `TimestampGenerator`, `ContentSummarizer` (if advanced summarization is needed).
    *   **Molecules**: `PromptFinder` (combines path resolution and file existence checks), `PromptWriter` (handles writing new prompt files with optional summaries), `PromptArchiver` (orchestrates file moves and naming for archives).
    *   **Organisms**: `PromptManager` (orchestrates the full lifecycle: finding, reading, archiving, and preparing new prompts based on user input and configuration).
    *   **Models**: `Prompt` (a data structure representing a prompt, its path, content, and metadata).
*   **Configuration**: Utilize `ace-support-core`'s config cascade (`ADR-019`) to define default prompt search paths (e.g., `.ace/prompts/`, `.ace-taskflow/v.X.Y.Z/prompts/`, `.ace-taskflow/v.X.Y.Z/tasks/ID/prompts/`) and archive locations. Example configurations will be provided in `.ace.example/prompt/config.yml`.
*   **CLI Interface**: A `Thor`-based CLI (`ADR-018`) will expose commands like `ace-prompt read [name] [--task ID] [--release VERSION]`, `ace-prompt archive [name] [--task ID]`, `ace-prompt new [name] [--task ID] [--template TEMPLATE_NAME]`. Commands will return status codes (0 for success, 1 for failure) for AI-native execution.
*   **Integration**: `ace-prompt` will integrate with `ace-taskflow` to resolve task and release specific paths. It will also be designed to seamlessly pipe prompt content to `ace-llm-query`.
*   **Handbook**: Include `handbook/agents/read-prompt.ag.md` for single-purpose prompt retrieval and `handbook/workflow-instructions/manage-prompt-lifecycle.wf.md` for comprehensive prompt management workflows.

## Considerations

### Core Functionality
-   **Prompt Search Order**: Clearly define the precedence for prompt file lookup (e.g., task-level overrides release-level, which overrides project-level).
-   **Archiving Format**: Standardize the naming convention for archived prompts (e.g., `prompt_name_YYYYMMDD_HHMMSS.md`).
-   **New Prompt Templates**: Allow users to specify templates for new prompt files, potentially leveraging `dev-handbook/templates/` or a dedicated `ace-prompt` template directory.
-   **Security**: Implement robust path validation to prevent directory traversal vulnerabilities when resolving prompt file paths.
-   **Deterministic Output**: Ensure CLI commands provide clear, parseable output for AI agents.

### Integration Enhancements
-   **ace-taskflow Integration**: Leverage `ace-taskflow` to automatically resolve current task ID and release version context. Use `ace-taskflow task current` or similar to determine active task workspace.
-   **LLM Piping**: Design for seamless piping to `ace-llm-query` with `ace-prompt read [name] | ace-llm-query -m gpt-4`. Consider adding `--pipe` flag that outputs raw prompt content without formatting.
-   **Context Composition**: Integrate with `ace-context` to enrich prompts with project context. Support `ace-prompt read [name] --with-context project` to automatically prepend project context to prompts.
-   **Review Integration**: Consider integration with `ace-review` for prompt-based code review workflows where prompts can reference review presets.

### User Experience Improvements
-   **Interactive Mode**: Add `ace-prompt select` command that lists available prompts and allows interactive selection using arrow keys (similar to `fzf` pattern).
-   **Template System**: Support prompt templates with variable substitution (e.g., `{{TASK_ID}}`, `{{RELEASE_VERSION}}`, `{{DATE}}`). Variables resolved from context or command-line arguments.
-   **Preview Before Execute**: Add `--preview` flag to show prompt content before archiving/executing. Useful for verifying prompt content before committing to archival.
-   **Prompt History**: Implement `ace-prompt history [name]` to show archived versions of a specific prompt with timestamps and optional diff between versions.
-   **Multi-Prompt Sessions**: Support linking multiple prompt files in a session for complex multi-turn interactions (e.g., `ace-prompt session start`, `ace-prompt session add [name]`, `ace-prompt session execute`).

### Prototype Command Cleanup
-   **Fix Typo**: Correct "Insturction" → "Instruction" in `.claude/commands/prompt.md`
-   **Error Handling**: Add clear error messages for missing prompt files with suggestions (e.g., "Prompt 'the-prompt.md' not found. Available prompts: [list]")
-   **Archive Directory Structure**: Clarify archive organization - should archived prompts maintain original directory structure or be flattened? Recommend: maintain hierarchy with timestamps (e.g., `.cache/prompts/archive/the-prompt/20251109-131500.md`)
-   **Summary Generation**: Specify how summary of previous prompt is generated - extract title and first paragraph? Full content? LLM-generated summary?

## Benefits
-   **Enhanced Prompt Management**: Provides a structured, file-based system for creating, storing, and retrieving prompts.
-   **Version Control for Prompts**: Enables easy iteration and tracking of prompt changes, crucial for debugging and improving AI agent performance.
-   **Improved Context Awareness**: Links prompts directly to specific tasks or releases, providing better context for LLM interactions.
-   **Auditability**: Archived prompts offer a historical record of interactions, improving transparency and debugging of AI agent workflows.
-   **Developer Experience**: Reduces reliance on limited in-editor prompt capabilities, allowing developers to use their preferred text editors for prompt crafting.
-   **AI-Native**: Designed with deterministic CLI commands and clear integration points for autonomous AI agent execution.

---

## Original Idea

```
ace-prompt command -> so we can read prompts from files (the coding editor in claude code is not the fancies one). it will read the prompt from file in scope of project / release / task -> (so any of them will have prompts folder .cache/prompts/, {release}/prompts, {task-folder}/prompts. it will return the contect of the prompt and archive the prompt - keeping the summary of previous prompt in hte current file, with a structure for new prompt. and also archive the prompt by copying it to timestamp name file
```