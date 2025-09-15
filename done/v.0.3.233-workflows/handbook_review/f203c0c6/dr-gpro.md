# SECTION LIST  ─ DO NOT CHANGE NAMES

## 1. Executive Summary

This review assesses a significant refactoring of the development handbook, guided by three new Architecture Decision Records (ADRs) that enforce workflow self-containment, XML-based template embedding, and centralized template management. The introduction of these ADRs establishes a robust and scalable foundation for AI agent workflows.

The provided workflow instructions largely adhere to the new principles, demonstrating a successful migration toward self-contained, machine-readable formats. However, several critical inconsistencies and ADR violations have been identified. Key workflows like `initialize-project-structure`, `update-blueprint`, and `update-roadmap` contain incorrect pathing for core documentation, which will cause execution failures. The `commit` workflow violates ADR-002 by not using the mandated XML template format.

These issues are considered blocking as they compromise the reliability and predictability required for AI agent execution. Immediate remediation is required to align the handbook with its own architectural principles before further development.

## 2. Workflow Instructions Updates

The provided workflows represent a major step towards self-contained execution. However, several critical and high-priority issues must be addressed.

### Compliance with New ADRs

* **ADR-001 (Self-Containment)**: ✅ Most workflows comply, embedding necessary context and referencing only the three permitted core documents (`what-do-we-build.md`, `architecture.md`, `blueprint.md`).
* **ADR-002 (XML Templates)**: ⚠️ Partial compliance. Most workflows correctly use the `<templates>` structure. However, `commit.wf.md` violates this rule by using raw markdown code blocks for templates.
* **ADR-003 (Template Directory)**: ✅ Workflows embedding templates correctly reference the new `.ace/handbook/templates/` directory structure.

### Specific Workflow Analysis

* ❌ **`initialize-project-structure.wf.md`**: Contains critical path contradictions. The "Project Context Loading" section references core documents in `.ace/taskflow/`, while the "Process Steps" and "Generated Documentation" sections correctly reference `docs/`. This internal inconsistency will break the workflow.
* ❌ **`update-blueprint.wf.md`**: Operates on the wrong file (`.ace/taskflow/blueprint.md`). The canonical project blueprint is located at `docs/blueprint.md` as established by the project context and `initialize-project-structure` workflow. This workflow is functionally broken.
* ❌ **`update-roadmap.wf.md`**: Embeds an incorrect and irrelevant template (`release-readme.template.md`) instead of a roadmap-related template. The workflow is unusable in its current state.
* ❌ **`commit.wf.md`**: Fails to use the gem's own `bin/git-commit-with-message` tool, instead instructing manual `git commit` commands. It also violates ADR-002 by not using XML-based templates.
* ⚠️ **`create-adr.wf.md`**: Contains an incorrect path reference in Step 7 (`docs/architecture-decisions/`). The correct path is `docs/decisions/`.
* ⚠️ **`create-task.wf.md`**: The workflow title is "Breakdown Notes into Tasks" while the filename is `create-task.wf.md`. This naming should be harmonized. The "Directory Audit" step is overly specific (`.ace/handbook/guides`) and should be generalized or made optional.

## 3. Template & Example Updates

The move to XML-embedded templates is a major improvement. The embedded templates are largely correct, but key issues exist.

* ❌ **`commit.wf.md`**: The "Commit Message Templates" section uses markdown code blocks instead of the required `<templates>` XML structure. This violates ADR-002 and requires immediate refactoring.
* ❌ **`update-roadmap.wf.md`**: The embedded template (`.ace/handbook/templates/release-planning/release-readme.template.md`) is incorrect for a roadmap update workflow. It appears to be a copy-paste error. This makes the workflow non-functional.
* ✅ **Other Workflows**: Workflows like `create-adr`, `create-api-docs`, `draft-release`, and `initialize-project-structure` correctly embed templates with valid paths according to ADR-002 and ADR-003.

## 4. Integration Guide Requirements

The project relies on external services and environment configuration, but lacks guides for setup.

* **Missing Guide**: Environment Setup and Secrets Management.
* **Required Workflow**: An `onboard-developer.wf.md` or similar workflow should orchestrate the setup process, referencing the new guide.
* **File Path**: `.ace/handbook/guides/setup/environment-setup.g.md`
* **Priority**: 🟡 High. This is crucial for both human developers and AI agents to use tools that interact with Gemini and GitHub APIs.

## 5. AI Agent Instruction Updates

The new ADRs are designed to improve the AI agent experience, but inconsistencies undermine this goal.

