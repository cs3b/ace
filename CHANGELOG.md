# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

## [v0.4.0] - 2025-06-25

### Added

- Enhanced initialize-project-structure workflow with v.0.0.0 template release tracking
  - Created template v.0.0.0 release structure in dev-handbook/guides/initialize-project-templates/
  - Added template copying and customization logic for new projects
  - Integrated roadmap creation into project initialization process
  - Included clear user guidance for post-initialization steps

### Changed

- Renamed manage-roadmap workflow to update-roadmap for improved clarity
  - Updated all references across the codebase
  - Enhanced workflow with cleanup functionality for completed releases
- Improved roadmap management with post-release cleanup integration
  - Added cleanup step to remove completed releases from roadmap
  - Updated step numbering and error handling procedures

## [v.0.3.0] - 2025-06-04

### v.0.3.0+tasks.24 - 2025-06-02 - Implement Roadmap Release Lifecycle Management

- **Enhanced manage-roadmap workflow with release lifecycle integration** to automatically maintain roadmap accuracy:
  - Added step 3 (Update Release Status) to check release folder locations (backlog|current|done) and update roadmap accordingly
  - Added step 7 (Validate Synchronization) to ensure roadmap matches project folder structure and validate cross-references
  - Enhanced with comprehensive error handling for format validation, file system inconsistencies, and commit failures
  - Added cross-workflow dependency documentation specifying integration with draft-release and publish-release workflows
- **Updated draft-release workflow** to include roadmap management:
  - Added step 7 to update roadmap with new release information after release scaffolding completion
  - Integrated separate roadmap commit with standardized message format
  - Added roadmap update validation to success criteria
- **Updated publish-release workflow** to include roadmap cleanup:
  - Added step 15 to remove completed releases from roadmap during documentation archival phase
  - Implemented roadmap cleanup with cross-reference dependency updates
  - Enhanced critical success criteria to include roadmap accuracy validation
- **Enhanced roadmap definition guide** with comprehensive release lifecycle specifications:
  - Added release status tracking format specifying how releases should be represented based on folder location
  - Created systematic release removal process with validation checklist
  - Documented integration triggers specifying when roadmap updates occur during release workflows
  - Added comprehensive error handling and recovery procedures for failed roadmap updates
  - Established cross-workflow dependencies and validation requirements for release lifecycle management

### v.0.3.0+tasks.22 - 2025-06-02 - Create Roadmap Definition Guide

- **Created comprehensive roadmap definition guide** at `dev-handbook/guides/roadmap-definition.g.md`:
  - Established deterministic format requirements for all roadmap sections (Front Matter, Project Vision, Strategic Objectives, Key Themes & Epics, Planned Major Releases, Cross-Release Dependencies, Update History)
  - Defined precise table format specifications with column definitions and validation criteria
  - Created content guidelines and best practices for writing style, strategic alignment, and maintenance
  - Added validation criteria for structure, content, and quality compliance
  - Provided concrete examples demonstrating correct and incorrect roadmap formatting
  - Documented integration guidelines for workflow instructions to reference format requirements
- **Separated format specification from workflow process** following separation of concerns principle:
  - Removed embedded format rules from manage-roadmap workflow instruction
  - Established pattern for workflows to reference dedicated format guide rather than embedding specifications
  - Created foundation for consistent roadmap format validation across all related workflows

### v.0.3.0+tasks.16 - 2025-06-02 - Implement Agreed Naming Conventions for Guides and Workflow Instructions

- **Implemented file extension conventions** to establish clear distinction between guides and workflow instructions:
  - Applied `.wf.md` suffix to all 21 workflow instruction files (breakdown-notes-into-tasks, commit, create-adr, create-api-docs, create-reflection-note, create-release-overview, create-retrospective-document, create-review-checklist, create-test-cases, create-user-docs, draft-release, fix-tests, initialize-project-structure, load-env, save-session-context, manage-roadmap, publish-release, review-task, review-tasks-board-status, update-blueprint, work-on-task)
  - Applied `.g.md` suffix to all guide files with noun-based naming (changelog, coding-standards, documentation, error-handling, performance, project-management, quality-assurance, security, strategic-planning, temporary-file-management, testing, release-codenames, release-publish, testing-tdd-cycle, debug-troubleshooting, version-control-system, task-definition)
  - Moved and renamed workflow-specific guides: embedding-tests-in-workflows → .meta/workflow-embedding-tests.g.md, tools-guide → .meta/tools.g.md
