---
:input_tokens: 73292
:output_tokens: 1005
:total_tokens: 74297
:took: 3.454
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-09-17T21:54:54Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 73292
:cost:
  :input: 0.007329
  :output: 0.000402
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.007731
  :currency: USD
---

# Rename Tools to `ace-*` Prefix

## Intention

Standardize all command-line tool names to begin with the `ace-` prefix to create a consistent and recognizable namespace for the toolkit's executables.

## Problem It Solves

**Observed Issues:**
- CLI tool names lack a unified namespace, making it difficult to distinguish them from other system commands or tools.
- Existing tool names are inconsistent (e.g., `task-manager` vs. `llm-query` vs. `git-status`).
- A lack of a common prefix hinders discoverability and can lead to naming conflicts in environments with many CLI tools.

**Impact:**
- Reduced clarity and recognition of the toolkit's commands.
- Potential for command name collisions with other installed CLI tools.
- Inconsistent user experience when interacting with different tools within the suite.
- Difficulty in establishing a clear brand identity for the command-line interface.

## Key Patterns from Reflections

- **ATOM Architecture**: The project is structured using ATOM, suggesting a need for modularity and clear component boundaries, which extends to CLI naming.
- **CLI Tool Patterns**: The project has 25+ existing executables, highlighting the importance of a scalable naming convention.
- **Migration Guide**: The migration from `coding-agent-tools` to `ace-tools` indicates a strong theme of rebranding and standardization.
- **`docs/tools.md`**: This document lists all current tools and their purposes, serving as a reference for renaming.
- **`docs/blueprint.md`**: This document outlines project organization, reinforcing the idea of a cohesive toolkit.
- **`docs/what-do-we-build.md`**: This document emphasizes the goal of providing "Predictable CLI tools for common development operations."

## Solution Direction

1. **Identify All CLI Executables**: Compile a comprehensive list of all executable commands provided by the `.ace/tools/exe/` directory and any other CLI entry points.
2. **Define Renaming Convention**: Establish a clear rule: prepend `ace-` to the existing tool name. For example, `task-manager` becomes `ace-task-manager`, `llm-query` becomes `ace-llm-query`.
3. **Implement Renaming**: Update the executable file names, any references within scripts (e.g., shell integration, workflow instructions), and documentation to reflect the new names.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the definitive list of all current CLI executables that need renaming?
2. Are there any scripts or configuration files outside of `.ace/tools/exe/` that directly reference these executable names and will require updates?
3. What is the impact on existing AI agent workflows that might directly invoke these tools by their old names?

**Open Questions:**
- What is the process for ensuring backward compatibility or providing clear migration guidance for users (both human and AI agents) who rely on the old tool names?
- Should the renaming process be automated, and if so, what is the safest and most comprehensive way to achieve this across all relevant files?
- Are there any tools that might have names that conflict with the `ace-` prefix or common shell commands that need special consideration?

## Assumptions to Validate

**We assume that:**
- All current CLI tools are located within or accessible via the `.ace/tools/exe/` directory. - *Needs validation*
- The `ace-` prefix aligns with the project's overall branding and goals. - *Needs validation*
- All references to tool names in documentation and scripts can be systematically identified and updated. - *Needs validation*

## Expected Benefits

- **Consistent Namespace**: All toolkit commands are clearly identifiable as belonging to the ACE suite.
- **Improved Discoverability**: Easier for users to find and recall toolkit commands.
- **Reduced Naming Conflicts**: Minimizes the chance of clashes with other CLI tools.
- **Stronger Brand Identity**: Reinforces the "ACE" branding across the entire toolkit.
- **Simplified Shell Integration**: A consistent prefix makes managing the PATH and autocompletion easier.

## Big Unknowns

**Technical Unknowns:**
- The exact number and location of all references to current tool names across the entire multi-repository structure.
- The best approach for automating the renaming process across all submodules and configurations.

**User/Market Unknowns:**
- How will AI agents and human users react to this change? Will it cause confusion or be easily adopted?

**Implementation Unknowns:**
- The precise steps and scripts required to update all shell integrations, workflow instructions, and documentation accurately.
- The potential impact on CI/CD pipelines that might rely on specific tool names.

> SOURCE

```text
rename all the tools to ace- eg.: ace-tm -> task manager ... and so on
```
