---
title: Standardize Project Naming: ACE (Agent Coding Environment) Consistency
filename_suggestion: chore-core-naming-consistency
enhanced_at: 2026-01-07 00:06:56
location: active
llm_model: gflash
---

# Standardize Project Naming: ACE (Agent Coding Environment) Consistency

## Problem
While the project vision defines ACE as the 'Agent Coding Environment,' this definition is not consistently applied across all documentation, prompt templates, and internal comments. Inconsistent naming conventions (e.g., 'Agentic Coding Environment,' 'ACE Project,' or undefined acronym usage) degrade the quality of context provided by `ace-context` and confuse LLM agents relying on deterministic definitions.

## Solution
Enforce a strict standard for the project name: **ACE (Agent Coding Environment)**. This requires a project-wide refactoring and the implementation of a new linting rule to prevent future drift.

## Implementation Approach
1. **Define Standard:** Officially confirm and document 'ACE (Agent Coding Environment)' as the required usage in `docs/what-do-we-build.md`.
2. **Refactor Documentation:** Use `ace-search` to locate all instances of the project name in `README.md`, `CHANGELOG.md`, and core `docs/` files. Systematically update them to the standardized format.
3. **`ace-lint` Integration:** Develop a new Molecule/Organism within `ace-lint` to check Markdown and YAML files for inconsistent project naming. This lint rule should enforce the use of the full name upon first mention in a document, or flag variations.
4. **Prompt Templates:** Review and update all workflow instructions (`handbook/workflow-instructions/*.wf.md`) and agent definitions (`handbook/agents/*.ag.md`) across all `ace-*` gems to use the standardized naming when referencing the project.

## Considerations
- **LLM Context:** Ensure the changes are immediately available to `ace-context` to improve agent performance.
- **`ace-lint` Rule Design:** The lint rule must be intelligent enough to allow the acronym 'ACE' alone in contexts where space is limited (e.g., CLI output or subsequent mentions).
- **Scope:** Focus on user-facing documentation and AI integration assets (`handbook/`), minimizing changes to internal Ruby module names which already follow `Ace::*`.

## Benefits
- **Deterministic Context:** Provides clearer, unambiguous context for LLM agents, improving the reliability of tasks executed via `ace-taskflow` and prompt generation via `ace-prompt`.
- **Documentation Quality:** Improves the consistency and professionalism of all project documentation, aligning with `ace-docs` standards.
- **Maintainability:** The new `ace-lint` rule ensures naming consistency is maintained automatically during future development.

---

## Original Idea

```
ace -> agentic coding environment we have fix the names across the repo
```