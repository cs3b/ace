---
id: v.0.4.0+task.2
status: done
priority: medium
estimate: 2h
dependencies: [v.0.4.0+task.1]
---

# Create capture-idea Workflow Instruction

## Objective

Create a workflow instruction that guides AI agents and developers through using the `capture-it` tool to capture and enhance raw ideas. This workflow
orchestrates the existing tool and focuses on when and how to use it effectively within the specification cycle.

## What: Behavioral Specification

### User Experience

* **Trigger**: User wants to capture a raw idea for future development
* **Process**: AI agent uses `capture-it` with appropriate options
* **Output**: Enhanced idea file ready for future specification phases

### Expected Behavior

1.  Determine appropriate release target for the idea
2.  Choose input method (text, clipboard, file)
3.  Execute `capture-it` with proper options
4.  Verify successful idea creation and enhancement
5.  Provide path to created idea file

### Workflow Contract

* **Prerequisites**: `ideas-manager` tool available (from task 1)
* **Input**: Raw idea text or reference to idea sources
* **Process**: Tool orchestration with context awareness
* **Output**: Path to enhanced idea file

## How: Implementation Plan

### Planning Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Review `ideas-manager` tool interface and options
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Analyze existing workflow instruction patterns
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Define decision tree for release targeting
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Plan integration with project context loading

### Execution Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Create capture-idea.wf.md in
  dev-handbook/workflow-instructions/
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Document `ideas-manager` command usage patterns
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Add decision guidance for release targeting
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Include error handling and troubleshooting
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Create examples showing tool usage
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Define success criteria
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Update workflow-instructions README.md

## Scope of Work

### Deliverables

#### Create

* dev-handbook/workflow-instructions/capture-idea.wf.md

#### Modify

* dev-handbook/workflow-instructions/README.md (add new workflow reference)

## Acceptance Criteria

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Workflow clearly documents `ideas-manager` usage
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Decision guidance for release targeting included
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Examples cover common usage patterns
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Error handling documented
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Integration with project context explained

## Example

### Scenario: Capturing Ideas Using ideas-manager Tool

**User Input**: "I want better error handling in the task manager"

**Workflow Execution:**

```bash
# Step 1: AI uses ideas-manager tool to capture and enhance the idea (defaults to backlog)
# Step 2: Tool automatically loads project context and enhances the idea
capture-it "I want better error handling in the task manager"

# Output: Created: dev-taskflow/backlog/ideas/20250730-1430-better-error-handling-task-manager.md
```

**Result**: The `ideas-manager` tool automatically:

* Loads project context from docs/\*.md files
* Enhances the raw idea with project-specific details
* Generates contextual questions for future specification
* Creates a properly formatted and timestamped idea file

**Follow-up**: AI provides the path to the created idea file for future reference and development planning.

## Implementation Notes

### Completed Deliverables

* ✅ **Created**: `dev-handbook/workflow-instructions/capture-idea.wf.md` - Self-contained workflow instruction following ADR-001 principles
* ✅ **Updated**: `dev-handbook/workflow-instructions/README.md` - Integrated new workflow into ecosystem (updated workflow count to 20, added to decision tree,
  common sequences, and reference sections)

### Key Implementation Decisions

1.  **No --commit flag**: Per user clarification, did not include auto-commit functionality in workflow
2.  **Default to backlog**: Workflow assumes `dev-taskflow/backlog/ideas/` as default target (no release parameter needed)
3.  **Self-contained design**: Embedded all necessary context, examples, and guidance within the workflow file
4.  **Comprehensive coverage**: Included all ideas-manager command options, error handling, and integration patterns
5.  **AI-agent focused**: Structured for autonomous execution by AI agents

### User Clarifications Applied

* Removed --commit flag example from workflow (was implementation detail, not workflow requirement)
* Confirmed ideas-manager tool from task.1 is assumed complete and functional
* Focused scope on idea capture only, not task transition workflow
* Used backlog as default target location

## Out of Scope

* ❌ Automatic task creation
* ❌ Idea validation or approval
* ❌ Complex project analysis
* ❌ Integration with external systems
* ❌ Auto-commit functionality (per user clarification)

## References

* Planning agent research: dev-taskflow/current/v.0.3.0-workflows/backlog/research/how-to-build-planning-agents-without-loosing-control.md
* Existing draft-task workflow: dev-handbook/workflow-instructions/draft-task.wf.md