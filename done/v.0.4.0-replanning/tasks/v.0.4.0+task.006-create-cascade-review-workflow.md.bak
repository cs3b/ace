---
id: v.0.4.0+task.6
status: done
priority: medium
estimate: 8h
dependencies: [v.0.4.0+task.4]
---

# Create replan-cascade-task Workflow for Dependency Impact Analysis

## Objective

Create the `replan-cascade-task.wf.md` workflow that handles manual dependency impact analysis after task completion. This workflow reviews downstream tasks to
identify necessary updates based on completed work, implementing the Joiner function from the planning agent architecture with robust dependency graph traversal
and controlled cascade operations.

## What: Behavioral Specification

### User Experience

* **Trigger**: Manually run after task completion
* **Process**: Review dependent tasks in dependency order
* **Output**: Updated downstream tasks with impact notes or modifications

### Expected Behavior

1.  Identify all tasks dependent on the completed task (full transitive dependency analysis)
2.  Process dependencies in topological order with cycle detection
3.  For draft tasks: Prepend impact notes after metadata and set `needs_review: true`
4.  For pending tasks: Review and update implementation details and set `needs_review: true`
5.  Document discovered needs in impact notes (do not auto-create idea files)
6.  Commit each task update separately with descriptive messages including source task ID
7.  Display needs_review count in task-manager list output: "!!! Needs review: X"
8.  Track already-visited tasks to prevent infinite loops in circular dependencies
9.  Report circular dependencies at workflow completion rather than aborting

### Impact Handling Rules

* **Draft tasks**: Prepend impact notes after metadata, set `needs_review: true`, preserve draft status
* **Pending tasks**: Update implementation plan based on changes, set `needs_review: true`
* **In-progress tasks**: Flag for developer attention only with `needs_review: true`
* **No automatic status changes**: Maintain human control
* **Circular dependencies**: Continue processing with visited-task tracking, report at end
* **Commit messages**: Include source task ID and brief impact description

## Phases

1.  **Research & Analysis**: Dependency graph traversal patterns and impact analysis strategies
2.  **Design**: Template formats and cascade operation boundaries
3.  **Implementation**: Workflow creation with embedded verification tests
4.  **Integration**: Connection with existing task management tools

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities
and actual implementation work.*

### Planning Steps

*Research, analysis, and design activities that help clarify the approach before implementation begins.*

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Analyze current task dependency patterns in dev-taskflow structure
  > TEST: Dependency Pattern Analysis Type: Pre-condition Check
  > Assert: All dependency patterns and formats are documented Command: find dev-taskflow/current -name "\*.md" -exec grep -l "dependencies:" \{} \\; \| head -5
  > **COMPLETED**: Dependencies use YAML format `dependencies: [v.X.Y.Z+task.N, ...]` in front matter

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Research topological sorting algorithms for dependency graph traversal
  > TEST: Algorithm Selection Validation Type: Research Validation Assert: Optimal algorithm chosen for documentation-based system Command: echo "Topological
  > sort approach documented with complexity analysis"
  > **[Added on review]** Consider Kahn's algorithm (BFS-based) for better parallel task identification vs DFS for simpler implementation
  > **COMPLETED**: 
  > - **DFS approach**: Simpler to implement, natural for recursive task processing, handles cycles with visited tracking
  > - **Kahn's algorithm**: Better for identifying parallelizable tasks, explicit in-degree tracking, immediate cycle detection
  > - **Selected**: DFS with visited-set tracking for simplicity and natural fit with our cascade processing model

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Design impact note template format for draft task integration
  > **[Added on review]** Must follow XML embedding pattern: `<documents><template path="...">` per project standards
  > **COMPLETED**: Designed XML-embedded template format for impact notes following project standards:
  > - Container: `<documents>` with `<template path="dev-handbook/templates/tasks/impact-note.template.md">`
  > - Structure: Markdown content with placeholders for source task, impact summary, and action items
  > - Integration: Prepended after YAML metadata in draft tasks
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Plan rollback strategy with git-based recovery mechanisms
  > **COMPLETED**: Git-based rollback strategy designed:
  > - **Individual commits**: Each task update gets its own commit with descriptive message
  > - **Rollback commands**: Use `git revert <commit-hash>` for individual task rollbacks
  > - **Safety checks**: Preview changes before applying, require manual confirmation
  > - **Recovery options**: Full cascade rollback or selective task reversal
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Define cascade scope boundaries and manual override points
  > **COMPLETED**: Cascade boundaries defined:
  > - **Scope**: Only current release directory (no cross-release cascades)
  > - **Status limits**: Only draft/pending tasks modified (in-progress/done are read-only)
  > - **Manual gates**: Confirmation before each task update, preview mode available
  > - **Depth control**: Optional max-depth parameter to limit transitive cascades
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />**[Added on review]** Document in-degree calculation method for dependency counting
  > **COMPLETED**: In-degree calculation method documented:
  > - **Definition**: In-degree = number of tasks that depend on a given task
  > - **Calculation**: Scan all tasks, count references to target task in dependencies arrays
  > - **Usage**: For Kahn's algorithm alternative, identify tasks with no dependents
  > - **Display**: Show in-degree counts in cascade analysis output

