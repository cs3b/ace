---
:input_tokens: 45872
:output_tokens: 1350
:total_tokens: 47222
:took: 7.148
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-07-31T08:57:29Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45872
:cost:
  :input: 0.004587
  :output: 0.00054
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005127
  :currency: USD
---

# Enhance `create-reflection-note` Workflow with Automation and Cookbook Generation

## Intention

To enhance the `create-reflection-note` workflow by enabling coding agents to capture insights on automation opportunities and identify potential new cookbooks, thereby improving the overall development process and knowledge sharing.

## Problem It Solves

**Observed Issues:**
- Current reflection notes lack structured prompts for identifying automation potential in workflows.
- There's no defined process for capturing insights that could lead to new reusable "cookbooks" for future tasks.
- The process of creating new cookbooks is manual and not integrated into the reflection workflow.
- Identifying improvements for future task automation (code, templates, task definitions) is not systematically captured.

**Impact:**
- Missed opportunities to automate repetitive parts of workflows, leading to continued manual effort.
- Valuable knowledge about specific integrations or setup processes is lost, requiring re-discovery for similar future tasks.
- Inefficient knowledge sharing, as insights on creating reusable guides are not systematically captured.
- Difficulty in identifying and creating standardized solutions (cookbooks) for common complex tasks.

## Key Patterns from Reflections

- **Workflow Self-Containment (ADR-001)**: New prompts must align with the principle that workflows should be self-contained, meaning automation ideas should be actionable within the current workflow's context or clearly define prerequisites for external tools/templates.
- **XML Template Embedding (ADR-002)**: Any new templates for cookbooks or automation ideas should follow the XML embedding structure.
- **Universal Document Embedding System (ADR-005)**: The system should support embedding various document types, including potential cookbook outlines or automation scripts.
- **ATOM Architecture**: Automation ideas should consider how they fit into the ATOM structure (e.g., new Atoms, Molecules, or Organisms).
- **Dynamic Provider System Architecture (ADR-012)**: If automation involves LLM providers, it should leverage the dynamic provider system.
- **Documentation-Driven Development**: The process of identifying and creating cookbooks is inherently documentation-driven.
- **Tools Reference (`docs/tools.md`)**: Automation ideas related to code should consider existing `dev-tools` executables.

## Solution Direction

1. **Enhance `create-reflection-note` Workflow**:
   - Modify the `create-reflection-note.wf.md` workflow to include specific prompts for capturing automation insights and cookbook ideas.
   - Add sections that guide the AI agent to analyze the just-completed workflow execution for potential automation.
   - Structure prompts to elicit detailed suggestions for code-based tools, template improvements, and task definition enhancements for full automation.

2. **Integrate Cookbook Identification and Templating**:
   - Introduce prompts that ask the agent to identify potential "cookbooks" based on the completed workflow's complexity and reusable steps.
   - Define a standard template for cookbooks, including sections for purpose, prerequisites, step-by-step instructions, required documentation links, and potential code snippets.
   - Ensure these cookbook templates can be embedded within the reflection note using the XML format.

3. **Develop `create-cookbook.wf.md` Workflow**:
   - Create a new workflow specifically for generating cookbooks.
   - This workflow should take the identified cookbook idea and its outline from the reflection note as input.
   - It should guide the agent through the process of fleshing out the cookbook, referencing existing documentation, and creating the final cookbook file in `dev-handbook/cookbooks/`.

## Critical Questions

**Before proceeding, we need to answer:**
1. What specific questions within `create-reflection-note.wf.md` will best elicit actionable automation insights (code, templates, task definitions) from AI agents?
2. What is the minimal viable structure for a cookbook template that is both informative and easy for AI agents to generate?
3. How will the `create-cookbook.wf.md` workflow receive and process the cookbook idea and outline from the reflection note?

**Open Questions:**
- How should the system handle the storage and retrieval of "automation ideas" before they are formalized into cookbooks?
- What level of detail is expected from the AI agent when suggesting code-based automation (e.g., specific tool names, pseudocode, or full code)?
- How will we ensure that the generated cookbooks are accurate, complete, and adhere to project standards?
- What mechanisms will be in place to review and approve newly generated cookbooks?
- Should cookbook ideas be linked back to the specific workflow that inspired them?

## Assumptions to Validate

**We assume that:**
- AI agents can effectively analyze their own workflow execution to identify automation opportunities. - *Needs validation*
- AI agents can understand and generate content according to a defined cookbook template. - *Needs validation*
- The `create-cookbook.wf.md` workflow can be triggered or linked from the `create-reflection-note.wf.md` workflow. - *Needs validation*
- Capturing automation ideas and cookbook suggestions will lead to tangible improvements in workflow efficiency and knowledge sharing. - *Needs validation*

## Expected Benefits

- **Increased Workflow Automation**: Identification and implementation of automation opportunities will reduce manual effort in future workflow executions.
- **Enhanced Knowledge Sharing**: Creation of reusable cookbooks will democratize complex setup and integration knowledge.
- **Improved Workflow Quality**: Reflection process will actively drive improvements in workflow design and efficiency.
- **Systematic Improvement**: A structured process for identifying and creating cookbooks will lead to a more robust and helpful development ecosystem.
- **Better AI Agent Capabilities**: Agents will contribute to the improvement of their own operating environment.

## Big Unknowns

**Technical Unknowns:**
- How to best pass structured data (automation ideas, cookbook outlines) from one workflow (`create-reflection-note`) to another (`create-cookbook`) in a robust way.
- The feasibility and reliability of AI agents generating functional code snippets or detailed setup instructions for cookbooks.

**User/Market Unknowns:**
- The degree to which developers will find and utilize the generated cookbooks.
- The actual impact on development speed and efficiency gained from these new features.

**Implementation Unknowns:**
- The exact prompts required to elicit high-quality automation insights and cookbook ideas from AI agents.
- The optimal structure and content for the cookbook template to maximize usability.
- The integration points and workflow triggers between reflection and cookbook creation.