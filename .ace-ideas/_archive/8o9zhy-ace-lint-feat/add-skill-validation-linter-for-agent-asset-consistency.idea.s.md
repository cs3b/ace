---
title: Add Skill Validation Linter to ace-lint for Agent Asset Consistency
filename_suggestion: feat-lint-skill-validation
enhanced_at: 2026-01-10 23:39:57.000000000 +00:00
location: archived
archived_at: 2026-01-22
implemented_by: v.0.9.0+task.226
llm_model: gflash
id: 8o9zhy
status: done
tags: []
created_at: '2026-01-10 23:39:56'
---

# Add Skill Validation Linter to ace-lint for Agent Asset Consistency

## Problem
The integrity and consistency of AI integration assets (workflows in `*.wf.md` and agents in `*.ag.md`) are critical for reliable Agentic Coding Environment (ACE) operation. Without automated validation, structural changes—such as the introduction of the `context/agent/allowed-tools` pattern (as seen in PR #147/Task 204)—can lead to silent failures, inconsistent skill registration, and poor Agent Experience (AX). Specifically, we need to ensure that required frontmatter fields are present, tool permissions are correctly declared, and metadata (like `last-updated` dates) is current.

## Solution
Implement a dedicated `SkillValidator` component within the `ace-lint` gem. This component will introduce a new command, `ace-lint skills`, capable of recursively scanning all `handbook/` directories across ACE gems or a specific project path, validating the frontmatter of all skill and workflow files against a defined schema.

The linter will perform the following checks:
1.  **Pattern Compliance:** Verify the presence and correct formatting of required frontmatter fields, including `context`, `agent`, and the `allowed-tools` list.
2.  **Tool Permission Validation:** Check that declared tools (e.g., `ace-test`, `ace-git-commit`) are valid ACE commands and that necessary file permissions (e.g., `Edit/Write` for modification workflows) are explicitly requested.
3.  **Metadata Consistency:** Validate YAML syntax and ensure metadata fields like `last-updated` are present and correctly formatted (using `ace-docs` standards).
4.  **Output:** Provide deterministic, parseable output (JSON or standard CLI format) suitable for CI/CD pipelines and agent consumption.

## Implementation Approach
The implementation will reside primarily in `ace-lint`.
1.  **CLI:** Extend `ace-lint` with a new subcommand: `ace-lint skills [path]`.
2.  **ATOM Pattern:**
    *   *Atoms:* Utilize existing `ace-support-core` Atoms for YAML parsing and date validation.
    *   *Molecules:* Create a `SkillFrontmatterExtractor` Molecule to reliably load and isolate frontmatter from Markdown files.
    *   *Organisms:* Implement the `SkillLinterOrchestrator` Organism to manage the recursive file search, delegate validation rules, and aggregate results.
3.  **Configuration:** The linter rules and the list of known `allowed-tools` should be configurable via the ACE Configuration Cascade, allowing projects to define custom tools or override required fields in `.ace/lint/skills.yml`.

## Considerations
- **Scope:** The linter must be able to target files based on the `ace-nav` protocol sources, ensuring it finds skills embedded in installed gems as well as local project skills.
- **Tool Mapping:** Requires a mechanism to map high-level workflow requirements (e.g., "fix-bug") to the necessary underlying ACE tools (e.g., `ace-test`, `ace-search`, `ace-git-commit`).
- **CLI interface design:** Ensure the output is deterministic and easy for CI systems to consume (e.g., exit code 1 on failure).

## Benefits
- **Improved AX:** Guarantees that AI agents receive correctly structured and permissioned skill definitions, leading to more reliable autonomous execution.
- **Enforced Consistency:** Standardizes the structure of all AI assets across the entire ACE ecosystem (25+ gems).
- **CI/CD Integration:** Enables automated validation in CI pipelines, preventing broken skills from being merged.
- **Reduced Friction (DX):** Developers get immediate feedback on skill definition errors, reducing debugging time related to agent integration.

---

## Original Idea

```
Add skill linter to ace-lint to validate:
1. Pattern compliance (context, agent, user-invocable fields present and uncommented)
2. Tool permissions match workflow requirements (e.g., fix-bug needs ace-test, rebase needs Edit/Write)
3. Metadata consistency (current dates, proper formatting, trailing newlines)
4. YAML syntax validation

This would prevent issues found in PR #147 from recurring.
```