- **Updated meta-documentation** to reflect new naming conventions:
  - Enhanced `dev-handbook/guides/.meta/writing-guides-guide.md` with `.g.md` convention documentation and noun-based naming examples
  - Enhanced `dev-handbook/guides/.meta/writing-workflow-instructions-guide.md` with `.wf.md` convention documentation and verb-first naming pattern
- **Fixed internal documentation links** throughout the codebase:
  - Updated all cross-references in workflow instructions and guides to use new `.wf.md` and `.g.md` filenames
  - Corrected relative paths in test-driven-development-cycle documentation
  - Verified link integrity with zero critical broken links remaining
- **Created Zed editor rule mapping documentation** for manual updates to development environment integration

### v.0.3.0+tasks.15 - 2025-06-01 - Rename "Prepare Release" to "Draft Release" and Ensure Independence from "Publish Release"

- **Renamed prepare-release to draft-release throughout codebase** for clearer separation from publish-release process:
  - Renamed `dev-handbook/workflow-instructions/prepare-release.md` to `dev-handbook/workflow-instructions/draft-release.md`
  - Renamed `dev-handbook/guides/prepare-release/` directory to `dev-handbook/guides/draft-release/`
  - Updated 147+ references across workflow instructions, guides, session files, and current tasks
- **Established complete independence between draft-release and publish-release processes**:
  - Removed inappropriate references to draft-release from publish-release documentation
  - Removed draft-release prerequisites from publish-release workflow instructions
  - Added clarifying note in draft-release.md explaining scope distinction from publish-release
- **Reorganized documentation structure** for better logical organization:
  - Split guides README.md into separate "Draft Release Management" and "Publish Release Management" sections
  - Restructured workflow instructions README.md with improved section hierarchy (Core Workflow, Project Initialization, Draft Releases, Testing, Project Management, Publish Release)
  - Added all missing guides to guides README.md including language-specific sub-guides and project initialization templates
- **Clarified process separation**: Draft Release focuses on creating and planning new releases in backlog, while Publish Release handles finalizing and deploying completed releases

### v.0.3.0+tasks.14 - 2025-06-01 - Define and Document "Publish Release" Process and Guide

- **Created comprehensive publish release process** replacing ship-release terminology:
  - `dev-handbook/guides/publish-release.md` - Detailed guide explaining release publishing philosophy, semantic versioning scheme (v<major>.<minor>.<patch> extracted from release folder names), and archival process from `dev-taskflow/current/` to `dev-taskflow/done/`
  - `dev-handbook/workflow-instructions/publish-release.md` - Step-by-step workflow instruction for executing the complete publish release process including version finalization, package publication, documentation archival, and stakeholder communication
  - `dev-handbook/guides/changelog-guide.md` - Comprehensive changelog writing guide following Keep a Changelog format with project-specific adaptations and integration guidelines
- **Replaced ship-release terminology throughout codebase**:
  - Deleted `dev-handbook/workflow-instructions/ship-release.md` and `dev-handbook/guides/ship-release.md` files
  - Moved `dev-handbook/guides/ship-release/` directory to `dev-handbook/guides/publish-release/` with updated language-specific examples (ruby.md, rust.md, typescript.md)
  - Updated all references from "ship-release" to "publish-release" across documentation files, workflow instructions, and guides
- **Enhanced versioning documentation**:
  - Updated `dev-handbook/guides/version-control.md` with semantic versioning scheme documentation and examples showing version extraction from release folder names
  - Updated `dev-handbook/guides/project-management.md` with archival process description and consistent publish release terminology
- **Integrated technology-agnostic approach** supporting diverse project types through `bin/build` execution and flexible package publication processes
- **Established clear process separation** between preparation (handled by existing prepare-release workflow) and final deployment/archival (handled by new publish-release process)

### v.0.3.0+tasks.12 - 2025-06-01 - Remove Checkboxes from Guides and Workflow Instructions; Clarify Use of Acceptance Criteria

- **Converted inappropriate interactive checklists to bullet points** in guides:
  - `dev-handbook/guides/version-control.md` - Changed PR template example from checkboxes to bullet points
  - `dev-handbook/guides/security.md` - Converted security review checklist from interactive checkboxes to informational bullet points with bold headers
