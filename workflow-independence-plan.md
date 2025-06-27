# Workflow Independence Refactoring Plan

## Summary

Based on the dependency analysis from task v.0.3.0+task.1, this plan outlines specific refactoring approaches for each of the 21 workflow files to achieve independence and enable autonomous execution by coding agents.

## Key Refactoring Principles

1. **Embed Essential Context** - Critical information from guides must be embedded directly in workflows
2. **Remove Workflow-to-Workflow Dependencies** - No workflow should depend on another workflow
3. **Standardize Path Resolution** - Use tools for dynamic paths, provide fallbacks
4. **Minimize User Interaction** - Only require user input when absolutely necessary
5. **Self-Contained Execution** - Each workflow must contain all information needed to execute

## Workflows to Remove (5 files)

Based on the analysis, these workflows should be deleted:

- `create-retrospective-document.wf.md`
- `create-review-checklist.wf.md`
- `review-tasks-board-status.wf.md`
- `create-release-overview.wf.md` (merge valuable content into `publish-release.wf.md`)
- `load-env.wf.md` (rename to `load-project-context.wf.md` and limit scope)

## Workflows to Refactor (16 files)

### 1. `draft-release.wf.md`

**Current Dependencies:**

- `task-definition.g.md`
- `project-management.g.md`
- `version-control-system.g.md` (remove)
- `breakdown-notes-into-tasks.wf.md`
- Multiple templates

**Refactoring Approach:**

- Embed task definition format directly
- Embed release planning principles from project-management guide
- Remove version-control-system guide reference
- Include template structures inline
- Add autonomous task breakdown logic

### 2. `breakdown-notes-into-tasks.wf.md`

**Current Dependencies:**

- `task-definition.g.md`
- 7 sub-workflows
- `bin/tnid`, `bin/rc`

**Refactoring Approach:**

- Embed task definition structure
- Consolidate sub-workflows into main workflow
- Include task ID generation logic
- Simplify complex orchestration

### 3. `update-roadmap.wf.md`

**Current Dependencies:**

- `roadmap-definition.g.md`
- `strategic-planning.g.md`
- Project context files

**Refactoring Approach:**

- Embed roadmap format and principles
- Include strategic planning guidelines
- Add project context loading section

### 4. `work-on-task.wf.md`

**Current Dependencies:**

- `task-definition.g.md` (remove)
- `temporary-file-management.g.md`
- `fix-tests.wf.md` reference
- Add: `coding-standards.g.md`

**Refactoring Approach:**

- Remove task-definition dependency
- Embed temporary file management rules
- Include fix-tests logic inline when needed
- Add coding standards section

### 5. `fix-tests.wf.md`

**Current Dependencies:**

- `testing.g.md`
- `coding-standards.g.md`
- `bin/test`, `bin/lint`, `bin/build`

**Refactoring Approach:**

- Embed core testing patterns
- Include coding standards relevant to test fixes
- Add tool usage instructions

### 6. `commit.wf.md`

**Current Dependencies:**

- `version-control-system.g.md`
- `documentation.g.md` (remove)
- `testing.g.md` (remove)
- `project-management.g.md` (remove)

**Refactoring Approach:**

- Embed conventional commit format
- Remove unnecessary guide references
- Add clear commit message examples

### 7. `create-adr.wf.md`

**Current Dependencies:**

- `documentation.g.md`
- Template: `decisions/_template.md`

**Refactoring Approach:**

- Embed ADR format and principles
- Include template structure inline
- Add examples of well-written ADRs

### 8. `create-api-docs.wf.md`

**Current Dependencies:**

- `documentation.g.md`
- `coding-standards.g.md` (remove)

**Refactoring Approach:**

- Embed YARD syntax basics
- Remove coding-standards dependency
- Include API documentation examples

### 9. `create-user-docs.wf.md`

**Current Dependencies:**

- `documentation.g.md`
- Templates: `docs/_template.md`, `user-experience/_template.md`

**Refactoring Approach:**

- Embed user documentation principles
- Include both templates inline
- Add user doc examples

### 10. `create-test-cases.wf.md`

