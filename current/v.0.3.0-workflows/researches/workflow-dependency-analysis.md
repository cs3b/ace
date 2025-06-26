# Workflow Dependency Analysis

**Analysis Date:** 2025-06-26
**Scope:** All 21 workflow instruction files in `dev-handbook/workflow-instructions/`
**Purpose:** Identify cross-dependencies, external references, and missing context preventing independent execution by coding agents

## Executive Summary

This analysis reveals significant dependency patterns across the 21 workflow instruction files that create barriers to independent execution by coding agents. Key findings:

- **88% of workflows** contain external dependencies on guides, templates, or other workflows
- **67% require project context loading** through standardized files (`docs/what-do-we-build.md`, `architecture.md`, `blueprint.md`)
- **43% have circular or complex dependencies** that require multiple workflow orchestration
- **76% lack complete embedded context** for independent agent execution

## Dependency Categories

### 1. Project Context Dependencies (14 workflows)

Most workflows require loading fundamental project context:

**Standard Context Pattern:**
```
- docs/what-do-we-build.md (project objectives)
- docs/architecture.md (system design)
- docs/blueprint.md (project structure)
```

**Affected Workflows:**
- breakdown-notes-into-tasks.wf.md
- fix-tests.wf.md
- initialize-project-structure.wf.md
- load-env.wf.md
- review-task.wf.md
- work-on-task.wf.md
- create-adr.wf.md
- create-api-docs.wf.md
- create-release-overview.wf.md
- create-retrospective-document.wf.md
- create-user-docs.wf.md
- draft-release.wf.md
- publish-release.wf.md
- update-roadmap.wf.md

### 2. Guide Dependencies (18 workflows)

**High-Frequency Guide References:**

**`dev-handbook/guides/task-definition.g.md` (5 workflows):**
- breakdown-notes-into-tasks.wf.md
- draft-release.wf.md
- review-task.wf.md

#@=> guide is not be needed within following workflows
- initialize-project-structure.wf.md (project structure should not create tasks, only roadmap, prd and so on, draft release is what will take it, but not as part of initialize project)
- work-on-task.wf.md

**`dev-handbook/guides/documentation.g.md` (4 workflows):**
- create-adr.wf.md
- create-api-docs.wf.md
- create-user-docs.wf.md

#@=> guide is not be needed within following workflows
- commit.wf.md

**`dev-handbook/guides/testing.g.md` (3 workflows):**
- create-test-cases.wf.md
- fix-tests.wf.md

#@=> guide is not be needed within following workflows
- commit.wf.md

**`dev-handbook/guides/version-control-system.g.md` (3 workflows):**
- commit.wf.md

#@=> guide is not be needed within following workflows
- draft-release.wf.md
- publish-release.wf.md

**`dev-handbook/guides/project-management.g.md` (4 workflows):**
- draft-release.wf.md (should stay)

@=> if anything valueable, then needs to be merged into draft-release.wf.md
- create-release-overview.wf.md

@=> below workflow we can delete
- review-tasks-board-status.wf.md

#@=> guide is not be needed within following workflows
- commit.wf.md
- create-retrospective-document.wf.md

**`dev-handbook/guides/quality-assurance.g.md` (2 workflows):**
- publish-release.wf.md

@#=> delete below workflow
- create-review-checklist.wf.md


**`dev-handbook/guides/coding-standards.g.md` (3 workflows):**
- fix-tests.wf.md

@#=> we should add it to:
- work-on-task

@#=> we should remove it from below workflow
- review-task.wf.md
- create-api-docs.wf.md

**`dev-handbook/guides/release-publish.g.md` (2 workflows):**
- publish-release.wf.md

@#=> we should remove this workflow (if anything specific, and valuable then add it to publish-release)
- create-release-overview.wf.md