- **Enhanced meta documentation** with comprehensive checkbox usage guidelines:
  - `dev-handbook/guides/.meta/writing-guides-guide.md` - Added detailed section on appropriate vs inappropriate checkbox usage, with examples of when checkboxes are legitimate (templates, examples) vs inappropriate (interactive checklists)
  - `dev-handbook/guides/.meta/writing-workflow-instructions-guide.md` - Added "List Formatting in Workflows" section clarifying that Success Criteria should use simple bullet points, Process Steps should use numbered lists, and checkboxes are only appropriate in templates/examples
- **Standardized all workflow instruction Success Criteria** to use simple bullet points instead of checkboxes across 11 workflow files: `create-user-docs.md`, `create-test-cases.md`, `create-retrospective-document.md`, `create-release-overview.md`, `create-api-docs.md`, `create-adr.md`, `commit.md`, `create-review-checklist.md`, `review-tasks-board-status.md`, `create-reflection-note.md`, `prepare-release.md`
- **Converted Process Steps in ship-release.md** from checkboxes to numbered steps (1-24) for better sequential execution guidance
- **Established clear distinction** between reference documentation (guides) and actionable content (tasks), preventing AI agents from treating guides as interactive checklists while preserving legitimate checkbox usage in templates and examples

### v.0.3.0+tasks.11 - 2025-06-01 - Clarify Policy on Updating "Done" Tasks if Referenced Files Change

- Added comprehensive policy section to `dev-handbook/guides/project-management.md` under Agent Operational Boundaries
- Defined clear distinction between prohibited modifications (content changes, historical revisions, status changes) and allowed reference updates (broken link fixes, security annotations, accessibility improvements)
- Established process requirements for human updates including justification, additive approach, history preservation, clear attribution, and minimal scope
- Provided concrete examples of acceptable vs unacceptable modifications to done tasks
- Maintains balance between preserving historical accuracy and ensuring practical usability of project documentation

### v.0.3.0 - 2025-06-01 - Enhance Review Task Workflow for New Task Structure

- Updated the `review-task.md` workflow instruction to incorporate the new Planning Steps and Execution Steps structure for tasks.
- Added steps to the review process to evaluate task structure, recommend using Planning Steps for complex tasks, and suggest adding embedded tests.
- Ensured the workflow guides reviewers to maintain consistency with the updated task template and standards.

### v.0.3.0+tasks.10 - 2025-06-01 - Refine Task Template to Include Distinct "Plan" and "Execution" Sections

- Updated the task template (`dev-handbook/guides/prepare-release/v.x.x.x/tasks/_template.md`) to include separate "Planning Steps" (`* [ ]`) and "Execution Steps" (`- [ ]`) subsections within the "Implementation Plan".
- Updated the `write-actionable-task.md` guide to document the new structure, explaining the rationale, visual distinction, when to use planning steps, and how it relates to workflow phases (review vs. work).
- Added examples to the guide demonstrating tasks with only execution steps and tasks with both planning and execution steps, including embedded tests in both sections.

### v.0.3.x+task.8 - 2025-06-01 - Refine Initialize Project Test Task and Create Review Roadmap Task

- Updated `dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2/tasks/008-test-initialize-project.md` to align its scope with the "Initialize Project Structure" workflow, specifically excluding the creation of `roadmap.md` and initial release scaffolding.
- Created new task `dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2/tasks/v.0.3.0+task.21.md` to review the `manage-roadmap.md` workflow instruction, following the guide for writing actionable tasks.

### v.0.3.x - 2025-05-30 - Standardize Binstub Location and Rename gat to tal

- Renamed the `bin/gat` wrapper script to `bin/tal`.
- Updated documentation and task references for the `bin/gat` -> `bin/tal` rename.
- Added binstub scripts for `tnid`, `rc`, and `tal` to `dev-tools/exe-old/_binstubs/`.

### v.0.3.x - 2025-05-30 - Incorporate Codename Picking Guide into Prepare Release Workflow

### v.0.3.x+task.20 - 2025-05-30 - Improve Initialize Project Structure Workflow

- **Refactored `initialize-project-structure.md` Workflow:**
  - Added explicit idempotency statement to clarify rerun behavior.
  - Streamlined the workflow by removing the redundant "Initialize Version Control" (formerly Step 3) and the "Tailor Development Guides" (formerly Step 4) steps.
  - Renumbered the steps to reflect the removal of the two steps.
  - Enhanced the "Core Documentation Generation" step to reference new templates and include improved example questions for interactive prompts.
  - Updated the "Setup Project `bin/` Scripts" step (now Step 3) to refer to the `dev-taskflow/architecture.md` for binstub explanations.
