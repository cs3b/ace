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
* Higher-order navigation tools are available for task management.

## Project Context Loading

- Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`

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
     ├── ideas/
     ├── docs/
     ├── reflections/
     ├── researches/
     └── user-experience/
     ```

3. **Create Release Overview Document**
   * Create the release overview file at: `dev-taskflow/backlog/v.X.Y.Z-codename/v.X.Y.Z-codename.md`
   * Use the release overview template:

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
        * `docs/` - Documentation tasks
        * `researches/` - Investigation/spike tasks

     b. Create a new task file using the task template:

     c. Key rules for task creation:
        * Use `task-manager create --release v.X.Y.Z-codename --title "Task Title" --priority high --estimate "4h"` to generate tasks automatically
        * This handles ID generation, file naming, and proper directory placement
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
     git-commit -i "docs(roadmap): add release v.X.Y.Z-codename to planned releases"
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
     git-commit -i "scaffold release v.X.Y.Z-codename with initial structure and tasks"
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

### Common Issues

**Task ID Generation Failures:**

**Symptoms:**

* `task-manager create` command not found or fails
* Duplicate task ID generation
* Inconsistent numbering sequence

**Recovery Steps:**

1. Check if higher-order navigation tools are available
2. Verify task-manager tools are properly configured
3. Use nav-path with simpler parameters if complex ones fail
4. Ensure task uniqueness is maintained by the system
5. Ask user to verify task numbering approach

**Prevention:**

* Test `task-manager create` functionality before starting release creation
* Verify project tooling is properly set up
* Understand available nav-path options and capabilities

**Version Conflicts:**

**Symptoms:**

* Release directory already exists for specified version
* Version number conflicts with existing releases
* Semantic versioning violations

**Recovery Steps:**

1. Check existing releases: `ls -la dev-taskflow/backlog/`
2. Ask user whether to:
   * Merge with existing release (if same version)
   * Use different version number
   * Replace existing release (destructive)
3. Validate semantic versioning rules:

   ```bash
   # Check if version follows MAJOR.MINOR.PATCH
   echo "v.0.3.0" | grep -E "v\.[0-9]+\.[0-9]+\.[0-9]+"
   ```

4. Suggest appropriate version number based on scope
5. Document version choice reasoning

**Prevention:**

* Check for existing releases before creating new ones
* Validate version format early in process
* Discuss versioning strategy with user upfront

**Directory Creation Failures:**

**Symptoms:**

* Cannot create release directory structure
* Permission denied on filesystem operations
* Missing parent directories

**Recovery Steps:**

1. Check current directory and permissions: `pwd && ls -la`
2. Verify `dev-taskflow/backlog/` exists and is writable
3. Create missing parent directories:

   ```bash
   mkdir -p dev-taskflow/backlog/
   ```

4. Check disk space availability: `df -h`
5. Ask user to check filesystem permissions if issues persist

**Prevention:**

* Verify template availability before release creation
* Check dev-handbook submodule status
* Have fallback template formats ready

**Incomplete User Input:**

**Symptoms:**

* User provides vague or incomplete release scope
* Missing acceptance criteria in task descriptions
* Unclear requirements or dependencies

**Recovery Steps:**

1. Request specific examples for vague requirements
2. Ask clarifying questions about acceptance criteria:
   * What specific outcomes are expected?
   * How will success be measured?
   * What are the dependencies?
3. Break down large, unclear items into smaller tasks
4. Iterate with user until requirements are clear
5. Document assumptions and get user confirmation

**Prevention:**

* Ask detailed questions about release scope upfront
* Provide examples of well-formed requirements
* Clarify acceptance criteria for each major item

**Roadmap Update Failures:**

**Symptoms:**

* Cannot locate roadmap file
* Roadmap format doesn't match expected structure
* Git commit fails during roadmap update

**Recovery Steps:**

1. Search for roadmap file in multiple locations:

   ```bash
   find . -name "*roadmap*" -type f
   find . -name "*ROADMAP*" -type f
   ```

2. Check roadmap file format and structure
3. Create minimal roadmap entry if format is unclear
4. Skip roadmap update if file is problematic (document in notes)
5. Ask user about roadmap file location and format

**Prevention:**

* Verify roadmap file existence and format before editing
* Understand project's roadmap structure
* Have backup approach for roadmap updates

**Task Breakdown Failures:**

**Symptoms:**

* Cannot map user notes to actionable tasks
* Tasks are too large or too small
* Missing dependencies between tasks
* Unrealistic time estimates

