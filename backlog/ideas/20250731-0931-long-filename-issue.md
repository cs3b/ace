---
:input_tokens: 46270
:output_tokens: 1057
:total_tokens: 47327
:took: 4.116
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-07-31T08:31:36Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 46270
:cost:
  :input: 0.004627
  :output: 0.000423
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.00505
  :currency: USD
---

# Address Filename Length Issues in AI Workflow Instructions

## Intention

To develop a strategy and implement mechanisms to mitigate potential filename length issues arising from complex or lengthy AI workflow instructions.

## Problem It Solves

**Observed Issues:**
- {specific_issue_1} The repeated statement "This is an extremely long idea..." indicates a potential concern about the length of generated workflow descriptions or titles.
- {specific_issue_2} If these lengthy descriptions are directly used in filenames or as part of file paths, it could lead to operating system limitations on filename length.
- {specific_issue_3} Such long filenames can also hinder readability and manageability in file explorers and command-line interfaces.

**Impact:**
- {consequence_1} Potential for errors or unexpected behavior on file systems with strict filename length limits (e.g., Windows).
- {consequence_2} Reduced discoverability and usability of workflow files due to unmanageably long names.
- {consequence_3} Increased friction for developers and AI agents when interacting with the file system for workflow management.

## Key Patterns from Reflections

- **Workflow Self-Containment (ADR-001)**: Workflows are intended to be self-contained, which might lead to more descriptive (and potentially longer) titles or embedded content.
- **XML Template Embedding (ADR-002)**: While not directly related to filenames, the complexity of embedding content highlights the need for structured organization.
- **Universal Document Embedding (ADR-005)**: The support for various document types within workflows could indirectly lead to more complex naming if not managed carefully.
- **ATOM Architecture**: Encourages modularity, which could apply to how workflow components are named or referenced.
- **Blueprint Document**: Provides an overview of project structure, implying a need for clear and manageable naming conventions.

## Solution Direction

1. **{approach_1} Implement a Naming Convention Strategy**: Define a clear set of rules for generating workflow filenames that balance descriptiveness with brevity.
2. **{approach_2} Utilize Short, Semantic Identifiers**: Introduce short, unique identifiers (e.g., UUIDs, sequential IDs, or concise keywords) that can be used in filenames, with full descriptions stored in metadata or the workflow content itself.
3. **{approach_3} Develop a Workflow Registry/Mapping**: Maintain a central registry or mapping that links these short identifiers to their full, descriptive titles and content, allowing for easy lookup and management.

## Critical Questions

**Before proceeding, we need to answer:**
1. {validation_question_1} What are the specific filename length limitations of target operating systems (e.g., Windows, macOS, Linux)?
2. {validation_question_2} What is the maximum practical length for filenames to ensure readability and compatibility across all environments?
3. {validation_question_3} How will these short identifiers be generated and managed to ensure uniqueness and traceability back to the original, descriptive idea?

**Open Questions:**
- {uncertainty_1} Should the short identifiers be human-readable keywords, or purely machine-generated identifiers?
- {uncertainty_2} How will AI agents be trained or configured to use these short identifiers and access the full descriptions when needed?
- {uncertainty_3} What is the process for updating or renaming workflows if their descriptions change significantly?

## Assumptions to Validate

**We assume that:**
- {assumption_1} The current issue is indeed about workflow filenames, not just descriptive text within the workflows. - *Needs validation*
- {assumption_2} A mechanism exists or can be created to associate short identifiers with detailed workflow content for AI agents. - *Needs validation*
- {assumption_3} Developers and AI agents can adapt to using short identifiers in conjunction with a lookup mechanism for full descriptions. - *Needs validation*

## Expected Benefits

- {benefit_1} Avoids potential operating system errors related to excessively long filenames.
- {benefit_2} Improves the manageability and readability of the project's file structure.
- {benefit_3} Ensures consistent and robust naming conventions for all workflow instructions.

## Big Unknowns

**Technical Unknowns:**
- {technical_uncertainty_1} The exact implementation details of the workflow registry or mapping system.
- {technical_uncertainty_2} The mechanism for AI agents to access the full workflow descriptions from short identifiers.

**User/Market Unknowns:**
- {user_uncertainty_1} How end-users (developers or AI agents) will perceive and interact with a system using short identifiers.
- {user_uncertainty_2} The impact of this naming convention change on existing integrations or workflows.

**Implementation Unknowns:**
- {implementation_uncertainty_1} The effort required to refactor existing workflow filenames and update any references.
- {implementation_uncertainty_2} The best approach for generating and managing the short identifiers to maintain uniqueness and semantic meaning.