- **Created New Project Initialization Templates:**
  - Added `dev-handbook/guides/initialize-project-templates/PRD.md` with a basic PRD structure.
  - Added `dev-handbook/guides/initialize-project-templates/README.md` with a basic README structure.
  - Added `dev-handbook/guides/initialize-project-templates/blueprint.md` based on the current project's blueprint structure.
  - Added `dev-handbook/guides/initialize-project-templates/architecture.md` based on the current project's architecture structure, including binstub explanations.
  - Added `dev-handbook/guides/initialize-project-templates/what-do-we-build.md` based on the current project's what-do-we-build structure.
- **Created New Guide for Codenames:**
  - Added `dev-handbook/guides/picking-codenames.md` with guidance on choosing themes, length, and uniqueness for project codenames.

### v.0.3.x - 2025-05-30 - Standardize Task ID Generation and Consolidate Task Templates

- **Task ID Generation Standardization:**
  - Updated `dev-handbook/guides/write-actionable-task.md`, `dev-handbook/workflow-instructions/breakdown-notes-into-tasks.md`, and `dev-handbook/guides/project-management.md` to mandate the use of the `bin/tnid` script for generating task IDs. This ensures unique, correctly formatted, and sequentially numbered task IDs.
- **Task Template and Example Consolidation:**
  - Moved the canonical task template to `dev-handbook/guides/prepare-release/v.x.x.x/tasks/_template.md`.
  - Relocated the full worked task example to `dev-handbook/guides/prepare-release/v.x.x.x/tasks/_example.md`.
  - Updated `dev-handbook/guides/write-actionable-task.md` to remove the embedded template and example, now linking to these new centralized locations. This streamlines task creation and ensures a single source of truth for the task structure.

### v.0.3.0+task.19 - 2025-05-28 - Fix Markdown Lint Errors

- **Documentation Quality Improvements:**
  - Fixed final markdown lint errors in `dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2/tasks/018-add-tool-for-getting-release-path.md`
  - Resolved MD013 line length violations by appropriately breaking long lines to comply with 120-character limit
  - Completed processing of all 81 markdown files in the project

- **Task Management:**
  - Updated task file checklist to mark final file as completed
  - Marked all scope of work items, deliverables, and acceptance criteria as completed
  - Changed task status from "in-progress" to "done"

- **Quality Assurance:**
  - All markdown files now pass `bin/lint` markdownlint checks
  - Project documentation now maintains consistent formatting standards
  - Improved documentation readability and compliance with style guidelines

### v.0.3.0+task.18 - 2025-05-27 - Add Tool for Getting Current Release Path and Version

- **Created New Development Tools:**
- Added `dev-tools/exe-old/get-current-release-path.sh` - Main tool script that determines the appropriate
  directory for storing newly created tasks and returns version information.
- Added `bin/rc` - Thin wrapper script for easy access to the get-current-release-path utility.
- Added `dev-tools/exe-old/test-get-current-release-path.sh` - Comprehensive test suite with 13 test
  assertions covering 5 test scenarios.

- **Tool Functionality:**
- Returns path to current release directory (e.g., `dev-taskflow/current/v.X.Y.Z-codename`)
  and version string (e.g., `v.X.Y.Z`) when a current release exists.
- Returns backlog tasks path (`dev-handbook/backlog/tasks`) and empty version when no current
  release is detected.
- Handles edge cases like multiple release directories gracefully.
- Includes help option and proper error handling for invalid arguments.

- **Workflow Integration:**
- Updated `dev-handbook/workflow-instructions/breakdown-notes-into-tasks.md` to utilize the new
  `bin/rc` tool in Step 6 for determining task storage location.
- Added instructions for creating necessary directories before saving task files.
- Integrated version information access for potential use in task metadata or naming.

- **Quality Assurance:**
- All automated tests pass, covering current release detection, backlog fallback, multiple
  directories, help functionality, and error handling.
- Tool correctly identifies and works with the actual project structure
  (`dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2`).

### v.0.3.x-fix - 2025-05-27 - Update Breakdown Notes to Tasks Workflow

