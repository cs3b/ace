---
:input_tokens: 45603
:output_tokens: 1206
:total_tokens: 46809
:took: 6.619
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-02T08:35:04Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45603
:cost:
  :input: 0.00456
  :output: 0.000482
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005043
  :currency: USD
---

# Integrate Custom Claude Commands into Claude Code Integration Script

## Intention

To integrate custom Claude commands for planning, working on, and drafting tasks into the Claude code integration script, ensuring these commands are discoverable and usable within the `dev-handbook/.integrations/claude/install-prompts.md` system.

## Problem It Solves

**Observed Issues:**
- Custom Claude commands for task management (`plan-tasks`, `work-on-tasks`, `draft-tasks`) are not currently recognized or integrated into the Claude Code integration script.
- These commands are not discoverable or executable within the `dev-handbook/.integrations/claude/install-prompts.md` framework, limiting their usability for AI agents interacting with Claude.
- Lack of standardization for adding new custom commands to the Claude integration script.

**Impact:**
- AI agents relying on Claude Code integration cannot leverage the custom task management commands.
- Development workflow for adding new, specialized commands to the Claude integration is not defined, leading to manual integration or missed functionality.
- Inconsistent user experience for AI agents interacting with Claude for task management.

## Key Patterns from Reflections

- **Workflow Self-Containment (ADR-001)**: New commands should ideally be self-contained or clearly documented as part of the integration script.
- **XML Template Embedding (ADR-002)**: Prompts and commands within the integration script might follow a structured format, potentially XML, for easier parsing and management.
- **Universal Document Embedding System (ADR-005)**: The integration script itself might embed or reference other documents, following a consistent system.
- **ATOM Architecture**: While not directly applicable to the script itself, the underlying principles of modularity and clear separation of concerns should guide how commands are added and managed.
- **Dynamic Provider System Architecture (ADR-012)**: If the integration script itself dynamically loads commands or providers, new commands should fit into this discoverable pattern.
- **Class Naming Conventions (ADR-013)**: If commands are implemented as Ruby classes, they should follow established naming conventions.

## Solution Direction

1. **Analyze `install-prompts.md` Structure**: Examine the existing `dev-handbook/.integrations/claude/install-prompts.md` file to understand how prompts/commands are currently defined, registered, or structured.
2. **Define Command Integration Strategy**: Determine the best method to register and expose the custom commands (`plan-tasks`, `work-on-tasks`, `draft-tasks`) within the Claude integration script. This could involve:
    - Adding new entries to a configuration file.
    - Creating new Ruby/Python files that are automatically discovered.
    - Modifying the script to parse and execute these commands.
3. **Implement Command Logic**: Ensure the actual logic for `plan-tasks`, `work-on-tasks`, and `draft-tasks` is either already present in a callable format or needs to be developed and placed in an accessible location.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the exact structure and format of `dev-handbook/.integrations/claude/install-prompts.md` and how are commands typically added?
2. Where is the implementation logic for `plan-tasks`, `work-on-tasks`, and `draft-tasks` located, and in what language is it written (e.g., Ruby, Python)?
3. What is the expected output or behavior of these custom commands when invoked by the Claude integration script?

**Open Questions:**
- Does the Claude integration script support arbitrary command execution, or does it require commands to conform to a specific interface or registration method?
- Are there existing patterns for adding new commands to this integration script that should be followed?
- What versioning or discovery mechanism is in place for commands within the Claude integration?

## Assumptions to Validate

**We assume that:**
- The `dev-handbook/.integrations/claude/install-prompts.md` file is the correct place to register or define these commands for Claude Code integration. - *Needs validation*
- The underlying logic for `plan-tasks`, `work-on-tasks`, and `draft-tasks` is either available or can be easily made available to the Claude integration script. - *Needs validation*
- The integration will involve adding new entries or files that the existing script can parse and execute. - *Needs validation*

## Expected Benefits

- **Enhanced AI Agent Capabilities**: AI agents using Claude Code integration will gain access to task management commands.
- **Improved Workflow Efficiency**: Streamlined task planning, execution, and drafting through integrated commands.
- **Standardized Integration Process**: A clear method for adding future custom commands to the Claude integration.
- **Increased Discoverability**: Commands become readily available to users of the Claude integration.

## Big Unknowns

**Technical Unknowns:**
- The specific technical requirements for integrating new commands into the Claude integration script (e.g., required file types, naming conventions, registration methods).
- The existing implementation details of the Claude integration script and how it discovers and executes commands.

**User/Market Unknowns:**
- How users (AI agents or developers) will expect these commands to be invoked within the Claude interface.
- The precise user experience for interacting with these commands via Claude.

**Implementation Unknowns:**
- The effort required to modify `dev-handbook/.integrations/claude/install-prompts.md` and potentially other parts of the Claude integration system.
- The testing strategy needed to ensure these new commands integrate correctly and function as expected.