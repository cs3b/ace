---
title: Fix `ace-git-worktree` upstream branch configuration
filename_suggestion: fix-git-worktree-upstream
enhanced_at: 2025-12-02 01:10:50.000000000 +00:00
completed_by:
- v.0.9.0+task.132
completed_at: 2025-12-09
status: done
llm_model: gflash
id: 8n11r0
tags: []
created_at: '2025-12-02 01:10:00'
---

# Fix `ace-git-worktree` upstream branch configuration

## Problem
The `ace-git-worktree` gem currently exhibits a bug where it fails to consistently set the upstream tracking branch for newly created local branches within a git worktree. Despite existing configuration intended to manage this, the upstream relationship is often not established correctly. This issue forces both AI agents and human developers to manually configure the upstream branch (e.g., using `git branch --set-upstream-to=origin/branch`) before performing `git pull` or `git push` operations, thereby breaking the intended seamless and autonomous workflow of `ace-git-worktree` for task-specific development.

## Solution
Implement a robust fix within `ace-git-worktree` to ensure that the upstream tracking branch is always correctly configured when a new local branch is created or checked out as part of a worktree operation. This involves programmatically setting the upstream using deterministic `git` commands, leveraging the configuration cascade provided by `ace-support-core` to determine the appropriate remote and branch names.

## Implementation Approach
1.  **Identify Affected Components**: Pinpoint the specific Organism or Molecule within `ace-git-worktree` responsible for orchestrating branch creation and checkout operations. This is where the `git branch --set-upstream-to` command needs to be integrated.
2.  **Configuration Integration**: Utilize `Ace::Core.config.get('ace', 'git-worktree', 'upstream_defaults')` (or a similar path) to retrieve any project-specific or global settings for remote and branch naming conventions.
3.  **Deterministic Git Commands**: After a local branch is created and checked out in the worktree, execute `git branch --set-upstream-to=<remote>/<branch_name>` to explicitly establish the tracking relationship. This command should be robustly integrated into the existing `ace-git-worktree` workflow.
4.  **Error Handling**: Implement comprehensive error handling for scenarios where the upstream branch cannot be set (e.g., the remote branch does not exist or network issues). This should provide clear, actionable feedback.
5.  **Testing**: Develop new unit and integration tests using `ace-test-support` to specifically validate that the upstream branch is correctly set across various `ace-git-worktree` operations, including creating new branches from scratch and checking out existing remote branches into a new worktree.

## Considerations
-   **Backward Compatibility**: Ensure the fix does not introduce regressions or break existing `ace-git-worktree` workflows or configurations.
-   **Configuration Cascade**: Verify that the fix correctly respects and applies upstream configuration defined via the `.ace/` configuration cascade.
-   **CLI Interface**: As this is primarily a bug fix, no new CLI options are anticipated, but the internal logic should be transparent and predictable.
-   **Agent Interaction**: The solution must ensure that the `git` commands executed by `ace-git-worktree` are deterministic and produce parseable output, consistent with the AI-native principles of ACE.

## Benefits
-   **Enhanced Reliability**: Eliminates a critical point of failure for `git` operations within worktrees, making `ace-git-worktree` more dependable.
-   **Improved Agent Autonomy**: Enables AI agents to perform `git pull` and `git push` operations seamlessly without requiring manual upstream configuration, fostering greater automation.
-   **Streamlined Developer Experience**: Human developers benefit from a more consistent and less error-prone worktree setup, reducing friction in their daily workflows.
-   **Reduced Manual Intervention**: Minimizes the need for developers or agents to debug and manually fix git configurations, saving time and effort.

---

## Original Idea

```
ace-git-worktree - bug - we have to ensure that the upstream branch is set for local branch as part of the process - we have configuration in place but it didnt' work

cd /Users/mc/Ps/ace-task.126
```