- Updated the `breakdown-notes-into-tasks.md` workflow instructions.
- Added clarification on where formal task files should be stored (current release `tasks/` directory or `dev-handbook/backlog/tasks/`).
- Introduced a new Step 6 to formalize the task structure according to the `write-actionable-task.md` guide after user verification.
- Reviewed and updated the workflow's goal, inputs, process steps, output, and success criteria for consistency.

### v.0.3.0+task.7 - 2025-05-27 - Add .meta/ Subdirectories for Self-Referential Workflows and Guides

- Created the `.meta/` subdirectories within `dev-handbook/guides/` and `dev-handbook/workflow-instructions/`.
- Moved the `writing-guides-guide.md`, `writing-workflow-instructions.md` (and renamed it to
  `writing-workflow-instructions-guide.md`), and `tools-guide.md` files into
  `dev-handbook/guides/.meta/`.
- Updated all internal links within the project that pointed to these moved guide files.
- Added documentation explaining the purpose and usage of the `.meta/` directories in `dev-handbook/README.md`.
- Verified internal links using the lint tool.

### v.0.3.0+task.5 - 2025-05-27 - Ensure Uniqueness and Consistency of Task IDs and Release Versioning (and Tooling Fixes)

- **Task ID and Release Versioning Standardization**:
  - Implemented new task ID convention: `v.X.Y.Z+task.<sequential_number>`.
  - Standardized release directory naming to `v.X.Y.Z-codename`.
- **Tooling Enhancements & Fixes**:
  - Added `bin/tnid` (`dev-tools/exe-old/get-next-task-id`) to generate the next unique task ID.
  - Added `bin/gat` (`dev-tools/exe-old/get-all-tasks`) to list all tasks in a release, sorted by
    dependencies and highlighting the next actionable one.
  - Added `dev-tools/exe-old/lint-task-metadata` script (integrated into `bin/lint`) to validate task
    metadata against new conventions.
  - Modified `bin/tn` (`dev-tools/exe-old/get-next-task`) to correctly sort task IDs numerically and
    prioritize `in-progress` tasks.
  - Updated `dev-handbook/guides/tools-guide.md` with refined principles for path conventions, testing,
    and binstub simplicity.
  - Corrected path usage, regdev-tools/exes for version parsing, and fixed bugs in the newly
    created/modified tools (`get-next-task-id`, `get-all-tasks`, `lint-task-metadata`) and their
    binstubs (`bin/tnid`, `bin/gat`).
  - Fixed minor errors in `bin/lint` script.
- **Documentation Updates**:
  - Updated `dev-handbook/guides/project-management.md` with new task ID convention, release folder
    naming, and tool information.
  - Updated `dev-handbook/guides/write-actionable-task.md` with new task ID format in
    templates/examples.
  - Updated `dev-handbook/workflow-instructions/prepare-release.md` to reflect new ID generation and
    versioning.
    versioning.

### **Minor Fix:**

- Bring back the directory `dev-handbook/workflow-instructions/breakdown-notes-into-tasks`, deleted
    in 33af0d94cb0598baa4b5d36b8ffd273d3b8ebcc8

### v.0.3.x-4 - 2025-05-27 - Implement Immutability Rules for Specified Paths via Agent Blueprint

- **Agent Operational Boundaries:**
  - Added "Read-Only Paths" and "Ignored Paths" sections to `dev-taskflow/blueprint.md` to define
    file access rules for the agent.
    - Populated "Ignored Paths" with default common patterns (e.g., `dev-taskflow/done/**/*`,
      `**/node_modules/**`).
    - Added project-specific "Read-Only Paths" (e.g., `dev-taskflow/releases/**/*`,
      `dev-taskflow/decisions/**/*`).
  - Updated `dev-handbook/workflow-instructions/initialize-project-structure.md` to include these new
    sections and their default content when generating a new `blueprint.md`.
  - Added a new "Agent Operational Boundaries" section to `dev-handbook/guides/project-management.md`
    to explain the purpose of these blueprint configurations and refer to `dev-taskflow/blueprint.md`
    for details.

### v.0.3.x-3 - 2025-05-27 - Establish Guidelines for Temporary File Usage by AI Agent

- **Temporary File Usage Guidelines:**
  - Defined criteria for appropriate use of temporary files by the agent.
  - Specified recommended locations, naming conventions, and cleanup responsibilities for temporary
    files.
  - Documented these guidelines in `dev-handbook/guides/temporary-file-management.md` and updated relevant
    links.

