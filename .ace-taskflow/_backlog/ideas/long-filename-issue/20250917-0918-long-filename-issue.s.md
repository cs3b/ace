---
:input_tokens: 74787
:output_tokens: 1277
:total_tokens: 76064
:took: 4.955
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-09-17T08:18:50Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 74787
:cost:
  :input: 0.007479
  :output: 0.000511
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.00799
  :currency: USD
---

# Address Long Filename Issues in Workflow Instructions

## Intention

To identify and mitigate potential filename length issues within the workflow instruction files that could cause problems on certain operating systems or file systems.

## Problem It Solves

**Observed Issues:**
- {specific_issue_1} The user has explicitly stated that the idea involves extremely long filenames.
- {specific_issue_2} This repetition indicates a significant focus on the filename length problem.
- {specific_issue_3} Current workflow instruction files may exceed acceptable filename length limits on some systems, leading to errors or unmanageable file paths.

**Impact:**
- {consequence_1} Workflows may fail to be created, accessed, or processed correctly on systems with strict filename length limits (e.g., Windows).
- {consequence_2} Development and debugging efforts could be hindered by unmanageable or unresolvable file paths.
- {consequence_3} Potential for data corruption or system instability if file operations fail due to path length issues.

## Key Patterns from Reflections

{patterns_extracted_from_project_context}
- **Workflow Instructions**: The core of the problem lies within `.ace/handbook/workflow-instructions/` directory.
- **Filename Conventions**: The project aims for structured filenames, but extreme length is now identified as a problem.
- **File Embedding**: ADR-002 and ADR-005 describe XML-based embedding of templates and documents, which could indirectly contribute to long paths if the embedded content itself has very long filenames.
- **`create-path` tool**: This tool might be involved in creating these long filenames, and its behavior might need adjustment.
- **`docs/decisions/ADR-003-template-directory-separation.md`**: This ADR defines template directory structure, which might influence the depth and length of paths.
- **`docs/decisions/ADR-004-consistent-path-standards.md`**: This ADR mandates relative paths and specific patterns like `.ace/handbook/templates/**/*.template.md`, which contributes to path length.
- **`docs/decisions/ADR-013-Class-Naming-Conventions-and-Zeitwerk-Inflections.t.md`**: While focused on class names, the underlying principles of naming conventions could be applied to filenames for workflows.
- **`docs/decisions/ADR-014-LLM-Integration-Architecture.t.md`**: This ADR mentions `very-long-long-long-long-long-long-long-long-long-long-long-long-long-long-long.md` within its context, directly illustrating the problem.

## Solution Direction

1. **Identify and Catalog Long Filenames**: Scan the `.ace/handbook/workflow-instructions/` directory and any related template/guide paths to identify filenames that are approaching or exceeding common system limits (e.g., 255 characters).
2. **Develop Renaming Strategy**: Create a strategy to shorten these filenames while maintaining clarity and adhering to existing project conventions (e.g., using abbreviations, removing redundant words, re-categorizing).
3. **Automate Renaming and Path Updates**: Implement scripts or leverage existing tools (like `create-path` if applicable) to rename files and automatically update all references (in workflow XML, documentation, and scripts) to these renamed files.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the maximum acceptable filename length for the target development environments (considering common OS limitations)?
2. What specific workflows or templates currently have the longest filenames, and what are their exact paths?
3. What is the current strategy for generating workflow and template filenames, and how can it be modified to prevent future long filename issues?

**Open Questions:**
- {uncertainty_1} Will renaming workflows require changes to the underlying LLM agent parsing or execution logic?
- {uncertainty_2} Are there any tools or systems within the project that are particularly sensitive to filename length?
- {uncertainty_3} What is the best approach for communicating these changes to developers and AI agents using the system?

## Assumptions to Validate

**We assume that:**
- {assumption_1} Renaming workflows will not fundamentally break their intended functionality, provided all internal references are updated correctly. - *Needs validation*
- {assumption_2} A clear and consistent renaming convention can be devised that shortens filenames without sacrificing clarity or breaking existing patterns. - *Needs validation*
- {assumption_3} Automated tools exist or can be created to reliably update all references to renamed files across the project. - *Needs validation*

## Expected Benefits

- {benefit_1} Improved compatibility and stability across all development environments, especially those with stricter filename length limitations.
- {benefit_2} Easier management and navigation of workflow files, reducing potential errors and confusion.
- {benefit_3} Prevention of future issues by establishing better conventions for generating workflow and template filenames.

## Big Unknowns

**Technical Unknowns:**
- {technical_uncertainty_1} The precise impact of renaming on any external systems or integrations that might parse or reference workflow filenames directly.
- {technical_uncertainty_2} The effectiveness and scope of automated renaming and reference updating scripts across a complex multi-repository structure.

**User/Market Unknowns:**
- {user_uncertainty_1} How users (both human developers and AI agents) will adapt to potentially shorter, abbreviated workflow names.
- {user_uncertainty_2} Whether any specific AI agents rely on exact, long workflow names for their internal logic.

**Implementation Unknowns:**
- {implementation_uncertainty_1} The total effort required to identify, rename, and update all references across the entire project codebase.
- {implementation_uncertainty_2} The best strategy for handling the actual renaming process to minimize disruption (e.g., phased rollout, single atomic commit).

> SOURCE

```text
This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues. This is an extremely long idea that would cause filename length issues.
```
