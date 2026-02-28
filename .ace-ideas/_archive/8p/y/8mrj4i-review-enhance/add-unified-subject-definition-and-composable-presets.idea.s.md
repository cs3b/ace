---
title: Enhance ace-review with Unified Subject Definition and Composable Subject Presets
filename_suggestion: feat-review-subject-presets
enhanced_at: 2025-11-28 12:45:09.000000000 +00:00
location: active
llm_model: gflash
status: done
completed_at: 2025-12-09 01:00:19.000000000 +00:00
id: 8mrj4i
tags: []
created_at: '2025-11-28 12:45:00'
---

# Enhance ace-review with Unified Subject Definition and Composable Subject Presets

## Problem
Currently, the `ace-review` gem allows specifying the review scope using various `--subject` formats (e.g., `pr:48`, `files:ace-git-worktree/**/*`, `diff:origin..HEAD`). However, these definitions are disparate and lack a unified parsing mechanism or the ability to be encapsulated and reused as presets. This limits the composability of review commands, making it difficult to define and reuse complex review scopes (e.g., "all changes in the current feature branch, excluding documentation files") and combine them with existing review style presets. The absence of a dedicated "subject preset" system reduces the determinism and flexibility of `ace-review` for both human developers and AI agents.

## Solution
This enhancement will unify how `ace-review` defines its subject and introduce a new concept of "subject presets." The solution involves:
1.  **Unified Subject Input**: Consolidate all subject definition types under a single `--subject` flag, accepting a standardized format (e.g., `type:value` like `pr:48`, `files:GLOB`, `diff:REF..REF`, `task:ID`). This provides a consistent interface for specifying the review target.
2.  **Subject Presets**: Introduce a new type of preset, `subject-presets`, which will define a reusable review scope. These presets will be stored in the configuration cascade (e.g., `.ace/review/subject-presets/my-scope.yml`) and can encapsulate complex file patterns, diff ranges, or task-related contexts.
3.  **Composable Review Presets**: Allow `ace-review` to combine a "review style preset" (defining *how* to review, e.g., `my-code-style`) with a "subject preset" (defining *what* to review, e.g., `my-feature-scope`). This enables commands like `ace-review --preset my-code-style --subject-preset my-feature-scope`.

## Implementation Approach
This feature will be implemented within the `ace-review` gem, leveraging the ATOM architecture:

*   **Atoms**: 
    *   `SubjectParser`: A pure function (Atom) to parse the `type:value` string from the `--subject` flag or a subject preset into a structured `ReviewSubject` data model.
    *   `GitDiffExtractor`: An Atom to retrieve file lists or diff content based on git references provided by the `ReviewSubject`.
    *   `FilePathExpander`: An Atom to resolve glob patterns (e.g., `ace-git-worktree/**/*`) into concrete file paths, potentially leveraging `ace-search` capabilities.
*   **Molecules**: 
    *   `SubjectResolver`: A Molecule that orchestrates `SubjectParser`, `GitDiffExtractor`, and `FilePathExpander` to produce the final set of files or diff content that needs to be reviewed.
    *   `PresetLoader`: A Molecule that utilizes `ace-support-core`'s configuration cascade to load both review style presets and the new subject presets from their respective configuration locations.
    *   `ConfigMerger`: A Molecule responsible for merging the configurations from the selected review preset and subject preset, ensuring proper precedence and combination logic.
*   **Organisms**: 
    *   `ReviewOrchestrator`: The main Organism in `ace-review` will be updated to use the `SubjectResolver` to determine the review scope and the `ConfigMerger` to apply the combined preset configurations before initiating the LLM analysis.
*   **Models**: 
    *   `ReviewSubject`: A new data model (Model) to represent the parsed subject, including its type (PR, files, diff, task) and associated value.
    *   `SubjectPreset`: A new data model (Model) to represent the configuration of a subject preset.

The CLI interface will be extended to include `--subject-preset <name>` alongside the existing `--preset <name>` and `--subject <value>` options.

## Considerations
-   **Backward Compatibility**: Ensure that existing `--subject` flag usage remains functional, potentially by treating it as an ad-hoc, anonymous subject definition.
-   **Configuration Cascade**: Subject presets must integrate seamlessly with `ace-support-core`'s configuration cascade, allowing for project-specific, user-specific, and global subject definitions.
-   **Naming Convention**: Carefully choose the naming for "subject presets" (e.g., `scope-presets`, `target-presets`) to clearly differentiate them from "review style presets" in documentation and CLI.
-   **Error Handling**: Implement robust validation and provide helpful error messages for malformed subject inputs or non-existent presets.
-   **Integration**: Leverage existing ACE gems like `ace-git-commit` for git context, `ace-search` for advanced file pattern matching, and `ace-nav` for resolving PR/task IDs to relevant files or diffs.
-   **Documentation**: Provide clear documentation in `ace-review/handbook/` and `docs/usage.md` detailing the new subject definition formats, how to create and use subject presets, and how to combine them with review style presets.

## Benefits
-   **Enhanced Composability**: Allows for highly flexible and reusable review workflows by clearly separating "what to review" from "how to review."
-   **Increased Determinism**: Standardized subject definitions and presets lead to more predictable and repeatable review outcomes, which is crucial for autonomous AI agent execution.
-   **Improved User Experience**: Simplifies complex review invocations by abstracting common review scopes into easily callable presets, reducing cognitive load.
-   **Agent Efficiency**: Enables AI agents to define review scopes more precisely and efficiently, reducing ambiguity and improving the quality and relevance of automated feedback.
-   **Reduced Redundancy**: Eliminates the need for repetitive and verbose command-line arguments for frequently used review scopes.

---

## Original Idea

```
ace-review - unify the subject redefinitions --subject pr:48 or --subject files:ace-git-worktree/**/* or --subject diff:origin..HEAD and also allow to pass preset (so we have review preset and subject preset - maybe we should name it differenlty) and then we can mix the preset how we review with subject preset what do we need to review and it will improve the composability of the reviews on the presets level and also cmd line level
```