# Idea

---
title: Implement Retrospective Management in ace-taskflow
filename_suggestion: feat-taskflow-retro-management
enhanced_at: 2025-09-30 10:48:40
location: current
llm_model: gflash
---

## Problem
Currently, `ace-taskflow` provides robust management for tasks, ideas, and releases. However, the system lacks explicit tooling for managing project retrospectives, which are mentioned in `docs/blueprint.md` as existing in `.ace-taskflow/v.*/retro/` but are treated as read-only. Human developers and AI agents need a structured way to create, list, and interact with these critical historical documents. The absence of standardized metadata for retrospectives limits the ability to query, summarize, or analyze past project reflections programmatically, hindering automated learning and process improvement.

## Solution
Introduce `retro` and `retros` commands to the `ace-taskflow` gem to provide comprehensive management of project retrospectives. This will include:
-   `ace-taskflow retro create [version]`: Generate a new retrospective markdown file (e.g., `v.1.0.0/retro/YYYY-MM-DD-summary.md`) with a predefined template and initial metadata.
-   `ace-taskflow retro next`: Identify and display the next relevant retrospective, potentially based on release schedules or predefined criteria.
-   `ace-taskflow retros list [--version v.X.X.X] [--status active|done]`: List all retrospectives, with options to filter by associated release version or status.
-   Integrate metadata (e.g., `status`, `release_version`, `title`, `date`, `key_themes`, `participants`) directly within the retrospective markdown files (e.g., using YAML front matter) to enable advanced querying and automated analysis.

## Implementation Approach
This feature will be implemented within the `ace-taskflow` gem, adhering to the ATOM architecture pattern:
-   **Models**: Define a `Retro` data structure to represent a retrospective, including its path, content, and parsed metadata. This will be an immutable value object.
-   **Atoms**: Develop pure functions such as `RetroFileParser` (to extract metadata and content from markdown files), `RetroFileNameGenerator` (to create consistent filenames), `RetroTemplateLoader` (to load templates from `dev-handbook/templates/reflections/`).
-   **Molecules**: Create composed operations like `RetroLoader` (to load a specific retro by path or ID), `RetrosFinder` (to locate retrospectives based on filters), and `RetroFileCreator` (to write new retro files using templates and initial metadata).
-   **Organisms**: Implement a `RetroManager` organism to orchestrate the molecules and atoms, providing the business logic for the `create`, `next`, and `list` CLI commands. This organism will handle file system interactions, metadata parsing, and output formatting.
-   **CLI Interface**: Design clear and deterministic command-line interfaces for `ace-taskflow retro` and `ace-taskflow retros`, consistent with existing `task` and `release` commands, ensuring parseable output for AI agents.
-   **Configuration**: Leverage the `.ace/` configuration cascade for optional settings related to default retro templates or naming conventions.

## Considerations
-   **Path Validation**: Ensure all file operations related to retrospectives include robust path validation to prevent security vulnerabilities, aligning with ACE security principles.
-   **Template Integration**: Utilize existing templates in `dev-handbook/templates/reflections/` for `retro create`, adhering to ADR-001 (Workflow Self-Containment) if used by workflows, or standard template loading for CLI.
-   **Metadata Standard**: Decide on a consistent metadata format (e.g., YAML front matter) within the markdown files to ensure interoperability and ease of parsing.
-   **Output Consistency**: Ensure `list` commands provide structured, parseable output (e.g., JSON or YAML) that AI agents can easily consume for analysis.
-   **Integration with `ace-nav`**: Consider how `ace-nav` could potentially link to or discover retrospectives in the future.

## Benefits
-   Provides a standardized and automated way to manage project retrospectives, improving historical tracking and knowledge retention.
-   Enables AI agents to autonomously create, review, and analyze project reflections, facilitating continuous improvement cycles.
-   Rich metadata allows for programmatic querying and aggregation of insights from past projects, supporting data-driven decision-making.
-   Aligns `ace-taskflow` with the vision of making every development capability an installable, AI-native Ruby gem.

---

## Original Idea

```
we should add retro / retros cmd to ace-taskflow to be able create fetch the next in the list, or list all retros - additional we can think about metadata for retros
```

---
Captured: 2025-09-30 10:48:26