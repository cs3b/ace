---
title: Implement ace-coworker for Isolated, Agentic Sandboxing via Git Worktrees
filename_suggestion: feat-coworker-sandbox-sync
enhanced_at: 2026-01-15 10:38:19
location: active
llm_model: gflash
---

# Implement ace-coworker for Isolated, Agentic Sandboxing via Git Worktrees

## Problem
Today's complex agentic tasks often require isolated, sandboxed environments to prevent unintended modifications to the main working directory. Relying on proprietary, external sandboxes (like those provided by LLM platforms) violates the ACE Core Principle of 'Same Environment, Same Tools.' We need a deterministic, auditable, and reversible mechanism for agents to perform work in isolation using standard developer tools.

## Solution
Introduce the `ace-coworker` gem, an orchestrator designed to manage isolated development sessions. This tool will leverage `ace-git-worktree` to create temporary, isolated Git worktrees as the 'sandbox' environment. The workflow will be:

| or use sync for folders that are not git 

1. **Setup:** `ace-coworker start <task_id>` creates a dedicated worktree branch and directory.
2. **Environment:** The tool ensures the environment (e.g., dependencies via `mise`) is correctly loaded within the worktree.
3. **Execution:** The agent executes standard ACE CLI commands (`ace-git-commit`, `ace-lint`, `ace-test`) within the isolated worktree.
4. **Review/Sync:** Upon completion, `ace-coworker finish` analyzes the changes using `ace-git diff`, generates a summary (potentially using `ace-llm`), and provides a deterministic output for merging back into the main branch.

An optional `ace-coworker-tui` will provide a real-time, auditable view of the agent's actions within the sandbox, adhering to the DX/AX Dual Optimization principle.

## Implementation Approach

**New Gem:** `ace-coworker` (CLI tool).

**Architecture:** The core logic will reside in the **Organism** layer (`CoworkerOrchestrator`), coordinating the following **Molecules** and external ACE tools:

1. **Worktree Management:** Delegate isolation tasks to `ace-git-worktree` (create, switch, delete worktrees).
2. **Context Loading:** Use `ace-context` to ensure the agent operating within the worktree has the full, relevant project context.
3. **Diff and Summary:** Utilize `ace-git` for generating deterministic diffs between the worktree and the main branch, and `ace-llm` for summarizing the resulting changes.
4. **TUI Integration:** The TUI component will monitor the worktree directory for changes and log agent command executions, providing transparency.

## Considerations
- **Isolation Integrity:** Ensure the worktree mechanism is robust and handles environment setup (e.g., `mise` integration) correctly within the isolated directory.
- **Configuration Cascade:** The worktree environment must inherit configuration from the project's `.ace/` directory, ensuring consistent behavior.
- **Deterministic Output:** The final summary and sync status must be provided in a structured, parseable format (e.g., JSON via `--json` flag) for subsequent agent steps.
- **Error Handling:** Implement robust rollback mechanisms in case the agent fails or introduces breaking changes within the worktree.

## Benefits
- **True Sandboxing:** Provides a safe, isolated environment for autonomous agent execution.
- **Auditable Workflows:** Every action taken by the agent is recorded within the worktree's Git history, making the process transparent and debuggable.
- **Seamless Integration:** Leverages existing ACE tools (`ace-git-worktree`, `ace-context`, `ace-llm`), reinforcing the modular ATOM architecture.
- **Enhanced DX/AX:** Developers can easily inspect, modify, or discard the agent's work before merging, improving the human-agent handoff.

---

## Original Idea

```
ace-coworker and ace-coworker-tui => work only on single dir, use sync to make copy on what is working, setup env with mise (use light sandboxing mechanism on osx), and do the work, at the very end verify if there was not changes in origin dir, summary the changes and then sync back .... similar to claude coworker
```
