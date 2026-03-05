---
title: Enhance ace-context with Dynamic Git Branch and PR Information
filename_suggestion: feat-context-git-pr-branch-info
enhanced_at: 2025-12-02 23:12:38.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2025-12-09 00:49:46.000000000 +00:00
id: 8n1yss
tags: []
created_at: '2025-12-02 23:11:58'
---

# Enhance ace-context with Dynamic Git Branch and PR Information

## Problem
LLM agents operating within the ACE (Agentic Coding Environment) often lack crucial, real-time Git context when performing development tasks. While `ace-context` excels at loading static project context, it currently does not dynamically gather information about the active Git branch, associated Pull Request (PR) details, or the target branch for that PR. This deficiency leads to less accurate code reviews, suboptimal commit message suggestions, and contextually irrelevant documentation updates from agents, as they operate without a complete understanding of the current development state.

## Solution
Enhance the `ace-context` gem to automatically gather and expose dynamic Git information. This includes:
-   The name of the currently active Git branch.
-   Comprehensive details about any open Pull Request (PR) associated with the current branch (e.g., PR ID, title, URL, status, author).
-   The target branch to which the PR is intended to merge (e.g., `main`, `develop`).

This enriched Git context will be seamlessly integrated into the overall context loaded by `ace-context`, making it readily available to other ACE gems (like `ace-git-commit`, `ace-review`, `ace-docs`) and AI agents for more informed decision-making and output generation.

## Implementation Approach
1.  **Git Interaction Layer**: Introduce new `Molecules` and `Organisms` within `ace-context` dedicated to interacting with the Git CLI. This layer will be responsible for executing Git commands and parsing their output.
2.  **Atoms**: Develop pure functions (Atoms) for specific Git operations, such as:
    -   `git_current_branch_name`: Executes `git rev-parse --abbrev-ref HEAD`.
    -   `git_remote_url_parser`: Extracts repository URL from `git config --get remote.origin.url`.
    -   `pr_info_parser`: Parses JSON output from `gh pr view --json` or similar Git platform CLI tools to extract PR ID, title, URL, and target branch.
3.  **Molecules**: Combine these atoms to perform higher-level operations:
    -   `fetch_current_branch_details`: Uses `git_current_branch_name`.
    -   `discover_associated_pr`: Uses `git_remote_url_parser` and `pr_info_parser` to find the PR linked to the current branch.
    -   `determine_pr_target_branch`: Extracts the target branch from the discovered PR information.
4.  **Organisms**: Orchestrate these molecules to construct a comprehensive `GitContextModel` object that encapsulates all relevant dynamic Git state.
5.  **Smart Caching**: Implement intelligent caching mechanisms within `ace-context` to store the fetched Git and PR information, minimizing redundant Git CLI calls and network requests, especially for PR data. This aligns with `ace-context`'s existing smart caching principles.
6.  **CLI Exposure**: Extend `ace-context`'s CLI (e.g., `ace-context show --git-info`) to display this new Git context in a parseable format (YAML or JSON), ensuring deterministic output for AI agents.
7.  **Programmatic Access**: Ensure the `GitContextModel` is easily accessible programmatically for other ACE gems.

## Considerations
-   **Integration with existing `ace-*` gems**: Define clear interfaces for `ace-git-commit`, `ace-review`, and `ace-docs` to consume this new Git context, ensuring it's seamlessly injected into their prompt generation pipelines.
-   **Configuration Cascade Implications**: Allow users to configure aspects like the preferred Git remote for PR checks, or to disable PR fetching if not required, via the `.ace/context/config.yml` cascade.
-   **Performance**: Prioritize minimizing the overhead of Git command execution, especially for network-intensive PR information retrieval. The smart caching mechanism will be critical here.
-   **Provider Agnosticism**: While `gh` CLI is a strong candidate for PR information, consider a pluggable architecture to support other Git hosting platforms (e.g., GitLab, Bitbucket) if future demand arises.
-   **Error Handling**: Robust error handling for scenarios where Git commands fail or no PR is found for the current branch.

## Benefits
-   **Enhanced LLM Accuracy**: Agents will gain a deeper, real-time understanding of the current development task, leading to significantly more relevant and precise outputs for commit messages, code reviews, and documentation.
-   **Improved Workflow Automation**: Enables more intelligent and context-aware automation for tasks that depend on Git state, such as automatically drafting release notes for a PR or generating context-specific test plans.
-   **Reduced Agent Hallucinations**: By providing concrete, verifiable Git context, the likelihood of agents generating incorrect or out-of-context information is substantially reduced.
-   **Consistency**: Standardizes how dynamic Git context is accessed and utilized across all ACE gems, ensuring a single, reliable source of truth for the current development environment.

---

## Original Idea

```
ace-context would be nice if it would gather context like - current branch, current branch pr, target branch for pr onto branch, so we have more context for development
```