**Recovery Steps:**

1. Review user notes sentence by sentence
2. Group related items that form cohesive work units
3. Break down tasks that are too large (>25h estimate)
4. Combine tasks that are too small (<1h estimate)
5. Map dependencies between tasks explicitly
6. Ask user to validate task breakdown and estimates

**Prevention:**

* Understand task sizing guidelines (1-4h simple, 5-10h medium, 11-25h complex)
* Consider implementation phases and dependencies
* Get user feedback on task breakdown approach

**No Codename Provided:**

**Symptoms:**

* User doesn't specify release codename
* Need to generate appropriate codename
* Codename conflicts with existing releases

**Recovery Steps:**

1. Suggest codename based on:
   * Project theme or domain
   * Major feature focus
   * Alphabetical progression
   * Version milestone significance
2. Check for codename conflicts in existing releases
3. Ask user to approve suggested codename
4. Use version number as fallback if no theme available

**Prevention:**

* Have codename generation strategy ready
* Understand project's naming conventions
* Prepare themed suggestions based on project domain

**Validation Step Failures:**

**Symptoms:**

* Directory structure validation finds missing components
* File count doesn't match expected task creation
* Release overview file incomplete or corrupted

**Recovery Steps:**

1. Re-run directory structure creation for missing components
2. Verify each required subdirectory exists:

   ```bash
   for dir in tasks docs reflections researches; do
     [ -d "dev-taskflow/backlog/v.X.Y.Z-codename/$dir" ] && echo "✓ $dir" || mkdir -p "dev-taskflow/backlog/v.X.Y.Z-codename/$dir"
   done
   ```

3. Regenerate missing files using templates
4. Validate release overview file content and format
5. Recount created tasks and verify against user scope

**Prevention:**

* Run validation steps incrementally during creation
* Use templates consistently for all file creation
* Double-check file creation success after each step

### Recovery Framework for Release Creation

When errors occur during release creation:

1. **Assessment Phase:**
   * Can the release creation continue with workarounds?
   * Are the errors due to environment/setup issues?
   * Do we have enough information to proceed?

2. **Recovery Actions:**
   * Document error details and attempted solutions
   * Use fallback approaches where possible
   * Get user input for unclear requirements
   * Create minimal viable release structure if needed

3. **Validation and Communication:**
   * Verify partial results meet minimum requirements
   * Explain limitations or compromises to user
   * Get user approval before proceeding with reduced scope
   * Document decisions for future reference

## Usage Example
>
> "Prepare a new release with the notes in `dev-taskflow/backlog/ideas.md`.
> Expected version: `v.0.3.0`, codename: `atlas`."

---

This workflow focuses on **drafting** a release in the backlog. Once development begins, the release
moves to `current/`. For publishing completed releases, use the publish-release workflow.

<documents>
    <template path="dev-handbook/templates/release-management/release-overview.template.md"># v.X.Y.Z [Codename]

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

<!-- Additional context, decisions, or clarifications --></template>

    <template path="dev-handbook/templates/task-management/task.pending.template.md">---
id: <generated automatically by nav-path>
status: pending
priority: <high/medium/low>
estimate: <n>h
dependencies: [<ticket-ids>]
---

# <Verb + Object>

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Why are we doing this?

## Scope of Work

- Bullet 1 …
- Bullet 2 …

### Deliverables

#### Create

- path/to/file.ext

#### Modify

- path/to/other.ext

#### Delete

- path/to/obsolete.ext

## Phases

1. Audit
2. Extract …
3. Refactor …

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Analyze current system/codebase to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Key components and their relationships are identified
  > Command: # Run project-specific test command --check-analysis-complete
- [ ] Research best practices and design approach
- [ ] Plan detailed implementation strategy

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Step 1: Describe the first implementation action.
- [ ] Step 2: Describe the second action, which produces a verifiable outcome.
  > TEST: Verify Action 2 Outcome
  > Type: Action Validation
  > Assert: The outcome of Step 2 (e.g., file created, content updated) is as expected.
  > Command: # Run project-specific test command --check-something path/to/relevant_artifact_from_step_2
- [ ] ... Add more implementation steps as needed.

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: All specified deliverables created/modified.
- [ ] AC 2: Key functionalities (if applicable) are working as described.
- [ ] AC 3: All automated checks in the Implementation Plan pass.

## Out of Scope

- ❌ …

## References

```
</template>
</documents>
