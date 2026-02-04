---
title: Implement Hierarchical Workflow and Agent Namespacing via wfi:// Protocol
filename_suggestion: feat-nav-workflow-namespacing
enhanced_at: 2026-02-04 00:02:01
location: active
llm_model: gflash
---

# Implement Hierarchical Workflow and Agent Namespacing via wfi:// Protocol

## Problem
The current structure of workflows (`.wf.md`) and agents (`.ag.md`) within the `handbook/` directories of various `ace-*` gems is flat. As the ACE ecosystem grows, this leads to potential naming conflicts (e.g., multiple 'commit' or 'review' workflows) and poor discoverability for agents and developers using `ace-nav` and the `wfi://` protocol.

## Solution
Introduce mandatory hierarchical namespacing for all workflows and agents, reflecting the structure within the `handbook/` directory. This requires updating `ace-nav` and `ace-bundle` to resolve nested paths.

**New Protocol Format:** `wfi://<gem_context>/<sub_namespace>/<workflow_name>`

**Example Translation:**
1.  A workflow file located at `ace-git/handbook/workflow-instructions/commit/standard.wf.md` would be accessed via `wfi://git/commit/standard`.
2.  This path would translate directly into a structured agent skill invocation, such as `/ace:git:commit:standard` or similar, ensuring deterministic execution and clear context for the agent.

## Implementation Approach
1.  **`ace-nav` and `ace-bundle` Update:** Modify the `context_loader` and resource discovery organisms within `ace-bundle` and `ace-nav` to recursively scan `handbook/workflow-instructions/` and `handbook/agents/`. The path relative to the base directory will define the namespace.
2.  **Configuration:** Ensure the configuration cascade (ADR-022) handles namespace resolution. The primary namespace should default to the gem's context (e.g., `ace-git` provides the `git` namespace).
3.  **Migration:** Existing flat workflows (e.g., `ace-git-commit/handbook/workflow-instructions/commit.wf.md`) must be migrated to a namespaced structure (e.g., `ace-git-commit/handbook/workflow-instructions/git/commit.wf.md`) or aliased during a deprecation period.
4.  **Agent Integration:** Update the skill generation process in `ace-llm` or `ace-integration-claude` to correctly map the hierarchical `wfi://` paths to structured agent commands in `.claude/skills/`.

## Considerations
- **Collision Resolution:** Define clear rules (likely based on the configuration cascade) for when multiple gems attempt to define the same namespace (e.g., if `ace-taskflow` and `ace-git` both define a top-level `git` namespace).
- **CLI Output:** Ensure `ace-nav list` provides a clear, parseable, namespaced output format.
- **Refactoring:** This change requires refactoring the resource discovery molecules in `ace-bundle` to handle nested file structures.

## Benefits
- Eliminates naming conflicts across the growing number of `ace-*` packages.
- Improves agent and developer discoverability of specific workflows (e.g., knowing all testing workflows are under `wfi://test/`).
- Enforces better organization, aligning with the 'Packaged and Customizable' core principle.

---

## Original Idea

```
ace-* all packages - we need to prefix the skills as we have too much of them ( workflows generally ) so we should define namespaces subfolders and sllow to use them wfi::/test/e2e-create  wfi://git/commit -> and this should translate to /ace:git:commit .... 

* 27bdef40e (HEAD -> 227-feedback-based-review-output-architecture) chore(deps): Update ace-review to v0.36.16
* 6fbcd58c1 feat(feedback): Introduce session discovery for feedback commands
* a506a9d57 (origin/227-feedback-based-review-output-architecture) docs(agent-integrations): Add critical feedback resolution reminders to ACE Review skill
* c357a63bd docs(ace-review): Enhance feedback resolution instructions in review PR workflow
* 04744cd87 chore(ace-review): release v0.36.14
* d721d44f1 chore(ace-review): release v0.36.14
* d764e19f6 chore(ace-review): release v0.36.13
* 79fbcdcf7 chore(taskflow): archive feedback review task files
* 543846a44 chore(ace-review): release v0.36.12
* ab77a2b3d chore(ace-review): release v0.36.12
* 64660b1cf chore(ace-support-timestamp): release v0.5.0
* ccf85f08b chore(ace-support-timestamp): release v0.5.0
```