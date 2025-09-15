---
:input_tokens: 45604
:output_tokens: 1511
:total_tokens: 47115
:took: 9.851
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-04T20:49:58Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45604
:cost:
  :input: 0.00456
  :output: 0.000604
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005165
  :currency: USD
---

# Refactor CLI Tools for LLM-Driven Workflow Execution

## Intention

To refactor existing CLI tools in `dev-tools/exe/` to perform only essential minimum operations, delegating complex logic, template review, and final versioning to AI coding agents, thereby ensuring flexibility and reducing the need for tool modifications.

## Problem It Solves

**Observed Issues:**
- CLI tools are becoming too complex, incorporating business logic that should be handled by AI agents.
- Changes to workflow logic (e.g., template review, commit message generation) require modifications to the CLI tools themselves, hindering flexibility.
- The current approach does not fully leverage the capabilities of AI coding agents for complex tasks like content generation and nuanced review.
- Maintaining flexibility and adaptability in the face of evolving AI capabilities and workflow requirements is challenging with tightly coupled CLI tools.

**Impact:**
- Increased maintenance burden on the `dev-tools` gem for business logic changes.
- Slower iteration cycles for workflow improvements, as tool modifications are required.
- Underutilization of AI coding agents' strengths in complex reasoning, content generation, and nuanced decision-making.
- Reduced agility in adapting to new LLM providers, model capabilities, or changing development best practices.

## Key Patterns from Reflections

- **Workflow Self-Containment (ADR-001)**: Workflows should be executable without external dependencies. This refactoring aligns by ensuring tools provide the minimal interface for workflows to operate.
- **ATOM Architecture**: Tools should be placed in appropriate layers. CLI executables are entry points, but the complex logic should reside in Organisms or Molecules, and potentially be orchestrated by Workflows (Ecosystems).
- **LLM Integration Architecture**: The system is designed to integrate with multiple LLMs. CLI tools should act as interfaces to these LLMs, passing through workflow instructions.
- **Dynamic Provider System Architecture (ADR-012)**: The system is designed to be extensible with new providers. CLI tools should not hardcode provider-specific complex logic.
- **AI-Native Design**: The toolkit is built for AI agents. CLI tools should expose a predictable interface for AI agents to interact with.

## Solution Direction

1. **Minimalist CLI Executables**: CLI executables in `dev-tools/exe/` will be refactored to perform only the essential tasks of:
    - Parsing arguments and options.
    - Invoking the appropriate Ruby logic (Organisms/Molecules) to execute a command.
    - Handling basic input/output and error reporting (via `ErrorReporter`).
    - **Example**: `llm-query` will primarily parse arguments and call an `Organisms::LLMQueryHandler` or similar. It will not contain the logic for prompt formatting, model selection based on complex criteria, or response parsing beyond basic JSON/text handling.

2. **LLM Agent Orchestration via Workflows**: Complex operations, including template review, final versioning, and nuanced decision-making, will be orchestrated by AI coding agents via workflow instructions (`.wf.md` files).
    - Workflows will define the sequence of operations, including calling specific CLI tools and using LLM agents to perform the heavy lifting.
    - **Example**: A `review-code.wf.md` workflow might call `code-review-prepare` to get diff context, then pass that context to an AI agent for detailed review and recommendations, and finally call `code-review-synthesize` to format the agent's output.

3. **Delegate Complex Logic to Organisms/Molecules**: Business logic, template parsing, model selection heuristics, and response interpretation will be moved from CLI executables to their corresponding Organism or Molecule components within `dev-tools/lib/coding_agent_tools/`.
    - These components will be designed to be callable by both the CLI tools and directly by AI agents (if appropriate via workflow definition).
    - **Example**: The logic for generating a commit message based on `git diff` output and user intent will reside in an Organism, which the `git-commit` CLI tool will call. The `git-commit` CLI will not contain the LLM interaction logic itself.

## Critical Questions

**Before proceeding, we need to answer:**
1. Which specific CLI tools currently contain logic that should be offloaded to AI agents or Organisms/Molecules?
2. What is the precise definition of "minimum" for each existing CLI tool to ensure it can still be functional as a basic interface?
3. How will AI agents receive and interpret the output from these minimalist CLI tools to perform subsequent complex actions (e.g., parsing structured data from `llm-query` output)?

**Open Questions:**
- What is the strategy for handling configuration and context passing between AI agents, workflows, and the refactored CLI tools?
- How will we ensure that the refactored CLI tools still provide sufficient meta-information or structure in their output for AI agents to reliably parse and act upon?
- What existing tools or new utility functions are needed to support AI agents in consuming and processing the output of these minimalist CLI commands?

## Assumptions to Validate

**We assume that:**
- AI coding agents can effectively parse structured output from minimalist CLI tools to perform complex tasks. - *Needs validation*
- Workflows can be designed to orchestrate AI agents and CLI tools in a way that achieves the desired flexibility and reduces tool maintenance. - *Needs validation*
- The ATOM architecture can accommodate this separation, with CLI executables acting as thin wrappers around Organism/Molecule logic called by Workflows. - *Needs validation*

## Expected Benefits

- **Increased Flexibility**: Workflows can be easily modified or enhanced without requiring changes to the `dev-tools` gem.
- **Improved Maintainability**: The `dev-tools` gem focuses on core utilities, reducing the scope of changes needed for business logic evolution.
- **Better LLM Utilization**: AI agents will handle complex reasoning, content generation, and nuanced reviews, leveraging their strengths.
- **Faster Iteration Cycles**: Workflow improvements can be implemented purely in the workflow definitions (e.g., `dev-handbook/workflow-instructions/`) without gem releases.
- **Clearer Separation of Concerns**: CLI tools become simple interfaces, business logic resides in Organisms/Molecules, and orchestration happens in Workflows.

## Big Unknowns

**Technical Unknowns:**
- How to design the output format of minimalist CLI tools to be maximally parsable and useful for AI agents.
- The impact of this refactoring on the overall performance and startup time of CLI commands, especially if workflows dynamically invoke complex Ruby logic.

**User/Market Unknowns:**
- How will developers perceive the change in CLI tool behavior – will it be clearer or more complex to understand where logic resides?
- What is the optimal balance between CLI tool functionality and AI agent responsibility for different types of tasks?

**Implementation Unknowns:**
- The exact set of CLI tools that need refactoring and the specific logic to be extracted from each.
- The effort required to update existing workflows to correctly orchestrate AI agents and the refactored CLI tools.

> SOURCE

```text
all the tools in dev-tools/exe should do only the minimum, and the hardest part, all the template review, and final version should be done by the llm / coding agents e.g.: handbook claude commmands, so we stay flexible without the need to change tools
```
