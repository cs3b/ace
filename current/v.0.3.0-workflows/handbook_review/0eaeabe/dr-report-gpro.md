# SECTION LIST  ─ DO NOT CHANGE NAMES

## 1. Executive Summary

This review assesses a comprehensive set of development workflow instructions designed for an AI Coding Agent. The underlying architecture and principles—particularly self-containment and structured formats—are robust. However, a critical and systemic inconsistency in file path conventions for core documentation (`docs/` vs. `dev-taskflow/`) currently breaks the context-loading mechanism for most workflows, posing a blocking issue.

Several key workflows, notably `initialize-project-structure.wf.md` and `commit.wf.md`, are outdated and do not comply with established handbook standards for template embedding and process structure. These discrepancies risk causing AI agent failure and unpredictable behavior.

While many workflows are well-structured, a concerted effort is required to perform a consistency pass across the entire handbook to align all instructions with the defined standards. Addressing these issues will significantly improve the reliability and effectiveness of the AI agent's operations.

## 2. Workflow Instructions Updates

Several workflows require updates to align with the standards defined in `workflow-instructions-definition.g.md` and to correct pathing errors.

🔴 **System-Wide Path Correction Needed:**
-   **Issue**: A critical inconsistency exists for core project documentation paths. The authoritative `architecture.md` file places them in `dev-taskflow/`, but most workflows reference them in a non-existent `docs/` directory.
-   **Affected Files**: `load-project-context.wf.md`, `commit.wf.md`, `create-adr.wf.md`, `create-api-docs.wf.md`, `create-reflection-note.wf.md`, `create-task.wf.md`, `create-test-cases.wf.md`, `create-user-docs.wf.md`, `draft-release.wf.md`, `fix-tests.wf.md`, `initialize-project-structure.wf.md`, `publish-release.wf.md`, `review-task.wf.md`, `save-session-context.md`, `update-blueprint.wf.md`, `update-roadmap.wf.md`, `work-on-task.wf.md`.
-   **Required Fix**: All `Project Context Loading` sections must be updated to use the correct `dev-taskflow/` prefix (e.g., `dev-taskflow/what-do-we-build.md`).

🟡 **Specific Workflow Updates:**
-   `commit.wf.md`:
    -   **Issue**: The workflow violates structural standards. It uses checkboxes within `## Process Steps`, which is explicitly forbidden, and the `High-Level Execution Plan` is improperly formatted. The title "Let's Commit Workflow Instruction" is too conversational.
    -   **Required Fix**: Refactor the workflow to match the standard structure defined in `workflow-instructions-definition.g.md`. Remove checkboxes from process steps and correctly structure the high-level plan. Change H1 title to "Commit Workflow Instruction".
-   `initialize-project-structure.wf.md`:
    -   **Issue**: This critical workflow uses outdated four-tick markdown for embedding templates, directly violating the `template-embedding.g.md` guide. Instructions for binstub creation are also ambiguous (copy from a directory vs. use embedded template content).
    -   **Required Fix**: Convert all embedded templates to the standard `<templates>` XML format. Clarify the single source of truth for binstub scripts.
-   `create-adr.wf.md`:
    -   **Issue**: Contains inconsistent path references for ADRs, mentioning `docs/decisions/` and `docs/architecture-decisions/`, while the project standard is `dev-taskflow/decisions/`.
    -   **Required Fix**: Standardize all paths to `dev-taskflow/decisions/`.
-   `save-session-context.md`:
    -   **Issue**: The file uses a `.md` extension instead of the required `.wf.md`. The README also lists it this way, indicating a systemic inconsistency.
    -   **Required Fix**: Rename the file to `save-session-context.wf.md` and update the `README.md` to reflect the change.

## 3. Template & Example Updates

The handbook's template embedding system is powerful but is not applied consistently.

🔴 **`initialize-project-structure.wf.md` Template Format:**
-   **Issue**: This workflow uses legacy four-tick markdown blocks (` ```` `) to embed numerous templates for core docs, binstubs, and release tasks. This violates the primary directive of `template-embedding.g.md` to use the XML format.
-   **Required Fix**: All templates within this workflow must be converted to the `<templates><template path="..."></template></templates>` format. This is a large but critical refactoring task.

🟡 **Stray `path(...)` References:**
-   **Issue**: Several workflows correctly use the `<templates>` block but also contain obsolete inline `path (...)` references within their process steps. This is confusing and redundant.
-   **Affected Files**: `create-adr.wf.md`, `create-api-docs.wf.md`, `create-reflection-note.wf.md`, `create-task.wf.md`, and others.
-   **Required Fix**: Remove all instances of the `path (...)` text from the body of the workflows. The `path` attribute in the `<template>` tag is the single source of truth.

🟡 **Incorrect Template Usage:**
-   `save-session-context.md`:
    -   **Issue**: This workflow embeds two templates (`retrospective.template.md` and `session-context.template.md`) but the text seems to incorrectly reference the retrospective template for creating a session log.
    -   **Required Fix**: Clarify the purpose of each template and ensure the process steps reference the correct one (`session-context.template.md`) for the primary goal.
-   `review-task.wf.md`:
    -   **Issue**: The workflow for creating a review summary incorrectly embeds and references `release-docs/documentation.template.md`, which is a template for feature documentation, not a review report.
    -   **Required Fix**: A new template for a "Task Review Summary" should be created and embedded. Using the current template is functionally incorrect.

## 4. Integration Guide Requirements

