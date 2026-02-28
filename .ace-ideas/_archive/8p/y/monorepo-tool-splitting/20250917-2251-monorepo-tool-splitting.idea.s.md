---
:input_tokens: 73355
:output_tokens: 1120
:total_tokens: 74475
:took: 3.393
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-09-17T21:51:31Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 73355
:cost:
  :input: 0.007336
  :output: 0.000448
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.007784
  :currency: USD
id: monore
status: done
title: Splitting Tools into Smaller Gems with Monorepo Support
tags: []
created_at: '2068-01-24 16:30:25'
---

# Splitting Tools into Smaller Gems with Monorepo Support

## Intention

To refactor the existing monolithic `ace-tools` gem into smaller, more focused gems while maintaining a monorepo structure for development and management.

## Problem It Solves

**Observed Issues:**
- The `ace-tools` gem has become very large, containing a wide range of functionalities from core utilities to specific LLM integrations.
- A large monolithic gem can lead to slower build times, increased complexity, and potential for unintended coupling between unrelated features.
- Managing dependencies and testing becomes more challenging in a large, single gem.
- Difficulty in isolating and reusing specific functionalities (e.g., only LLM querying without Git tools).

**Impact:**
- Slower development cycles due to the large size of the gem.
- Increased risk of introducing bugs in unrelated areas when making changes.
- Hindered adoption of specific toolsets due to the need to install the entire monolithic gem.
- Difficulty in managing dependencies between different parts of the toolkit.

## Key Patterns from Reflections

- **ATOM Architecture**: The project is structured using ATOM principles (Atoms, Molecules, Organisms, Ecosystems), which inherently promotes modularity and can guide the separation into smaller gems.
- **Multi-Repository Coordination**: While the goal is to split into gems, the current monorepo structure with Git submodules (`.ace/handbook`, `.ace/tools`, `.ace/taskflow`) shows a precedent for managing multiple distinct components within a single Git repository.
- **CLI Tool Patterns**: The existence of 25+ executables with consistent interfaces suggests that these can be grouped and potentially exported from their respective smaller gems.
- **Modular Design**: The project emphasizes modularity, which is a foundational principle for successful gem splitting.
- **Gem Distribution**: The project already uses RubyGems for distribution, so creating new gems follows established patterns.

## Solution Direction

1. **Gem Splitting Strategy**: Define clear boundaries for new gems based on functionality, drawing from the ATOM architecture.
2. **Monorepo Management Tools**: Integrate tools or adopt practices that facilitate managing multiple gems within a single repository (e.g., Bundler workspaces, specialized monorepo tools).
3. **Dependency Management**: Establish clear dependency relationships between the new gems (e.g., `ace-llm-claude-code` depending on `ace-llm-query`).

## Critical Questions

**Before proceeding, we need to answer:**
1. What are the optimal boundaries for the new gems (e.g., `ace-tools-core`, `ace-git-tools`, `ace-llm-query`, `ace-llm-anthropic`, `ace-llm-gemini`, `ace-task-manager`, `ace-handbook`)?
2. How will we manage the inter-gem dependencies and versioning within the monorepo?
3. What tools or configurations are necessary to support a multi-gem monorepo structure effectively (e.g., Bundler workspaces, `Gemfile` structure)?

**Open Questions:**
- How will the CLI executables be managed and exported from their respective gems?
- What is the impact on the existing `ace-tools` gem (will it become a meta-gem or be deprecated)?
- How will the migration process be handled for existing users and projects that depend on the monolithic gem?

## Assumptions to Validate

**We assume that:**
- The ATOM architecture provides a sound basis for defining gem boundaries. - *Needs validation*
- Bundler's workspace capabilities or similar monorepo tooling can effectively manage multiple local gems. - *Needs validation*
- Splitting the gem will lead to tangible improvements in development speed, maintainability, and modularity. - *Needs validation*

## Expected Benefits

- **Improved Modularity**: Each gem will have a focused responsibility, making it easier to understand, test, and maintain.
- **Faster Development Cycles**: Smaller codebases build and test faster.
- **Reduced Complexity**: Less cognitive load for developers working on specific features.
- **Easier Dependency Management**: Projects can depend only on the specific tools they need.
- **Clearer Boundaries**: Enforces better separation of concerns between different functionalities.
- **Enhanced Reusability**: Specific toolsets can be more easily reused in other projects.

## Big Unknowns

**Technical Unknowns:**
- The exact tooling and configuration required for seamless multi-gem development within a monorepo.
- Potential complexities in managing inter-gem dependencies and ensuring they are correctly resolved.
- How to handle shared code (e.g., common utilities, the ATOM structure itself) that might be used across multiple new gems.

**User/Market Unknowns:**
- How will users adapt to the new gem structure and installation process?
- Will the benefits of modularity outweigh the added complexity of managing multiple gems?

**Implementation Unknowns:**
- The precise steps and effort required to refactor the existing monolithic gem into multiple smaller gems.
- The strategy for handling the transition from the monolithic `ace-tools` gem to the new structure (e.g., deprecation, meta-gem).
- How to ensure consistent CLI interfaces and behavior across gems that might have previously shared code.

> SOURCE

```text
We can split all our tools into smaller gems - eg.: ace-tools-core, ace-llm-query, ace-llm-claude-code (that depends on llm-query) and so on. This lib is too big and we should split it - still keep it as monorepo. Add support for monorepo to the tools (ace-tools and so on)
```