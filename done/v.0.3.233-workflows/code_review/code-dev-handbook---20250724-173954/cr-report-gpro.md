---
---
:input_tokens: 259722
:output_tokens: 1967
:total_tokens: 265404
:took: 87.485
:provider: google
:model: gemini-2.5-pro
:timestamp: '2025-07-24T16:42:52Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 259722
:cost:
  :input: 0.324653
  :output: 0.01967
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.344323
  :currency: USD
---

# SECTION LIST ─ DO NOT CHANGE NAMES

## 1. Executive Summary

This diff introduces a foundational refactoring of the `dev-handbook`. The core changes involve:
1.  **Centralizing all document templates** into a new, well-organized `dev-handbook/templates/` directory.
2.  **Standardizing template embedding** within workflow instructions using a new, machine-readable XML `<documents>` format, which replaces the previous markdown-based system.
3.  **Introducing new guides and tools** (`markdown-sync-embedded-documents`) to support and automate this new template system.
4.  **Significantly simplifying complex workflows** (e.g., `synthesize-reviews`, `synthesize-reflection-notes`, `create-task`) into single, powerful commands, which greatly enhances the AI agent experience.

Overall, this is a 🟢 **highly positive and strategic update**. It dramatically improves the handbook's structure, maintainability, and suitability for automation. However, the changes are **breaking** for existing AI agent workflows due to the new template embedding format. Critical updates to integration guides are required to bridge this gap.

## 2. Workflow Instructions Updates

✅ **New Workflows & Patterns:**
*   A new XML-based document embedding pattern (`<documents>` with `<template>` and `<guide>` tags) has been introduced across all relevant workflows. This is a major architectural improvement for machine readability.
*   Workflows like `synthesize-reviews`, `synthesize-reflection-notes`, and `create-task` have been drastically simplified to leverage new CLI tools (`code-review-synthesize`, `reflection-synthesize`, `nav-path`), reducing complex multi-step scripts to single commands. This is a significant enhancement for AI agent execution.
*   The `work-on-task` workflow now includes explicit guidance on where to place generated artifacts like task-specific documentation and codemods, improving clarity for AI agents.

⚠️ **Modified Workflows:**
*   **Nearly all `.wf.md` files have been modified** to adopt the new XML embedding format. This is a fundamental change to how workflows are structured.
*   The `initialize-project-structure` workflow is heavily updated, moving core documentation to a root `docs/` directory and relying more on `dev-tools` for binstubs, indicating tighter system integration.
*   The main `workflow-instructions/README.md` has been transformed into a comprehensive "Workflow Integration Guide", complete with scenarios and a decision tree for agents. This is a major usability improvement.

❌ **Breaking Workflow Changes:**
*   The change from markdown-header/four-tick template embedding to the XML `<documents>` format is a **critical breaking change**. Any AI agent with parsers hardcoded for the old format will fail. This change is not backward compatible.

## 3. Template & Example Updates

✅ **Massive Template Refactoring:**
*   All templates have been moved from disparate locations (e.g., `guides/draft-release/`, `guides/initialize-project-templates/`) into a new, centralized, and logically categorized `dev-handbook/templates/` directory. This greatly improves organization and discoverability.
*   Many new, more granular templates have been added (e.g., for commit messages, review summaries, session context), providing better structure for common development artifacts.
*   The content and structure of most templates have been refined and standardized.

⚠️ **Deprecated/Removed Templates:**
*   The old template structure under `guides/` has been completely removed.
*   Obsolete templates, such as those for Vue.js testing (`vue-firebase-auth.md`, `vue-vitest.md`), have been correctly removed, cleaning up out-of-scope content.

## 4. Integration Guide Requirements

⚠️ The introduction of new tools and the simplification of complex workflows necessitates significant updates to integration guides.

*   **Missing Guide Update:** The core `guides/ai-agent-integration.g.md` was not updated in this diff. It is now critically out of date and provides incorrect guidance.
    *   **Required Workflow:** Update this guide to reflect the new XML embedding standard, the new single-command workflows (`code-review-synthesize`, etc.), and the use of `nav-path` for task creation.
    *   **File Path:** `dev-handbook/guides/ai-agent-integration.g.md`
    *   **Priority:** 🔴 Critical