- **Development Cycle Documentation Refinement:**
  - Renamed `dev-handbook/guides/task-cycle.md` to `dev-handbook/guides/test-driven-development-cycle.md`.
  - Renamed directory `dev-handbook/guides/task-cycle/` to `dev-handbook/guides/test-driven-development-cycle/`.
  - Updated all internal references to these renamed paths.
  - Deleted redundant `dev-handbook/guides/testing/test-cycle.md`.

### v.0.3.x-2 - 2025-05-27 - Design a Standard for Incorporating Tests into AI Agent Workflows

- **Workflow Testing Standard:**
  - Defined a standard for embedding tests (`> TEST:`, `> VERIFY:`) in workflow instruction files.
  - Created `dev-handbook/guides/embedding-tests-in-workflows.md` detailing the standard.
  - Updated `dev-handbook/guides/writing-workflow-instructions.md` to reference the new testing guide.
  - Added a proposed `bin/test` script to `dev-taskflow/architecture.md`.
  - Integrated the testing standard into `dev-handbook/guides/write-actionable-task.md`,
    `dev-handbook/workflow-instructions/work-on-task.md`, and
    `dev-handbook/workflow-instructions/breakdown-notes-into-tasks.md`.

### v.0.3.x-13 - 2025-05-26 - Create `bin/` Aliases for Common Development Commands

- **Standardized `bin/` Commands:**
  - Introduced top-level `bin/test`, `bin/lint`, `bin/build`, and `bin/run` alias scripts.
  - These scripts wrap underlying project-specific commands for consistent developer experience.
  - Created placeholder binstub templates in `dev-tools/exe-old/_binstubs/` for new projects.
  - Documented the new `bin/` aliases.

### v.0.3.x-6 - 2025-05-26 - Merge tools and utils Directories

- **Tooling Structure Refinement:**
  - Merged `dev-handbook/utils` directory into `dev-tools/exe-old`.
  - Renamed scripts in `dev-tools/exe-old` to follow a verb-prefix naming convention (e.g.,
    `recent-tasks` to `get-recent-tasks`).
  - Updated all internal and external references to the old script paths and names.

- **Minor Cleanup:**
  - Deleted duplicate directory `dev-handbook/workflow-instructions/breakdown-notes-into-tasks`.

---

## 2025-05-26

- Updated submodules for documentation.
- Rewrote `prepare-release` workflow.
- Scaffolded `v.x.y.z-ideas-after-toolkit-meta` release.
- Marked preflight task as "someday".
- Prepared release `v0.2.22`.

## 2025-05-09

- **Added:**
  - FAQ section to `README.md`.
  - `package-lock.json` to track dependencies.
  - `package.json` to define devDependencies.

- **Changed:**
  - Updated submodule commits.

## 2025-05-08

- **Added:**
  - `create-reflection-note` workflow.

- **Changed:**
  - Reviewed and restructured project management workflows.
  - Split Task `v.0.2.3-18` (Review and Restructure Project Management Workflows) into Plan & Execute phases.
  - Improved usage examples in `README.md` including initializing project structure, breaking down ideas
    into tasks, reviewing tasks, and working on tasks.
  - Drafted initial `README.md` content for the Coding Agent Workflow Toolkit, explaining key
    components, purpose, and setup.
  - Updated documentation subprojects.

## 2025-05-07

- **Changed:**
  - Updated `dev-taskflow` to `v0.2.3-17` which refactored documentation generation workflows.
    This includes:
    - Flattening the `dev-handbook/workflow-instructions/docs/` subdirectory.
    - Renaming documentation generation workflows to `create-<context>.md`
      (e.g., `create-adr.md`, `create-api-docs.md`).
    - Updating H1 titles and internal links.
  - Corrected introductory sentences in documentation to reference `breakdown-notes-into-tasks.md`.
  - Updated references to old workflow names.

---

## Prior to 2025-05-07 (Based on Release Summaries)

Changes in this period are summarized by their release version.

### Release v.0.2.3 (Feedback After Zed Extension)

(Corresponds to tasks completed around and before 2025-05-07, many of which are reflected
in the 2025-05-07 and 2025-05-08 git logs)

- **Documentation Standardization:**
  - Refactored developer guides and workflow instructions by technology stack (Ruby, Rust,
    TypeScript). (Task `01-tailor-guides-tech-stack`, `07-tailor-workflow-instructions-tech-stack`)
  - Implemented consistent naming conventions for release documents
    (`02-release-doc-naming-consistency`), workflow instructions
    (`09-define-apply-workflow-naming-convention`), and task IDs (`08-define-task-id-convention`).
