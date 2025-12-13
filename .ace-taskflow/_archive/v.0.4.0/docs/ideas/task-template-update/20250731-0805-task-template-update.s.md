---
:input_tokens: 45628
:output_tokens: 1002
:total_tokens: 46630
:took: 4.366
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-07-31T07:05:55Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45628
:cost:
  :input: 0.004563
  :output: 0.000401
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.004964
  :currency: USD
---

# Update Task Template for Enhanced Development Phases

## Intention

To enhance the task template by incorporating structured phases for development, including automatic tests, implementation, verification (manual and acceptance), and improved guidance for AI agents.

## Problem It Solves

**Observed Issues:**
- The current task template lacks specific sections for different development lifecycle stages (implementation, testing, verification).
- There is no standardized way to define or embed automatic tests within a task.
- Manual verification and acceptance criteria are not explicitly called out, leading to ambiguity.
- AI agents lack clear guidance on how to structure their work through distinct development phases.
- The existing template may not sufficiently guide the AI agent through the entire development lifecycle of a task.

**Impact:**
- Inconsistent task execution by AI agents, leading to incomplete or unverified work.
- Difficulty in tracking progress and ensuring quality at each stage of development.
- Increased manual effort required from human developers to guide AI agents through task completion.
- Potential for missed requirements or unaddressed edge cases due to lack of structured verification.
- Reduced clarity on how to implement and test new features or bug fixes within a task.

## Key Patterns from Reflections

- **ADR-002: XML Template Embedding Architecture**: Templates are embedded within workflow instructions using XML. This new task template structure should also follow this pattern.
- **ADR-005: Universal Document Embedding System**: The system supports embedding different document types (templates, guides). This task template will leverage this by potentially embedding specific code snippets or test structures.
- **ADR-011: ATOM Architecture House Rules**: Components should follow ATOM principles. While this is a template, the structure should reflect a logical flow that could map to ATOM components (e.g., "Implementation" might relate to Organisms, "Tests" to Molecules/Atoms).
- **Workflow Self-Containment (ADR-001)**: The task template itself should be self-contained, providing all necessary instructions and examples within its structure.

## Solution Direction

1. **Phase-Based Structure**: Introduce distinct sections for `Implementation`, `Automated Tests`, `Verification`, and `Acceptance Criteria`.
2. **Embedded Test Structures**: Provide YAML or Markdown structures within the template for defining unit tests, integration tests, and their expected outcomes.
3. **Verification Guidelines**: Include explicit sections for manual verification steps and clear acceptance criteria.
4. **AI Agent Guidance**: Embed prompts and instructions within each phase to guide the AI agent's actions.

## Critical Questions

**Before proceeding, we need to answer:**
1. What specific YAML or Markdown structures would be most effective for embedding test definitions within the template?
2. How should the template handle tasks that might not require all phases (e.g., documentation-only tasks)?
3. What level of detail is required for "manual verification" and "acceptance criteria" to be actionable by an AI agent?

**Open Questions:**
- Should there be a "Pre-implementation" phase for setup or requirement clarification?
- How should dependencies between phases be managed or indicated?
- What is the best way to provide examples of test code or verification steps within the template?

## Assumptions to Validate

**We assume that:**
- AI agents can interpret and execute instructions within structured phases like "Implementation" and "Verification". - *Needs validation*
- Embedding test definitions directly in the template is feasible and will be parsable by future tooling. - *Needs validation*
- A consistent set of phases will cover the majority of task types encountered. - *Needs validation*

## Expected Benefits

- **Improved Task Clarity**: AI agents and human developers will have a clearer understanding of task requirements and expected outcomes at each stage.
- **Enhanced Testability**: Built-in support for defining tests will encourage better test coverage.
- **Standardized Workflow**: Consistent structure for all tasks will improve predictability and maintainability.
- **Increased AI Agent Autonomy**: Agents can better manage their workflow by following defined phases and criteria.
- **Better Quality Control**: Explicit verification and acceptance criteria ensure higher quality deliverables.

## Big Unknowns

**Technical Unknowns:**
- The specific tooling or scripts that will parse and execute these new template structures (e.g., for running embedded tests).
- How to handle complex or conditional test/verification steps within the template.

**User/Market Unknowns:**
- How AI agents will interpret and act upon the detailed phase instructions and embedded test definitions.
- Whether the proposed phase structure will be intuitive and useful for a wide range of task types.

**Implementation Unknowns:**
- The effort required to refactor existing workflows that embed task templates.
- The process for creating and maintaining standardized examples for each phase.