* **Path Unreliability**: The path confusion between `docs/` and `.ace/taskflow/` in `initialize-project-structure.wf.md` and `update-blueprint.wf.md` is the most severe issue. An agent cannot reliably load project context or update key documents.
* **Inconsistent Tool Usage**: Workflows like `commit.wf.md` should instruct the agent to use the project's own tools (e.g., `bin/git-commit-with-message`) to promote adoption and test the gem's features. Instructing manual `git` commands defeats the purpose of the CAT gem.
* **Parsing Inconsistency**: The non-compliant templates in `commit.wf.md` would require the agent to have special-case parsing logic, violating the principle of standardized, predictable workflow files established by ADR-002.

## 6. Cross-Reference Integrity

Significant cross-referencing issues exist that will break automated workflows.

* 🔴 **Core Document Location**: There is a fundamental conflict regarding the location of core project documents.
  * **Canonical Source**: `architecture.md`, `blueprint.md`, and `what-do-we-build.md` state that core docs reside in `docs/`.
  * **Conflict in `initialize-project-structure.wf.md`**: The "Project Context Loading" section incorrectly points to `.ace/taskflow/` for these same files.
  * **Conflict in `update-blueprint.wf.md`**: This workflow incorrectly targets `.ace/taskflow/blueprint.md` for updates.
* 🟡 **Incorrect Directory in `create-adr.wf.md`**: Step 7 refers to `docs/architecture-decisions/`, which is incorrect. The canonical path is `docs/decisions/`.

These inconsistencies must be resolved to ensure agents can navigate the project correctly. All references should point to the single source of truth in the `docs/` directory.

## 7. Prioritised Handbook Tasks

🔴 **Critical (workflow-blocking)**

* **Task**: Resolve core document path conflicts in all workflows.
  * **Files**: `initialize-project-structure.wf.md`, `update-blueprint.wf.md`, `load-project-context.wf.md`.
  * **Action**: Ensure all references to `what-do-we-build.md`, `architecture.md`, and `blueprint.md` consistently point to the `docs/` directory.
* **Task**: Refactor `commit.wf.md` to comply with ADR-002.
  * **Files**: `commit.wf.md`.
  * **Action**: Convert all embedded templates to the `<templates>` XML format.
* **Task**: Correct the embedded template in `update-roadmap.wf.md`.
  * **Files**: `update-roadmap.wf.md`.
  * **Action**: Replace the incorrect `release-readme.template.md` with a relevant roadmap template or remove it.
* **Task**: Correct directory path in `create-adr.wf.md`.
  * **Files**: `create-adr.wf.md`.
  * **Action**: Change `docs/architecture-decisions/` to the correct `docs/decisions/`.

🟡 **High**

* **Task**: Create an environment setup guide.
  * **Files**: `.ace/handbook/guides/setup/environment-setup.g.md` (new).
  * **Action**: Document how to set up `GEMINI_API_KEY`, `GITHUB_TOKEN`, and local LM Studio for using the CAT gem.
* **Task**: Align workflows with the gem's own tools.
  * **Files**: `commit.wf.md`.
  * **Action**: Update instructions to use `bin/git-commit-with-message` instead of manual `git commit`.

🟢 **Medium**

* **Task**: Standardize workflow naming and content.
  * **Files**: `create-task.wf.md`.
  * **Action**: Align the filename with the H1 title ("Breakdown Notes into Tasks"). Generalize the "Directory Audit" step.

🔵 **Nice-to-have**

* **Task**: Add a README for the templates directory.
  * **Files**: `.ace/handbook/templates/README.md` (new).
  * **Action**: Briefly explain the template categories and naming conventions defined in ADR-003.

## 8. Risk Assessment

* 🔴 **Workflow Execution Failure**: The identified path inconsistencies in core workflows create a high probability of execution failure for an AI agent. This is the most significant risk, as it invalidates the primary purpose of the handbook.
* 🟡 **Compliance Dilution**: The `commit.wf.md` workflow's violation of ADR-002 undermines the new architectural principles. If not corrected, it could lead to further inconsistencies and reduce the benefits of standardization.
* 🟡 **Onboarding Friction**: The absence of an environment setup guide increases the effort required for any user (human or AI) to become productive with the toolchain, potentially hindering adoption.

## 9. Implementation Recommendation

    [ ] ✅ Handbook coverage is complete
    [ ] ⚠️ Minor guide updates needed
    [x] ❌ Major workflow updates required (blocking)
    [ ] 🔴 Critical guide gaps found (workflow-breaking)

**Justification**: The handbook contains blocking issues. Several core workflows (`initialize-project-structure`, `update-blueprint`, `update-roadmap`, `commit`) are functionally broken or violate foundational architectural principles (ADRs). These issues prevent reliable, automated execution by an AI agent and must be resolved before the handbook can be considered operational.