The principle of self-contained workflows is well-established but undermined by inconsistencies.

-   **Missing Guides – Required Workflow – File Path – Priority**
    -   **Missing Guide**: A guide is needed to define the purpose and expected content for each subdirectory created by the `draft-release.wf.md` workflow. The agent has no context for what goes into `codemods/`, `researches/`, `user-experience/`, etc.
    -   **Required Workflow**: `work-on-task.wf.md`, `create-task.wf.md`
    -   **File Path**: `dev-handbook/guides/project-management/release-directory-contents.g.md`
    -   **Priority**: 🟡 High

-   **Missing Guides – Required Workflow – File Path – Priority**
    -   **Missing Guide**: A guide or explicit definition is needed for all custom `bin/` commands beyond the standard `test`/`lint`/`build`/`run`. The `bin/gc` command in `draft-release.wf.md` is undocumented.
    -   **Required Workflow**: `draft-release.wf.md`
    -   **File Path**: `dev-handbook/guides/project-tools/cli-reference.g.md` or update `architecture.md`.
    -   **Priority**: 🟢 Medium

## 5. AI Agent Instruction Updates

The clarity of instructions for the AI agent is generally high, but critical inconsistencies introduce ambiguity that will lead to execution failure.

-   **Path Ambiguity**: The primary issue is the `docs/` vs `dev-taskflow/` path problem. An agent following `load-project-context.wf.md` will fail because the specified files do not exist at the given path. This is a workflow-breaking ambiguity.
-   **Instructional Conflict**: In `initialize-project-structure.wf.md`, the agent is told to copy binstubs from a directory, but the workflow also provides embedded templates for those same binstubs. This creates a conflict on the source of truth, leading to unpredictable agent behavior.
-   **Vague Actions**: In `commit.wf.md`, the instruction "Update task status if applicable" is too vague. A well-instructed agent needs to know *how* to find the related task and *what* file/field to modify.

## 6. Cross-Reference Integrity

Cross-reference errors are the most significant issue in this review.

-   **Core Document Paths**: All 18 workflow files incorrectly reference core documentation (e.g., `what-do-we-build.md`) in `docs/` instead of the correct `dev-taskflow/` directory. This is a critical, systemic error.
-   **Internal Workflow Paths**: `create-adr.wf.md` contains conflicting internal paths, referencing both `docs/decisions/` and `docs/architecture-decisions/` when the correct path is `dev-taskflow/decisions/`.
-   **File Extension**: The reference to `save-session-context.md` in `README.md` is inconsistent with the `.wf.md` standard for workflow files.

## 7. Prioritised Handbook Tasks

🔴 **Critical (workflow-blocking)**
-   [ ] **Fix Core Doc Paths**: Update all `Project Context Loading` sections in all 18 workflow files to reference `dev-taskflow/what-do-we-build.md`, `dev-taskflow/architecture.md`, and `dev-taskflow/blueprint.md`.
-   [ ] **Refactor `initialize-project-structure.wf.md`**: Convert all four-tick markdown template embeddings to the standard `<templates>` XML format.

🟡 **High**
-   [ ] **Refactor `commit.wf.md`**: Align workflow structure with handbook standards (remove checkboxes from Process Steps, fix High-Level Execution Plan format).
-   [ ] **Fix `save-session-context.wf.md`**: Rename file to use `.wf.md` extension, update `README.md` link, and resolve the confusing dual-template embedding.
-   [ ] **Fix `create-adr.wf.md` Paths**: Standardize all internal directory references to `dev-taskflow/decisions/`.
-   [ ] **Create "Task Review Summary" Template**: Create a new template for the output of `review-task.wf.md` and update the workflow to use it.

🟢 **Medium**
-   [ ] **Remove Stray `path(...)` References**: Purge all obsolete inline `path(...)` notes from workflows where XML templates are used.
-   [ ] **Clarify `bin/gc` Command**: Document the purpose and usage of the `bin/gc` command referenced in `draft-release.wf.md`.

🔵 **Nice-to-have**
-   [ ] **Create "Release Subdirectory" Guide**: Write a guide explaining the purpose of each subdirectory created by `draft-release.wf.md` (e.g., `codemods/`, `researches/`).

## 8. Risk Assessment

-   **High Risk (🔴)**: The systemic path inconsistency for core project documents presents a high risk of complete workflow failure. The AI agent's context-loading step, which is a prerequisite for almost all tasks, will fail, rendering the entire handbook unusable.
-   **High Risk (🔴)**: The use of outdated template formats and structures in critical workflows like `initialize-project-structure.wf.md` and `commit.wf.md` will lead to unpredictable agent behavior, incorrect project setup, and non-compliant commits. This undermines the reliability and trustworthiness of the AI-assisted workflow.
-   **Medium Risk (🟡)**: Inconsistent file naming (`save-session-context.md`) and incorrect template references (`review-task.wf.md`) will cause specific workflows to fail or produce incorrect output, requiring manual intervention and debugging. This erodes the efficiency gains the system is supposed to provide.

## 9. Implementation Recommendation

[ ] ❌ **Major workflow updates required (blocking)**

The handbook contains a critical, systemic error in its core documentation pathing that affects nearly every workflow. This is a blocking issue that prevents the reliable execution of the context-loading step, a fundamental prerequisite for agent operation. Additionally, foundational workflows like `initialize-project-structure` are severely out of compliance with handbook standards. These issues must be resolved before the handbook can be considered functional.