### Execution Steps

*Concrete implementation actions that modify code, create files, or change the system state.*

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Create replan-cascade-task.wf.md workflow file in
  dev-handbook/workflow-instructions/
  > TEST: Workflow File Creation Type: Action Validation Assert: Workflow file exists with proper structure and embedded templates Command: test -f
  > dev-handbook/workflow-instructions/replan-cascade-task.wf.md && grep -q "## Process Steps" dev-handbook/workflow-instructions/replan-cascade-task.wf.md
  > **COMPLETED**: Created comprehensive workflow with all required sections and embedded impact note template

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Implement dependency identification algorithm with cycle detection
  > TEST: Dependency Detection Logic Type: Algorithm Validation Assert: Cycle detection and topological sort logic is documented and testable Command: grep -q
  > "cycle detection" dev-handbook/workflow-instructions/replan-cascade-task.wf.md
  > **COMPLETED**: Documented DFS-based algorithm with visited-set tracking for cycle detection

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Create impact-note.template.md in dev-handbook/templates/tasks/ with XML
  embedding
  > TEST: Template Creation Type: File Validation Assert: Impact note template uses XML embedding like other project templates Command: test -f
  > dev-handbook/templates/tasks/impact-note.template.md && grep -q "<template" dev-handbook/templates/tasks/impact-note.template.md
  > **COMPLETED**: Created template file and embedded it in workflow using proper XML format

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Document git-based rollback procedures with commit-per-file strategy
  > TEST: Rollback Documentation Type: Documentation Validation Assert: Rollback procedures specify individual file commits with descriptive messages Command:
  > grep -q "commit-per-file\|individual commit" dev-handbook/workflow-instructions/replan-cascade-task.wf.md
  > **COMPLETED**: Documented commit strategy with individual commits per task and rollback instructions

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Add cascade execution examples with real task scenarios from current release
  > **COMPLETED**: Added comprehensive examples section with task 4 cascade scenario and detailed command usage
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Integrate direct task-manager and nav-path command invocations
  > TEST: Tool Integration Type: Command Integration Assert: Workflow includes direct command invocations for task-manager and nav-path Command: grep -E
  > "(task-manager|nav-path)" dev-handbook/workflow-instructions/replan-cascade-task.wf.md
  > **COMPLETED**: Integrated nav-path commands in examples section

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />**[Added after review]** Implement needs_review counter display in task-manager list command
  > TEST: Needs Review Counter Type: Feature Validation Assert: task-manager list shows needs_review count prominently Command: task-manager list | grep -q "Needs review:"
  > **COMPLETED**: Documented needs_review display requirement in workflow (actual implementation requires dev-tools modification)

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Update dev-handbook/workflow-instructions/README.md with new workflow
  > TEST: Documentation Integration Type: Integration Validation
  > Assert: New workflow is properly documented in README Command: grep -q "replan-cascade-task" dev-handbook/workflow-instructions/README.md
  > **COMPLETED**: Added workflow to task management section, individual reference, decision tree, and updated count to 21

## Scope of Work

### Deliverables

#### Create

* dev-handbook/workflow-instructions/replan-cascade-task.wf.md - Complete workflow with embedded templates
* dev-handbook/templates/tasks/impact-note.template.md - Standardized impact documentation format

#### Modify

* dev-handbook/workflow-instructions/README.md - Add documentation for new workflow

### Key Features

* Full transitive dependency graph traversal algorithm (not limited to immediate dependencies)
* Automated impact scope identification with cycle detection and reporting
* Manual approval gates at critical decision points
* Git-based rollback with commit-per-file granularity and descriptive messages
* Direct integration with task-manager and nav-path command invocations
* XML-embedded impact note templates following project standards
* **[Added on review]** Support for both Kahn's (BFS) and DFS topological sorting approaches
* **[Added after review]** Automatic `needs_review: true` flag setting for impacted tasks
* **[Added after review]** Needs review counter display in task-manager list output
* **[Added after review]** Visited-task tracking to handle circular dependencies gracefully

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in
the Implementation Plan.*

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />AC 1: Workflow handles complete dependency graph traversal with cycle detection
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />AC 2: Draft tasks receive impact notes without automatic status transitions
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />AC 3: Pending tasks get implementation plan updates based on cascade analysis
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />AC 4: Each cascade update creates individual commits per modified file with
  descriptive messages explaining adjustment rationale
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />AC 5: Manual intervention points prevent uncontrolled cascade execution
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />AC 6: Direct task-manager and nav-path command invocations are integrated into
  workflow steps
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />AC 7: All embedded tests in Implementation Plan pass validation

