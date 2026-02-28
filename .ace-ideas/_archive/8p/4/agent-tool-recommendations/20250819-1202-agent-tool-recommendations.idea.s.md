---
:input_tokens: 85569
:output_tokens: 1120
:total_tokens: 86689
:took: 3.724
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-19T11:02:24Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 85569
:cost:
  :input: 0.008557
  :output: 0.000448
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.009005
  :currency: USD
---

# Add Information About Recommended Agents and Tools to Workflow Instructions

## Intention

Enhance workflow instructions by embedding information about recommended agents and tools to guide AI agents towards more effective and efficient execution.

## Problem It Solves

**Observed Issues:**
- AI agents may not know about specialized agents or tools that could perform sub-tasks more efficiently or reliably.
- Workflow instructions currently lack guidance on leveraging the full suite of available specialized agents and tools.
- Discovery of optimal agents and tools for specific sub-tasks within a workflow is left to the agent's own (potentially limited) knowledge or exploration.

**Impact:**
- AI agents might use less optimal or more general-purpose tools, leading to longer execution times or less precise results.
- The discovery of specialized agents and tools within the toolkit is not being actively guided for AI agents.
- Potential for increased prompt engineering or trial-and-error by AI agents to find the right tools.

## Key Patterns from Reflections

- **Self-Contained AI Workflows**: Workflows in `.ace/handbook/workflow-instructions/` are designed to be self-contained, meaning any necessary guidance should ideally be embedded within them.
- **ATOM Architecture**: The project is structured using ATOM, with distinct layers (Atoms, Molecules, Organisms, Ecosystems) for tools in `.ace/tools/lib/coding_agent_tools/`. This structure implies specialized components (Organisms) that act as agents or tools.
- **Specialized Development Agents**: The project has specialized agents (e.g., for Git, task management) documented in `.ace/handbook/.integrations/claude/agents/`.
- **CLI Tool Reference**: `docs/tools.md` provides a comprehensive cheat-sheet of available CLI tools.
- **Workflow Instructions**: Workflows themselves define sequences of actions, and could benefit from explicit recommendations for sub-tasks.

## Solution Direction

1. **Embed Agent/Tool Recommendations within Workflows**:
   * **Description**: Modify existing and new workflow instruction files (`.wf.md`) to include sections that suggest specific agents or CLI tools for particular sub-tasks or decision points within the workflow. This aligns with the "self-contained" principle (ADR-001) and the goal of providing comprehensive guidance.

2. **Create a Structured Recommendation Format**:
   * **Description**: Define a clear, parseable format for embedding these recommendations. This could be a new markdown section like `## Recommended Agents and Tools` or a more structured YAML/JSON block within the workflow.

3. **Reference `docs/tools.md` and Agent Directories**:
   * **Description**: Ensure recommendations point to the correct agent names (e.g., `git-commit` CLI tool, `task-finder` agent) and potentially link to relevant documentation or the specific tool's purpose as described in `docs/tools.md` or agent definition files.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the most effective and parseable format for embedding agent/tool recommendations within workflow instructions? (e.g., Markdown list, YAML block, specific tags)
2. How should recommendations be presented to avoid overwhelming the AI agent while still providing sufficient guidance?
3. What is the process for determining which agents/tools are "recommended" for a given sub-task? Is this static, or context-dependent?

**Open Questions:**
- Should recommendations be hardcoded into workflows, or should there be a mechanism to dynamically suggest tools based on workflow context?
- How will these recommendations be kept up-to-date as new agents and tools are added or existing ones are refactored?
- What is the expected impact on workflow file size and readability with the addition of recommendation sections?

## Assumptions to Validate

**We assume that:**
- AI agents can effectively utilize explicit recommendations embedded within workflow instructions. - *Needs validation*
- The existing workflow structure can accommodate new recommendation sections without breaking parsers or significantly impacting readability. - *Needs validation*
- There is a clear mapping between sub-tasks in a workflow and the most appropriate specialized agent or tool. - *Needs validation*

## Expected Benefits

- **Improved Agent Efficiency**: AI agents can leverage specialized tools and agents more readily, leading to faster and more accurate task completion.
- **Enhanced Discoverability**: Makes the toolkit's specialized capabilities more apparent to AI agents executing workflows.
- **Reduced Agent "Guesswork"**: Provides explicit guidance, minimizing the need for agents to infer the best approach or tool.
- **More Robust Workflows**: Workflows become more resilient by guiding agents towards proven, specialized components.

## Big Unknowns

**Technical Unknowns:**
- The best method for integrating recommendation data without creating parsing conflicts or overly verbose workflow files.
- Potential need for a new CLI tool or workflow helper to manage and validate these embedded recommendations.

**User/Market Unknowns:**
- How much "guidance" is optimal before it becomes overwhelming or prescriptive for the AI agent's autonomy.
- User perception of workflows that are heavily "opinionated" about tool usage.

**Implementation Unknowns:**
- The effort required to update all existing workflows with relevant recommendations.
- The process for ensuring recommendations remain accurate and relevant as the toolkit evolves.
```

> SOURCE

```text
in context of commands / workflow instructions -> we should add info about recommneded agents and tools worth to use
```
