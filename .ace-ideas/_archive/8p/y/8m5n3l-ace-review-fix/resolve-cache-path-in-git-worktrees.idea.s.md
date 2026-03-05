---
title: Fix ace-review cache path resolution in git worktrees
filename_suggestion: fix-review-worktree-path-resolution
enhanced_at: 2025-11-06 15:24:40.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2025-11-15 10:33:43.000000000 +00:00
id: 8m5n3l
tags: []
created_at: '2025-11-06 15:23:58'
---

# Fix ace-review cache path resolution in git worktrees

## Problem
The `ace-review` tool is exhibiting incorrect behavior when executed from within a git worktree. The provided output shows the review session cache being created in a deeply nested and unexpected path (`/Users/mc/Ps/ace-meta/.ace-wt/task.094/ace-context/.cache/ace-review/sessions/`) instead of the standard `.ace/review/sessions/` relative to the worktree's root or the main mono-repo root. This indicates a fundamental issue with how `ace-review` (or its underlying dependencies like `ace-support-core` or `ace-context`) resolves the project root and subsequent cache directories when operating in a worktree environment. This bug prevents reliable use of `ace-review` in common development workflows that utilize `ace-git-worktree`.

## Solution
Ensure that `ace-review` consistently and correctly identifies the project root, especially when invoked from within a git worktree. The cache path for review sessions must be resolved to a predictable location, typically `.ace/review/sessions/` relative to the *active* project root (which, in a worktree, should be the worktree's root, or the main mono-repo root if the worktree is considered a sub-project). This requires a review of path resolution logic within `ace-review`, `ace-context`, and `ace-support-core` to ensure compatibility with `ace-git-worktree`'s environment.

## Implementation Approach
1.  **Identify Root Cause**: Debug `ace-review`'s execution flow, specifically focusing on calls to `Ace::Core.config.get` for cache paths and any direct or indirect calls to `Ace::Context.project_root`. Determine if the issue lies in `ace-review`'s specific implementation, `ace-context`'s root detection, or `ace-support-core`'s general path resolution within a worktree.
2.  **Path Resolution Logic**: Review `ace-support-core`'s mechanisms for determining the project root and resolving `.ace/` configuration paths. Ensure it correctly handles the presence of `.git` directories in both the main repository and worktrees to establish the correct base for relative paths.
3.  **Cache Directory Configuration**: Verify that `ace-review`'s configuration for its cache directory (likely defined in `.ace.example/review/config.yml` and accessed via `Ace::Core.config.get('ace', 'review', 'cache_dir')`) is being interpreted correctly relative to the determined project root.
4.  **Testing**: Add a dedicated integration test case to `ace-review` (or the responsible core gem) that simulates running the tool from a git worktree. This test should assert that the session cache is created in the expected, correct location. Leverage the "Protected Method for ENV Access" pattern from `docs/testing-patterns.md` to mock environment variables or `git` commands that influence root detection without modifying global state.

## Considerations
-   **Consistency**: Any changes to path resolution in `ace-support-core` or `ace-context` must be carefully evaluated for their impact on all other `ace-*` gems that rely on these core services.
-   **Configuration Cascade**: Ensure the fix respects the `.ace/` configuration cascade, allowing users to override cache paths if necessary, while maintaining a sensible default.
-   **CLI Interface**: The `ace-review` CLI should continue to function transparently regardless of the execution environment (main repo or worktree).

## Benefits
-   Enables `ace-review` to be used reliably within git worktrees, aligning with the `ace-git-worktree` development workflow.
-   Improves the robustness and predictability of path resolution across the ACE ecosystem.
-   Enhances the overall developer experience by eliminating environment-specific bugs.
-   Reinforces the principle of deterministic tool behavior, crucial for AI agent integration.

---

## Original Idea

```
ace-review bug when running outside the project root

❯ ace-review --preset pr --model codex --subject "commands: ['ghrc pr 18 diff']"
✓ Review session prepared: /Users/mc/Ps/ace-meta/.ace-wt/task.094/ace-context/.cache/ace-review/sessions/review-20251106-152323
  Prompt:

To execute with LLM:
  ace-llm query --file

task.094/ace-context on  feat/ace-context-section-based-organization via 💎 v3.4.6 took 2s
```