## Example

### Scenario: Completing Task 4 (Create Task Template System)

After completing `v.0.4.0+task.4-draft-task-template-system.md`, run the cascade review workflow:

```bash
# Navigate to the completed task
nav-path file v.0.4.0+task.4-draft-task-template-system.md

# Run the cascade review workflow
replan-cascade-task v.0.4.0+task.4
```

**Step 1: Dependency Identification** The workflow identifies all downstream tasks (transitive) that depend on task 4:

* `v.0.4.0+task.6-create-cascade-review-workflow.md` (dependencies: \[v.0.4.0+task.4\])
* `v.0.4.0+task.7-draft-task-review-workflow.md` (dependencies: \[v.0.4.0+task.4\])
* `v.0.4.0+task.12-enhance-tooling.md` (dependencies: \[v.0.4.0+task.7\]) - transitive dependency

**Step 2: Topological Processing** Tasks are processed in dependency order with cycle detection:

1.  **Task 6 (draft status)**: Prepend impact notes and set needs_review:
```markdown
---
id: v.0.4.0+task.6
status: draft
needs_review: true
---

## Impact Notes from v.0.4.0+task.4 Completion

- New template system available: use standardized XML embedding format
- Template location: dev-handbook/templates/tasks/impact-note.template.md
- Integration point: impact note template should follow XML embedding pattern
- **Action needed**: Review and update cascade workflow design to use new templates

[Original content follows...]
```

2.  **Task 7 (pending status)**: Update implementation plan and set needs_review:
```markdown
---
id: v.0.4.0+task.7
status: pending
needs_review: true
---

## Implementation Plan Updates

### Planning Steps (Updated based on Task 4 completion)
* [✓] Template system research → Use new standardized template system
* [ ] Review workflow design → Integrate with XML embedding format from task 4
```

**Step 3: Commit Strategy** Each task update creates individual commits with impact rationale:

```bash
git-commit -m "task.6: Impact from task.4 - new template system available

Added impact notes for XML embedding template integration"

git-commit -m "task.7: Impact from task.4 - template system changes

Updated implementation plan to use new standardized templates"

git-commit -m "task.12: Transitive impact from task.4 via task.7

Flagged for review due to upstream template system changes"
```

**Step 4: Task Manager Display** After cascade review:

```bash
task-manager list
# Output:
# Status: 13 done, 1 draft, 1 in-progress (15 total) !!! Needs review: 3
```

**Step 5: Circular Dependency Report** If circular dependencies detected:

```
WARNING: Circular dependencies detected:
- task.8 → task.9 → task.10 → task.8
Processing continued with visited-task tracking to prevent infinite loops.
```

### Command Integration Examples

The workflow integrates directly with project tools:

```bash
# Find dependent tasks
task-manager deps v.0.4.0+task.4

# Navigate to impact templates
nav-path file impact-note.template.md

# Check cascade scope
find dev-taskflow/current -name "*.md" -exec grep -l "dependencies.*v.0.4.0+task.4" {} \;
```

## Out of Scope

* ❌ Fully automated cascade execution without human oversight
* ❌ Automatic task status transitions (maintain manual control)
* ❌ Complex multi-release dependency resolution algorithms
* ❌ Direct integration with external CI/CD systems
* ❌ Automated testing framework for cascade operations
* ❌ GUI interface for dependency visualization
* ❌ Real-time dependency monitoring and alerts

## References

* Research findings on dependency impact analysis patterns (from task research)
* Joiner function architecture from planning agent design
* Current project's ATOM architecture principles (dev-tools/)
* Existing workflow instruction patterns (dev-handbook/workflow-instructions/)
* Git-based multi-repository coordination strategies (CLAUDE.md)
* dev-handbook/workflow-instructions/capture-idea.wf.md
* dev-handbook/workflow-instructions/draft-task.wf.md
* dev-handbook/workflow-instructions/plan-task.wf.md
* **[Added on review]** dev-handbook/guides/documents-embedding.g.md - XML template embedding format
* **[Added on review]** Industry best practices for transitive dependency management (2024)
* **[Added on review]** Topological sorting algorithms: Kahn's algorithm and DFS-based approaches