**Current Dependencies:**

- `testing.g.md`
- Template: `test-cases/_template.md`

**Refactoring Approach:**

- Embed testing patterns and principles
- Include template structure inline
- Add test case examples

### 11. `create-reflection-note.wf.md`

**Current Dependencies:**

- Template: `reflections/_template.md`
- `bin/rc` (update behavior)

**Refactoring Approach:**

- Include template inline
- Update to self-review session if no context provided
- Add reflection examples

### 12. `publish-release.wf.md`

**Current Dependencies:**

- `quality-assurance.g.md`
- `release-publish.g.md`
- `changelog.g.md`
- `roadmap-definition.g.md`
- `version-control-system.g.md` (remove)

**Refactoring Approach:**

- Embed QA checklist
- Include release publishing steps
- Embed changelog format
- Remove version-control dependency

### 13. `review-task.wf.md`

**Current Dependencies:**

- `task-definition.g.md`
- `coding-standards.g.md` (remove)
- `bin/tnid` (remove)
- `bin/tn`, `bin/tr`
- `bin/gl`

**Refactoring Approach:**

- Embed task review criteria
- Remove unnecessary tool references
- Focus on review process

### 14. `initialize-project-structure.wf.md`

**Current Dependencies:**

- `task-definition.g.md` (remove)
- Multiple templates
- `bin/tnid` (remove)
- `bin/tn`, `bin/tr` (remove)
- `bin/tree`

**Refactoring Approach:**

- Remove task-related dependencies
- Embed all template contents
- Include directory structure

### 15. `update-blueprint.wf.md`

**Current Dependencies:**

- `bin/tn`, `bin/tr` (remove)
- `bin/tree`

**Refactoring Approach:**

- Remove unnecessary tool references
- Add blueprint format specification
- Include update guidelines

### 16. `save-session-context.md`

**Current Dependencies:**

- `bin/rc` (remove)
- Embedded session format

**Refactoring Approach:**

- Remove tool dependency
- Enhance session format specification
- Add examples

## Context Embedding Strategy

### 1. Guide Content Extraction

For each workflow, extract only the essential information from referenced guides:

- Core concepts and definitions
- Required formats and structures
- Critical rules and constraints
- Common patterns and examples

### 2. Template Inlining

Replace template file references with:

- Complete template content for simple templates
- Minimal viable template structure for complex ones
- Clear placeholders and instructions

### 3. Tool Usage Documentation

For each required tool:

- Document expected input/output
- Provide usage examples
- Include error handling

### 4. Project Context Loading

Standardize context loading sections:

```markdown
## Project Context Loading
- Load project objectives: docs/what-do-we-build.md
- Load architecture overview: docs/architecture.md  
- Load project structure: docs/blueprint.md
```

### 5. Autonomous Execution Patterns

Replace user verification with:

- Programmatic validation checks
- Confidence thresholds for proceeding
- Clear error messages when user input needed

## Implementation Priority

### Phase 1: High-Impact Workflows (Week 1)

1. `draft-release.wf.md` - Critical for release management
2. `work-on-task.wf.md` - Core development workflow
3. `commit.wf.md` - Most frequently used

### Phase 2: Task Management (Week 2)

4. `breakdown-notes-into-tasks.wf.md`
5. `review-task.wf.md`
6. `fix-tests.wf.md`

### Phase 3: Documentation Workflows (Week 3)

7. `create-adr.wf.md`
8. `create-api-docs.wf.md`
9. `create-user-docs.wf.md`
10. `create-test-cases.wf.md`

### Phase 4: Remaining Workflows (Week 4)

11. `update-roadmap.wf.md`
12. `publish-release.wf.md`
13. `initialize-project-structure.wf.md`
14. `create-reflection-note.wf.md`
15. `update-blueprint.wf.md`
16. `save-session-context.md`

## Success Criteria

Each refactored workflow must:

1. Execute without external workflow dependencies
2. Contain all necessary context inline
3. Use tools only for dynamic operations
4. Minimize user interaction requirements
5. Include clear error handling
6. Pass independence validation tests