*   **Missing Guide:** A migration guide is needed for AI agents to transition from the old template format to the new XML format.
    *   **Required Workflow:** Create a new guide explaining the breaking change, how to detect the format, and the new parsing logic required.
    *   **File Path:** `dev-handbook/guides/migration/agent-template-embedding-migration.g.md` (suggested)
    *   **Priority:** 🟡 High

*   **New Guides:** New guides for the `markdown-sync-embedded-documents` tool have been added (`template-synchronization.md` and `template-sync-operations.md`), which is excellent coverage for the new system.

## 5. AI Agent Instruction Updates

❌ **CRITICAL BREAKING CHANGE:**
*   Agents must be updated to stop parsing markdown headers and four-tick code blocks for templates.
*   Agents must now parse the `<documents>` XML block to find embedded templates and guides.
*   The logic for executing workflows like `synthesize-reviews` and `create-task` must be updated to use the new, simpler single-command approach instead of following the previous multi-step shell scripts.

✅ **Workflow Simplification:**
*   The agent experience for several complex workflows is now vastly improved. What was once a 10-step script is now a single command with flags, reducing the chance of execution error.

## 6. Cross-Reference Integrity

✅ The diff shows a concerted effort to update links to reflect the new `templates/` structure and renamed workflows. Key index files like `guides/README.md` have been updated correctly.

⚠️ **High Potential for Missed Links:**
*   The scale of this refactoring is immense. A full, automated link-check across the entire `dev-handbook` is strongly recommended to catch any missed references.
*   The structural change moving ADRs from `dev-taskflow/decisions/` to a root `docs/decisions/` is significant. All documents must be scrubbed for old paths to ADRs.

## 7. Prioritised Handbook Tasks

🔴 **Critical (workflow-blocking):**
*   **Update AI Agent Integration Guide:** The `guides/ai-agent-integration.g.md` file is now incorrect and provides harmful instructions. It must be updated immediately to describe the new XML embedding format and the new single-command workflows.

🟡 **High:**
*   **Create Agent Migration Guide:** Document the breaking change in template embedding and provide a clear migration path for AI agents. This is crucial for backward compatibility and smooth transitions.
*   **Full Link Integrity Check:** Perform an automated link-check across the entire `dev-handbook` submodule to ensure no broken references remain after the massive template refactoring.
*   **Verify ADR Path References:** Audit all guides for hardcoded paths to `dev-taskflow/decisions/` and update them to the new `docs/decisions/` location.

🟢 **Medium:**
*   **Consolidate Template Sync Guides:** The new `template-synchronization.md` and `template-sync-operations.md` guides have significant overlap. Consider merging them into a single, comprehensive guide with a "Quick Reference" section.

🔵 **Nice-to-have:**
*   *No nice-to-have tasks identified; focus should be on critical and high-priority items.*

## 8. Risk Assessment

*   🔴 **Agent Workflow Breakage (High):** This is the primary risk. Agents built to parse the old template format will fail. Without updated integration guides and an explicit migration path, this change will block AI-assisted development.
*   🟡 **Incomplete Refactoring (Medium):** The sheer volume of moved files creates a risk of broken cross-references that could disrupt both human and AI navigation of the handbook.
*   🟢 **Tooling Dependency (Low):** The newly simplified workflows are highly dependent on the custom CLI tools (`nav-path`, `reflection-synthesize`, etc.). The handbook should clearly state these dependencies and link to their documentation.

## 9. Implementation Recommendation

*   [ ] ✅ Handbook coverage is complete
*   [ ] ⚠️ Minor guide updates needed
*   [ ] ❌ Major workflow updates required (blocking)
*   [X] 🔴 Critical guide gaps found (workflow-breaking)

**Justification:** While the refactoring is a massive improvement, it introduces a critical breaking change for AI agents. The primary `guides/ai-agent-integration.g.md` is now dangerously out of date, and there is no migration guide for the new template embedding format. These gaps will break existing AI agent workflows until they are addressed.