**Other Guide Dependencies:**
- `dev-handbook/guides/roadmap-definition.g.md`: update-roadmap.wf.md, publish-release.wf.md
- `dev-handbook/guides/strategic-planning.g.md`: update-roadmap.wf.md
- `dev-handbook/guides/changelog.g.md`: publish-release.wf.md
- `dev-handbook/guides/temporary-file-management.g.md`: work-on-task.wf.md

### 3. Template Dependencies (12 workflows)

**`dev-handbook/guides/draft-release/v.x.x.x/` templates (7 workflows):**
- create-adr.wf.md → `decisions/_template.md`
- create-reflection-note.wf.md → `reflections/_template.md`
- create-release-overview.wf.md → `v.x.x.x-codename.md`
- create-retrospective-document.wf.md → `reflections/_template.md`
- create-test-cases.wf.md → `test-cases/_template.md`
- create-user-docs.wf.md → `docs/_template.md`, `user-experience/_template.md`
- draft-release.wf.md → Multiple templates in subdirectories

**`dev-handbook/guides/initialize-project-templates/` (2 workflows):**
- initialize-project-structure.wf.md → `PRD.md`, `README.md`, `what-do-we-build.md`, `architecture.md`, `blueprint.md`, `v.0.0.0/`
- draft-release.wf.md → References for structure validation

**Other Template Dependencies:**
- breakdown-notes-into-tasks.wf.md → Sub-workflow templates in `breakdown-notes-into-tasks/` directory
- log-compact-session.wf.md → Embedded session log format template
- review-tasks-board-status.wf.md → Task `.md` file format expectations

### 4. Tool Dependencies (8 workflows)

**CLI Tool Requirements:**

**`bin/tnid` - Task ID generation (4 workflows):**
- breakdown-notes-into-tasks.wf.md
- draft-release.wf.md

@#=> we don't need to mention this tool in below workflows
- review-task.wf.md
- initialize-project-structure.wf.md

**`bin/rc` - Release context (3 workflows):**
- breakdown-notes-into-tasks.wf.md

@#=> below workflow needs udpdate: a) if user call it wihtout additional information we should self review current session b) if user provide context, then use the context
- create-reflection-note.wf.md

@#=> we don't need to mention this tool in below workflows
- log-compact-session.wf.md

**`bin/tn`, `bin/tr` - Task navigation (5 workflows):**
- review-task.wf.md
- work-on-task.wf.md

@#=> we don't need to mention this tool in below workflows
- update-blueprint.wf.md
- initialize-project-structure.wf.md
- review-tasks-board-status.wf.md


**`bin/gl` - Git history (2 workflows):**
- review-task.wf.md

@#=> below workflow needs to be removed
- create-retrospective-document.wf.md

**Other Tool Dependencies:**
- `bin/test`, `bin/lint`, `bin/build`: fix-tests.wf.md, publish-release.wf.md
- `bin/tree`: initialize-project-structure.wf.md, update-blueprint.wf.md

### 5. Workflow Orchestration Dependencies (9 workflows)

**Complex Workflow Chains:**

**Primary Chain - Release Management:**
- `draft-release.wf.md` → `breakdown-notes-into-tasks.wf.md` → Multiple sub-workflows

- `draft-release.wf.md` → `update-roadmap.wf.md`
- `publish-release.wf.md` → `update-roadmap.wf.md`

**Task Execution Chain:**
- `work-on-task.wf.md` → `fix-tests.wf.md` (conditional)
- `work-on-task.wf.md` → `review-task.wf.md` (reference)

**Session Management Chain:**
@=> we should remove the `create-retrospective-document.wf.md` workflow
- `create-retrospective-document.wf.md` → Uses outputs from `log-compact-session.wf.md`
- `create-retrospective-document.wf.md` → Uses outputs from `create-reflection-note.wf.md`

