---
status: done
id: 8knziw
title: Idea
tags: []
created_at: '2025-09-24 23:40:59'
---

# Idea

---

title: Implement Descriptive Task Paths in ace-taskflow
filename_suggestion: ace-taskflow-descriptive-task-paths
enhanced_at: 2025-09-25 00:41:23
location: done
llm_model: gflash
completed_by: [v.0.9.0+task.031]
completed_at: 2025-09-25
status: done
---

## Problem

Currently, `ace-taskflow` generates task file paths that are numerically indexed and can be quite verbose, such as `/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/025/add-git-commit-and-llm-enhance-flags-to-idea-comma.md`. When browsing the `.ace-taskflow/v.*/t/` directory, users and AI agents only see numeric folder names (e.g., `025`), which provides no immediate context about the task's content or purpose. This hinders efficient navigation, understanding, and discovery for both human developers and AI agents leveraging tools like `ace-nav`.

## Solution

Introduce a new, descriptive task file and folder naming convention within `ace-taskflow`. The new convention will embed a concise, semantic slug directly into the task folder name, making tasks easily identifiable at a glance. The proposed format is `[task_id]-[type]-[context]-[keywords]/task.[task_id].md`.

**Example:** `025-feat-taskflow-idea-gc-llm/task.025.md`

**Slug Components:**

* **`[task_id]`**: The unique numerical identifier for the task.
* **`[type]`**: A short, standardized prefix indicating the task's nature (e.g., `feat` for feature, `fix` for bug fix, `docs` for documentation, `test` for testing, `refactor` for refactoring). This aligns with common commit message conventions.
* **`[context]`**: A brief, hyphenated phrase indicating the primary ACE gem or component affected (e.g., `taskflow`, `context`, `nav`).
* **`[keywords]`**: A concise, hyphenated summary derived from the task's title or description (e.g., `idea-gc-llm` for 'idea git commit LLM enhancement').

## Implementation Approach

1. **ace-taskflow Gem Modifications**: This enhancement will primarily affect the `ace-taskflow` gem.
    * **Molecule for Slug Generation**: Develop a new `Molecule` (e.g., `Ace::Taskflow::Molecules::TaskSlugGenerator`) responsible for taking a task's ID, type, and title/description to deterministically generate the descriptive slug.
    * **Organism for Task Creation**: Modify the `Organism` responsible for creating new tasks (e.g., `Ace::Taskflow::Organisms::TaskCreator`) to utilize the `TaskSlugGenerator` when creating the task directory and initial `task.[task_id].md` file.
    * **Organism/Molecules for Task Discovery/Loading**: Update existing `Molecules` and `Organisms` within `ace-taskflow` that discover or load tasks to correctly parse and interpret the new path format. This includes `Ace::Taskflow::Molecules::TaskFinder` and `Ace::Taskflow::Organisms::TaskManager`.
2. **CLI Interface**: Ensure that `ace-taskflow` CLI commands (e.g., `ace-taskflow task show`, `ace-taskflow tasks --list`) display these new, more descriptive paths.
3. **AI-Native Design**: This change directly improves the AI-native design of ACE by providing more semantic information in file paths, enhancing `ace-nav` capabilities and general agent understanding without needing to parse file content.
4. **Configuration**: Consider making the available `[type]` prefixes and potentially `[context]` mapping configurable via the `.ace/config` cascade, allowing project-specific customization.
5. **Migration Strategy**: Plan for backward compatibility or a migration utility to handle existing tasks created with the old naming convention.

## Considerations

* **Determinism**: The slug generation process must be deterministic to ensure consistent and predictable paths.
* **Uniqueness**: The `[task_id]` remains the primary unique identifier; the slug enhances readability.
* **User Input**: Provide options for users to suggest or override generated slugs during task creation.
* **`ace-nav` Integration**: Leverage these richer paths to enhance `ace-nav`'s ability to discover and describe workflows/tasks via the `wfi://` protocol.
* **Slug Length**: Maintain a balance between descriptiveness and conciseness to avoid excessively long paths.

## Benefits

* **Improved Navigation**: Both human developers and AI agents can quickly understand the purpose of a task by looking at its path/folder name, especially when browsing the `.ace-taskflow/v.*/t/` directory.
* **Enhanced AI Understanding**: Provides richer context for AI agents without needing to open the file, improving the efficiency of tools like `ace-nav` and overall agent task processing.
* **Better Organization**: Standardized naming improves the overall organization and maintainability of the `.ace-taskflow` directory.
* **Clarity for `ace-taskflow` CLI**: CLI outputs that include task paths will be more informative and user-friendly.
* **Consistency**: Enforces a consistent and semantic naming convention across all tasks, aligning with ACE's principles of predictability and clarity.

---

## Original Idea

```
currently paths for tasks looks like: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/025/add-git-commit-and-llm-enhance-flags-to-idea-comma.md
this doesn't help as much and when in the t folder i see only numbers ... 
lets workon defining slug 3-6 words, can user shorthands, that would define task e.g:
025-feat-taskflow-idea-gc-llm/task.025.md 
so we have number - task type: (feat, docs, test, fix, ... ) - context - what (key words)

thanks to this in t folder it would be easy to spot what is folder about
```

---
Captured: 2025-09-25 00:41:08