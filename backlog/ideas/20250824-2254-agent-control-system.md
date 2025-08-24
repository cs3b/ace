---
:input_tokens: 115376
:output_tokens: 1279
:total_tokens: 116655
:took: 4.626
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-24T21:54:58Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 115376
:cost:
  :input: 0.011538
  :output: 0.000512
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.012049
  :currency: USD
---

# Enhance Agent Control and Security with Custom Shell and Firewall

## Intention

To provide agents with a more secure, controlled, and configurable environment by implementing a custom shell and firewall, alongside enhanced system prompt management for tool selection and better testing of the MCP proxy.

## Problem It Solves:

**Observed Issues:**
- Current reliance on "hooks" for Claude Code to block Git commands is a reactive and potentially fragile security mechanism.
- Limited granular control over agent actions and environment access.
- System prompts are not easily configurable to define available tools or specific agent behaviors.
- Lack of robust testing for the MCP proxy's capabilities in enforcing agent constraints.

**Impact:**
- Increased security risk due to potential bypass of basic Git command blocking.
- Reduced ability to define fine-grained permissions for agents, limiting their safe operational scope.
- Inconsistent agent behavior due to lack of control over system prompts and tool access.
- Difficulty in validating and improving the MCP proxy's effectiveness as a constraint enforcement mechanism.

## Key Patterns from Reflections:

- **Security-First Development**: The project emphasizes path validation, sanitization, and secure logging. This proposal extends that by focusing on runtime agent security. (docs/architecture.md, docs/architecture-tools.md)
- **ATOM Architecture**: The custom shell and firewall components could be designed as Molecules or Organisms, leveraging existing Atoms for execution and path management. (docs/architecture-tools.md)
- **Multi-Provider LLM Integration**: The system's flexibility with LLMs should extend to how agents interact with the environment, implying a need for provider-agnostic control mechanisms. (docs/architecture-tools.md)
- **MCP Proxy Integration**: The mention of MCP proxy suggests an existing framework for agent communication that can be leveraged and tested. (dev-handbook/.integrations/README.md)
- **Workflow Self-Containment**: While this proposal is about agent environment, it aligns with the principle of making components functional and testable in isolation. (docs/decisions/ADR-001-workflow-self-containment-principle.md)

## Solution Direction:

1. **Custom Agent Shell**: Implement a sandboxed shell environment that intercepts and validates agent commands before execution.
    - This shell will act as an intermediary between the agent's requested action and the underlying system.
    - It will integrate with the firewall to enforce access policies.
2. **Agent Firewall**: Develop a rule-based firewall to control agent access to system resources, commands, and network operations.
    - Rules can be defined per agent or per workflow, specifying allowed/denied actions.
    - This replaces the current "hooks" approach with a more comprehensive and configurable security layer.
3. **Configurable System Prompts**: Enhance the system prompt management to allow explicit definition of available tools and execution contexts for agents.
    - This ensures agents are aware of and restricted to the tools they are permitted to use, potentially defined via the MCP proxy.
4. **MCP Proxy Testing and Enhancement**: Actively use and potentially extend the MCP proxy to test and validate the effectiveness of the custom shell, firewall, and system prompt configurations.
    - This will involve defining test scenarios for various agent behaviors and constraint enforcement.

## Critical Questions:

**Before proceeding, we need to answer:**
1. What specific commands or system resources should be explicitly allowed/denied by default in the custom shell and firewall for a secure baseline?
2. How will the system prompt configuration integrate with the MCP proxy to dynamically provide agents with their allowed toolsets and execution contexts?
3. What is the minimum viable set of rules and configurations required for the firewall to effectively replace the current "hooks" and provide meaningful control?

**Open Questions:**
- How will the custom shell handle agent requests that involve file system access (reading, writing, creating, deleting)?
- What level of abstraction should the MCP proxy testing reach? Should it simulate full agent interactions or focus on specific command/tool invocations?
- How will we manage the lifecycle and updates of firewall rules and system prompt configurations?
- What are the performance implications of running commands through an additional shell/firewall layer?

## Assumptions to Validate:

**We assume that:**
- The MCP proxy can be effectively leveraged to pass tool definitions and execution constraints to agents in a structured way. - *Needs validation*
- A rule-based system can adequately define and enforce agent permissions without becoming overly complex. - *Needs validation*
- Intercepting commands via a custom shell is a robust enough mechanism to prevent unauthorized actions. - *Needs validation*
- Developers will be able to define and manage firewall rules and system prompts effectively. - *Needs validation*

## Expected Benefits:

- **Enhanced Security**: Significantly reduces the attack surface by strictly controlling agent actions and resource access.
- **Improved Agent Control**: Allows for precise definition of agent capabilities and operational boundaries.
- **Increased Reliability**: Predictable agent behavior due to controlled execution environment.
- **Better Testability**: Provides a solid foundation for testing MCP proxy integration and agent security models.
- **Adherence to Security-First Principle**: Aligns with the project's core commitment to security in development tools.

## Big Unknowns:

**Technical Unknowns:**
- The exact implementation details of the custom shell and how it will intercept and validate commands across different operating systems and shells (e.g., bash, zsh, fish).
- The performance overhead introduced by the custom shell and firewall layers.
- The complexity of defining and managing comprehensive firewall rulesets.

**User/Market Unknowns:**
- How users (developers or AI agents) will perceive and interact with the new security controls.
- The demand for highly granular agent permission management beyond basic command blocking.

**Implementation Unknowns:**
- The effort required to integrate with the MCP proxy for dynamic tool definition.
- The potential need for a dedicated DSL or configuration format for firewall rules.
- The strategy for testing and validating the custom shell and firewall against various attack vectors or edge cases.

> SOURCE

```text
instead of hooks for claude code to block git commands we should have a custom shell, and custom firewal to controll how the agent is working, and what is allowed, and whats not; additional ability to controll system prompts would be great (so we can define list of tools for agents - maybe we should go further with mcp-proxy to test it more.
```
