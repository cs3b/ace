---
:input_tokens: 45585
:output_tokens: 1488
:total_tokens: 47073
:took: 9.09
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-03T12:42:30Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45585
:cost:
  :input: 0.004559
  :output: 0.000595
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005154
  :currency: USD
---

```markdown
# Enhance Repository and Best Practice Research for Task Workflows

## Intention

Improve the efficiency and accuracy of how AI agents research repository structures and best practices, including project-specific guides, when executing task-related workflows.

## Problem It Solves

**Observed Issues:**
- AI agents currently lack a robust mechanism to intelligently research and understand project repository structures before executing task-related workflows.
- Research into best practices, including internal project guides, is manual and can be inefficient, leading to inconsistent application of standards.
- Workflows like `draft-task.wf`, `plan-task.wf`, and `review.task.wf` may not fully leverage available project context or adhere to all established best practices due to rudimentary research capabilities.
- There's no clear guidance on how AI agents should systematically identify and utilize relevant project documentation and guides for task execution.

**Impact:**
- AI agents may perform tasks without full awareness of the project's structure, leading to incorrect file operations or misinterpretation of context.
- Inconsistent adherence to best practices can result in code quality issues, architectural drift, and increased review cycles.
- Task execution may be slower or less effective due to suboptimal research strategies.
- The utility of internal guides and documentation as a knowledge source for AI agents is not fully realized.

## Key Patterns from Reflections

- **ADR-001: Workflow Self-Containment Principle**: Workflows must be self-contained, implying that necessary research context should ideally be discoverable or embedded.
- **ADR-002: XML Template Embedding Architecture**: Templates and potentially other document types can be embedded, suggesting a structured way to include knowledge.
- **ADR-004: Consistent Path Standards**: Defined paths for templates and guides (`dev-handbook/templates/`, `dev-handbook/guides/`) provide a structured way to locate resources.
- **ADR-005: Universal Document Embedding System**: The ability to embed multiple document types (guides, templates) within workflows suggests a pattern for providing context.
- **ADR-011: ATOM Architecture House Rules**: Emphasizes clear component classification, which could be extended to how research capabilities are structured (e.g., a dedicated "research" molecule or organism).
- **`nav-tree` and `nav-path` Tools**: Existing CLI tools (`dev-tools/exe/nav-tree`, `dev-tools/exe/nav-path`) are designed for repository navigation, indicating a foundational capability that can be enhanced.
- **`handbook` Tool**: The `handbook sync-templates` command suggests a mechanism for accessing and synchronizing documentation, which could be leveraged for research.
- **`llm-query` Tool**: The ability to query LLMs with specific prompts is a core mechanism that can be used for synthesizing information found during research.
- **Project Blueprint (`docs/blueprint.md`)**: Provides an overview of project structure, which can be a starting point for repository research.
- **Tools Reference (`docs/tools.md`)**: Documents available CLI tools, some of which might be useful for research or information gathering.

## Solution Direction

1. **Enhanced `nav-tree` and `nav-path` Usage**:
    - **Description**: Augment existing navigation tools within workflows to intelligently identify relevant directories and files based on task context (e.g., `draft-task`, `plan-task`, `review-task`). This could involve context-aware file discovery beyond simple path resolution.
2. **Structured Guide Indexing and Querying**:
    - **Description**: Develop a mechanism to index or create a searchable map of the `dev-handbook/guides/` directory. AI agents could then query this index to find the most relevant guides for a given task, potentially using LLM summarization or keyword matching.
3. **LLM-Powered Synthesis of Research Findings**:
    - **Description**: Combine the output from navigation tools and guide searches, then use `llm-query` to synthesize this information into actionable insights or summaries directly relevant to the current task workflow. This allows AI agents to "understand" the repository and best practices rather than just listing files.

## Critical Questions

**Before proceeding, we need to answer:**
1. What specific search queries or patterns should AI agents use to effectively identify relevant guides and repository sections for different task types (drafting, planning, reviewing)?
2. How can we systematically index or map the `dev-handbook/guides/` directory to enable efficient programmatic searching and retrieval of relevant information?
3. What is the optimal way to integrate `llm-query` to synthesize research findings, ensuring the output is concise, accurate, and directly applicable to the workflow's current step?

**Open Questions:**
- Should a dedicated "research" molecule or organism be created to encapsulate these enhanced research capabilities, or should this functionality be integrated into existing task workflow logic?
- How can we balance the depth of research to avoid overwhelming the AI agent with too much information while still ensuring all critical context is gathered?
- What specific LLM prompts are most effective for synthesizing repository structure and best practice information into actionable steps for task-related workflows?

## Assumptions to Validate

**We assume that:**
- The `dev-handbook/guides/` directory contains sufficiently relevant and well-structured information to be useful for AI agent research. - *Needs validation*
- The existing `nav-tree` and `nav-path` tools can be extended or used in conjunction with new logic to effectively identify task-relevant project context. - *Needs validation*
- AI agents can effectively process and act upon LLM-synthesized research findings. - *Needs validation*

## Expected Benefits

- **Improved AI Agent Efficiency**: Faster and more accurate execution of task-related workflows.
- **Enhanced Best Practice Adherence**: Consistent application of project standards and guidelines.
- **Reduced Rework**: Tasks are more likely to be completed correctly the first time due to better contextual understanding.
- **Increased Leverage of Project Documentation**: Internal guides become more accessible and actionable for AI agents.
- **More Intelligent Workflow Execution**: Workflows can adapt dynamically based on discovered project context.

## Big Unknowns

**Technical Unknowns:**
- The specific implementation details for indexing the `dev-handbook/guides/` directory and performing efficient searches.
- The optimal LLM prompts required for synthesizing research findings relevant to various task types.

**User/Market Unknowns:**
- How will AI agents and developers perceive the enhanced research capabilities in terms of usefulness and integration into their workflow?
- What level of detail in research findings is most beneficial for AI agents?

**Implementation Unknowns:**
- The effort required to refactor existing task workflows (`draft-task.wf`, `plan-task.wf`, `review.task.wf`) to incorporate these new research capabilities.
- How to best integrate these new research functions within the existing ATOM architecture (e.g., as new molecules or by extending existing ones).
```