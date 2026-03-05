---
title: Implement Descriptive Slugs for ace-taskflow Idea Paths
filename_suggestion: feat-taskflow-idea-slugs
enhanced_at: 2026-01-07 12:51:50.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2026-01-07 14:34:05.000000000 +00:00
id: 8o6jap
tags: []
created_at: '2026-01-07 12:51:52'
---

# Implement Descriptive Slugs for ace-taskflow Idea Paths

## Problem
Idea paths in `ace-taskflow` currently rely solely on the Base36 Compact ID (e.g., `.ace-taskflow/v.0.9.0/ideas/8o6iro-ace-rename/idea.s.md`). While the ID ensures uniqueness, the path lacks immediate context, making manual navigation and agent discovery less efficient. This deviates from the established pattern for tasks, which include a descriptive slug (e.g., `179-migrate-cli-framework`).

## Solution
Modify the `ace-taskflow idea create` command to automatically generate a short, descriptive slug from the idea's title or initial summary. This slug will be appended to the Base36 Compact ID when creating the idea directory, ensuring that the path is both unique and meaningful.

## Implementation Approach
1.  **Slug Generation Molecule:** Introduce a new **Molecule** within `ace-taskflow` (or potentially `ace-support-core` if reusable) responsible for sanitizing, shortening, and hyphenating a string (the idea title) into a filesystem-safe slug.
2.  **Idea Creation Organism:** Update the `IdeaCreation` **Organism** in `ace-taskflow` to integrate the slug generation immediately after obtaining the Base36 Compact ID. The resulting directory name will follow the pattern `{compact_id}-{slug}`.
3.  **CLI Integration:** Ensure the `ace-taskflow idea create` command handles the input required for slug generation (e.g., prompting for a title if not provided via arguments).
4.  **Path Consistency:** Ensure the resulting path structure is consistent with the existing task path structure, improving overall workflow predictability.

## Considerations
- **Slug Quality:** The slug generation logic must be robust, handling special characters and length constraints (ideally 3-5 words maximum).
- **Backward Compatibility:** Existing ideas using only the ID must remain resolvable.
- **Dependency:** This relies on the established Base36 Compact ID format (recently implemented via Task 149).

## Benefits
- Significantly improves human readability and navigation within the `.ace-taskflow/ideas/` directory structure.
- Enhances context awareness for AI agents using file system tools like `ace-search` or `ace-nav`.
- Standardizes idea path naming, aligning it with the existing task naming convention, improving overall UX consistency across `ace-taskflow`.

---

## Original Idea

```
ace-taskflow idea create -> should use slug for both folder (give context) - and the filename, similar to what we have with tasks, then path is more meaningful then .ace-taskflow/v.0.9.0/ideas/8o6iro-ace-rename/idea.s.md, it still should be short
```