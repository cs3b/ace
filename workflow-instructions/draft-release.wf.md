# Draft Release Workflow Instruction

## Goal

Guide the AI agent and developer through **drafting a new release** in the project backlog.
This includes creating the initial release directory structure under `dev-taskflow/backlog/`,
setting up the standard subdirectories, creating the release overview document, and breaking the
user-provided release scope into actionable tasks.

## Prerequisites

* Developer has gathered raw release scope notes (features, bug-fixes, refactoring ideas, etc.).
* The current project version is known or can be discovered from the project's version file.
* Access to the `dev-taskflow/` and `dev-handbook/` directories.
* The `bin/tnid` command is available and functional for generating task IDs.

## Project Context Loading

* Load project objectives: `docs/what-do-we-build.md`
* Load architecture overview: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`

## Process Steps

1. **Gather Release Metadata**
   * Ask the user for:
     * Desired specific semantic version (e.g., `v.0.1.0`, `v.1.2.3`). This must include the patch version following MAJOR.MINOR.PATCH format.
     * Release codename (derive from user input if not explicitly given, using project-themed naming).
     * Raw scope notes (bullet list, document paths, or free-form text).

2. **Create Release Directory and Structure**
   * Create the target release directory using the specific semantic version:
     `dev-taskflow/backlog/v.X.Y.Z-codename/` (e.g., `dev-taskflow/backlog/v.0.3.0-new-feature/`).
   * Create standard sub-directories within the new release directory:

     ```
     dev-taskflow/backlog/v.X.Y.Z-codename/
     ├── tasks/
     ├── docs/
     ├── decisions/
     ├── codemods/
     ├── reflections/
     ├── researches/
     ├── test-cases/
     └── user-experience/
     ```

3. **Create Release Overview Document**
   * Create the release overview file at: `dev-taskflow/backlog/v.X.Y.Z-codename/v.X.Y.Z-codename.md`
   * Use the release overview template: path (dev-handbook/templates/release-management/release-overview.template.md)

4. **Populate Overview Document**
   * Fill in the release overview with:
     * Release title with version and codename
     * Release type based on semantic versioning rules
     * Start date (today) and estimated target date
     * Copy raw user input into **Collected Notes** section
     * Extract primary goals from the user's notes
     * Initial high-level implementation plan (to be refined)

5. **Break Down Scope Into Tasks**
   * Analyze the raw notes to identify distinct actionable items
   * Group related items that form cohesive work units
   * For each distinct item or group:
     a. Determine the appropriate category:
        * `tasks/` - Implementation work
        * `decisions/` - Architecture decisions (ADRs)
        * `docs/` - Documentation tasks
        * `researches/` - Investigation/spike tasks
        * `test-cases/` - Test scenario definitions
        * `user-experience/` - UX/UI related tasks

     b. Create a new task file using the task template: path (dev-handbook/templates/release-tasks/task.template.md)
     
     c. Key rules for task creation:
        * Use `bin/tnid v.X.Y.Z` to generate the next sequential task ID
        * Task filename format: `v.X.Y.Z+task.N-kebab-case-title.md`
        * Planning steps use asterisk markers (`* [ ]`)
        * Execution steps use hyphen markers (`- [ ]`)
        * Always include a directory audit for context
        * Embed test verification inline with steps
        * Clear deliverables (Create/Modify/Delete)
        * Define what's out of scope

6. **Ensure Completeness**
   * Verify that **every sentence or bullet** from the user input maps to at least one task file
   * Check for:
     * Ambiguous requirements that need clarification
     * Missing acceptance criteria
     * Undefined dependencies between tasks
     * Unrealistic time estimates
   * Highlight any issues and request clarification from the user

7. **Update Roadmap**
   * Add the new release to the roadmap's "Planned Major Releases" table:

     ```markdown
     | Version | Codename | Target Window | Goals | Key Epics |
     |---------|----------|---------------|-------|-----------|
     | v.X.Y.Z | Codename | Month YYYY    | Brief | Epic list |
     ```

   * Update roadmap's `last_reviewed` date
   * Add entry to Update History section
   * Commit roadmap changes separately with message:

     ```bash
     git commit -m "docs(roadmap): add release v.X.Y.Z-codename to planned releases"
     ```

8. **Validate Directory Structure**
   * Run validation checks:

     ```bash
     # Verify directory structure
     ls -la dev-taskflow/backlog/v.X.Y.Z-codename/
     
     # Check subdirectories
     for dir in tasks docs decisions codemods reflections researches test-cases user-experience; do
       [ -d "dev-taskflow/backlog/v.X.Y.Z-codename/$dir" ] && echo "✓ $dir" || echo "✗ $dir missing"
     done
     
     # Verify overview file
     [ -f "dev-taskflow/backlog/v.X.Y.Z-codename/v.X.Y.Z-codename.md" ] && echo "✓ Overview file" || echo "✗ Overview file missing"
     
     # Count created tasks
     find dev-taskflow/backlog/v.X.Y.Z-codename/tasks -name "*.md" | wc -l
     ```

9. **Prepare Commit Message (Do NOT Execute)**
   * Display the following git command for the user:

     ```bash
     bin/gc -i "scaffold release v.X.Y.Z-codename with initial structure and tasks"
     ```

   * Do **not** run the command automatically

10. **Review With User**
    * Present summary:
      * Release version and codename
      * Number of tasks created in each category
      * List of all task IDs and titles
    * Ask for confirmation on:
      * Task priorities and estimates
      * Any unclear task descriptions
      * Missing tasks or requirements
    * Iterate until the user is satisfied

## Input

* Semantic version and codename (requested interactively if not provided)
* Raw release scope notes (features, fixes, refactors, docs, etc.)

## Output / Success Criteria

* A new directory `dev-taskflow/backlog/v.X.Y.Z-codename/` exists with all subdirectories
* Release overview document created and populated with user's notes
* All user notes have corresponding task files with unique IDs
* Each task follows the standard format with clear objectives and acceptance criteria
* Roadmap updated with new release information and committed
* Git commit command displayed (not executed)
* User has reviewed and confirmed all generated tasks

## Common Patterns

### Semantic Versioning Rules

* **MAJOR** (X.0.0): Incompatible API changes
* **MINOR** (x.Y.0): New functionality, backward compatible
* **PATCH** (x.y.Z): Bug fixes, backward compatible

### Task Priority Guidelines

* **High**: Blocks other work or critical path
* **Medium**: Important but not blocking
* **Low**: Nice-to-have or can be deferred

### Estimate Guidelines

* Simple task: 1-4h
* Medium complexity: 5-10h
* Complex task: 11-25h
* Epic (break down): >25h

## Error Handling

* If `bin/tnid` fails: Use manual numbering starting from last known ID
* If directory exists: Ask user whether to merge or use different version
* If user notes are vague: Request specific examples or acceptance criteria
* If no codename provided: Suggest based on project theme or feature focus

## Usage Example
>
> "Prepare a new release with the notes in `dev-taskflow/backlog/ideas.md`.
> Expected version: `v.0.3.0`, codename: `atlas`."

---

This workflow focuses on **drafting** a release in the backlog. Once development begins, the release
moves to `current/`. For publishing completed releases, use the publish-release workflow.

## Embedded Templates

### Release Overview Template: path (dev-handbook/templates/release-management/release-overview.template.md)

````markdown
# v.X.Y.Z [Codename]

## Release Overview
<!-- Brief description of the release's purpose and value proposition. -->

## Release Information
- **Type**: [Major | Feature | Bug Fix]
- **Start Date**: YYYY-MM-DD
- **Target Date**: YYYY-MM-DD  
- **Status**: Planning

## Collected Notes
<!-- Raw notes provided by the user -->

## Goals & Requirements

### Primary Goals
- [ ] <!-- Goal 1 with specific metrics -->
- [ ] <!-- Goal 2 with acceptance criteria -->
- [ ] <!-- Goal 3 with success strategy -->

### Dependencies
- <!-- External dependencies -->
- <!-- Internal dependencies -->

### Risks & Mitigation
- <!-- Risk 1: Description | Mitigation strategy -->
- <!-- Risk 2: Description | Mitigation strategy -->

## Implementation Plan

### Core Components
1. **Design & Architecture**
   - [ ] <!-- Architecture decision/design task -->
   - [ ] <!-- API design task -->

2. **Dependencies**  
   - [ ] <!-- Dependency setup task -->
   - [ ] <!-- Integration task -->

3. **Implementation Phases**
   - [ ] <!-- Phase 1: Foundation -->
   - [ ] <!-- Phase 2: Core features -->
   - [ ] <!-- Phase 3: Polish and testing -->

## Quality Assurance

### Test Coverage
- [ ] Unit Tests (>80% coverage)
- [ ] Integration Tests
- [ ] Performance Tests
- [ ] User Acceptance Tests

### Documentation
- [ ] API Documentation
- [ ] User Guide
- [ ] Developer Guide
- [ ] CHANGELOG Entry

## Release Checklist
- [ ] All planned features implemented and tested
- [ ] All tests passing (unit, integration, e2e)
- [ ] Documentation complete and reviewed
- [ ] CHANGELOG.md updated with all changes
- [ ] Version numbers updated in relevant files
- [ ] Security review completed
- [ ] Performance benchmarks meet targets
- [ ] Backward compatibility verified
- [ ] Migration guide prepared (if needed)
- [ ] Release notes drafted

## Notes
<!-- Additional context, decisions, or clarifications -->
````

### Task Template: path (dev-handbook/templates/release-tasks/task.template.md)

````markdown
---
id: v.X.Y.Z+task.N  # Generated using bin/tnid v.X.Y.Z
status: pending
priority: [high | medium | low]
estimate: Nh
dependencies: []
---

# [Verb + Object]

## 0. Directory Audit ✅

_Command run:_
```bash
tree -L 2 [relevant-directory] | sed 's/^/    /'
```

_Result excerpt:_

```
[insert tree output here]
```

## Objective

[Why are we doing this? What value does it provide?]

## Scope of Work

* [What will be touched/changed]
* [Key areas of impact]

### Deliverables

#### Create

* path/to/new/file.ext

#### Modify  

* path/to/existing/file.ext

#### Delete

* path/to/obsolete/file.ext

## Phases

1. [Audit/Research phase]
2. [Design/Planning phase]
3. [Implementation phase]
4. [Testing/Validation phase]

## Implementation Plan

### Planning Steps

* [ ] [Research/analysis task - use asterisk markers]
  > TEST: Pre-condition Check
  > Type: [Pre-condition Check | Action Validation]
  > Assert: [What needs to be verified]
  > Command: bin/test --check-something

### Execution Steps

* [ ] [Concrete implementation action - use hyphen markers]
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: [Expected outcome]
  > Command: bin/test --verify-result

## Acceptance Criteria

* [ ] All deliverables created/modified as specified
* [ ] [Specific functionality working]
* [ ] All automated tests pass
* [ ] Documentation updated

## Out of Scope

* ❌ [What won't be touched in this task]
* ❌ [Clear boundaries]

## References

* [Relevant guide or documentation]
* [Related task or ADR]
````