- **Workflow Streamlining:**
  - Consolidated task specification workflows (`lets-spec-*`) into `prepare-tasks` (now
    `breakdown-notes-into-tasks`). (Task `03-consolidate-spec-workflows`,
    `16-review-simplify-prepare-tasks-workflow`)
  - Reviewed, refined, and renamed core workflows:
    - `lets-start` to `work-on-task`. (Task `10-review-rename-lets-start-workflow`)
    - `lets-tests` (merged into `work-on-task`). (Task `11-review-lets-tests-workflow`)
    - `lets-fix-tests` to `fix-tests`. (Task `12-review-lets-fix-tests-workflow`)
    - `lets-release` reviewed (Task `13-review-lets-release-workflow`), leading to new
      `ship-release` workflow.
    - `init-project` to `initialize-project-structure`. (Task `14-review-rename-init-project-workflow`)
    - `generate-blueprint` reviewed and renamed. (Task `15-review-rename-generate-blueprint-workflow`)
    - Clarified and restructured project management (`review-tasks-board-status`) and reflection
      (`save-session-context`, `create-retrospective-document`) workflows. (Task
      `18-review-restructure-project-management-workflows`)
  - Reviewed and restructured documentation generation workflows (Task
    `17-review-documentation-generation-workflows` - details in 2025-05-07 log).
- **Project Planning & Execution Enhancements:**
  - Defined and implemented a project roadmap (`dev-taskflow/roadmap.md`) and strategic planning
    process (`dev-handbook/guides/strategic-planning-guide.md`,
    `dev-handbook/workflow-instructions/manage-roadmap.md`). (Task
    `20-define-roadmap-and-strategic-planning`)
  - Mandated and defined a structured "Implementation Plan" section within task files
    (`dev-handbook/guides/write-actionable-task.md`). (Task `21-define-embedded-plan-structure`)
  - Created a new `ship-release` workflow. (Task `22-create-ship-release-workflow`)
- **Documentation Quality & Structure Improvements:**
  - Created guides for troubleshooting (`dev-handbook/guides/troubleshooting-workflow.md`). (Task `04-high-level-dev-debug-workflow`)
  - Created guide for task implementation cycle (`dev-handbook/guides/test-driven-development-cycle.md`). (Task `05-support-writing-workflow-guide`)
  - Split testing guides by technology. (Task `06-split-testing-guides-by-tech`)
  - Reviewed and improved `prepare-release` templates. (Task `19-review-prepare-release-templates`)

### Release v-0.2.2 (Feedback to Process)

- Clarified "Command" terminology in documentation, replacing it with "Workflow Instruction".
- Updated development guides with research insights on AI-assisted development, prompting, and general
  best practices.
- Created a new guide on "Writing Workflow Instructions".

### Release v.0.2.1 (Spec from Diff)

- Introduced the `lets-spec-from-git-diff` workflow instruction to analyze git diffs and generate
  structured feedback and task specifications.

### Release v.0.2.0 (Dev Docs Review - Streamline Workflow)

- **Unified Task Management:** Solidified a single task management system using structured Markdown files
  in `dev-taskflow/{backlog,current,done}`. Removed the experimental `project/task-manager`.
- **Simplified Release Documentation:** Provided clearer guidelines for documentation required for
  different release types (Patch, Feature, Major).
- **Workflow Consistency:** Ensured consistent terminology and aligned Kanban board references. Commands
  were updated to link to guides rather than duplicating content.
- **Integrated Best Practices:** Incorporated research on "planning before coding" and structured task
  details into guides.
- Updated and created various workflow instructions (`load-env`, `work-on-task`, `lets-spec-from-pr-comments`,
  `review-kanban-board`, `self-reflect`, `lets-release`, `log-session`, `generate-blueprint`,
  `lets-spec-from-release-backlog`) to align with the unified system.
- Updated core guides (`project-management.md`, `ship-release.md`, `unified-workflow-guide.md`) and
  introduced a project blueprint.
- Separated context loading (`load-env`) from task execution (`work-on-task`).

### Release v.0.0.1 (Initial Release)

- Established initial project infrastructure.
- Set up the project structure and documentation framework.
- Documented the initial release process.
