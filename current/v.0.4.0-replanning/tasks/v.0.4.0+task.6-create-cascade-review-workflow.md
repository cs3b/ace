---
id: v.0.4.0+task.6
status: draft
priority: medium
estimate: 8h
dependencies: [v.0.4.0+task.4]
---

# Create replan-cascade-task Workflow for Dependency Impact Analysis

## 0. Directory Audit ✅

*Command run:*

```bash
find dev-handbook/workflow-instructions -name "*.wf.md" | head -10
```

*Result excerpt:*

```bash
dev-handbook/workflow-instructions/capture-idea.wf.md
dev-handbook/workflow-instructions/draft-task.wf.md
dev-handbook/workflow-instructions/plan-task.wf.md

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

1.  Identify all tasks dependent on the completed task
2.  Process dependencies in topological order
3.  For draft tasks: Add impact notes at the beginning
4.  For pending tasks: Review and update implementation details
5.  Generate new ideas for discovered needs
6.  Commit each task update separately for rollback capability

### Impact Handling Rules

* **Draft tasks**: Add notes section with impacts, preserve draft status
* **Pending tasks**: Update implementation plan based on changes
* **In-progress tasks**: Flag for developer attention only
* **No automatic status changes**: Maintain human control

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

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Analyze current task dependency patterns in dev-taskflow structure
  > TEST: Dependency Pattern Analysis Type: Pre-condition Check  
  > Assert: All dependency patterns and formats are documented Command: find dev-taskflow/current -name "\*.md" -exec grep -l "dependencies:" \{} \\; \| head -5

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Research topological sorting algorithms for dependency graph traversal
  > TEST: Algorithm Selection Validation Type: Research Validation Assert: Optimal algorithm chosen for documentation-based system Command: echo "Topological
  > sort approach documented with complexity analysis"

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Design impact note template format for draft task integration
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Plan rollback strategy with git-based recovery mechanisms
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Define cascade scope boundaries and manual override points

### Execution Steps

*Concrete implementation actions that modify code, create files, or change the system state.*

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Create replan-cascade-task.wf.md workflow file in
  dev-handbook/workflow-instructions/
  > TEST: Workflow File Creation Type: Action Validation Assert: Workflow file exists with proper structure and embedded templates Command: test -f
  > dev-handbook/workflow-instructions/replan-cascade-task.wf.md && grep -q "## Process Steps" dev-handbook/workflow-instructions/replan-cascade-task.wf.md

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Implement dependency identification algorithm with cycle detection
  > TEST: Dependency Detection Logic Type: Algorithm Validation Assert: Cycle detection and topological sort logic is documented and testable Command: grep -q
  > "cycle detection" dev-handbook/workflow-instructions/replan-cascade-task.wf.md

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Create impact-note.template.md in dev-handbook/templates/tasks/ with XML
  embedding
  > TEST: Template Creation Type: File Validation Assert: Impact note template uses XML embedding like other project templates Command: test -f
  > dev-handbook/templates/tasks/impact-note.template.md && grep -q "<template" dev-handbook/templates/tasks/impact-note.template.md

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Document git-based rollback procedures with commit-per-file strategy
  > TEST: Rollback Documentation Type: Documentation Validation Assert: Rollback procedures specify individual file commits with descriptive messages Command:
  > grep -q "commit-per-file\|individual commit" dev-handbook/workflow-instructions/replan-cascade-task.wf.md

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Add cascade execution examples with real task scenarios from current release
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Integrate direct task-manager and nav-path command invocations
  > TEST: Tool Integration Type: Command Integration Assert: Workflow includes direct command invocations for task-manager and nav-path Command: grep -E
  > "(task-manager\|nav-path)" dev-handbook/workflow-instructions/replan-cascade-task.wf.md

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Update dev-handbook/workflow-instructions/README.md with new workflow
  > TEST: Documentation Integration Type: Integration Validation  
  > Assert: New workflow is properly documented in README Command: grep -q "replan-cascade-task" dev-handbook/workflow-instructions/README.md

## Scope of Work

### Deliverables

#### Create

* dev-handbook/workflow-instructions/replan-cascade-task.wf.md - Complete workflow with embedded templates
* dev-handbook/templates/tasks/impact-note.template.md - Standardized impact documentation format

#### Modify

* dev-handbook/workflow-instructions/README.md - Add documentation for new workflow

### Key Features

* Topological dependency graph traversal algorithm (single-release scope)
* Automated impact scope identification with cycle detection
* Manual approval gates at critical decision points
* Git-based rollback with commit-per-file granularity and descriptive messages
* Direct integration with task-manager and nav-path command invocations
* XML-embedded impact note templates following project standards

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in
the Implementation Plan.*

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />AC 1: Workflow handles complete dependency graph traversal with cycle detection
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />AC 2: Draft tasks receive impact notes without automatic status transitions
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />AC 3: Pending tasks get implementation plan updates based on cascade analysis
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />AC 4: Each cascade update creates individual commits per modified file with
  descriptive messages explaining adjustment rationale
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />AC 5: Manual intervention points prevent uncontrolled cascade execution
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />AC 6: Direct task-manager and nav-path command invocations are integrated into
  workflow steps
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />AC 7: All embedded tests in Implementation Plan pass validation

## Example

### Scenario: Completing Task 4 (Create Task Template System)

After completing `v.0.4.0+task.4-draft-task-template-system.md`, run the cascade review workflow:

# Navigate to the completed task
nav-path file v.0.4.0+task.4-draft-task-template-system.md

# Run the cascade review workflow  
replan-cascade-task v.0.4.0+task.4
```

**Step 1: Dependency Identification** The workflow identifies downstream tasks that depend on task 4:

* `v.0.4.0+task.6-create-cascade-review-workflow.md` (dependencies: \[v.0.4.0+task.4\])
* `v.0.4.0+task.7-draft-task-review-workflow.md` (dependencies: \[v.0.4.0+task.4\])

**Step 2: Topological Processing** Tasks are processed in dependency order:

1.  **Task 6 (draft status)**: Add impact notes section at the beginning:
```bash
    ## Impact Notes from v.0.4.0+task.4 Completion
       
    - New template system available: use standardized XML embedding format
    - Template location: dev-handbook/templates/tasks/impact-note.template.md
    - Integration point: impact note template should follow XML embedding pattern


2.  **Task 7 (pending status)**: Update implementation plan:
    ## Implementation Plan Updates
       
    ### Planning Steps (Updated based on Task 4 completion)
    * [✓] Template system research → Use new standardized template system
    * [ ] Review workflow design → Integrate with XML embedding format from task 4


**Step 3: Commit Strategy** Each task update creates individual commits:

git-commit -m "task.6: Add impact notes from task.4 template system completion

Cascade review identified template integration requirements for 
cascade workflow implementation."

git-commit -m "task.7: Update implementation plan based on task.4 completion  

Modified planning steps to leverage new XML embedding template 
system for consistency with project standards."
```

**Step 4: Generated Ideas** New ideas discovered during cascade analysis:

```bash
# Auto-generated idea file
cat > dev-taskflow/backlog/ideas/20250730-cascade-review-template-consistency.md
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