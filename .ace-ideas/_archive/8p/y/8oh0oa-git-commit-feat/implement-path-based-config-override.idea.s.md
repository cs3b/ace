---
title: Implementing Path-Based Configuration Splitting in ace-git-commit
filename_suggestion: feat-git-commit-config-split
enhanced_at: 2026-01-18 00:26:59.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2026-01-22 18:34:09.000000000 +00:00
id: 8oh0oa
tags: []
created_at: '2026-01-18 00:26:58'
---

# Implementing Path-Based Configuration Splitting in ace-git-commit

## Problem
In a monorepo environment like ACE, different sub-packages (e.g., `ace-docs/`, `ace-lint/`) often require distinct development standards, such as different Git commit conventions (e.g., Conventional Commits for code, simple messages for documentation). The current ACE configuration cascade (ADR-022) resolves configuration project-wide. When an agent or developer runs `ace-git-commit` on staged files spanning multiple packages with conflicting commit configurations, the resulting single commit cannot satisfy all required standards, leading to inconsistent output and potential CI failures.

## Solution
Introduce a **Path-Based Configuration Override** layer to the ACE configuration cascade, allowing specific directories or packages within the project to define their own `ace-git-commit` settings (model, convention, prompt). The `ace-git-commit` tool must be enhanced to detect staged files belonging to different configuration scopes. If multiple distinct scopes are found, the `CommitOrchestrator` will automatically split the staged changes into separate, sequential commits, each generated using its respective package configuration.

## Implementation Approach
1.  **Configuration Layer:** Enhance `ace-config` (or `ace-support-core`) with a new Molecule, `PathConfigResolver`, capable of resolving configuration based on file path, potentially looking for configuration files within subdirectories or using glob patterns defined in the project's `.ace/` directory.
2.  **Orchestration (Organism):** Update the `CommitOrchestrator` in `ace-git-commit` to:
    a. Analyze the staged file list (`git diff --cached --name-only`).
    b. Map each file path to its effective `git/commit` configuration using the new `PathConfigResolver`.
    c. Group files by their resolved configuration hash.
    d. Iterate through each group, temporarily staging only those files, running the LLM generation using the group's specific configuration, and executing the commit.
3.  **Deterministic Output:** Ensure the process is deterministic. The default behavior for agents should be to split commits if conflicting configurations are detected, guaranteeing that each resulting commit adheres to the standards defined for the files it touches.

## Considerations
- **Integration with existing ace-config:** The path-based override must integrate seamlessly as the highest priority layer in the configuration cascade, overriding Project, User, and Gem defaults.
- **CLI Interface:** The primary command remains `ace-git-commit`. The splitting behavior should be the default agentic behavior, but a `--no-split` flag could be considered for human developers who prefer a single, potentially non-compliant, commit.
- **Atomicity:** Ensure the splitting process maintains atomicity; if one sub-commit fails, the entire operation should be reversible (e.g., using temporary worktrees or careful staging management).

## Benefits
- **Improved Monorepo Consistency (AX/DX):** Enforces distinct commit standards across different packages within the ACE monorepo, crucial for maintaining high quality in specialized gems like `ace-docs` vs. `ace-core`.
- **Enhanced Agent Autonomy:** Allows agents to handle complex, multi-package changes reliably without human intervention, as the tool itself manages the necessary splitting and configuration switching.
- **Deterministic Behavior:** Provides predictable, configuration-driven output, aligning perfectly with Core Principle 2 (DX/AX Dual Optimization) and the need for deterministic CLI tools.

---

## Original Idea

```
cascade config - example in git commit, we have different styles config for certail folders in the repo (one for ace-docs, and one for ace-handbook, if we runn git commit on multiple files in the repo ace-git commit should detect this and create commit for each package seperately acording to the configration we have - tricky but might be useful

https://x.com/affaanmustafa/status/2012378465664745795?s=46&t=ammjmCWfjA_RhV64oVV9Eg
```