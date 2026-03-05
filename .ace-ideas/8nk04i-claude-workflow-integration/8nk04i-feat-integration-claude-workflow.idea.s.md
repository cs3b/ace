---
title: Standardized Workflow Execution CLI for Claude Code Integration
filename_suggestion: feat-integration-claude-workflow
enhanced_at: 2025-12-21 00:05:24.000000000 +00:00
llm_model: gflash
source: taskflow:v.0.9.0
id: 8nk04i
status: pending
tags: []
created_at: '2025-12-21 00:05:00'
---

# Standardized Workflow Execution CLI for Claude Code Integration

## Problem
Currently, integrating specific ACE workflows (like `commit` or `review`) into Claude Code requires defining individual slash commands or agents for each workflow. This leads to redundancy and complicates the maintenance of the `ace-integration-claude` package. The core ACE architecture relies on the `wfi://` protocol for workflow discovery, but this capability needs a standardized, generic entry point within the AI environment.

## Solution
Implement a single, generic workflow execution command, `/ace:wf <workflow_name> [params]`, within the `ace-integration-claude` integration package. This command will serve as the primary interface for AI agents to execute any self-contained ACE workflow (`.wf.md`).

This command will delegate the following steps:
1. Use `ace-nav` to resolve the full path and content of the workflow using the `wfi://<workflow_name>` protocol.
2. Execute the workflow instructions, potentially using `ace-taskflow` or a dedicated runner, ensuring the agent receives the full, contextual instructions (ADR-001 self-containment principle).

This approach standardizes AI interaction, moving away from specific commands (e.g., `/ace:commit`) to a unified delegation pattern (`/ace:wf commit`).

## Implementation Approach
1. **Integration Asset**: Define the `/ace:wf` command structure within the `ace-integration-claude/integrations/claude/commands/_custom/` directory, registering it as a Claude Code command.
2. **Delegation**: The command implementation (likely a shell script or Ruby executable wrapper) will call `ace-nav wfi://<workflow_name>` to retrieve the workflow content.
3. **Execution**: The output (the `.wf.md` content) is then presented to the agent, or the wrapper executes the underlying CLI tools defined in the workflow's frontmatter, depending on the desired level of autonomy.
4. **Refinement**: Ensure the implementation adheres to the ATOM pattern within `ace-integration-claude`, using Molecules to handle `ace-nav` interaction and an Organism to orchestrate the command execution and output formatting.

## Considerations
- **Parameter Handling**: The command must reliably parse and pass parameters (`[params]`) from the Claude environment to the underlying workflow execution logic.
- **Deterministic Output**: The output must be predictable and easily parseable by the agent, ensuring the agent can follow the multi-step instructions contained in the `.wf.md` file.
- **Configuration**: Ensure the command respects the configuration cascade for `ace-nav` and workflow source definitions.
- **Backward Compatibility**: Review existing specific commands (like those related to git commits) and deprecate them in favor of the generic `/ace:wf` pattern.

## Benefits
- **Standardization**: Provides a single, consistent interface for AI agents to access all ACE workflows.
- **Maintainability**: Reduces the number of specific command definitions required in `ace-integration-claude`.
- **Scalability**: Any new workflow added to any `ace-*` gem (and registered via `wfi://`) is instantly accessible via `/ace:wf`.
- **Agent Autonomy**: Leverages the self-contained nature of ACE workflows (ADR-001) for more reliable autonomous execution.

---

## Original Idea

```
claude code integration - would be better to have command /ace:wf commit -> read and follow instructions from `ace-context wfi://commit` it would significaly improve the integration with claude code - we loose only autocompleted. It relates to task.153
```