**Sub-workflow Dependencies:**
@#=> lets simplify breakdown-notes-into-tasks.wf.md -> create seperate task for it
- `breakdown-notes-into-tasks.wf.md` → 7 sub-workflows in subdirectory:
  - `from-concepts-in-backlog.md`
  - `from-diff.md`
  - `from-frd.md`
  - `from-pr-comments-api.md`
  - `from-pr-comments-mcp.md`
  - `from-prd.md`
  - `from-release-backlog.md`

## Critical Issues Preventing Independent Execution

### 1. Missing Embedded Context (16 workflows)

**Problem:** Workflows reference external guides/templates but don't embed essential information.

**Examples:**
- `commit.wf.md` references "conventional commit format" in external guide but doesn't specify format
- `create-test-cases.wf.md` requires testing guidelines but doesn't include key patterns
- `create-api-docs.wf.md` assumes YARD knowledge without embedding basic syntax

### 2. Dynamic Path Resolution (11 workflows)

**Problem:** Workflows use dynamic paths that require runtime resolution.

**Examples:**
@#=> we should prefer using tools for dynamic parts if tools avaiable
- `dev-taskflow/current/{release_dir}/` - requires discovering active release
- `bin/rc` output parsing for directory determination
- Template paths with variable version numbers

### 3. User Interaction Dependencies (8 workflows)

**Problem:** Workflows require user input/verification that breaks autonomous execution.

@#=> we should do this only if some information are missing, and user feedback / decisions are essential. If coding agent is sure the recomendations are fine, it should go on auto, but only then

**Examples:**
- `breakdown-notes-into-tasks.wf.md` - user verification step
- `draft-release.wf.md` - user confirmation of tasks
- `create-reflection-note.wf.md` - user content input

### 4. File System State Assumptions (13 workflows)

**Problem:** Workflows assume specific directory structures exist without validation.

**Examples:**
- Release directories must exist before many workflows can run
- Template files must be present but availability isn't verified
- Git repository state assumptions

## Dependency Mapping

### Core Infrastructure Workflows
@#=> we should no use load-env.wf.md in any workflow anymore.
```
load-env.wf.md → [PROJECT CONTEXT]
     ↓
work-on-task.wf.md → fix-tests.wf.md
                  → review-task.wf.md
```

### Release Management Chain
```
draft-release.wf.md → breakdown-notes-into-tasks.wf.md → [SUB-WORKFLOWS]
                   → update-roadmap.wf.md
     ↓
[DEVELOPMENT WORKFLOWS]
     ↓
publish-release.wf.md → update-roadmap.wf.md (removal)
```

### Documentation Workflows (Mostly Independent)
```
create-adr.wf.md
create-api-docs.wf.md
create-user-docs.wf.md
create-review-checklist.wf.md
create-test-cases.wf.md
```

### Session Management
```
log-compact-session.wf.md → create-retrospective-document.wf.md
create-reflection-note.wf.md → create-retrospective-document.wf.md
```

## Recommendations for Agent Independence

### Priority 1: Context Embedding

**Action:** Embed essential content from frequently referenced guides directly in workflows.

**Targets:**
- Conventional commit format in `commit.wf.md`
- Basic YARD syntax in `create-api-docs.wf.md`
- Core testing patterns in `create-test-cases.wf.md`
- Task definition structure in task-related workflows

### Priority 2: Path Resolution Standardization

**Action:** Create standard path resolution patterns and embed fallback logic.

**Implementation:**
- Add path discovery sections to workflows
- Provide default directory structures
- Include validation steps before proceeding

### Priority 3: Template Consolidation

**Action:** Reduce template fragmentation and provide embedded alternatives.

**Implementation:**
- Consolidate similar templates
- Embed minimal templates directly in workflows
- Create template discovery mechanisms

### Priority 4: Autonomous User Interaction

**Action:** Convert user verification steps to automated validation where possible.

**Implementation:**
- Replace user confirmation with programmatic checks
- Provide default values for common inputs
- Add bypass flags for automated execution

### Priority 5: Dependency Declaration

