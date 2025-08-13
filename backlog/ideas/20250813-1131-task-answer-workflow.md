---
:input_tokens: 45969
:output_tokens: 1252
:total_tokens: 47221
:took: 8.662
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-13T10:32:08Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45969
:cost:
  :input: 0.004597
  :output: 0.000501
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005098
  :currency: USD
---

```markdown
# Task Review Workflow Integration

## Intention

To create a new workflow that prepares project and task context, including any pending review questions, and submits it to GPT-5 for answering.

## Problem It Solves

**Observed Issues:**
- AI agents need a structured way to ask clarifying questions about project context, release details, or specific tasks that require review.
- Manually gathering and formatting this context for LLM queries is inefficient and prone to errors.
- There isn't a defined process for AI agents to ask for help or clarification on tasks that have review-required questions.

**Impact:**
- Inefficient AI agent workflows due to manual context gathering for questions.
- Delays in task completion when clarification is needed but not easily obtainable.
- Inconsistent or incomplete context provided to LLMs when questions arise.
- Lack of a clear mechanism for AI agents to signal the need for external clarification.

## Key Patterns from Reflections

- **Workflow Self-Containment (ADR-001)**: The new workflow must be self-contained, embedding all necessary context rather than referencing external documents.
- **Universal Document Embedding System (ADR-005)**: The workflow can leverage this system to embed relevant project, release, and task information.
- **ATOM Architecture**: The new workflow will likely be an "Ecosystem" or "Organism" level component, orchestrating other tools (Molecules, Atoms).
- **CLI Tool Patterns**: The workflow will likely be executed via a CLI command, potentially within the `dev-tools` gem.
- **LLM Integration Architecture**: The workflow will integrate with an LLM provider (GPT-5), requiring careful prompt engineering and context preparation.
- **Task Management**: The workflow needs to identify tasks with "review required" questions.

## Solution Direction

1. **Workflow Definition (`answer-task-question.wf.md`)**: Define a new workflow that:
    - Identifies the current project context (e.g., from `docs/blueprint.md`, `docs/architecture.md`).
    - Identifies the current release context (e.g., from `dev-taskflow/current/` or `release-manager`).
    - Filters and gathers all tasks that have "review required" questions.
    - Formats this gathered information into a structured prompt for the LLM.
    - Invokes an LLM (GPT-5) using `llm-query` or a similar mechanism.
    - Processes the LLM's response and potentially updates the task status or adds comments.

2. **Task Context Gathering Mechanism**: Develop a component (likely a Molecule or Organism) that can:
    - Access task data from `dev-taskflow/`.
    - Identify tasks with specific "review required" flags or question fields.
    - Extract relevant context for each task, including project and release details.

3. **LLM Interaction Component**: Utilize or extend existing LLM integration components (Organisms) to:
    - Select GPT-5 as the target model.
    - Construct a prompt that includes the prepared project, release, and task-specific context and questions.
    - Handle the LLM API call and parse the response.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the exact format or flag used to mark a task as having "review required" questions within the `dev-taskflow/` structure?
2. How should the project and release context be dynamically determined and embedded within the workflow?
3. What is the specific prompt structure and desired output format for GPT-5 to effectively answer task-related questions?

**Open Questions:**
- What LLM provider and model name corresponds to "gpt-5" within our `llm-query` tool?
- How should the workflow handle situations where GPT-5 cannot provide a satisfactory answer or when the answer needs further human validation?
- Should the workflow automatically update task statuses or add comments based on GPT-5's answers, or should this be a manual step?

## Assumptions to Validate

**We assume that:**
- GPT-5 is accessible via our LLM integration tools and has a defined model name. - *Needs validation*
- The "review required" questions for tasks are stored in a machine-readable format within the `dev-taskflow/` repository. - *Needs validation*
- The context gathered (project, release, task details) can be effectively formatted into a prompt that GPT-5 can understand and act upon. - *Needs validation*

## Expected Benefits

- Streamlined process for AI agents to seek clarification on complex tasks.
- Improved AI agent autonomy by enabling them to gather necessary context for questions.
- More efficient task resolution when clarification is needed from external knowledge sources.
- Consistent and structured approach to querying LLMs for task-specific information.

## Big Unknowns

**Technical Unknowns:**
- The precise schema or method for storing "review required" questions within task files.
- The optimal prompt engineering strategy for GPT-5 to elicit accurate and actionable answers for task-related queries.
- The exact mechanism for integrating a specific LLM like "GPT-5" if it's not a direct alias in our current `llm-query` tool.

**User/Market Unknowns:**
- How frequently will AI agents need to ask clarifying questions that require external LLM consultation?
- What types of questions are most likely to arise that would benefit from GPT-5's advanced capabilities?

**Implementation Unknowns:**
- Which existing ATOM components (Atoms, Molecules, Organisms) can be leveraged or extended for this workflow?
- What level of detail is required in the embedded context for GPT-5 to be most effective?
- How will the success or failure of the GPT-5 query be reported back to the AI agent or task management system?
```

> SOURCE

```text
in context of task specification, after /task-review - regardless it is for draft (behaviour) pending (implementation) - we should add workflow /answear-task-question -> that will prepare context of the project / release / and all task (that have any questions review required) - and send it to gpt-5 to get the answears
```
