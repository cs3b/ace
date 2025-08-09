---
:input_tokens: 45955
:output_tokens: 1564
:total_tokens: 47519
:took: 6.788
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-09T07:40:40Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45955
:cost:
  :input: 0.004596
  :output: 0.000626
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005221
  :currency: USD
---

# Update Tool Guides for Dev Handbook

## Intention

Update the development handbook's guides for the CLI tools to reflect current practices, specifically by removing references to binstubs, emphasizing the use of `dev-tools` for tool distribution, and integrating established best practices from the `dev-tools` library into the guides.

## Problem It Solves

**Observed Issues:**
- The "Tools Reference" guide (`docs/tools.md`) and other related documentation incorrectly mention the use of binstubs for accessing CLI tools.
- The current documentation does not clearly articulate that the primary distribution mechanism for CLI tools is via the `dev-tools` Ruby gem and its `exe/` directory.
- Established best practices within the `dev-tools` gem (e.g., ATOM architecture, security, LLM integration patterns) are not effectively transported and documented in the general development guides.
- Developer onboarding and tool usage documentation is outdated, potentially leading to confusion about how to access and utilize the project's CLI tools.

**Impact:**
- Developers and AI agents may be misled into using outdated or incorrect methods for accessing CLI tools, causing frustration and errors.
- The value and consistency of best practices established in `dev-tools` are not being effectively communicated or leveraged across the broader project documentation.
- Onboarding new team members or contributors to the toolset becomes more difficult due to inconsistent and inaccurate documentation.
- Potential for duplication of effort if best practices are not centralized and clearly communicated in the handbook.

## Key Patterns from Reflections

- **dev-tools/docs/tools.md**: This document serves as the primary reference for all CLI tools, including their purpose, usage, and flags. It should be the authoritative source for tool documentation.
- **dev-tools/exe/**: This directory contains the actual executable CLI tools, which are packaged within the `coding_agent_tools` Ruby gem.
- **ATOM Architecture**: The `dev-tools` gem is structured using ATOM principles, which should inform how guides explain component organization and best practices.
- **Security-First Development**: The gem incorporates security best practices (path validation, sanitization) that should be highlighted in relevant guides.
- **LLM Integration Architecture**: The unified LLM interface, cost tracking, and caching strategies are key features of `dev-tools` that should be documented in the handbook.
- **Multi-Repository Coordination**: The handbook needs to clearly link to and explain the role of the `dev-tools` submodule.
- **ADR-007: Zeitwerk for Autoloading**: This ADR highlights the importance of standardized autoloading, which is relevant to how tools are loaded and executed.
- **ADR-010: HTTP Client Strategy**: The use of Faraday and its middleware for API interactions is a key best practice within `dev-tools`.
- **ADR-011: ATOM Architecture House Rules**: These rules define component classification and should be used to explain the structure of the tools.

## Solution Direction

1. **Remove Binstub References**: Update all relevant handbook guides (especially `docs/tools.md` and any guides referencing tool execution) to remove any mention of binstubs as a method for accessing CLI tools.
2. **Emphasize Gem Distribution**: Clearly state that CLI tools are distributed via the `coding_agent_tools` Ruby gem and are executed directly from the `dev-tools/exe/` directory when working within the submodule, or via `gem install coding_agent_tools` when installed separately. Update `docs/tools.md` and `docs/what-do-we-build.md` to reflect this.
3. **Integrate `dev-tools` Best Practices**:
    - **ATOM Architecture**: Explain the ATOM structure as it applies to the tools housed in `dev-tools/lib/coding_agent_tools/`.
    - **Security**: Highlight security-first principles like path validation and sanitization that are implemented in the tools.
    - **LLM Integration**: Detail the unified LLM interface, cost tracking, and caching mechanisms as key features of the tools.
    - **CLI Design Principles**: Discuss the importance of consistent CLI interfaces, flags, and help messages, drawing from the established patterns in `dev-tools`.
    - **Testing Strategy**: Briefly mention the test-driven approach used for the tools (RSpec, VCR) and its importance for reliability.

## Critical Questions

**Before proceeding, we need to answer:**
1. Which specific guides in the `dev-handbook` currently reference binstubs or outdated tool access methods?
2. What is the most effective way to communicate the `dev-tools` gem as the sole distribution channel for CLI tools within the handbook?
3. How can we best integrate the ATOM architecture and security best practices from `dev-tools` into the handbook's guides without making them overly technical or redundant?

**Open Questions:**
- Should we create a dedicated "Tools Overview" section in the handbook that acts as an entry point to `dev-tools/docs/tools.md`?
- What level of detail regarding the internal workings of the `dev-tools` gem (e.g., specific middleware used by Faraday) should be included in the handbook guides?
- How can we ensure that updates to the `dev-tools` gem are reflected promptly in the handbook guides?

## Assumptions to Validate

**We assume that:**
- Developers and AI agents primarily interact with the CLI tools through the `dev-tools` submodule or a separately installed gem, not through direct binstub invocation. - *Needs validation: Confirm current primary access method.*
- The `docs/tools.md` file is the canonical reference for tool usage, and other guides should link to it rather than duplicating information. - *Needs validation: Confirm scope and authority of `docs/tools.md`.*
- The ATOM architecture, security principles, and LLM integration patterns from `dev-tools` are valuable context for handbook users. - *Needs validation: Gauge user interest and need for this level of detail.*

## Expected Benefits

- **Accurate Tooling Information**: Users will receive correct guidance on accessing and using CLI tools.
- **Improved Developer Experience**: Clearer documentation reduces confusion and onboarding time.
- **Consistent Best Practices**: Established practices from `dev-tools` will be more widely adopted.
- **Centralized Documentation**: Handbook becomes a more authoritative source for tool usage and related best practices.
- **Reduced Maintenance Overhead**: Eliminates the need to update multiple guides with outdated information.

## Big Unknowns

**Technical Unknowns:**
- Are there any edge cases or specific configurations within `dev-tools` that require special mention in the handbook guides?
- What is the precise mechanism for ensuring the handbook guides stay synchronized with the latest practices in the `dev-tools` gem?

**User/Market Unknowns:**
- How familiar are the target users (developers and AI agents) with Ruby gems and the ATOM architecture?
- What level of detail do users expect regarding the underlying implementation of the CLI tools?

**Implementation Unknowns:**
- What is the scope of changes required across all handbook documents to remove binstub references and integrate new best practices?
- What is the process for updating the handbook guides when the `dev-tools` gem is updated with new features or best practices?

> SOURCE

```text
in context of dev handbook / meta - update guides for tools, a) we don't use binstubs anymore, b) we use dev-tools to keep tools in the ruby lib c) expore best practices, that we already establish in this library, and transport it to guides
```