**Action:** Add explicit dependency sections to all workflows.

**Format:**
```markdown
## Dependencies
- **Required Files:** [list]
- **Required Tools:** [list]
- **Required Context:** [list]
- **Environmental Assumptions:** [list]
```

## Implementation Roadmap

### Phase 1: Foundation (Immediate)
1. Add dependency declarations to all workflows
2. Embed conventional commit format in `commit.wf.md`
3. Create path resolution utilities
4. Add file existence validation

### Phase 2: Context Reduction (Short-term)
1. Embed essential guide content in high-use workflows
2. Consolidate template dependencies
3. Create fallback mechanisms for missing files
4. Implement automated validation

### Phase 3: Agent Optimization (Medium-term)
1. Create agent-specific workflow variants
2. Implement autonomous user interaction patterns
3. Add comprehensive error handling
4. Create workflow orchestration engine

## Recommended Changes Based on Analysis

### Workflows to Remove/Consolidate

Based on the analysis and recommendations, the following workflows should be removed or consolidated:

1. **`create-retrospective-document.wf.md`** - Remove entirely
2. **`create-review-checklist.wf.md`** - Remove entirely
3. **`review-tasks-board-status.wf.md`** - Remove entirely
4. **`create-release-overview.wf.md`** - Remove (merge valuable content into `publish-release.wf.md`)
5. **`load-env.wf.md`** - Rename to `load-project-context.wf.md` and limit to loading `docs/*.md` files only

### Guide Dependencies to Remove

The following guide dependencies should be removed from workflows:

**From `task-definition.g.md`:**
- Remove from `initialize-project-structure.wf.md`
- Remove from `work-on-task.wf.md`

**From `documentation.g.md`:**
- Remove from `commit.wf.md`

**From `testing.g.md`:**
- Remove from `commit.wf.md`

**From `version-control-system.g.md`:**
- Remove from `draft-release.wf.md`
- Remove from `publish-release.wf.md`

**From `project-management.g.md`:**
- Remove from `commit.wf.md`
- Remove from `create-retrospective-document.wf.md`

**From `coding-standards.g.md`:**
- Add to `work-on-task.wf.md`
- Remove from `review-task.wf.md`
- Remove from `create-api-docs.wf.md`

### Tool Dependencies to Update

**Remove tool mentions from workflows:**
- `bin/tnid`: Remove from `review-task.wf.md` and `initialize-project-structure.wf.md`
- `bin/rc`: Remove from `log-compact-session.wf.md`
- `bin/tn`, `bin/tr`: Remove from `update-blueprint.wf.md`, `initialize-project-structure.wf.md`, `review-tasks-board-status.wf.md`

**Workflow behavior updates:**
- `create-reflection-note.wf.md`: Update to self-review current session if no context provided

### Workflow Simplification

1. **`breakdown-notes-into-tasks.wf.md`** - Create separate task to simplify and remove 7 sub-workflows
2. **Dynamic paths** - Prefer using tools for dynamic path resolution where available
3. **User interactions** - Only require when information is missing or decisions are essential

### Key Principles for Refactoring

1. **No workflow-to-workflow dependencies** - Guides and templates are acceptable, but workflows should not depend on other workflows
2. **Avoid circular dependencies** - Complex dependencies should be simplified where possible
3. **Autonomous execution** - User verification only when agent cannot confidently proceed
4. **Tool-based resolution** - Use existing tools for dynamic content rather than hardcoded paths

## Conclusion

The current workflow system requires significant refactoring to enable independent execution by coding agents. The analysis reveals that most workflows are designed for human-guided execution with manual context loading and verification steps.

Priority should be given to:
1. Removing redundant workflows and consolidating functionality
2. Eliminating unnecessary guide dependencies
3. Simplifying complex workflow chains
4. Enabling autonomous execution with minimal user intervention

The dependency mapping shows clear workflow families that can be optimized together, providing a structured approach to the refactoring effort.
